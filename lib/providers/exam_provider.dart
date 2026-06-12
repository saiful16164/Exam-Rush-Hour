import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/exam.dart';
import '../services/exam_service.dart';

part 'exam_provider.g.dart';

@riverpod
ExamService examService(ExamServiceRef ref) {
  return ExamService();
}

@riverpod
Future<List<Exam>> activeExams(ActiveExamsRef ref) {
  return ref.watch(examServiceProvider).getActiveExams();
}

@riverpod
Future<List<Exam>> teacherExams(TeacherExamsRef ref) {
  return ref.watch(examServiceProvider).getTeacherExams();
}

@riverpod
Future<Exam?> currentExam(CurrentExamRef ref, String code) {
  return ref.watch(examServiceProvider).getExamByCode(code);
}
