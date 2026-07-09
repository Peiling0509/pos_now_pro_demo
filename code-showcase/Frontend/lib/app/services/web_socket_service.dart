import 'dart:async';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:get/get.dart';
import 'package:pos_now_pro/app/modules/order/order_controller.dart';
import '../modules/menu/menu_controller.dart';
import 'package:pos_now_pro/app/services/sync_services.dart';

class WebSocketService extends GetxService {
  PusherChannelsClient? _client;
  bool _isConnected = false;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _allEventsSubscription;

  StreamSubscription? _tableEventSubscription;
  StreamSubscription? _menuEventSubscription;

  Future<WebSocketService> init() async {
    Get.log("--- WebSocket Init Started ---");
    try {
      // 1. Configure Options
      // Hidden Code

      // 2. Create the Client
      _client = PusherChannelsClient.websocket(
        options: options,
        connectionErrorHandler: (error, trace, refresh) {
          Get.log("WebSocket Connection Error: $error");
          _isConnected = false;
          // Add a slight delay to prevent aggressive connection spam loops
          Future.delayed(const Duration(seconds: 3), () => refresh());
        },
      );

      // 3. BIND CHANNELS & EVENTS BEFORE CONNECTING
      final channel = _client?.publicChannel("pos-now-channel");

      // Subscribe to the channel immediately (the library queues this until connected)
      channel?.subscribe();

      // Table Updated Event
      _tableEventSubscription = channel?.bind("table.updated").listen((event) {
        Get.log("🔔 [WEBSOCKET] Table Updated Event Received!");

        if (event.data != null) {
          _handleTableUpdate();
        }
      });

      // Menu Updated Event
      _menuEventSubscription = channel?.bind("menu.updated").listen((event) async {
        Get.log("🔔 [WEBSOCKET] Menu Updated Event Received! Syncing now...");

        if (Get.isRegistered<SyncService>()) {
          await Get.find<SyncService>().syncMenu();
          if (Get.isRegistered<MenuController>()) {
            Get.find<MenuController>().loadMenu();
          }
        } else {
          Get.log("🚨 WARNING: SyncService not found in memory!");
        }
      });

      // 4. Handle Connection State Logs
      _connectionSubscription = _client?.onConnectionEstablished.listen((_) {
        Get.log(">>> WEB SOCKET SUCCESSFULLY CONNECTED <<<");
        _isConnected = true;
      });

      _allEventsSubscription = _client?.eventStream.listen((event) {
        Get.log("Raw System Event: ${event.name} | Data: ${event.data}");
      });

      // 5. Connect
      Get.log("Attempting to connect to ${options.uri} ...");
      await _client?.connect();

    } catch (e) {
      Get.log("WebSocket Init Exception: $e");
    }

    return this;
  }

  // Helper function to keep the listener clean
  void _handleTableUpdate() {
    bool handled = false;

    if (Get.isRegistered<MenuController>()) {
      Get.find<MenuController>().loadTables();
      handled = true;
    }
    if (Get.isRegistered<OrderController>()) {
      Get.find<OrderController>().onOrderUpdate();
      handled = true;
    }

    if (!handled) {
      Get.log("⚠️ Table updated, but neither MenuController nor OrderController are currently active.");
      // Consider setting a boolean flag here like `needsRefresh = true`
      // so your controllers can check it in their onInit() or onReady()
    }
  }

  void disconnect() {
    Get.log("🔌 Disconnecting WebSocket...");
    _tableEventSubscription?.cancel();
    _menuEventSubscription?.cancel();
    _allEventsSubscription?.cancel();
    _connectionSubscription?.cancel();

    _client?.disconnect();
    _client?.dispose();
    _client = null;
  }

  /// Safely checks the connection status and reconnects if dead
  void ensureConnected() {
    if (_client == null) {
      Get.log("⚠️ WebSocket client is null. Re-initializing...");
      init();
      return;
    }

    // Use our manual tracking flag instead of a getter
    if (!_isConnected) {
      Get.log("🔌 WebSocket is asleep or disconnected. Reconnecting...");
      try {
        _client?.connect();
      } catch (e) {
        Get.log("Failed to reconnect WebSocket on resume: $e");
      }
    } else {
      Get.log("⚡ WebSocket is already connected. No action needed.");
    }
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}