import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:get/get.dart';
import 'package:pos_now_pro/app/data/models/payment_model.dart';
import 'package:pos_now_pro/app/services/print_log_service.dart';
import 'package:pos_now_pro/app/services/user_preference_service.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart'; // <-- NEW: Added intl for DateFormat

import '../data/models/order_model.dart';
import '../data/models/payment_method_enum.dart';
import '../data/models/print_log_model.dart';
import '../data/repositories/order_repository.dart';

extension PrinterTypeExtension on PrinterType {
  String get title {
    switch (this) {
      case PrinterType.kitchen:
        return "KITCHEN TICKET";
      case PrinterType.drink:
        return "BAR TICKET";
      case PrinterType.counter:
        return "JONG'S SEAFOOD";
    }
  }
}

class PrinterService extends GetxService {
  final UserPreferenceService prefs = UserPreferenceService.instance;

  CapabilityProfile? _profile;

  // GLOBAL VARIABLE FOR KITCHEN/BAR TICKET FONT SIZE
  PosTextSize ticketFontSize = PosTextSize.size2;

  // Initialize profile once at app startup
  Future<PrinterService> init() async {
    _profile = await CapabilityProfile.load();
    Get.log("🖨️ Printer Service Initialized");
    return this;
  }

  /// Request necessary permissions for Bluetooth
  Future<bool> _requestBluetoothPermissions() async {
    var bluetoothScanStatus = await Permission.bluetoothScan.request();
    var bluetoothConnectStatus = await Permission.bluetoothConnect.request();
    var locationStatus = await Permission.location.request();

    if (bluetoothScanStatus.isGranted &&
        bluetoothConnectStatus.isGranted &&
        locationStatus.isGranted) {
      Get.log("Bluetooth and location permissions granted");
      return true;
    } else {
      Get.log("Bluetooth or location permissions denied");
      return false;
    }
  }

  /// Connects to a printer and prints a diagnostic test slip
  Future<void> testPrint(String address, {String type = 'ip'}) async {
    if (_profile == null) {
      Get.snackbar("Error".tr, "Printer profile not loaded".tr);
      return;
    }

    Get.showOverlay(
      loadingWidget: const Center(child: CircularProgressIndicator()),
      asyncFunction: () async {
        try {
          Get.log("Testing $type connection to $address...");

          if (type == 'ip') {
            await _testNetworkPrinter(address);
          } else if (type == 'bluetooth') {
            await _testBluetoothPrinter(address);
          }
        } catch (e) {
          Get.log("Test Print Exception: $e");
          Get.snackbar("Error".tr, "An unexpected error occurred: $e");
        }
      },
    );
  }

  // ==========================================
  // LAYOUT 1: Kitchen Ticket (Food Only)
  // ==========================================
  Future<void> printKitchenTicket({required OrderModel order}) async {
    if (!prefs.getIsKitchenPrinterEnabled()) return;
    if (_profile == null) return;

    final String type = prefs.getKitchenPrinterType();
    final String address = type == 'ip'
        ? prefs.getKitchenPrinterIp()
        : prefs.getKitchenBluetoothAddress();

    if (address.isEmpty) {
      Get.snackbar("Error".tr, "Kitchen Printer address not configured".tr);
      return;
    }

    final foodItems = order.orderItems.where((item) {
      final cat = item.categoryName.toLowerCase();
      return cat.contains('food');
    }).toList();

    if (foodItems.isEmpty) return;

    await _executePrintJob(
      type: type,
      address: address,
      printerType: PrinterType.kitchen,
      order: order,
      itemsToPrint: foodItems,
      isReceipt: false,
    );
  }

  // ==========================================
  // LAYOUT 2: Drink Ticket (Drinks Only)
  // ==========================================
  Future<void> printDrinkTicket({required OrderModel order}) async {
    if (!prefs.getIsDrinkPrinterEnabled()) return;
    if (_profile == null) return;

    final String type = prefs.getDrinkPrinterType();
    final String address = type == 'ip'
        ? prefs.getDrinkPrinterIp()
        : prefs.getDrinkBluetoothAddress();

    if (address.isEmpty) {
      Get.snackbar("Error".tr, "Drink Printer address not configured".tr);
      return;
    }

    final drinkItems = order.orderItems.where((item) {
      final cat = item.categoryName.toLowerCase();
      return cat.contains('beverage');
    }).toList();

    if (drinkItems.isEmpty) return;

    await _executePrintJob(
      type: type,
      address: address,
      printerType: PrinterType.drink,
      order: order,
      itemsToPrint: drinkItems,
      isReceipt: false, // Standard Bar Ticket format
    );
  }

