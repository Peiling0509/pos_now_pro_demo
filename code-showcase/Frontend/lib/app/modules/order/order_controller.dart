import 'dart:ui';

import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:pos_now_pro/app/data/repositories/menu_repository.dart';
import 'package:pos_now_pro/app/data/repositories/order_repository.dart';
import 'package:pos_now_pro/app/modules/order/edit_product_dialog.dart';
import 'package:pos_now_pro/app/routes/app_route.dart';
import 'package:pos_now_pro/app/services/local_storage_service.dart';
import 'package:pos_now_pro/app/services/web_socket_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/order_model.dart';
import '../../services/printer_service.dart';
import '../menu/menu_controller.dart';

class OrderController extends GetxController {
  // --- DATA STATE ---
  var ordersPending = <OrderModel>[].obs;
  var ordersServed = <OrderModel>[].obs;

  var isLoading = true.obs;

  // --- UI STATE ---
  // 0 = Pending (订单), 1 = Served (还钱)
  var currentTabIndex = 0.obs;
  var selectedOrder = Rxn<OrderModel>();

  // --- REPOSITORY --
  final orderRes = OrderRepository();
  final menuRes = MenuRepository();

  // --- Dependencies ---
  final localService = Get.find<LocalStorageService>();
  final webSocketService = Get.find<WebSocketService>();
  final printerService = Get.find<PrinterService>();
  final menuController = Get.put(MenuController());

