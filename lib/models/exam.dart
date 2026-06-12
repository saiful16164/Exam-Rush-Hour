class Exam {
  final String id;
  final String teacherId;
  final String title;
  final String? description;
  final String examCode;
  final String password;
  final int mcqTimeMinutes;
  final int writtenTimeMinutes;
  final bool hasMcq;
  final bool hasWritten;
  final bool isActive;
  final DateTime createdAt;

  Exam({
    required this.id,
    required this.teacherId,
    required this.title,
    this.description,
    required this.examCode,
    required this.password,
    required this.mcqTimeMinutes,
    required this.writtenTimeMinutes,
    required this.hasMcq,
    required this.hasWritten,
    required this.isActive,
    required this.createdAt,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'],
      teacherId: json['teacher_id'],
      title: json['title'],
      description: json['description'],
      examCode: json['exam_code'],
      password: json['password'],
      mcqTimeMinutes: json['mcq_time_minutes'] ?? 30,
      writtenTimeMinutes: json['written_time_minutes'] ?? 60,
      hasMcq: json['has_mcq'] ?? true,
      hasWritten: json['has_written'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'title': title,
      'description': description,
      'exam_code': examCode,
      'password': password,
      'mcq_time_minutes': mcqTimeMinutes,
      'written_time_minutes': writtenTimeMinutes,
      'has_mcq': hasMcq,
      'has_written': hasWritten,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
