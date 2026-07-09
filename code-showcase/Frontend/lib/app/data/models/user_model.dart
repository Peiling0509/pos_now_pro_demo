class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? pinCode; // Make nullable if it can be
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.pinCode,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      pinCode: json['pin_code'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'pin_code': pinCode,
      'created_at': createdAt.toIso8601String(),
    };
  }
}