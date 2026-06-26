import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Future<String?> _openDrawingBoard(BuildContext context, String url, bool isPdf, String answerId, {int initialRotation = 0}) async {
    String? gradedUrl;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 800,
            height: 600,
            child: DrawingBoard(
              initialRotation: initialRotation,
              onSave: (Uint8List bytes) async {
                try {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving graded copy...')));
                  final newUrl = await StorageService().uploadGradedAnswer(answerId, bytes);
                  await SubmissionService().updateGradedAnswerUrl(answerId, newUrl);
                  gradedUrl = newUrl;
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Graded copy saved successfully!')));
                  }
                } catch (e) {
                  if (ctx.mounted) Navigator.pop(ctx);
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
    return gradedUrl;
  }

  void _viewWrittenAnswers(Submission sub) async {
    // Fetch written answers
    final answers = await _supabase.from('written_answers').select().eq('submission_id', sub.id).order('page_number', ascending: true);

    if (mounted) {
      // Make a mutable copy so we can update graded URLs in-place
      final mutableAnswers = List<Map<String, dynamic>>.from(
        (answers as List).map((a) {
          final map = Map<String, dynamic>.from(a);
          if (map['graded_image_url'] != null) {
            // Append cache buster to existing graded image urls so we always see the latest
            map['graded_image_url'] = '${map['graded_image_url']}?t=${DateTime.now().millisecondsSinceEpoch}';
          }
          return map;
        }),
      );
      
      showDialog(
        context: context,
        builder: (ctx) {
          return _WrittenAnswersDialog(
            submission: sub,
            initialAnswers: mutableAnswers,
            openDrawingBoard: _openDrawingBoard,
            onSaveMarks: _loadSubmissions,
          );
        },
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

class _WrittenAnswersDialog extends StatefulWidget {
  final Submission submission;
  final List<Map<String, dynamic>> initialAnswers;
  final Future<String?> Function(BuildContext, String, bool, String, {int initialRotation}) openDrawingBoard;
  final VoidCallback onSaveMarks;

  const _WrittenAnswersDialog({
    required this.submission,
    required this.initialAnswers,
    required this.openDrawingBoard,
    required this.onSaveMarks,
  });

  @override
  State<_WrittenAnswersDialog> createState() => _WrittenAnswersDialogState();
}

class _WrittenAnswersDialogState extends State<_WrittenAnswersDialog> {
  late final PageController _pageController;
  late final List<Map<String, dynamic>> _answers;
  late final TextEditingController _marksController;
  final FocusNode _focusNode = FocusNode();
  final FocusNode _marksFocusNode = FocusNode();
  final Map<int, int> _rotationMap = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _answers = List<Map<String, dynamic>>.from(widget.initialAnswers);
    _marksController = TextEditingController(text: widget.submission.writtenMarks?.toString() ?? '');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _marksController.dispose();
    _focusNode.dispose();
    _marksFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 600,
        width: double.infinity,
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (FocusNode node, KeyEvent event) {
            // If user is focused on the marks text field, don't change pages with arrow keys
            if (_marksFocusNode.hasFocus) {
              return KeyEventResult.ignored;
            }
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                if (_pageController.hasClients) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                if (_pageController.hasClients) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Column(
            children: [
              AppBar(
                title: const Text('Written Answers'),
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              Expanded(
                child: _answers.isEmpty
                    ? const Center(
                        child: Text(
                          'No written answers uploaded.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: _answers.length,
                        itemBuilder: (context, index) {
                          final String originalUrl = _answers[index]['image_url'];
                          final String? gradedUrl = _answers[index]['graded_image_url'];
                          final String displayUrl = gradedUrl ?? originalUrl;
                          final String answerId = _answers[index]['id'];
                          final bool originalIsPdf = originalUrl.toLowerCase().contains('.pdf') ||
                              originalUrl.toLowerCase().endsWith('.pdf');
                          final int quarterTurns = _rotationMap[index] ?? 0;

                          Widget contentWidget;
                          if (gradedUrl != null) {
                            // Graded copy is always saved as a PNG image
                            contentWidget = InteractiveViewer(
                              child: RotatedBox(
                                quarterTurns: quarterTurns,
                                child: Image.network(
                                  displayUrl,
                                  key: ValueKey(displayUrl),
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF1DB954),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.error),
                                ),
                              ),
                            );
                          } else if (originalIsPdf) {
                            contentWidget = SfPdfViewer.network(displayUrl);
                          } else {
                            contentWidget = InteractiveViewer(
                              child: RotatedBox(
                                quarterTurns: quarterTurns,
                                child: Image.network(
                                  displayUrl,
                                  key: ValueKey(displayUrl),
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF1DB954),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.error),
                                ),
                              ),
                            );
                          }

                          return Stack(
                            children: [
                              Positioned.fill(child: contentWidget),
                              if (gradedUrl != null)
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Graded',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FloatingActionButton.extended(
                                      heroTag: 'annotate_$index',
                                      icon: const Icon(Icons.edit),
                                      label: Text(gradedUrl != null ? 'Re-Annotate' : 'Annotate'),
                                      onPressed: () async {
                                        final newGradedUrl = await widget.openDrawingBoard(
                                          context,
                                          originalUrl,
                                          originalIsPdf,
                                          answerId,
                                          initialRotation: quarterTurns,
                                        );
                                        if (newGradedUrl != null) {
                                          setState(() {
                                            _answers[index]['graded_image_url'] =
                                                '$newGradedUrl?t=${DateTime.now().millisecondsSinceEpoch}';
                                            _rotationMap[index] = 0;
                                          });
                                        }
                                      },
                                    ),
                                    if (!originalIsPdf) ...[
                                      const SizedBox(height: 10),
                                      FloatingActionButton.extended(
                                        heroTag: 'rotate_$index',
                                        icon: const Icon(Icons.rotate_right),
                                        label: const Text('Rotate'),
                                        backgroundColor: Colors.blueGrey[700],
                                        onPressed: () {
                                          setState(() {
                                            _rotationMap[index] = ((_rotationMap[index] ?? 0) + 1) % 4;
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
              if (_answers.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Swipe or use Left/Right arrows to see next pages',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _marksController,
                        focusNode: _marksFocusNode,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Marks',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final marks = int.tryParse(_marksController.text);
                        if (marks != null) {
                          await SubmissionService().updateWrittenMarks(widget.submission.id, marks);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          widget.onSaveMarks();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Marks saved')),
                          );
                        }
                      },
                      child: const Text('Save Marks'),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
