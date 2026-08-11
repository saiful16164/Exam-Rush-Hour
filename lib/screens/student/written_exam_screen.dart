import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/exam.dart';
import '../../models/written_question.dart';
import '../../providers/auth_provider.dart';
import '../../providers/exam_provider.dart';
import '../../providers/written_state_provider.dart';
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
  bool _isProcessingFile = false;

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
        var currentSubId = ref.read(currentSubmissionIdProvider);
        if (currentSubId.isEmpty) {
          final user = ref.read(authProvider);
          if (user != null) {
            final studentName = ref.read(studentNameProvider);
            currentSubId = await SubmissionService().getOrCreateSubmission(
              _exam!.id,
              user.id,
              studentName.isNotEmpty ? studentName : (user.email ?? 'Unknown Student'),
            );
            ref.read(currentSubmissionIdProvider.notifier).state = currentSubId;
          }
        }
        ref.read(writtenAnswersProvider.notifier).clear();
      }
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _extractCleanExtension(String nameOrPath) {
    if (nameOrPath.isEmpty) return 'png';
    final pathOnly = nameOrPath.split('?').first;
    final fileName = pathOnly.split(RegExp(r'[/\\]')).last;
    final parts = fileName.split('.');
    if (parts.length > 1) {
      final ext = parts.last.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (ext.isNotEmpty && ext.length <= 5) {
        return ext;
      }
    }
    return 'png';
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isProcessingFile = true);
    
    try {
      List<Map<String, dynamic>> files = [];

      try {
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
          withData: true,
        );

        if (result != null && result.files.isNotEmpty) {
          for (var file in result.files) {
            Uint8List? bytes = file.bytes;
            if (bytes == null && file.path != null && file.path!.isNotEmpty) {
              bytes = await File(file.path!).readAsBytes();
            }
            if (bytes != null && bytes.isNotEmpty) {
              final ext = _extractCleanExtension(file.name.isNotEmpty ? file.name : (file.path ?? ''));
              files.add({'bytes': bytes, 'ext': ext});
            }
          }
        }
      } catch (fpError) {
        debugPrint('FilePicker error, falling back to ImagePicker: $fpError');
        final ImagePicker picker = ImagePicker();
        final List<XFile> images = await picker.pickMultiImage(imageQuality: 70);
        for (var image in images) {
          final bytes = await image.readAsBytes();
          if (bytes.isNotEmpty) {
            final ext = _extractCleanExtension(image.name.isNotEmpty ? image.name : image.path);
            files.add({'bytes': bytes, 'ext': ext});
          }
        }
      }

      if (files.isNotEmpty) {
        ref.read(writtenAnswersProvider.notifier).addImages(files);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error selecting files: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessingFile = false);
    }
  }

  Future<void> _submitWritten() async {
    if (_isSubmitting) return;

    final pages = ref.read(writtenAnswersProvider);
    if (pages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one answer sheet before submitting.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    ref.read(writtenTimerProvider.notifier).stopTimer();

    try {
      var submissionId = ref.read(currentSubmissionIdProvider);
      if (submissionId.isEmpty && _exam != null) {
        final user = ref.read(authProvider);
        if (user != null) {
          final studentName = ref.read(studentNameProvider);
          submissionId = await SubmissionService().getOrCreateSubmission(
            _exam!.id,
            user.id,
            studentName.isNotEmpty ? studentName : (user.email ?? 'Unknown Student'),
          );
          ref.read(currentSubmissionIdProvider.notifier).state = submissionId;
        }
      }

      if (submissionId.isEmpty) {
        throw Exception('Could not determine submission ID. Please try joining the exam again.');
      }

      await SubmissionService().submitWrittenAnswers(submissionId, pages);

      ref.read(writtenAnswersProvider.notifier).clear();

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
                            icon: _isProcessingFile 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.photo_library),
                            label: Text(_isProcessingFile ? 'Loading...' : 'Upload Answer'),
                            onPressed: _isProcessingFile ? null : _pickFromGallery,
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isProcessingFile && answerPages.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
                                Text('Processing file... Please wait.'),
                              ],
                            ),
                          )
                        : answerPages.isEmpty
                          ? const Center(child: Text('No pages captured yet.'))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: answerPages.length + (_isProcessingFile ? 1 : 0),
                              itemBuilder: (ctx, idx) {
                                if (idx == answerPages.length) {
                                  return Container(
                                    margin: const EdgeInsets.all(8),
                                    width: 120,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(strokeWidth: 2),
                                          SizedBox(height: 8),
                                          Text('Adding file...', style: TextStyle(fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                final isPdf = answerPages[idx]['ext'] == 'pdf';
                                return Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.all(8),
                                      width: 120,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        color: isPdf ? Colors.red.shade50 : null,
                                        image: isPdf ? null : DecorationImage(
                                          image: MemoryImage(answerPages[idx]['bytes'] as Uint8List),
                                          fit: BoxFit.cover,
                                        )
                                      ),
                                      child: isPdf 
                                          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.picture_as_pdf, size: 40, color: Colors.red), SizedBox(height: 8), Text('PDF Document', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red))]))
                                          : null,
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
                        onPressed: (answerPages.isEmpty || _isProcessingFile) ? null : _submitWritten,
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
