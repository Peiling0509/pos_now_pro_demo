import 'package:get/get.dart';
import 'app/modules/login/auth_controller.dart';
import 'app/services/polling_services.dart';
import 'app/services/sync_services.dart';

class AppLifecycleController extends FullLifeCycleController with FullLifeCycleMixin {

  @override
  void onInit() {
    super.onInit();
    // Start polling when the app first boots up
    if (Get.isRegistered<PollingService>()) {
      Get.find<PollingService>().startPolling();
    }
  }

  @override
  void onResumed() {
    if(Get.find<AuthController>().getUserRole() == "admin"){
      Get.log("📱 App Resumed: Waking up services...");
      try {
        Get.find<SyncService>().syncServerTime();

        // RESUME POLLING
        if (Get.isRegistered<PollingService>()) {
          Get.find<PollingService>().startPolling();
        }
      } catch (e) {
        Get.log("SyncService not ready yet: $e");
      }
    }
  }

  @override
  void onPaused() {
    // STOP POLLING WHEN APP IS IN BACKGROUND
    Get.log("📱 App Paused: Suspending background tasks...");
    if (Get.isRegistered<PollingService>()) {
      Get.find<PollingService>().stopPolling();
    }
  }

  @override
  void onDetached() {}

  @override
  void onInactive() {}

  @override
  void onHidden() {}
}