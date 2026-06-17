import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_provider.g.dart';

@riverpod
class Auth extends _$Auth {
  @override
  User? build() {
    return Supabase.instance.client.auth.currentUser;
  }

  Future<void> signIn(String email, String password) async {
    final res = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    state = res.user;
  }

  Future<void> requestSignUpOtp(String email, String password) async {
    await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> verifySignUpOtp({
    required String email,
    required String otp,
    required String fullName,
    required UserRole role,
    String? secretCode,
  }) async {
    if (role == UserRole.teacher && secretCode != '2021331541') {
      throw Exception('Invalid Admin Secret Code');
    }

    final res = await Supabase.instance.client.auth.verifyOTP(
      email: email,
      token: otp,
      type: OtpType.signup,
    );

    if (res.user != null) {
      if (role == UserRole.teacher) {
        await Supabase.instance.client.from('teachers').insert({
          'id': res.user!.id,
          'full_name': fullName,
          'email': email,
        });
      } else if (role == UserRole.student) {
        await Supabase.instance.client.from('students').insert({
          'id': res.user!.id,
          'full_name': fullName,
          'email': email,
        });
      }
      state = res.user;
    } else {
      throw Exception('Failed to verify OTP');
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    state = null;
  }
}

enum UserRole { teacher, student, unknown }

@riverpod
Future<UserRole> userRole(UserRoleRef ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return UserRole.unknown;

  final supabase = Supabase.instance.client;
  
  // Check if teacher
  final teacherRes = await supabase.from('teachers').select('id').eq('id', user.id).maybeSingle();
  if (teacherRes != null) return UserRole.teacher;

  // Check if student
  final studentRes = await supabase.from('students').select('id').eq('id', user.id).maybeSingle();
  if (studentRes != null) return UserRole.student;

  return UserRole.unknown;
}

