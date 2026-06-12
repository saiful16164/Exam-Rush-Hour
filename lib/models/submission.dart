class Submission {
  final String id;
  final String examId;
  final String? studentId;
  final String studentName;
  final String? studentEmail;
  final DateTime submittedAt;
  final int? writtenMarks;

  Submission({
    required this.id,
    required this.examId,
    this.studentId,
    required this.studentName,
    this.studentEmail,
    required this.submittedAt,
    this.writtenMarks,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'],
      examId: json['exam_id'],
      studentId: json['student_id'],
      studentName: json['student_name'],
      studentEmail: json['students'] != null ? json['students']['email'] : null,
      submittedAt: DateTime.parse(json['submitted_at']),
      writtenMarks: json['written_marks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_id': examId,
      'student_id': studentId,
      'student_name': studentName,
      'submitted_at': submittedAt.toIso8601String(),
      'written_marks': writtenMarks,
    };
  }
}