  // --- AUDIO ---
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    webSocketService.disconnect();
    super.onClose();
  }

  Future<void> load() async {
    await loadPendingOrders();
    await loadServedOrders();
  }

  void printTicket() async {
    try {
      await printerService.printKitchenTicket(order: selectedOrder.value!);
      await Future.delayed(const Duration(milliseconds: 500));
      await printerService.printDrinkTicket(order: selectedOrder.value!);
      await updateOrderStatusToServed();
    } catch (e) {
      Get.log("Print Ticket Error: $e");
    }
  }

  Future<void> loadPendingOrders() async {
    isLoading.value = true;
    try {
      final data = await orderRes.getOrder('pending');
      ordersPending.assignAll(data);
      // If we are on the Pending tab, fix the selection
      if (currentTabIndex.value == 0) {
        _maintainSelection(ordersPending);
      }
    } catch (e) {
      Get.log("Error loading pending orders: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadServedOrders() async {
    isLoading.value = true;
    try {
      final data = await orderRes.getOrder('served');
      ordersServed.assignAll(data);
      // If we are on the Served tab, fix the selection
      if (currentTabIndex.value == 1) {
        _maintainSelection(ordersServed);
      }
    } catch (e) {
      Get.log("Error loading served orders: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateSingleOrderItem({
    required int orderId,
    required int orderItemId,
    required int quantity,
    required String remark,
    required List<int> optionIds,
    // double? customPrice, // <-- Removed as it's no longer needed
    double? weight,
  }) async {
    try {
      // Prepare payload according to Laravel validation
      Map<String, dynamic> payload = {
        "items": [
          {
            "id": orderItemId,
            "quantity": quantity,
            "remark": remark,
            "menu_item_option": optionIds,
            "weight": weight,
            // "custom_price": customPrice <-- Removed from payload
          },
        ],
      };

      // Call Repository
      await orderRes.updateOrderItem(orderId, payload);

      // Success
      Get.back(); // Close the Edit Dialog
      Get.snackbar("Success".tr, "Order updated successfully".tr);

      // Refresh the list to show new prices/options
      load();
    } catch (e) {
      Get.snackbar("Error", "Failed to update: $e");
    }
  }

  Future<void> deleteOrderItem({required int orderItemId}) async {
    try {
      if (selectedOrder.value == null) return;
      final body = {
        'order_id': selectedOrder.value?.id,
        'order_item_id': orderItemId,
      };

      await orderRes.deleteOrderItem(body);

      Get.back(); // Close the Dialog
      Get.snackbar("Success".tr, "Order deleted successfully".tr);

      // Refresh the list to show new prices/options
      load();
    } catch (e) {
      Get.snackbar("Error", "Failed to update: $e");
    }
  }

  Future<void> clearTable({required int tableId}) async {
    try {
      final body = {
        'table_id': tableId
      };

      await orderRes.clearTable(body);

      Get.back(); // Close the Dialog
      Get.snackbar("Success".tr, "Table deleted successfully".tr);

      // Refresh the list to show new prices/options
      load();
    } catch (e) {
      Get.snackbar("Error", "Failed to update: $e");
    }
  }

  Future<void> updateOrderStatusToServed() async {
    try {
      if (selectedOrder.value == null) return;
      final body = {'order_id': selectedOrder.value?.id, 'status': 'served'};

      await orderRes.updateOrderStatus(body);
      // Refresh the list to show new prices/options
      await load();
    } catch (e) {
      Get.snackbar("Error", "Failed to update: $e");
    }
  }

  Future<void> openWebDashboard() async {
    isLoading.value = true;

    // 1. Ask Laravel for the secret link
    final magicUrl = await orderRes.getMagicLink();

    if (magicUrl != null) {
      // 2. Parse the URL string into a Uri object
      final Uri url = Uri.parse(magicUrl);

      // 3. Open the browser! (LaunchMode.externalApplication forces the native Chrome/Safari browser to open)
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        Get.snackbar("Error", "Could not open the browser.");
      }
    } else {
      Get.snackbar("Access Denied", "Could not generate secure login link.");
    }

    isLoading.value = false;
  }

  void goToPayment() {
    // Check if an order is actually selected to prevent null errors
    if (selectedOrder.value == null) {
      Get.snackbar("Error", "Please select an order first");
      return;
    }
    Get.toNamed(AppRoute.PAYMENT, arguments: selectedOrder.value);
  }

  Future<void> onOrderUpdate() async {
    if (Get.currentRoute == AppRoute.ORDER) {
      // 1. Snapshot the current pending order IDs
      final oldOrderIds = ordersPending.map((order) => order.id).toSet();

      // 2. ALWAYS poll Pending Orders (so we can check for new orders and play the sound)
      await loadPendingOrders();

      // 3. OPTIMIZATION: ONLY poll Served orders if the user is actively viewing the Served tab!
      // if (currentTabIndex.value == 1) {
      //   await loadServedOrders();
      // }

      // 4. Check if a brand-new order arrived
      final newOrderIds = ordersPending.map((order) => order.id).toSet();
      final hasBrandNewOrder = newOrderIds.difference(oldOrderIds).isNotEmpty;

      // 5. Play sound
      if (hasBrandNewOrder) {
        _playNotificationSound();
      }
    }
  }

  void switchTab(int index) {
    if (currentTabIndex.value == index) return; // Prevent reload if same tab

    currentTabIndex.value = index;
    selectedOrder.value = null; // Reset selection momentarily

    if (index == 0) {
      // When SWITCHING tabs, we usually want the first item
      if (ordersPending.isNotEmpty) selectedOrder.value = ordersPending.first;
      loadPendingOrders();
    } else {
      if (ordersServed.isNotEmpty) selectedOrder.value = ordersServed.first;
      loadServedOrders();
    }
  }

  void selectOrder(OrderModel order) {
    selectedOrder.value = order;
  }

  void openEditProductDialog(OrderItem orderItem) async {
    // Find the menu item from SQLite
    final menuItem = await localService.getMenuItemById(orderItem.menuItemId);
    if (menuItem != null) {
      Get.dialog(
        EditProductDialog(currentMenuItem: menuItem, orderItem: orderItem),
      );
    }
  }

  // ==============================
  // NAVIGATION ACTIONS
  // ==============================
  /// 1. Called from Table List Panel (Left Side)
  void goToNewOrder() async {
    // Reset menu state to show Table Grid
    menuController.resetToTableSelection();
    await Get.toNamed(AppRoute.MENU);
    load();
  }

  /// 2. Called from Order Detail Panel (Right Side)
  void goToAddItemsToExistingOrder({String? targetCategoryName}) async {
    final order = selectedOrder.value;
    if (order == null) return;

    // Set menu state to show Products for this specific table AND pass the category
    menuController.resumeOrderForTable(
      order.tableId!,
      targetCategoryName: targetCategoryName,
    );

    await Get.toNamed(AppRoute.MENU, arguments: {'from': 'order_view'});
    load();
  }

  // Helper method to maintain selection
  void _maintainSelection(List<OrderModel> newList) {
    if (newList.isEmpty) {
      selectedOrder.value = null;
      return;
    }

    // 1. Get the currently selected ID (if any)
    final currentId = selectedOrder.value?.id;

    // 2. Try to find this ID in the NEW list
    final foundOrder = newList.firstWhereOrNull((e) => e.id == currentId);

    if (foundOrder != null) {
      // 3. If found, select the updated version of the order (keeps position)
      selectedOrder.value = foundOrder;
    } else {
      // 4. If NOT found (or nothing was selected), default to the first one
      selectedOrder.value = newList.first;
    }
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notif_new_order.mp3'));
    } catch (e) {
      Get.log("Audio Error: $e");
    }
  }
}