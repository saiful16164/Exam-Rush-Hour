import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/mcq_state_provider.dart';
import '../../providers/written_state_provider.dart';
import 'join_exam_page.dart';

class SubmissionComplete extends ConsumerWidget {
  const SubmissionComplete({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            const Text('Exam Submitted Successfully!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Your answers have been saved. You may now close this app or return to the landing page.', textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Clear state
                ref.invalidate(mcqAnswersProvider);
                ref.invalidate(writtenAnswersProvider);
                ref.invalidate(studentNameProvider);
                ref.invalidate(currentSubmissionIdProvider);
                
                context.go('/');
              },
              child: const Text('Back to Home'),
            )
          ],
        ),
      ),
    );
  }
}