  // ==========================================
  // LAYOUT 3: Counter Ticket (All items / Receipt)
  // ==========================================
  Future<void> printCounterTicket({
    required OrderModel order,
    PaymentMethod? paymentMethod,
    double? tenderedAmount,
    double? changeAmount,
  }) async
  {
    if (!prefs.getIsCounterPrinterEnabled()) return;

    if (_profile == null) return;

    final String type = prefs.getCounterPrinterType();
    final String address = type == 'ip'
        ? prefs.getCounterPrinterIp()
        : prefs.getCounterBluetoothAddress();

    if (address.isEmpty) {
      Get.snackbar("Error".tr, "Counter Printer address not configured".tr);
      return;
    }

    final allItems = order.orderItems;
    if (allItems.isEmpty) return;

    await _executePrintJob(
      type: type,
      address: address,
      printerType: PrinterType.counter,
      order: order,
      itemsToPrint: allItems,
      isReceipt: true,
      paymentMethod: paymentMethod,
      tenderedAmount: tenderedAmount,
      changeAmount: changeAmount,
    );
  }

  // ==========================================
  // RE-PRINT LOGIC
  // ==========================================
  Future<void> reprintFromLog(PrintLogModel log) async {
    if (_profile == null) return;
    if (log.order == null) {
      Get.snackbar(
        "Error".tr,
        "Cannot reprint: Order data missing from log.".tr,
      );
      return;
    }

    String type = 'ip';
    String address = log.printerIp;

    if (log.printerType == PrinterType.kitchen) {
      type = prefs.getKitchenPrinterType();
      address = type == 'ip'
          ? prefs.getKitchenPrinterIp()
          : prefs.getKitchenBluetoothAddress();
    } else if (log.printerType == PrinterType.drink) {
      type = prefs.getDrinkPrinterType();
      address = type == 'ip'
          ? prefs.getDrinkPrinterIp()
          : prefs.getDrinkBluetoothAddress();
    } else if (log.printerType == PrinterType.counter) {
      type = prefs.getCounterPrinterType();
      address = type == 'ip'
          ? prefs.getCounterPrinterIp()
          : prefs.getCounterBluetoothAddress();
    }

    List<OrderItem> itemsToReprint = [];
    if (log.printerType == PrinterType.kitchen) {
      itemsToReprint = log.order!.orderItems
          .where((item) => item.categoryName.toLowerCase().contains('food'))
          .toList();
    } else if (log.printerType == PrinterType.drink) {
      itemsToReprint = log.order!.orderItems
          .where((item) => item.categoryName.toLowerCase().contains('beverage'))
          .toList();
    } else {
      itemsToReprint = log.order!.orderItems;
    }

    bool isReceipt = log.printerType == PrinterType.counter;

    double? tenderedAmt;
    double? changeAmt;
    PaymentMethod? payMethod;

    //Fetch payment data from API if this is a Counter Receipt
    if (isReceipt) {
      await Get.showOverlay(
        loadingWidget: const Center(child: CircularProgressIndicator()),
        asyncFunction: () async {
          try {
            final orderRes = OrderRepository();
            Map<String, dynamic> payload = {"order_id": log.order!.id};
            PaymentModel paymentData = await orderRes.getPayment(payload);

            tenderedAmt = paymentData.tenderedAmount;
            changeAmt = paymentData.changeAmount;
            payMethod = paymentData.method;
          } catch (e) {
            Get.log("Could not fetch payment data for reprint: $e");
          }
        },
      );
    }

    await _executePrintJob(
      type: type,
      address: address,
      printerType: log.printerType,
      order: log.order!,
      itemsToPrint: itemsToReprint,
      existingLogId: log.id,
      isReceipt: isReceipt,
      tenderedAmount: tenderedAmt,
      changeAmount: changeAmt,
      paymentMethod: payMethod,
    );
  }

