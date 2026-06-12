import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class StudentRegisterPage extends ConsumerStatefulWidget {
  const StudentRegisterPage({super.key});

  @override
  ConsumerState<StudentRegisterPage> createState() => _StudentRegisterPageState();
}

class _StudentRegisterPageState extends ConsumerState<StudentRegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final name = _nameController.text.trim();

      await ref.read(authProvider.notifier).requestSignUpOtp(email, password);
      
      if (mounted) setState(() => _isLoading = false);

      // Show OTP Dialog
      if (!mounted) return;
      final otp = await _showOtpDialog();
      if (otp != null && otp.isNotEmpty) {
        setState(() => _isLoading = true);
        await ref.read(authProvider.notifier).verifySignUpOtp(
          email: email,
          otp: otp,
          fullName: name,
          role: UserRole.student,
        );
        if (mounted) context.go('/student/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _showOtpDialog() async {
    final otpController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('A 6-digit code has been sent to your email.'),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'OTP Code', prefixIcon: Icon(Icons.password)),
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, otpController.text.trim()),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register as Student')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person_add, size: 80, color: Color(0xFF1DB954)),
                const SizedBox(height: 24),
                const Text(
                  'Create an Account',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _register,
                        child: const Text('Create Account'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
