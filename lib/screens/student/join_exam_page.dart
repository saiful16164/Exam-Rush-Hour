import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/exam_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/submission_service.dart';

// A small provider to hold the current student's name and submission ID during the exam
final studentNameProvider = StateProvider<String>((ref) => '');
final currentSubmissionIdProvider = StateProvider<String>((ref) => '');

class JoinExamPage extends ConsumerStatefulWidget {
  const JoinExamPage({super.key});

  @override
  ConsumerState<JoinExamPage> createState() => _JoinExamPageState();
}

class _JoinExamPageState extends ConsumerState<JoinExamPage> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _loadStudentName();
  }

  Future<void> _loadStudentName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final studentRes = await Supabase.instance.client.from('students').select('full_name').eq('id', user.id).maybeSingle();
      if (studentRes != null && studentRes['full_name'] != null && studentRes['full_name'].toString().isNotEmpty && studentRes['full_name'] != user.email) {
        if (mounted) {
          setState(() {
            _nameController.text = studentRes['full_name'];
          });
        }
      } else if (user.userMetadata?['full_name'] != null) {
        if (mounted) {
          setState(() {
            _nameController.text = user.userMetadata!['full_name'];
          });
        }
      }
    }
  }

  Future<void> _joinExam() async {
    final state = GoRouterState.of(context);
    final examCode = state.pathParameters['examCode']!;
    
    final user = ref.read(authProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final exam = await ref.read(examServiceProvider).getExamByCode(examCode);
      if (exam == null) throw Exception('Exam not found');
      if (!exam.isActive) throw Exception('Exam is no longer active');
      if (exam.password != _passwordController.text) throw Exception('Incorrect password');

      final submissionService = SubmissionService();
      final hasSubmitted = await submissionService.hasStudentSubmitted(exam.id, user.id);
      if (hasSubmitted) {
        final submission = await submissionService.getStudentSubmission(exam.id, user.id);
        if (submission != null && mounted) {
          context.push('/student/result', extra: submission);
          return;
        } else {
          throw Exception('You have already submitted this exam, but your submission could not be loaded.');
        }
      }

      // Fetch student name from students table
      final studentRes = await Supabase.instance.client.from('students').select('full_name').eq('id', user.id).maybeSingle();
      
      final inputName = _nameController.text.trim();
      String studentName = user.email ?? 'Unknown Student';
      
      if (inputName.isNotEmpty) {
        studentName = inputName;
      } else if (studentRes != null && studentRes['full_name'] != null && studentRes['full_name'].toString().isNotEmpty) {
        studentName = studentRes['full_name'];
      } else if (user.userMetadata?['full_name'] != null) {
        studentName = user.userMetadata!['full_name'];
      }

      // Upsert the student name to ensure it's saved correctly
      if (studentRes == null || studentRes['full_name'] != studentName) {
        await Supabase.instance.client.from('students').upsert({
          'id': user.id,
          'full_name': studentName,
          'email': user.email,
        });
      }

      // Create submission record immediately
      final subId = await submissionService.createSubmission(exam.id, user.id, studentName);
      
      ref.read(studentNameProvider.notifier).state = studentName;
      ref.read(currentSubmissionIdProvider.notifier).state = subId;

      if (mounted) {
        if (exam.hasMcq) {
          context.go('/exam/${exam.examCode}/mcq');
        } else if (exam.hasWritten) {
          context.go('/exam/${exam.examCode}/written');
        } else {
          context.go('/submission-complete');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    final examCode = state.pathParameters['examCode']!;

    return Scaffold(
      appBar: AppBar(title: Text('Join Exam: $examCode')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Your Full Name', prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Exam Password', prefixIcon: Icon(Icons.lock)),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _joinExam,
                    child: const Text('Enter Exam'),
                  )
          ],
        ),
      ),
    );
  }
}

