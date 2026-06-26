import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../models/submission.dart';
import '../../services/submission_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/drawing_board.dart';

class ResultsPage extends ConsumerStatefulWidget {
  const ResultsPage({super.key});

  @override
  ConsumerState<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends ConsumerState<ResultsPage> {
  late String _examId;
  List<Submission> _submissions = [];
  bool _isLoading = true;
  final _supabase = Supabase.instance.client;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = GoRouterState.of(context);
    _examId = state.pathParameters['examId']!;
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    try {
      final service = SubmissionService();
      final subs = await service.getSubmissionsForExam(_examId);
      setState(() {
        _submissions = subs;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteSubmission(Submission sub) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Submission'),
        content: Text(
          'Are you sure you want to delete the submission from "${sub.studentName}"?\n\nThis will permanently remove all their answers and marks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleting submission...')),
        );
        await SubmissionService().deleteSubmission(sub.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Submission deleted successfully.')),
          );
          _loadSubmissions();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  Future<int> _getMcqScore(String submissionId) async {
    return await SubmissionService().getMcqScore(submissionId);
  }

  Future<void> _emailMarks(Submission sub, int mcqScore) async {
    if (sub.studentEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No email found for this student.')));
      return;
    }
    final subject = Uri.encodeComponent('Your Exam Result for Exam Rush Hour');
    final body = Uri.encodeComponent(
        'Hello ${sub.studentName},\n\n'
        'Your marks have been published.\n'
        'MCQ Score: $mcqScore\n'
        'Written Marks: ${sub.writtenMarks ?? 'Not Graded'}\n\n'
        'Best Regards,\nYour Teacher'
    );
    final url = Uri.parse('mailto:${sub.studentEmail}?subject=$subject&body=$body');
    if (!await launchUrl(url)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open email app.')));
    }
  }
  void _openDrawingBoard(BuildContext context, String url, bool isPdf, String answerId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 800,
            height: 600,
            child: DrawingBoard(
              onSave: (Uint8List bytes) async {
                Navigator.pop(ctx);
                try {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving graded copy...')));
                  final newUrl = await StorageService().uploadGradedAnswer(answerId, bytes);
                  await SubmissionService().updateGradedAnswerUrl(answerId, newUrl);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Graded copy saved successfully!')));
                  }
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
                }
              },
              child: isPdf 
                ? SfPdfViewer.network(url, canShowScrollHead: false, canShowScrollStatus: false)
                : Image.network(url),
            )
          )
        );
      }
    );
  }

  void _viewWrittenAnswers(Submission sub) async {
    // Fetch written answers
    final answers = await _supabase.from('written_answers').select().eq('submission_id', sub.id).order('page_number', ascending: true);

    if (mounted) {
      final marksController = TextEditingController(text: sub.writtenMarks?.toString() ?? '');
      showDialog(
        context: context,
        builder: (ctx) {
          // Track rotation per page (in quarter turns: 0, 1, 2, 3)
          final Map<int, int> rotationMap = {};
          return StatefulBuilder(
            builder: (ctx, setDialogState) {
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: SizedBox(
                  height: 600,
                  width: double.infinity,
                  child: Column(
                    children: [
                      AppBar(
                        title: const Text('Written Answers'),
                        automaticallyImplyLeading: false,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))],
                      ),
                      Expanded(
                        child: answers.isEmpty
                          ? const Center(child: Text('No written answers uploaded.', style: TextStyle(color: Colors.grey)))
                          : PageView.builder(
                              itemCount: answers.length,
                              itemBuilder: (context, index) {
                                final String url = answers[index]['image_url'];
                                final String answerId = answers[index]['id'];
                                final bool isPdf = url.toLowerCase().contains('.pdf?t=') || url.toLowerCase().endsWith('.pdf');
                                final int quarterTurns = rotationMap[index] ?? 0;
                                
                                Widget contentWidget;
                                if (isPdf) {
                                  contentWidget = SfPdfViewer.network(url);
                                } else {
                                  contentWidget = InteractiveViewer(
                                    child: Transform.rotate(
                                      angle: quarterTurns * math.pi / 2,
                                      child: Image.network(
                                        url,
                                        loadingBuilder: (context, child, progress) {
                                          if (progress == null) return child;
                                          return const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)));
                                        },
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                                      ),
                                    ),
                                  );
                                }

                                return Stack(
                                  children: [
                                    Positioned.fill(child: contentWidget),
                                    Positioned(
                                      top: 16,
                                      right: 16,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FloatingActionButton.extended(
                                            heroTag: 'annotate_$index',
                                            icon: const Icon(Icons.edit),
                                            label: const Text('Annotate'),
                                            onPressed: () => _openDrawingBoard(context, url, isPdf, answerId),
                                          ),
                                          if (!isPdf) ...[
                                            const SizedBox(height: 10),
                                            FloatingActionButton.extended(
                                              heroTag: 'rotate_$index',
                                              icon: const Icon(Icons.rotate_right),
                                              label: const Text('Rotate'),
                                              backgroundColor: Colors.blueGrey[700],
                                              onPressed: () {
                                                setDialogState(() {
                                                  rotationMap[index] = ((rotationMap[index] ?? 0) + 1) % 4;
                                                });
                                              },
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                      ),
                      if (answers.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Swipe to see next pages', style: TextStyle(color: Colors.grey)),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: marksController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Marks',
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () async {
                                final marks = int.tryParse(marksController.text);
                                if (marks != null) {
                                  await SubmissionService().updateWrittenMarks(sub.id, marks);
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  if (!mounted) return;
                                  _loadSubmissions();
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marks saved')));
                                }
                              },
                              child: const Text('Save Marks'),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                )
              );
            },
          );
        }
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Results')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _submissions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No submissions yet.', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _submissions.length,
              itemBuilder: (context, index) {
                final sub = _submissions[index];
                return FutureBuilder<int>(
                  future: _getMcqScore(sub.id),
                  builder: (ctx, snapshot) {
                    final mcqScore = snapshot.data ?? 0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF1DB954).withOpacity(0.1),
                                  child: Text('$mcqScore', style: const TextStyle(color: Color(0xFF1DB954), fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(sub.studentName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text('Submitted: ${sub.submittedAt.toLocal().toString().split('.')[0]}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Written Marks', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        const SizedBox(height: 4),
                                        Text(
                                          sub.writtenMarks != null ? '${sub.writtenMarks}' : 'Not Graded',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: sub.writtenMarks != null ? Colors.green : Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: () => _deleteSubmission(sub),
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.red,
                                  tooltip: 'Delete Submission',
                                ),
                                const Spacer(),
                                OutlinedButton.icon(
                                  onPressed: () => _emailMarks(sub, mcqScore),
                                  icon: const Icon(Icons.email, size: 18),
                                  label: const Text('Email Marks'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _viewWrittenAnswers(sub),
                                  icon: const Icon(Icons.visibility, size: 18),
                                  label: const Text('View Written'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
