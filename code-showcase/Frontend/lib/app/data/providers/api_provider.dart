import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:pos_now_pro/app/core/constants/url.dart';
import '../../modules/login/auth_controller.dart';
import 'dart:convert';

class ApiProvider extends GetxService {
  final Dio _dio = Dio();
  final AuthController _authController = Get.find<AuthController>();

  // --- NEW: Lock to prevent multiple logouts triggering at once ---
  bool _isLoggingOut = false;

  @override
  void onInit() {
    super.onInit();

    _dio.options = BaseOptions(
      baseUrl: rootapi,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = _authController.accessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          _printRequest(options);
          handler.next(options);
        },
        onResponse: (response, handler) {
          _printResponse(response);
          handler.next(response);
        },
        onError: (DioException e, handler) {
          _printError(e);

          // --- UPDATED: 401 Handler with Lock & Better Message ---
          if (e.response?.statusCode == 401) {
            if (!_isLoggingOut) {
              _isLoggingOut = true; // Lock it!

              _authController.logout();

              Get.snackbar(
                "Session Expired".tr,
                "Your account was logged in from another device.".tr, // Clearer message
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.redAccent,
                colorText: Colors.white,
                duration: const Duration(seconds: 5),
              );

              // Reset the lock after a few seconds so they can log back in normally
              Future.delayed(const Duration(seconds: 3), () {
                _isLoggingOut = false;
              });
            }
          }

          handler.next(e);
        },
      ),
    );
  }

  // ------------ LOGGING HELPERS ------------ //

  void _printRequest(RequestOptions options) {
    Get.log("--------------------------------------------------------");
    Get.log("➡️  REQUEST: ${options.method} ${options.baseUrl}${options.path}");

    if (options.headers.isNotEmpty) {
      Get.log("➡️  HEADERS: ${jsonEncode(options.headers)}");
    }

    if (options.data != null) {
      try {
        Get.log("➡️  BODY: ${_prettyJson(options.data)}");
      } catch (_) {
        Get.log("➡️  BODY: ${options.data}");
      }
    }

    if (options.queryParameters.isNotEmpty) {
      Get.log("➡️  QUERY: ${jsonEncode(options.queryParameters)}");
    }
    Get.log("--------------------------------------------------------");
  }

  void _printResponse(Response response) {
    Get.log("⬅️  RESPONSE [${response.statusCode}] ${response.requestOptions.path}");

    try {
      Get.log("⬅️  DATA: ${_prettyJson(response.data)}");
    } catch (_) {
      Get.log("⬅️  DATA: ${response.data}");
    }

    Get.log("--------------------------------------------------------");
  }

  void _printError(DioException e) {
    Get.log("❌ ERROR: ${e.message}");

    if (e.response != null) {
      Get.log("❌ STATUS: ${e.response?.statusCode}");
      try {
        Get.log("❌ BODY: ${_prettyJson(e.response?.data)}");
      } catch (_) {
        Get.log("❌ BODY: ${e.response?.data}");
      }
    }

    Get.log("--------------------------------------------------------");
  }

  String _prettyJson(dynamic data) {
    try {
      return const JsonEncoder.withIndent("  ").convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  // ------------ GENERIC API METHODS ------------ //

  Future<Response> get(String url, {Map<String, dynamic>? query}) {
    return _dio.get(url, queryParameters: query);
  }

  Future<Response> post(String url, {dynamic data}) {
    return _dio.post(url, data: data);
  }

  Future<Response> put(String url, {dynamic data}) {
    return _dio.put(url, data: data);
  }

  Future<Response> destroy(String url) {
    return _dio.delete(url);
  }
}