import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/exam.dart';
import '../../models/written_question.dart';
import '../../providers/exam_provider.dart';
import '../../providers/written_state_provider.dart';
import '../../services/exam_service.dart';
import '../../services/submission_service.dart';
import 'join_exam_page.dart';

class WrittenExamScreen extends ConsumerStatefulWidget {
  const WrittenExamScreen({super.key});

  @override
  ConsumerState<WrittenExamScreen> createState() => _WrittenExamScreenState();
}

class _WrittenExamScreenState extends ConsumerState<WrittenExamScreen> {
  late String _examCode;
  Exam? _exam;
  WrittenQuestion? _question;
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_exam == null) {
      final state = GoRouterState.of(context);
      _examCode = state.pathParameters['examCode']!;
      _loadExamData();
    }
  }

  Future<void> _loadExamData() async {
    try {
      final examService = ref.read(examServiceProvider);
      _exam = await examService.getExamByCode(_examCode);
      if (_exam != null) {
        _question = await examService.getWrittenQuestion(_exam!.id);
        if (_question != null && _question!.fileType == 'pdf') {
          try {
            final response = await Supabase.instance.client.storage
                .from('written-questions')
                .download(_question!.fileUrl.split('written-questions/').last);
            _pdfBytes = response;
          } catch (e) {
            debugPrint('Error downloading PDF bytes: $e');
          }
        }
        ref.read(writtenTimerProvider.notifier).startTimer(_exam!.writtenTimeMinutes);
      }
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final ext = image.path.split('.').last;
      ref.read(writtenAnswersProvider.notifier).addImages([{'bytes': bytes, 'ext': ext}]);
    }
  }

  Future<void> _submitWritten() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    ref.read(writtenTimerProvider.notifier).stopTimer();

    try {
      final submissionId = ref.read(currentSubmissionIdProvider);
      final pages = ref.read(writtenAnswersProvider);

      await SubmissionService().submitWrittenAnswers(submissionId, pages);

      if (mounted) {
        context.go('/submission-complete');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeRemaining = ref.watch(writtenTimerProvider);
    final answerPages = ref.watch(writtenAnswersProvider);

    // Auto submit check
    if (timeRemaining <= 0 && !_isLoading && !_isSubmitting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _submitWritten();
      });
    }

    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_exam == null) return const Scaffold(body: Center(child: Text('Exam not found')));

    final minutes = timeRemaining ~/ 60;
    final seconds = timeRemaining % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final isTimeLow = timeRemaining < 300;

    return Scaffold(
      appBar: AppBar(
        title: Text(_exam!.title + ' (Written)'),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                timeStr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isTimeLow ? Colors.red : null,
                ),
              ),
            ),
          )
        ],
      ),
      body: _isSubmitting
        ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Uploading files... Please wait.')]))
        : Column(
            children: [
              // Top half: Question Viewer
              Expanded(
                flex: 3,
                child: Container(
                  color: Colors.grey.shade300,
                  child: _question == null 
                    ? const Center(child: Text('No written question file provided.'))
                    : _question!.fileType == 'pdf'
                      ? _pdfBytes != null
                          ? SfPdfViewer.memory(_pdfBytes!)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                const Text('Loading PDF Document...'),
                              ],
                            )
                      : InteractiveViewer(
                          child: Image.network(
                            _question!.fileUrl,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                          ),
                        ),
                ),
              ),
              const Divider(height: 1),
              // Bottom half: Uploads
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Your Answer Sheets:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Capture Page'),
                            onPressed: _pickImage,
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: answerPages.isEmpty
                        ? const Center(child: Text('No pages captured yet.'))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: answerPages.length,
                            itemBuilder: (ctx, idx) {
                              return Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.all(8),
                                    width: 120,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      image: DecorationImage(
                                        image: MemoryImage(answerPages[idx]['bytes'] as Uint8List),
                                        fit: BoxFit.cover,
                                      )
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                                      onPressed: () => ref.read(writtenAnswersProvider.notifier).removeImage(idx),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      color: Colors.black54,
                                      child: Text('Page ${idx+1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                  )
                                ],
                              );
                            }
                          ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                        onPressed: answerPages.isEmpty ? null : _submitWritten,
                        child: const Text('Submit Written Answers'),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
    );
  }
}
