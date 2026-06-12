class Student {
  final String id;
  final String fullName;
  final String email;

  Student({
    required this.id,
    required this.fullName,
    required this.email,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
    };
  }
}
