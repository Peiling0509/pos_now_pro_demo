// This models the "data" object in successful response
import 'package:pos_now_pro/app/data/models/user_model.dart';

// This models the entire API response
class AuthModel {
  final bool status;
  final String message;
  final AuthDataModel? data; // Nullable in case of error

  AuthModel({
    required this.status,
    required this.message,
    this.data,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      status: json['status'],
      message: json['message'],
      data: json['status'] ? AuthDataModel.fromJson(json['data']) : null,
    );
  }
}

class AuthDataModel {
  final User user;
  final String token;

  AuthDataModel({required this.user, required this.token});

  factory AuthDataModel.fromJson(Map<String, dynamic> json) {
    return AuthDataModel(
      user: User.fromJson(json['user']),
      token: json['token'],
    );
  }
}