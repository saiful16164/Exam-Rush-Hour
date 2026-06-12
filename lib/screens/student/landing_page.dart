import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndRedirect();
    });
  }

  Future<void> _checkAuthAndRedirect() async {
    final role = await ref.read(userRoleProvider.future);
    if (!mounted) return;
    
    if (role == UserRole.teacher) {
      context.go('/teacher/dashboard');
    } else if (role == UserRole.student) {
      context.go('/student/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.school, size: 100, color: Color(0xFF1DB954)),
                const SizedBox(height: 24),
                const Text(
                  'ExamFlow',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'The Premium Examination Platform',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: () => context.push('/student/login'),
                  icon: const Icon(Icons.person),
                  label: const Text('I am a Student'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.push('/teacher/login'),
                  icon: const Icon(Icons.admin_panel_settings, color: Color(0xFF1DB954)),
                  label: const Text('I am a Teacher', style: TextStyle(color: Color(0xFF1DB954))),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF1DB954), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
