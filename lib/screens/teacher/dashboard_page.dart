import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/exam_provider.dart';


class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final examsAsyncValue = ref.watch(teacherExamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: const BoxDecoration(
              color: Color(0xFF1DB954),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  user?.userMetadata?['full_name'] ?? 'Teacher',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, color: Color(0xFF1DB954)),
                  label: const Text('Create New Exam', style: TextStyle(color: Color(0xFF1DB954))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: () => context.push('/teacher/exam/create'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Your Exams',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          Expanded(
            child: examsAsyncValue.when(
              data: (exams) {
                if (exams.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No exams found.', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: exams.length,
                  itemBuilder: (context, index) {
                    final exam = exams[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    exam.title,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Switch(
                                  value: exam.isActive,
                                  activeColor: const Color(0xFF1DB954),
                                  onChanged: (val) async {
                                    await ref.read(examServiceProvider).updateExamStatus(exam.id, val);
                                    ref.invalidate(teacherExamsProvider);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Code: ${exam.examCode}', style: TextStyle(color: Colors.grey[700])),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (exam.hasMcq)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('MCQ', style: TextStyle(color: Colors.blue, fontSize: 12)),
                                  ),
                                if (exam.hasWritten)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Written', style: TextStyle(color: Colors.orange, fontSize: 12)),
                                  ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.assessment, color: Color(0xFF1DB954)),
                                  label: const Text('Results', style: TextStyle(color: Color(0xFF1DB954))),
                                  onPressed: () => context.push('/teacher/exam/${exam.id}/results'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: Icon(Icons.edit, color: Colors.grey[700]),
                                  label: Text('Edit', style: TextStyle(color: Colors.grey[700])),
                                  onPressed: () => context.push('/teacher/exam/${exam.id}/edit', extra: exam),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
