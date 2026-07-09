import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData;
import 'dart:convert';

class NoAuthProvider extends GetxController {
  final Dio _dio = Dio();

  @override
  void onInit() {
    super.onInit();

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _printRequest(options);
          handler.next(options);
        },
        onResponse: (response, handler) {
          _printResponse(response);
          handler.next(response);
        },
        onError: (DioException e, handler) {
          _printError(e);
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

  Future<Response> store(String url, Map<String, dynamic> data) {
    return _dio.post(
      url,
      data: FormData.fromMap(data),
    );
  }

  Future<Response> index(String url) {
    return _dio.get(url);
  }

  Future<Response> show(String url) {
    return _dio.get(url);
  }

  Future<Response> put(String url, dynamic data) {
    return _dio.put(url, data: data);
  }

  Future<Response> destroy(String url) {
    return _dio.delete(url);
  }
}
