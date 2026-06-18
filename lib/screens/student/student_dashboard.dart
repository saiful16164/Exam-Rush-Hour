import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/exam_provider.dart';
import '../../services/submission_service.dart';
import '../../models/submission.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  int _currentIndex = 0;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Rush Hour Student'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (mounted) context.go('/student/login');
            },
          )
        ],
      ),
      body: _currentIndex == 0 ? _buildActiveExamsTab() : _buildPerformanceTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF1DB954),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Active Exams'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'My Performance'),
        ],
      ),
    );
  }

  Widget _buildActiveExamsTab() {
    final activeExamsAsyncValue = ref.watch(activeExamsProvider);
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search Exam Code or Title...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
          ),
        ),
        Expanded(
          child: activeExamsAsyncValue.when(
            data: (exams) {
              final filteredExams = exams.where((e) {
                return e.examCode.toLowerCase().contains(_searchQuery) || 
                       e.title.toLowerCase().contains(_searchQuery);
              }).toList();

              if (filteredExams.isEmpty) {
                return const Center(child: Text('No active exams found.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredExams.length,
                itemBuilder: (ctx, idx) {
                  final exam = filteredExams[idx];
                  final user = ref.read(authProvider);
                  
                  return FutureBuilder<Submission?>(
                    future: user != null ? SubmissionService().getStudentSubmission(exam.id, user.id) : Future.value(null),
                    builder: (context, snapshot) {
                      final submission = snapshot.data;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(exam.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('Code: ${exam.examCode}\n${exam.description ?? ''}'),
                          ),
                          trailing: submission != null
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black87),
                                onPressed: () => context.push('/student/result', extra: submission),
                                child: const Text('View Result'),
                              )
                            : ElevatedButton(
                                onPressed: () => context.push('/join/${exam.examCode}'),
                                child: const Text('Join'),
                              ),
                        ),
                      );
                    }
                  );
                }
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceTab() {
    final user = ref.read(authProvider);
    if (user == null) return const Center(child: Text('Not logged in.'));

    return FutureBuilder<List<Submission>>(
      future: SubmissionService().getSubmissionsForStudent(user.id),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final submissions = snapshot.data ?? [];
        if (submissions.isEmpty) {
          return const Center(child: Text('You have not taken any exams yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: submissions.length,
          itemBuilder: (context, index) {
            final sub = submissions[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text('Exam Date: ${sub.submittedAt.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Tap to view your detailed result.'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF1DB954)),
                onTap: () {
                  // Wait, we need the exam code for the route, but we might only have examId. 
                  // For simplicity, we can pass just the submission to a generic result page.
                  // Actually, our previous route was /exam/:examCode/result. 
                  // Let's create a route just for student result view without examCode: /student/result
                  context.push('/student/result', extra: sub);
                },
              ),
            );
          },
        );
      },
    );
  }
}
