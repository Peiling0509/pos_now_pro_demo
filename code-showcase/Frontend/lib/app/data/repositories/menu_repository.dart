import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:pos_now_pro/app/core/constants/url.dart';
import 'package:pos_now_pro/app/data/models/main_menu_model.dart';
import 'package:pos_now_pro/app/data/providers/api_provider.dart';

import '../models/table_model.dart';

class MenuRepository {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  /// Fetch all tables
  Future<List<TableModel>> getTables() async {
    try {
      Response response = await _apiProvider.get(UrlStorage.table);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final tables = (response.data['data'] as List)
            .map((e) => TableModel.fromJson(e))
            .toList();
        return tables;
      } else {
        throw Exception("Failed to load tables");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<MainMenuModel>> getSyncMenu() async {
    try {
      Response response = await _apiProvider.get(UrlStorage.sync_menu);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final tables = (response.data['data'] as List)
            .map((e) => MainMenuModel.fromJson(e))
            .toList();
        return tables;
      } else {
        throw Exception("Failed to load tables");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncServerTime(dynamic data) async {
    try {
      await _apiProvider.post(UrlStorage.sync_server_time, data: data);
    } catch (e) {
      Get.log("❌ Error sync time: $e");
      rethrow;
    }
  }
}