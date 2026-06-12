import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../models/exam.dart';
import '../../models/mcq_question.dart';
import '../../providers/exam_provider.dart';
import '../../providers/mcq_state_provider.dart';
import '../../services/exam_service.dart';
import '../../services/submission_service.dart';
import 'join_exam_page.dart';

class McqExamScreen extends ConsumerStatefulWidget {
  const McqExamScreen({super.key});

  @override
  ConsumerState<McqExamScreen> createState() => _McqExamScreenState();
}

class _McqExamScreenState extends ConsumerState<McqExamScreen> {
  late String _examCode;
  Exam? _exam;
  List<McqQuestion> _questions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
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
        _questions = await examService.getMcqQuestions(_exam!.id);
        ref.read(mcqTimerProvider.notifier).startTimer(_exam!.mcqTimeMinutes);
      }
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _submitMcq() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    ref.read(mcqTimerProvider.notifier).stopTimer();

    try {
      final submissionId = ref.read(currentSubmissionIdProvider);
      final answers = ref.read(mcqAnswersProvider);

      await SubmissionService().submitMcqAnswers(submissionId, answers);

      if (mounted) {
        if (_exam!.hasWritten) {
          context.go('/exam/$_examCode/written');
        } else {
          context.go('/submission-complete');
        }
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
    final timeRemaining = ref.watch(mcqTimerProvider);
    final answers = ref.watch(mcqAnswersProvider);

    // Auto submit check
    if (timeRemaining <= 0 && !_isLoading && !_isSubmitting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _submitMcq();
      });
    }

    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_exam == null) return const Scaffold(body: Center(child: Text('Exam not found')));

    final currentQ = _questions.isNotEmpty ? _questions[_currentIndex] : null;

    final minutes = timeRemaining ~/ 60;
    final seconds = timeRemaining % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final isTimeLow = timeRemaining < 300;

    return Scaffold(
      appBar: AppBar(
        title: Text(_exam!.title),
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
        ? const Center(child: CircularProgressIndicator())
        : currentQ == null 
          ? const Center(child: Text('No MCQ questions available.'))
          : Column(
              children: [
                LinearProgressIndicator(value: (_currentIndex + 1) / _questions.length),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Question ${_currentIndex + 1} of ${_questions.length}'),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(currentQ.questionText, style: const TextStyle(fontSize: 18)),
                            const SizedBox(height: 24),
                            _buildOption(currentQ.id, 'A', currentQ.optionA, answers[currentQ.id]),
                            _buildOption(currentQ.id, 'B', currentQ.optionB, answers[currentQ.id]),
                            _buildOption(currentQ.id, 'C', currentQ.optionC, answers[currentQ.id]),
                            _buildOption(currentQ.id, 'D', currentQ.optionD, answers[currentQ.id]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                        child: const Text('Previous'),
                      ),
                      if (_currentIndex < _questions.length - 1)
                        ElevatedButton(
                          onPressed: () => setState(() => _currentIndex++),
                          child: const Text('Next'),
                        )
                      else
                        ElevatedButton(
                          onPressed: _submitMcq,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          child: const Text('Submit MCQ'),
                        ),
                    ],
                  ),
                )
              ],
            ),
    );
  }

  Widget _buildOption(String qId, String optionId, String text, String? selectedValue) {
    final isSelected = selectedValue == optionId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () {
          ref.read(mcqAnswersProvider.notifier).selectAnswer(qId, optionId);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? Colors.blue : Colors.grey),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? Colors.blue.withOpacity(0.1) : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isSelected ? Colors.blue : Colors.grey.shade300,
                child: Text(optionId, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 14)),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(text)),
            ],
          ),
        ),
      ),
    );
  }
}
