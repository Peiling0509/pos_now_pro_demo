import 'package:dio/dio.dart';
import 'package:pos_now_pro/app/data/models/auth_model.dart';
import 'package:get/get.dart';
import 'package:pos_now_pro/app/core/constants/url.dart';

import '../providers/no_auth_provider.dart';

class LoginRepository {
  final NoAuthProvider _noAuthProvider = Get.find<NoAuthProvider>();

  /// Handles the login API call
  Future<AuthModel> login(String username, String pin) async {
    try {
      final body = {
        'name': username,
        'pin': pin,
      };
      final response = await _noAuthProvider.store(UrlStorage.login, body);
      return AuthModel.fromJson(response.data);

    } on DioException catch (e) {
      // 5. Handle all errors, including validation (422) or auth (401)
      if (e.response != null && e.response?.data != null) {
        if (e.response!.data is Map) {
          return AuthModel.fromJson(e.response!.data);
        } else {
          return AuthModel(status: false, message: e.response?.statusMessage ?? "Error");
        }
      } else {
        return AuthModel(status: false, message: "Network error: ${e.message}");
      }
    } catch (e) {
      return AuthModel(status: false, message: "Unexpected error: $e");
    }
  }
}