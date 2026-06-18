import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../models/submission.dart';
import '../../services/submission_service.dart';

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

  void _viewWrittenAnswers(Submission sub) async {
    // Fetch written answers
    final answers = await _supabase.from('written_answers').select().eq('submission_id', sub.id).order('page_number', ascending: true);

    if (mounted) {
      final marksController = TextEditingController(text: sub.writtenMarks?.toString() ?? '');
      showDialog(
        context: context,
        builder: (ctx) {
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
                            final bool isPdf = url.toLowerCase().contains('.pdf?t=') || url.toLowerCase().endsWith('.pdf');
                            
                            if (isPdf) {
                              return SfPdfViewer.network(url);
                            }

                            return InteractiveViewer(
                              child: Image.network(
                                url,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)));
                                },
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                              ),
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
