import 'dart:async';
import 'package:get/get.dart';
import 'package:pos_now_pro/app/modules/order/order_controller.dart';
import '../modules/menu/menu_controller.dart';

class PollingService extends GetxService {
  Timer? _timer;

  /// Starts the 10-second polling loop
  void startPolling() {
    // Cancel any existing timer to prevent duplicates
    stopPolling();

    Get.log("⏱️ Started 10-Second Polling...");

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _triggerUpdates();
    });
  }

  /// Stops the polling loop
  void stopPolling() {
    if (_timer != null) {
      Get.log("🛑 Stopped Polling.");
      _timer?.cancel();
      _timer = null;
    }
  }

  /// The function that runs every 10 seconds
  void _triggerUpdates() {
    if (Get.isRegistered<OrderController>()) {
      // Always trigger the update, let the controller decide what to fetch
      Get.find<OrderController>().onOrderUpdate();
    }
  }

  @override
  void onClose() {
    stopPolling();
    super.onClose();
  }
}