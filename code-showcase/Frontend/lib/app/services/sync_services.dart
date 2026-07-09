// sync_service.dart
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pos_now_pro/app/data/repositories/menu_repository.dart';

import 'local_storage_service.dart';

class SyncService extends GetxService {
  // Dependency Injection
  final MenuRepository _menuRepo = MenuRepository();
  final LocalStorageService _localDb = Get.find<LocalStorageService>();

  Future<bool> syncMenu() async {
    try {
      Get.log("🔄 Syncing Menu...");

      final res = await _menuRepo.getSyncMenu();
      if (res.isEmpty) {
        Get.snackbar("Empty menu".tr, "Empty menu found.".tr);
        return true; // Not an error, just empty
      }

      await _localDb.saveFullMenu(res);

      String message = "categories_processed".trParams({
        'count': res.length.toString(),
      });

      Get.log("✅ Menu Synced: ${res.length} categories processed.");
      Get.snackbar("Menu Synced".tr, message);

      return true;
    } catch (e) {
      Get.log("❌ Sync Menu failed: $e");
      Get.snackbar("Error".tr, "Sync failed, please check your network connectivity...".tr);
      return false;
    }
  }

  Future<void> syncServerTime() async {
    try {
      String currentTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      Map<String, dynamic> payload = {
        "datetime": currentTime
      };
      final res = await _menuRepo.syncServerTime(payload);
      Get.log('Server time synced!');
    } catch (e) {
      Get.log('Failed to sync time: $e');
    }
  }

  Future<void> syncAll() async {
    await syncServerTime();
    await syncMenu();
  }
}