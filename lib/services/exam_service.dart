import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exam.dart';
import '../models/mcq_question.dart';
import '../models/written_question.dart';

class ExamService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Exam>> getActiveExams() async {
    final response = await _supabase
        .from('exams')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);
    
    return (response as List).map((e) => Exam.fromJson(e)).toList();
  }

  Future<List<Exam>> getTeacherExams() async {
    final response = await _supabase
        .from('exams')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List).map((e) => Exam.fromJson(e)).toList();
  }

  Future<Exam?> getExamByCode(String code) async {
    final response = await _supabase
        .from('exams')
        .select()
        .eq('exam_code', code)
        .maybeSingle();
    
    if (response == null) return null;
    return Exam.fromJson(response);
  }

  Future<List<McqQuestion>> getMcqQuestions(String examId) async {
    final response = await _supabase
        .from('mcq_questions')
        .select()
        .eq('exam_id', examId)
        .order('order_index', ascending: true);
    
    return (response as List).map((e) => McqQuestion.fromJson(e)).toList();
  }

  Future<List<WrittenQuestion>> getWrittenQuestions(String examId) async {
    final response = await _supabase
        .from('written_questions')
        .select()
        .eq('exam_id', examId)
        .order('uploaded_at', ascending: true);
    
    return (response as List).map((e) => WrittenQuestion.fromJson(e)).toList();
  }

  Future<WrittenQuestion?> getWrittenQuestion(String examId) async {
    final res = await getWrittenQuestions(examId);
    return res.isNotEmpty ? res.first : null;
  }

  Future<void> updateExamStatus(String examId, bool isActive) async {
    await _supabase
        .from('exams')
        .update({'is_active': isActive})
        .eq('id', examId);
  }

  Future<void> deleteExam(String examId) async {
    await _supabase.from('exams').delete().eq('id', examId);
  }
}
