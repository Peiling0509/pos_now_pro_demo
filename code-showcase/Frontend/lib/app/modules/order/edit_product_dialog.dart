import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_color.dart';
import '../../data/models/main_menu_model.dart';
import '../../data/models/order_model.dart';
import '../../services/user_preference_service.dart';
import 'order_controller.dart';

class EditProductDialog extends StatelessWidget {
  final MenuItemModel currentMenuItem;
  final OrderItem orderItem;

  const EditProductDialog({
    super.key,
    required this.currentMenuItem,
    required this.orderItem,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ItemDetailController(currentMenuItem, orderItem),
      tag: orderItem.id.toString(),
    );

    final orderController = Get.find<OrderController>();

    final bool isChineseUI =
        UserPreferenceService.instance.getAppLanguage() == "zh";

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: Get.width * 0.6,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF7),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(24),
        child: ListView(
          shrinkWrap: true,
          children: [
            // --- HEADER: Title & Quantity ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isChineseUI
                        ? currentMenuItem.subName
                        : currentMenuItem.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                // Quantity Counter
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      _buildQtyBtn(
                        icon: Icons.remove,
                        color: Colors.red,
                        onTap: controller.decrement,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Obx(
                              () => Text(
                            "${controller.quantity.value}",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      _buildQtyBtn(
                        icon: Icons.add,
                        color: Colors.blue,
                        onTap: controller.increment,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- SCROLLABLE CONTENT (Options, Weight, Open Price & Remarks) ---
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🌟 WEIGHT & OPEN PRICE FIELDS
                  if (currentMenuItem.isOpenPrice) ...[
                    Text(
                      isChineseUI ? "重量 (Kg)" : "Weight (Kg)",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: controller.weightController,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: isChineseUI ? "例如: 1.5" : "e.g., 1.5",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: InputBorder.none,
                          suffixText: "Kg",
                          suffixStyle:
                          TextStyle(color: Colors.grey[600], fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- HIDDEN MANUAL OPEN PRICE BOX ---
                    /*
                    Text(
                      "Enter Open Price (RM)".tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: TextField(
                          controller: controller.openPriceController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: "0.00",
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey[400]),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    */
                    // ------------------------------------
                  ],

                  // Dynamic Options Grouped by Type
                  ...controller.groupedOptions.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10.0,
                          runSpacing: 10.0,
                          children: entry.value.map((option) {
                            return Obx(() {
                              final isSelected =
                                  controller.selectedOptions[entry.key]?.id ==
                                      option.id;

                              return GestureDetector(
                                onTap: () =>
                                    controller.selectOption(entry.key, option),
                                child: AnimatedContainer(
                                  height: 80,
                                  width: (Get.width * 0.6 - 68) / 3,
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFDC2626)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                    border: isSelected
                                        ? null
                                        : Border.all(
                                      color: Colors.transparent,
                                    ),
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text(
                                        isChineseUI && option.subName.isNotEmpty
                                            ? option.subName
                                            : option.name.tr,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey[600],
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            });
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),

                  const SizedBox(height: 10),

                  // Remarks Field
                  Container(
                    height: 120,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEDED),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      controller: controller.remarksController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: "${"Remarks".tr}...",
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // --- BOTTOM BUTTONS ---
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE0E0E0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Cancel".tr,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        final qty = controller.quantity.value;
                        final rmk = controller.remarksController.text;

                        double? customOpenPrice;
                        double? parsedWeight;

                        // 🌟 UPDATED: Validate Weight and bypass Custom Open Price
                        if (currentMenuItem.isOpenPrice) {
                          if (controller.weightController.text.isEmpty) {
                            Get.snackbar(
                                "Required".tr,
                                "Please enter the weight.".tr,
                                backgroundColor: Colors.redAccent,
                                colorText: Colors.white);
                            return;
                          }

                          // No longer passing manual price since it is auto-calculated
                          customOpenPrice = null;

                          if (controller.weightController.text.isNotEmpty) {
                            parsedWeight = double.tryParse(
                                controller.weightController.text);
                          }
                        }

                        final optIds = controller.selectedOptions.values
                            .map((e) => e.id)
                            .where((id) => id != -1)
                            .toList();

                        orderController.updateSingleOrderItem(
                          orderId: orderItem.orderId,
                          orderItemId: orderItem.id,
                          quantity: qty,
                          remark: rmk,
                          optionIds: optIds,
                          weight: parsedWeight,
                        );

                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        "Update".tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}

class ItemDetailController extends GetxController {
  final MenuItemModel item;
  final OrderItem existingOrderItem;

  ItemDetailController(this.item, this.existingOrderItem);

  var quantity = 1.obs;
  var selectedOptions = <int, OptionModel>{}.obs;
  Map<int, List<OptionModel>> groupedOptions = {};

  final TextEditingController remarksController = TextEditingController();

  final TextEditingController openPriceController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _groupOptions();
    _loadExistingData();
  }

  @override
  void onClose() {
    remarksController.dispose();
    openPriceController.dispose();
    weightController.dispose();
    super.onClose();
  }

  void _groupOptions() {
    bool hasBasePrice = item.price.toString().isNotEmpty && item.price != 0;

    if (hasBasePrice && item.options.isNotEmpty) {
      int firstOptionTypeId = item.options.first.optionTypeId;

      OptionModel basePriceOption = OptionModel(
        id: -1,
        optionTypeId: firstOptionTypeId,
        name: '1 Pax',
        subName: '1 人份',
        extraPrice: 0.0,
      );

      groupedOptions[firstOptionTypeId] = [basePriceOption];
    }

    for (var option in item.options) {
      if (!groupedOptions.containsKey(option.optionTypeId)) {
        groupedOptions[option.optionTypeId] = [];
      }
      groupedOptions[option.optionTypeId]!.add(option);
    }
  }

  void _loadExistingData() {
    quantity.value = existingOrderItem.quantity;
    remarksController.text = existingOrderItem.remark ?? "";

    if (item.isOpenPrice) {
      // openPriceController.text = existingOrderItem.price.toString();

      if (existingOrderItem.weight != null) {
        weightController.text = existingOrderItem.weight.toString();
      }
    }

    bool hasSizeOptionSelected = false;

    for (var savedOption in existingOrderItem.options) {
      for (var option in item.options) {
        if (option.id == savedOption.id) {
          selectedOptions[option.optionTypeId] = option;

          if (option.optionTypeId == 1) {
            hasSizeOptionSelected = true;
          }
          break;
        }
      }
    }

    if (!hasSizeOptionSelected && groupedOptions.isNotEmpty) {
      int firstKey = groupedOptions.keys.first;
      var paxOption =
      groupedOptions[firstKey]?.firstWhereOrNull((o) => o.id == -1);

      if (paxOption != null) {
        selectedOptions[firstKey] = paxOption;
      }
    }
  }

  void selectOption(int typeId, OptionModel option) {
    selectedOptions[typeId] = option;
  }

  void increment() => quantity.value++;

  void decrement() {
    if (quantity.value > 1) quantity.value--;
  }
}