  // ==========================================
  // SHARED PRINT LOGIC
  // ==========================================
  Future<void> _executePrintJob({
    required String type,
    required String address,
    required PrinterType printerType,
    required OrderModel order,
    required List<OrderItem> itemsToPrint,
    String? existingLogId,
    bool isReceipt = false,
    PaymentMethod? paymentMethod,
    double? tenderedAmount,
    double? changeAmount,
  }) async {
    var status = PrintStatus.failed;
    String? errorMsg;

    await Get.showOverlay(
      loadingWidget: const Center(child: CircularProgressIndicator()),
      asyncFunction: () async {
        try {
          Get.log(
            "Connecting to $type printer at $address for ${printerType.title}...",
          );

          bool isSuccess = false;

          if (type == 'ip') {
            final printer = NetworkPrinter(PaperSize.mm80, _profile!);
            final PosPrintResult res = await printer.connect(
              address,
              port: 9100,
            );

            if (res == PosPrintResult.success) {
              _printNetworkTicketContent(
                printer,
                printerType.title,
                order,
                itemsToPrint,
                isReceipt,
                paymentMethod,
                tenderedAmount,
                changeAmount,
              );
              printer.disconnect();
              isSuccess = true;
            } else {
              errorMsg = res.msg;
            }
          } else if (type == 'bluetooth') {
            List<int> bytes = _generateTicketBytes(
              printerType.title,
              order,
              itemsToPrint,
              isReceipt,
              paymentMethod,
              tenderedAmount,
              changeAmount,
            );
            isSuccess = await _sendBluetoothBytes(address, bytes);
            if (!isSuccess) errorMsg = "Bluetooth connection or print failed";
          }

          if (isSuccess) {
            status = PrintStatus.success;
          } else {
            status = PrintStatus.failed;
            Get.snackbar(
              "Print Error".tr,
              "Could not connect: $errorMsg",
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        } catch (e) {
          status = PrintStatus.failed;
          errorMsg = e.toString();
          Get.snackbar("Error".tr, "Connection failed: $e");
        }
      },
    );

    // Logging Logic
    if (Get.isRegistered<PrintLogService>()) {
      final logService = Get.find<PrintLogService>();
      if (existingLogId != null) {
        await logService.updateLogStatus(
          existingLogId,
          status,
          errorMsg: errorMsg,
        );
      } else {
        final log = PrintLogModel(
          id: const Uuid().v4(),
          orderId: order.id,
          printerType: printerType,
          printerIp: address,
          timestamp: DateTime.now(),
          status: status,
          order: order,
          errorMessage: errorMsg,
        );
        await logService.addLog(log);
      }
    }
  }

  // ==========================================
  // CONTENT GENERATION (NETWORK VS BLUETOOTH)
  // ==========================================
  void _printNetworkTicketContent(
      NetworkPrinter printer,
      String title,
      OrderModel order,
      List<OrderItem> items,
      bool isReceipt,
      PaymentMethod? paymentMethod,
      double? tenderedAmount,
      double? changeAmount,
      ) {
    // 1. HEADER
    printer.text(
      title,
      containsChinese: true,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    printer.feed(1);

    // --- NEW: DUAL-LANGUAGE ORDER TYPE ---
    String typeLabel = order.orderType == 'take_away'
        ? '- TAKEAWAY / 外带 -'
        : '- DINE IN / 堂食 -';

    printer.text(
      typeLabel,
      containsChinese: true,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );

    // Print Table Number ONLY if it exists (Takeaways usually don't have one)
    if (order.tableId != null) {
      printer.text(
        'TABLE: ${order.tableId}',
        containsChinese: true,
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size3,
          width: PosTextSize.size3,
          bold: true,
        ),
      );
    }

    printer.hr();

    // --- UPDATED DATE & TIME FORMAT ---
    String timeStr = DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt);

    printer.row([
      PosColumn(text: 'Order #${order.id}', width: 5),
      PosColumn(
        text: timeStr,
        width: 7,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    printer.hr();
    printer.feed(1);

    // 2. ITEMS
    for (var item in items) {
      if (isReceipt) {
        printer.row([
          PosColumn(
            text: '${item.quantity}x ${item.menuItemName}',
            width: 10,
            styles: const PosStyles(bold: true),
          ),
          PosColumn(
            text: item.price != 0.0 ? item.price.toStringAsFixed(2) : '',
            width: 2,
            styles: const PosStyles(bold: true, align: PosAlign.right),
          ),
        ]);
        //display weight
        if (item.weight != null) {
          printer.text('   + ${item.weight} KG');
        }
      } else {
        // KITCHEN/BAR (MULTI-LANGUAGE + CUSTOM FONT SIZE)
        String combinedName = '${item.quantity}x  ${item.menuItemSubName}';
        if (item.menuItemName.isNotEmpty) {
          combinedName += '  ${item.menuItemName}';
        }

        printer.text(
          combinedName,
          containsChinese: true,
          styles: PosStyles(
            bold: true,
            height: ticketFontSize,
            width: ticketFontSize,
          ),
        );

        if (item.weight != null) {
          printer.text(
            '   + ${item.weight} KG',
            styles: PosStyles(height: ticketFontSize, width: ticketFontSize),
          );
        }
      }

      for (var option in item.options) {
        if (isReceipt) {
          // --- RECEIPT (SMALL FONT) ---
          if (option.additionalPrice > 0) {
            printer.row([
              PosColumn(text: '   + ${option.name}'.tr, width: 8),
              PosColumn(
                text: option.additionalPrice.toStringAsFixed(2),
                width: 4,
                styles: const PosStyles(align: PosAlign.right),
              ),
            ]);
          } else {
            printer.text('   + ${option.name}'.tr, containsChinese: true);
          }
        } else {
          //KITCHEN/BAR (OPTIONS MULTI-LANGUAGE + CUSTOM FONT SIZE)
          String optionCombined = '  +${option.subName}'.tr;
          optionCombined += ' ${option.name}';

          printer.text(
            optionCombined,
            containsChinese: true,
            styles: PosStyles(
              height: ticketFontSize,
              width: ticketFontSize,
              bold: true,
            ),
          );
        }
      }

      if (item.remark != null && item.remark!.isNotEmpty) {
        printer.text(
          '   REMARK: ${item.remark}',
          containsChinese: true,
          styles: const PosStyles(bold: true),
        );
      }
      printer.feed(1);
    }

    // 3. TOTALS SECTION
    if (isReceipt) {
      printer.hr();

      printer.row([
        PosColumn(
          text: 'TOTAL',
          width: 6,
          styles: const PosStyles(
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        ),
        PosColumn(
          text: order.totalPrice.toStringAsFixed(2),
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);

      if (tenderedAmount != null && changeAmount != null) {
        printer.feed(1);
        printer.row([
          PosColumn(text: paymentMethod!.label, width: 6),
          PosColumn(
            text: tenderedAmount.toStringAsFixed(2),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
        printer.row([
          PosColumn(text: 'CHANGE', width: 6),
          PosColumn(
            text: changeAmount.toStringAsFixed(2),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }
    }

    // 4. FOOTER
    printer.hr();
    printer.text(
      'End of Ticket',
      containsChinese: true,
      styles: const PosStyles(align: PosAlign.center),
    );
    printer.feed(2);
    printer.cut();
  }

  /// Generates Raw Bytes for Bluetooth Printers
  List<int> _generateTicketBytes(
      String title,
      OrderModel order,
      List<OrderItem> items,
      bool isReceipt,
      PaymentMethod? paymentMethod,
      double? tenderedAmount,
      double? changeAmount,
      ) {
    List<int> bytes = [];
    final generator = Generator(PaperSize.mm80, _profile!);

    bytes += generator.text(
      title,
      containsChinese: true,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.feed(1);

    // --- NEW: DUAL-LANGUAGE ORDER TYPE (BLUETOOTH) ---
    String typeLabel = order.orderType == 'take_away'
        ? '- TAKEAWAY / 外带 -'
        : '- DINE IN / 堂食 -';

    bytes += generator.text(
      typeLabel,
      containsChinese: true,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );

    // Print Table Number ONLY if it exists
    if (order.tableId != null) {
      bytes += generator.text(
        'TABLE: ${order.tableId}',
        containsChinese: true,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }

    bytes += generator.hr();

    // --- UPDATED DATE & TIME FORMAT ---
    String timeStr = DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt);

    bytes += generator.row([
      PosColumn(text: 'Order #${order.id}', width: 5),
      PosColumn(
        text: timeStr,
        width: 7,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.hr();
    bytes += generator.feed(1);

    for (var item in items) {
      if (isReceipt) {
        bytes += generator.row([
          PosColumn(
            text: '${item.quantity}x ${item.menuItemName}',
            width: 10,
            styles: const PosStyles(bold: true),
          ),
          PosColumn(
            text: item.price != 0.0 ? item.price.toStringAsFixed(2) : '',
            width: 2,
            styles: const PosStyles(bold: true, align: PosAlign.right),
          ),
        ]);

        if (item.weight != null) {
          bytes += generator.text('   + ${item.weight} KG');
        }
      } else {
        String combinedName = '${item.quantity}x  ${item.menuItemSubName}';
        combinedName += '  ${item.menuItemName}';

        bytes += generator.text(
          combinedName,
          containsChinese: true,
          styles: PosStyles(
            bold: true,
            height: ticketFontSize,
            width: ticketFontSize,
          ),
        );

        if (item.weight != null) {
          bytes += generator.text(
            '   + ${item.weight} KG',
            styles: PosStyles(height: ticketFontSize, width: ticketFontSize),
          );
        }
      }

      for (var option in item.options) {
        if (isReceipt) {
          if (option.additionalPrice > 0) {
            bytes += generator.row([
              PosColumn(text: '   +${option.name}'.tr, width: 8),
              PosColumn(
                text: option.additionalPrice.toStringAsFixed(2),
                width: 4,
                styles: const PosStyles(align: PosAlign.right),
              ),
            ]);
          } else {
            bytes += generator.text(
              '   + ${option.name}'.tr,
              containsChinese: true,
            );
          }
        } else {
          String optionCombined = '  + ${option.subName}'.tr;
          optionCombined += ' ${option.name}';

          bytes += generator.text(
            optionCombined,
            containsChinese: true,
            styles: PosStyles(
              height: ticketFontSize,
              width: ticketFontSize,
              bold: true,
            ),
          );
        }
      }

      if (item.remark != null && item.remark!.isNotEmpty) {
        bytes += generator.text(
          '   REMARK: ${item.remark}',
          containsChinese: true,
          styles: const PosStyles(bold: true),
        );
      }
      bytes += generator.feed(1);
    }

    if (isReceipt) {
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
          text: order.totalPrice.toStringAsFixed(2),
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
      bytes += generator.row([
        PosColumn(text: paymentMethod!.label, width: 6),
        PosColumn(
          text: tenderedAmount!.toStringAsFixed(2),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(text: 'CHANGE', width: 6),
        PosColumn(
          text: changeAmount!.toStringAsFixed(2),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr();
    bytes += generator.text(
      'End of Ticket',
      containsChinese: true,
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.cut();

    return bytes;
  }

  // ==========================================
  // HARDWARE TRANSMISSION HELPERS
  // ==========================================

  Future<void> _testNetworkPrinter(String ip) async {
    final printer = NetworkPrinter(PaperSize.mm80, _profile!);
    final PosPrintResult res = await printer.connect(ip, port: 9100);

    if (res == PosPrintResult.success) {
      printer.text(
        'NETWORK TEST OK',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      printer.text('IP: $ip', styles: const PosStyles(align: PosAlign.center));
      printer.feed(2);
      printer.cut();
      printer.disconnect();
      Get.snackbar("Success".tr, "Network test print sent successfully".tr);
    } else {
      Get.snackbar(
        "Connection Failed".tr,
        "Could not reach IP printer: ${res.msg}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _testBluetoothPrinter(String macAddress) async {
    List<int> bytes = [];
    final generator = Generator(PaperSize.mm80, _profile!);

    bytes += generator.text(
      'BLUETOOTH TEST OK',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'MAC: $macAddress',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.cut();

    bool isSuccess = await _sendBluetoothBytes(macAddress, bytes);

    if (isSuccess) {
      Get.snackbar("Success".tr, "Bluetooth test print sent successfully".tr);
    } else {
      Get.snackbar(
        "Connection Failed".tr,
        "Could not reach Bluetooth printer",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<bool> _sendBluetoothBytes(String macAddress, List<int> bytes) async {
    try {
      bool hasPermissions = await _requestBluetoothPermissions();
      if (!hasPermissions) {
        Get.snackbar(
          "Permission Denied".tr,
          "Bluetooth permissions are required to print.".tr,
        );
        return false;
      }

      bool isBlueOn = await PrintBluetoothThermal.bluetoothEnabled;
      if (!isBlueOn) {
        Get.snackbar(
          "Bluetooth Off".tr,
          "Please turn on Bluetooth to print.".tr,
        );
        return false;
      }

      Get.log("Attempting Bluetooth connection to $macAddress...");
      bool connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: macAddress,
      );

      if (connected) {
        Get.log("Bluetooth Connected! Sending bytes...");
        await PrintBluetoothThermal.writeBytes(bytes);
        await PrintBluetoothThermal.disconnect;
        return true;
      } else {
        Get.log("Failed to connect to Bluetooth printer.");
        return false;
      }
    } catch (e) {
      Get.log("Bluetooth Error: $e");
      await PrintBluetoothThermal.disconnect;
      return false;
    }
  }
}