// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:pos_now_pro/app/core/widgets/neumorphic_container.dart';
// import '../../core/theme/app_color.dart';
// import '../../data/models/order_model.dart';
// import '../../data/models/payment_method_enum.dart';
// import '../../services/user_preference_service.dart';
// import 'payment_controller.dart';
//
// class PaymentView extends GetView<PaymentController> {
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//
//   PaymentView({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Get.back(),
//         ),
//         title: Text(
//           "Pay".tr,
//           style: TextStyle(
//             color: AppColors.textSecondary,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//       body: SafeArea(
//         child: Obx(() {
//           if (controller.isLoading.value) {
//             return Center(child: CircularProgressIndicator());
//           }
//
//           // Handle case where no order is selected
//           if (controller.currentOrder.value == null) {
//             return Center(child: Text("No served orders found"));
//           }
//           return Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // --- LEFT COLUMN: BILL DETAILS ---
//                 Expanded(
//                   flex: 35, // 35% width
//                   child: _buildBillDetails(),
//                 ),
//
//                 SizedBox(width: 16),
//
//                 // --- RIGHT COLUMN: PAYMENT INTERFACE ---
//                 Expanded(
//                   flex: 65, // 65% width
//                   child: Column(
//                     children: [
//                       // Top Info Card (Total & Change)
//                       _buildTopInfoCard(),
//
//                       SizedBox(height: 16),
//
//                       // Payment Method & Keypad Area
//                       Expanded(child: _buildPaymentInterface()),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }),
//       ),
//     );
//   }
//
//   // Widget: Left Side Bill List (Dynamic)
//   Widget _buildBillDetails() {
//     // Access the current order safely
//     final order = controller.currentOrder.value;
//
//     // Fallback if no order is selected (should be handled by the parent Obx, but good for safety)
//     if (order == null) return Center(child: Text("Please select an order"));
//
//     return NeumorphicContainer(
//       padding: EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // 1. Dynamic Table Number
//           Text(
//             "bill_details_table".trParams({
//               "tableId": order.tableId.toString(),
//             }),
//             style: TextStyle(fontSize: 16, color: Colors.grey[700]),
//           ),
//
//           Divider(height: 24),
//
//           // 2. Dynamic List of Items
//           Expanded(
//             child: ListView.builder(
//               itemCount: order.orderItems.length,
//               itemBuilder: (context, index) {
//                 final item = order.orderItems[index];
//                 return _buildOrderItem(item);
//               },
//             ),
//           ),
//
//           Divider(),
//
//           // 3. Dynamic Total Bottom Row
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 "Total".tr,
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//               // Observe the total directly from the order data
//               Text(
//                 "RM ${order.totalPrice.toStringAsFixed(2)}",
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildOrderItem(OrderItem item) {
//     bool isChineseUI = UserPreferenceService.instance.getAppLanguage() == 'zh';
//
//     // 1. Create an empty list to gather all modifiers
//     List<String> modifiers = [];
//
//     // 2. Add Weight if it exists
//     if (item.weight != null) {
//       modifiers.add("${item.weight} kg");
//     }
//
//     // 3. Add Options
//     if (item.options.isEmpty && item.categoryName.toLowerCase() == 'food') {
//       modifiers.add(isChineseUI ? "1 人份" : "1 Pax");
//     } else {
//       // Otherwise, add the actual options from the database
//       modifiers.addAll(item.options.map((opt) {
//         return (isChineseUI && opt.subName.isNotEmpty) ? opt.subName : opt.name;
//       }));
//     }
//
//     // 4. Join everything together into one string
//     String combinedOptionsText = modifiers.join(', ');
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // LEFT SIDE: Quantity box
//           Container(
//             width: 24,
//             height: 24,
//             alignment: Alignment.center,
//             decoration: BoxDecoration(
//               color: Colors.grey[200],
//               borderRadius: BorderRadius.circular(4),
//             ),
//             child: Text(
//               '${item.quantity}x',
//               style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
//             ),
//           ),
//
//           const SizedBox(width: 12),
//
//           // MIDDLE: Name + Combined Options
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Item Name
//                 Text(
//                   (isChineseUI && item.menuItemSubName.isNotEmpty)
//                       ? item.menuItemSubName
//                       : item.menuItemName,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 16,
//                   ),
//                 ),
//
//                 // 🌟 Combined Weight & Options Display
//                 if (combinedOptionsText.isNotEmpty)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 4.0),
//                     child: Text(
//                       combinedOptionsText,
//                       style: TextStyle(
//                         fontSize: 13,
//                         color: Colors.grey[600],
//                         fontStyle: FontStyle.italic,
//                       ),
//                     ),
//                   ),
//
//                 // Optional: Show Remarks if they exist
//                 if (item.remark != null && item.remark!.isNotEmpty)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 2.0),
//                     child: Text(
//                       'Note: ${item.remark}',
//                       style: TextStyle(fontSize: 12, color: Colors.orange[800]),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//
//           // RIGHT SIDE: Total Price
//           Text(
//             'RM ${item.total.toStringAsFixed(2)}',
//             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Widget: Right Side Top (Total/Change)
//   Widget _buildTopInfoCard() {
//     return NeumorphicContainer(
//       padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//       child: IntrinsicHeight(
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                 children: [
//                   Text("Total".tr, style: TextStyle(fontWeight: FontWeight.bold)),
//                   Obx(
//                     () => Text(
//                       "RM ${controller.totalAmount.value.toStringAsFixed(2)}",
//                       style: TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             VerticalDivider(color: Colors.grey),
//             Expanded(
//               child: Column(
//                 children: [
//                   Text("Change".tr, style: TextStyle(fontWeight: FontWeight.bold)),
//                   Obx(
//                     () => Text(
//                       "RM ${controller.changeAmount.toStringAsFixed(2)}",
//                       style: TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Widget: Right Side Bottom (Methods + Keypad)
//   Widget _buildPaymentInterface() {
//     return NeumorphicContainer(
//       padding: EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text("Payment Method".tr, style: TextStyle(color: Colors.grey[700])),
//           SizedBox(height: 10),
//           //Payment Method Buttons (Generated from Enum)
//           Obx(
//             () => Wrap(
//               spacing: 10,
//               children: PaymentMethod.values.map((method) {
//                 final isSelected =
//                     controller.selectedPaymentMethod.value == method;
//                 return _buildPaymentTypeBtn(method, isSelected);
//               }).toList(),
//             ),
//           ),
//           SizedBox(height: 16),
//
//           // Input Display
//           Container(
//             width: double.infinity,
//             height: 60,
//             padding: EdgeInsets.symmetric(horizontal: 16),
//             decoration: BoxDecoration(
//               color: Colors.grey[200],
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Stack(
//               alignment: Alignment.center,
//               children: [
//                 // 1. The Currency Label (Pinned to Left)
//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     "RM",
//                     style: TextStyle(fontSize: 24, color: Colors.grey),
//                   ),
//                 ),
//
//                 // 2. The Number (Centered in the container)
//                 Obx(
//                   () => Text(
//                     controller.tenderedAmount.value,
//                     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: 16),
//
//           // Keypad Area
//           Expanded(
//             child: Row(
//               children: [
//                 // Column 1: Quick Amounts
//                 Expanded(
//                   flex: 1,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       _buildQuickAmountBtn(50),
//                       _buildQuickAmountBtn(100),
//                       _buildQuickAmountBtn(150),
//                       _buildQuickAmountBtn(200),
//                     ],
//                   ),
//                 ),
//                 SizedBox(width: 10),
//
//                 // Column 2: Numpad
//                 Expanded(
//                   flex: 3,
//                   child: Column(
//                     children: [
//                       Expanded(
//                         child: Row(
//                           children: [
//                             _buildKeyBtn("1"),
//                             _buildKeyBtn("2"),
//                             _buildKeyBtn("3"),
//                           ],
//                         ),
//                       ),
//                       Expanded(
//                         child: Row(
//                           children: [
//                             _buildKeyBtn("4"),
//                             _buildKeyBtn("5"),
//                             _buildKeyBtn("6"),
//                           ],
//                         ),
//                       ),
//                       Expanded(
//                         child: Row(
//                           children: [
//                             _buildKeyBtn("7"),
//                             _buildKeyBtn("8"),
//                             _buildKeyBtn("9"),
//                           ],
//                         ),
//                       ),
//                       Expanded(
//                         child: Row(
//                           children: [
//                             _buildActionBtn(
//                               "Cancel".tr,
//                               onTap: () => controller.clearInput(),
//                             ),
//                             _buildKeyBtn("0"),
//                             _buildKeyBtn("."),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(width: 10),
//
//                 // Column 3: Pay Button (or located at bottom right)
//                 // In your image, the button is large. We can use a container here.
//                 GestureDetector(
//                   onTap: () => controller.processPayment(),
//                   child: Container(
//                     width: 100,
//                     decoration: BoxDecoration(
//                       color: AppColors.primary,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     alignment: Alignment.center,
//                     child: Text(
//                       "Pay".tr,
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // --- Helper Widgets ---
//   Widget _buildPaymentTypeBtn(PaymentMethod method, bool isSelected) {
//     return GestureDetector(
//       onTap: () => controller.setPaymentMethod(method),
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? AppColors.primary
//               : Colors.grey[200], // Active Color
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(
//             color: isSelected ? Colors.red : Colors.transparent,
//           ),
//           boxShadow: isSelected
//               ? [
//                   BoxShadow(
//                     color: AppColors.primary.withValues(alpha: 0.3),
//                     blurRadius: 8,
//                     offset: Offset(0, 4),
//                   ),
//                 ]
//               : [],
//         ),
//         child: Text(
//           method.label.tr,
//           style: TextStyle(
//             color: isSelected ? Colors.white : Colors.black87,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildQuickAmountBtn(double amount) {
//     return Expanded(
//       child: Padding(
//         padding: const EdgeInsets.all(4.0),
//         child: ElevatedButton(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.white,
//             foregroundColor: Colors.black,
//             elevation: 2,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             padding: const EdgeInsets.all(14.0),
//           ),
//           onPressed: () => controller.setExactAmount(amount),
//           child: Text(
//             "RM ${amount.toStringAsFixed(0)}",
//             style: TextStyle(fontSize: 16),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildKeyBtn(String val) {
//     return Expanded(
//       child: Padding(
//         padding: const EdgeInsets.all(4.0),
//         child: ElevatedButton(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.white,
//             foregroundColor: Colors.black,
//             elevation: 2,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             padding: const EdgeInsets.all(14.0),
//           ),
//           onPressed: () => controller.onKeypadTap(val),
//           child: Text(val, style: TextStyle(fontSize: 24)),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildActionBtn(String label, {required VoidCallback onTap}) {
//     return Expanded(
//       child: Padding(
//         padding: const EdgeInsets.all(4.0),
//         child: ElevatedButton(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.white,
//             foregroundColor: Colors.black,
//             elevation: 2,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             padding: const EdgeInsets.all(20.0),
//           ),
//           onPressed: onTap,
//           child: Text(label, style: TextStyle(fontSize: 16)),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_now_pro/app/core/widgets/neumorphic_container.dart';
import '../../core/theme/app_color.dart';
import '../../data/models/order_model.dart';
import '../../data/models/payment_method_enum.dart';
import '../../services/user_preference_service.dart';
import 'payment_controller.dart';

class PaymentView extends GetView<PaymentController> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  PaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CUSTOM NEUMORPHIC TOP BAR ---
              _buildTopBar(),
              const SizedBox(height: 24),

              // --- MAIN CONTENT AREA ---
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (controller.currentOrder.value == null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 60,
                            color: AppColors.border,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No served orders found".tr,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- LEFT COLUMN: BILL DETAILS ---
                      Expanded(
                        flex: 35,
                        child: NeumorphicContainer(
                          borderRadius: 28,
                          child: _buildBillDetails(),
                        ),
                      ),

                      const SizedBox(width: 24),

                      // --- RIGHT COLUMN: PAYMENT INTERFACE ---
                      Expanded(
                        flex: 65,
                        child: Column(
                          children: [
                            // Top Info Card (Total & Change)
                            _buildTopInfoCard(),
                            const SizedBox(height: 24),
                            // Payment Method & Keypad Area
                            Expanded(child: _buildPaymentInterface()),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= TOP BAR =================

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-4, -4),
                  blurRadius: 8,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(4, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 24),
        Text(
          "Pay".tr,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ================= LEFT COLUMN: BILL DETAILS =================

  Widget _buildBillDetails() {
    final order = controller.currentOrder.value!;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "bill_details_table".trParams({
                  "tableId": order.tableId.toString(),
                }),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "#${order.id.toString().padLeft(4, '0')}",
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: AppColors.border, thickness: 0.5),
          ),

          // Items List
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: order.orderItems.length,
              itemBuilder: (context, index) {
                final item = order.orderItems[index];
                return _buildOrderItem(item);
              },
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: AppColors.border, thickness: 0.5),
          ),

          // Total Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Amount".tr,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                "RM ${order.totalPrice.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    bool isChineseUI = UserPreferenceService.instance.getAppLanguage() == 'zh';
    List<String> modifiers = [];

    if (item.weight != null) {
      modifiers.add("${item.weight} kg");
    }

    if (item.options.isEmpty && item.categoryName.toLowerCase() == 'food') {
      modifiers.add(isChineseUI ? "1 人份" : "1 Pax");
    } else {
      modifiers.addAll(
        item.options.map((opt) {
          return (isChineseUI && opt.subName.isNotEmpty)
              ? opt.subName
              : opt.name;
        }),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quantity Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-2, -2),
                  blurRadius: 4,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              '${item.quantity}x',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Name & Modifiers
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (isChineseUI && item.menuItemSubName.isNotEmpty)
                      ? item.menuItemSubName
                      : item.menuItemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.text,
                  ),
                ),
                if (modifiers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: modifiers
                          .map((mod) => _buildPillBadge(mod))
                          .toList(),
                    ),
                  ),
                if (item.remark != null && item.remark!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      '${"Remarks".tr}: ${item.remark}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Price
          Text(
            'RM ${item.total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  // ================= RIGHT COLUMN: INFO & KEYPAD =================

  Widget _buildTopInfoCard() {
    return NeumorphicContainer(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 24,
      ), // Condense vertical padding
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Amount".tr,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(
                    () => Text(
                      "RM ${controller.totalAmount.value.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 28, // Reduced from 36 to save vertical space
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            VerticalDivider(
              color: AppColors.border.withValues(alpha: 0.3),
              thickness: 1.5,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Change".tr,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(
                    () => Text(
                      "RM ${controller.changeAmount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 28, // Reduced from 36
                        fontWeight: FontWeight.w800,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInterface() {
    return NeumorphicContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(20), // Reduced from 28
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Payment Method".tr,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),

          // Payment Method Toggles
          Obx(
            () => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: PaymentMethod.values.map((method) {
                final isSelected =
                    controller.selectedPaymentMethod.value == method;
                return _buildPaymentTypeBtn(method, isSelected);
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Tendered Amount Display Screen
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ), // Condense padding
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(2, 2),
                  blurRadius: 6,
                  blurStyle: BlurStyle.inner,
                ),
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-2, -2),
                  blurRadius: 6,
                  blurStyle: BlurStyle.inner,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "RM",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
                Obx(
                  () => Text(
                    controller.tenderedAmount.value,
                    style: const TextStyle(
                      fontSize: 28, // Reduced from 32
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Keypad Area
          Expanded(
            child: Row(
              children: [
                // Quick Amounts
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildQuickAmountBtn(50),
                      _buildQuickAmountBtn(100),
                      _buildQuickAmountBtn(150),
                      _buildQuickAmountBtn(200),
                    ],
                  ),
                ),

                // Numbers
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            _buildNeumorphicKeyBtn("1"),
                            _buildNeumorphicKeyBtn("2"),
                            _buildNeumorphicKeyBtn("3"),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            _buildNeumorphicKeyBtn("4"),
                            _buildNeumorphicKeyBtn("5"),
                            _buildNeumorphicKeyBtn("6"),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            _buildNeumorphicKeyBtn("7"),
                            _buildNeumorphicKeyBtn("8"),
                            _buildNeumorphicKeyBtn("9"),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            _buildActionKeyBtn(
                              "C",
                              onTap: () => controller.clearInput(),
                              color: Colors.orange.shade400,
                            ),
                            _buildNeumorphicKeyBtn("0"),
                            _buildNeumorphicKeyBtn("."),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Giant Pay Action Button
                GestureDetector(
                  onTap: () => controller.processPayment(),
                  child: Container(
                    width: 100, // Slightly slimmer
                    margin: const EdgeInsets.all(
                      6.0,
                    ), // Align with numpad margins
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Pay".tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPER WIDGETS =================

  Widget _buildPaymentTypeBtn(PaymentMethod method, bool isSelected) {
    return GestureDetector(
      onTap: () => controller.setPaymentMethod(method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Colors.white,
                    offset: Offset(-3, -3),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                  ),
                ],
        ),
        child: Text(
          method.label.tr,
          style: TextStyle(
            color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountBtn(double amount) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setExactAmount(amount),
        child: Container(
          margin: const EdgeInsets.all(6.0), // Uniform margin matches Numpad
          padding: const EdgeInsets.all(8.0), // Internal padding for safety
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              const BoxShadow(
                color: Colors.white,
                offset: Offset(-3, -3),
                blurRadius: 6,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(3, 3),
                blurRadius: 6,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "RM ${amount.toStringAsFixed(0)}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicKeyBtn(String val) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.onKeypadTap(val),
        child: Container(
          margin: const EdgeInsets.all(6.0), // Uniform margin
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              const BoxShadow(
                color: Colors.white,
                offset: Offset(-4, -4),
                blurRadius: 8,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(4, 4),
                blurRadius: 8,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              val,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKeyBtn(
    String label, {
    required VoidCallback onTap,
    required Color color,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(6.0), // Uniform margin
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              const BoxShadow(
                color: Colors.white,
                offset: Offset(-4, -4),
                blurRadius: 8,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(4, 4),
                blurRadius: 8,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
