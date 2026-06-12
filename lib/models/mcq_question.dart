class McqQuestion {
  final String id;
  final String examId;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;
  final int marks;
  final int orderIndex;

  McqQuestion({
    required this.id,
    required this.examId,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    required this.marks,
    required this.orderIndex,
  });

  factory McqQuestion.fromJson(Map<String, dynamic> json) {
    return McqQuestion(
      id: json['id'],
      examId: json['exam_id'],
      questionText: json['question_text'],
      optionA: json['option_a'],
      optionB: json['option_b'],
      optionC: json['option_c'],
      optionD: json['option_d'],
      correctOption: json['correct_option'],
      marks: json['marks'] ?? 1,
      orderIndex: json['order_index'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_id': examId,
      'question_text': questionText,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_option': correctOption,
      'marks': marks,
      'order_index': orderIndex,
    };
  }
}
