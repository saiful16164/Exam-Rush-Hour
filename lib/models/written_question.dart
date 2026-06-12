class WrittenQuestion {
  final String id;
  final String examId;
  final String fileUrl;
  final String fileType;
  final DateTime uploadedAt;

  WrittenQuestion({
    required this.id,
    required this.examId,
    required this.fileUrl,
    required this.fileType,
    required this.uploadedAt,
  });

  factory WrittenQuestion.fromJson(Map<String, dynamic> json) {
    return WrittenQuestion(
      id: json['id'],
      examId: json['exam_id'],
      fileUrl: json['file_url'],
      fileType: json['file_type'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_id': examId,
      'file_url': fileUrl,
      'file_type': fileType,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}
