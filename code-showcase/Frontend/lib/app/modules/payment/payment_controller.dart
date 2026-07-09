import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_now_pro/app/data/models/order_model.dart';
import 'package:pos_now_pro/app/modules/order/order_controller.dart';
import '../../data/models/payment_method_enum.dart';
import '../../data/repositories/order_repository.dart';

// 🌟 ADDED: Import the PrinterService
import '../../services/printer_service.dart';

class PaymentController extends GetxController {
  // --- Dependencies ---
  final OrderRepository orderRes = OrderRepository();
  final OrderController orderController = Get.find<OrderController>();

  // --- Observables ---
  var isLoading = false.obs;
  var currentOrder = Rxn<OrderModel>(); // The specific order being paid for

  var totalAmount = 0.00.obs;
  var tenderedAmount = "0".obs;
  var selectedPaymentMethod = PaymentMethod.cash.obs;

  // --- Computed Properties ---
  double get changeAmount {
    double tender = double.tryParse(tenderedAmount.value) ?? 0.0;
    double change = tender - totalAmount.value;
    return change < 0 ? 0.00 : change;
  }

  @override
  void onInit() {
    super.onInit();
    loadArguments();
  }

  //load selected order that pass from the OrderController
  void loadArguments() {
    if (Get.arguments != null && Get.arguments is OrderModel) {
      currentOrder.value = Get.arguments;

      totalAmount.value = currentOrder.value!.totalPrice;

      tenderedAmount.value = "0";
    }
  }

  // --- Helper to set up the payment screen for a specific order ---
  void selectOrderToPay(OrderModel order) {
    currentOrder.value = order;
    totalAmount.value = order.totalPrice;
    tenderedAmount.value = "0"; // Reset input
  }

  // --- Keypad Logic (Same as before) ---
  void onKeypadTap(String value) {
    if (value == ".") {
      if (!tenderedAmount.value.contains(".")) {
        tenderedAmount.value += value;
      }
    } else {
      if (tenderedAmount.value == "0") {
        tenderedAmount.value = value;
      } else {
        tenderedAmount.value += value;
      }
    }
  }

  void clearInput() => tenderedAmount.value = "0";

  void setExactAmount(double amount) =>
      tenderedAmount.value = amount.toStringAsFixed(0);

  void setPaymentMethod(PaymentMethod method) {
    selectedPaymentMethod.value = method;

    if (method != PaymentMethod.cash) {
      // For Spay/DuitNow, exact amount is required. Auto-fill it.
      tenderedAmount.value = totalAmount.value.toStringAsFixed(2);
    } else {
      // Optional: Reset to 0 when clicking Cash, or keep it.
      // tenderedAmount.value = "0";
    }
  }

  Future<void> processPayment() async {
    if (currentOrder.value == null) return;

    // Grab the exact numbers from your controller's state
    double tender = double.tryParse(tenderedAmount.value) ?? 0.0;
    double currentChange = changeAmount;

    if (selectedPaymentMethod.value == PaymentMethod.cash &&
        tender < totalAmount.value) {
      Get.snackbar("Error".tr, "Insufficient amount tendered".tr);
      return;
    }

    isLoading.value = true;

    try {
      final body = {
        "order_id": currentOrder.value!.id,
        "method": selectedPaymentMethod.value.jsonValue,
        "amount": totalAmount.value,
        "tendered_amount": selectedPaymentMethod.value == PaymentMethod.cash
            ? tender
            : totalAmount.value,
        "pad_time": DateTime.now().toIso8601String(),
      };

      // 1. Send to API (Saves to Payment Table)
      await orderRes.payments(body);

      // Save a copy of the order to print
      final OrderModel completedOrder = currentOrder.value!;

      // 2. Close the payment screen IMMEDIATELY for a better user experience
      Get.back(result: true);

      // 3. Refresh the orders list in the background
      orderController.load();

      // Show success message
      Get.snackbar(
        "Success".tr,
        "Payment Complete".tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // 4. Trigger Counter Receipt Print (Pass the tender & change manually!)
      Future.delayed(const Duration(milliseconds: 400), () async {
        try {
          if (Get.isRegistered<PrinterService>()) {
            final printerService = Get.find<PrinterService>();
            await printerService.printCounterTicket(
              order: completedOrder,
              paymentMethod: selectedPaymentMethod.value,
              tenderedAmount: tender,
              changeAmount: currentChange,
            );
          }
        } catch (printError) {
          Get.log("❌ Failed to print counter receipt: $printError");
        }
      });
    } catch (e) {
      Get.snackbar("Error".tr, e.toString());
      Get.log("❌ Error process payment: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
