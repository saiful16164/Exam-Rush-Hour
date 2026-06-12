import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'screens/student/landing_page.dart';
import 'screens/student/join_exam_page.dart';
import 'screens/student/mcq_exam_screen.dart';
import 'screens/student/written_exam_screen.dart';
import 'screens/student/submission_complete.dart';
import 'screens/student/student_result_page.dart';
import 'screens/teacher/login_page.dart';
import 'screens/teacher/register_page.dart';
import 'screens/teacher/dashboard_page.dart';
import 'screens/teacher/create_exam_page.dart';
import 'screens/teacher/results_page.dart';

import '../../models/submission.dart';

import 'screens/student/student_login_page.dart';
import 'screens/student/student_register_page.dart';
import 'screens/student/student_dashboard.dart';

part 'router.g.dart';

@riverpod
GoRouter router(RouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Student Routes
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: '/student/login',
        builder: (context, state) => const StudentLoginPage(),
      ),
      GoRoute(
        path: '/student/register',
        builder: (context, state) => const StudentRegisterPage(),
      ),
      GoRoute(
        path: '/student/dashboard',
        builder: (context, state) => const StudentDashboard(),
      ),
      GoRoute(
        path: '/student/result',
        builder: (context, state) => StudentResultPage(submission: state.extra as Submission),
      ),
      GoRoute(
        path: '/join/:examCode',
        builder: (context, state) => const JoinExamPage(),
      ),
      GoRoute(
        path: '/exam/:examCode/mcq',
        builder: (context, state) => const McqExamScreen(),
      ),
      GoRoute(
        path: '/exam/:examCode/written',
        builder: (context, state) => const WrittenExamScreen(),
      ),
      GoRoute(
        path: '/submission-complete',
        builder: (context, state) => const SubmissionComplete(),
      ),
      // Teacher Routes
      GoRoute(
        path: '/teacher/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/teacher/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/teacher/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/teacher/exam/create',
        builder: (context, state) => const CreateExamPage(),
      ),
      GoRoute(
        path: '/teacher/exam/:examId/edit',
        builder: (context, state) => CreateExamPage(existingExam: state.extra as dynamic),
      ),
      GoRoute(
        path: '/teacher/exam/:examId/results',
        builder: (context, state) => const ResultsPage(),
      ),
    ],
  );
}
