import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/submission.dart';
import 'storage_service.dart';

class SubmissionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> createSubmission(String examId, String studentId, String studentName) async {
    final response = await _supabase.from('submissions').insert({
      'exam_id': examId,
      'student_id': studentId,
      'student_name': studentName,
    }).select().single();
    
    return response['id'];
  }

  Future<List<Submission>> getSubmissionsForStudent(String studentId) async {
    final response = await _supabase
        .from('submissions')
        .select()
        .eq('student_id', studentId)
        .order('submitted_at', ascending: false);
    return (response as List).map((e) => Submission.fromJson(e)).toList();
  }

  Future<void> submitMcqAnswers(String submissionId, Map<String, String> answers) async {
    if (answers.isEmpty) return;

    final List<Map<String, dynamic>> payload = answers.entries.map((e) => {
      'submission_id': submissionId,
      'question_id': e.key,
      'selected_option': e.value,
    }).toList();

    await _supabase.from('mcq_answers').insert(payload);

    // Calculate score and store it immediately
    final score = await getMcqScore(submissionId);
    await _supabase.from('submissions').update({'mcq_marks': score}).eq('id', submissionId);
  }

  Future<void> submitWrittenAnswer(String submissionId, String imageUrl, int pageNumber) async {
    await _supabase.from('written_answers').insert({
      'submission_id': submissionId,
      'image_url': imageUrl,
      'page_number': pageNumber,
    });
  }

  Future<void> submitWrittenAnswers(String submissionId, List<dynamic> pages) async {

    final storage = StorageService();
    for (int i = 0; i < pages.length; i++) {
      final data = pages[i] as Map<String, dynamic>;
      final url = await storage.uploadWrittenAnswer(
        submissionId, 
        i + 1, 
        data['bytes'] as Uint8List, 
        data['ext'] as String
      );
      await submitWrittenAnswer(submissionId, url, i + 1);
    }
  }

  Future<List<Submission>> getSubmissionsForExam(String examId) async {
    final response = await _supabase
        .from('submissions')
        .select('*, students(email)')
        .eq('exam_id', examId)
        .order('submitted_at', ascending: false);
    
    return (response as List).map((e) {
      final sub = Submission.fromJson(e);
      // We can inject email if needed, or just attach it dynamically.
      // Let's modify the Submission object below to include email.
      return sub;
    }).toList();
  }

  Future<bool> hasStudentSubmitted(String examId, String studentId) async {
    final response = await _supabase
        .from('submissions')
        .select('id')
        .eq('exam_id', examId)
        .eq('student_id', studentId)
        .maybeSingle();
    return response != null;
  }

  Future<Submission?> getStudentSubmission(String examId, String studentId) async {
    final response = await _supabase
        .from('submissions')
        .select()
        .eq('exam_id', examId)
        .eq('student_id', studentId)
        .maybeSingle();
    if (response == null) return null;
    return Submission.fromJson(response);
  }

  Future<int> getMcqScore(String submissionId) async {
    final subData = await _supabase.from('submissions').select('mcq_marks').eq('id', submissionId).maybeSingle();
    if (subData != null && subData['mcq_marks'] != null) {
      return subData['mcq_marks'] as int;
    }

    final answers = await _supabase.from('mcq_answers').select('selected_option, mcq_questions(correct_option, marks)').eq('submission_id', submissionId);
    int score = 0;
    for (var a in answers as List) {
      if (a['selected_option'] == a['mcq_questions']['correct_option']) {
        score += (a['mcq_questions']['marks'] as int);
      }
    }

    // Save for next time
    await _supabase.from('submissions').update({'mcq_marks': score}).eq('id', submissionId);
    
    return score;
  }

  Future<void> updateWrittenMarks(String submissionId, int marks) async {
    await _supabase
        .from('submissions')
        .update({'written_marks': marks})
        .eq('id', submissionId);
  }
}
