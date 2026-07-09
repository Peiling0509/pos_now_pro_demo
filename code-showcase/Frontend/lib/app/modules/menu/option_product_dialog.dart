import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_color.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/main_menu_model.dart';
import '../../services/user_preference_service.dart';
import 'menu_controller.dart' as app_menu;

class OptionProductDialog extends StatelessWidget {
  final MenuItemModel item;
  final CartItemModel? existingCartItem;

  final app_menu.MenuController menuController = Get.find();

  OptionProductDialog({super.key, required this.item, this.existingCartItem});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ItemDetailController(item, existingCartItem: existingCartItem),
    );

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
                // Food Code Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  margin: const EdgeInsets.only(right: 8, top: 1),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.foodCode,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    isChineseUI ? item.subName : item.name,
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

            // --- SCROLLABLE CONTENT (Options, Open Price & Remarks) ---
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //Open Price Text Box Section
                  if (item.isOpenPrice) ...[
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
                      style: TextStyle(
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                        // Option Group Row
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: entry.value.map((option) {
                            return Obx(() {
                              final isSelected =
                                  controller.selectedOptions[entry.key]?.id ==
                                      option.id;

                              return GestureDetector(
                                onTap: () =>
                                    controller.selectOption(entry.key, option),
                                child: AnimatedContainer(
                                  height: 60, // Slightly shorter for better fit
                                  width: (Get.width * 0.6 - 68) /
                                      3, // 3 items per row approx
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
                                        : Border.all(color: Colors.transparent),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isChineseUI
                                          ? option.subName
                                          : option.name,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey[600],
                                        fontSize: 20, // Adjusted font size
                                        fontWeight: FontWeight.bold,
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
                        // 1. OPTION VALIDATION
                        // Check if there are mandatory options that are NOT just 'Take Away' / '打包'
                        bool requiresSelection = false;
                        for (var options in controller.groupedOptions.values) {
                          for (var option in options) {
                            final name = option.name.toLowerCase();
                            final subName = option.subName.toLowerCase();

                            if (!name.contains('take away') &&
                                !name.contains('takeaway') &&
                                !subName.contains('打包') &&
                                !subName.contains('外带')) {
                              requiresSelection = true;
                              break;
                            }
                          }
                          if (requiresSelection) break;
                        }

                        if (requiresSelection && controller.selectedOptions.isEmpty) {
                          Get.snackbar(
                            "Selection Required".tr,
                            "Please select at least one option before proceeding."
                                .tr,
                            backgroundColor: Colors.redAccent,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.TOP,
                            margin: const EdgeInsets.all(15),
                            icon: const Icon(Icons.warning_amber_rounded,
                                color: Colors.white),
                          );
                          return;
                        }

                        // 2. Validate Open Price & Parse Weight
                        double? customOpenPrice;
                        double? parsedWeight;

                        if (item.isOpenPrice == true) {
                          // Removed controller.openPriceController.text.isEmpty check
                          if (controller.weightController.text.isEmpty) {
                            Get.snackbar(
                              "Required".tr,
                              "Please enter the weight.".tr,
                              backgroundColor: Colors.redAccent,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          customOpenPrice = null;

                          // Parse the weight if they typed one
                          if (controller.weightController.text.isNotEmpty) {
                            parsedWeight =
                                double.tryParse(controller.weightController.text);
                          }
                        }

                        // 3. ADD TO CART OR UPDATE
                        if (existingCartItem != null) {
                          // EDITING EXISTING ITEM
                          menuController.updateCartItem(
                            existingCartItem!,
                            controller.quantity.value,
                            controller.selectedOptions.values.toList(),
                            controller.remarksController.text,
                            customOpenPrice,
                            parsedWeight,
                          );
                        } else {
                          // ADDING NEW ITEM
                          menuController.confirmAddToCart(
                            item,
                            controller.quantity.value,
                            controller.selectedOptions.values.toList(),
                            controller.remarksController.text,
                            customOpenPrice,
                            parsedWeight,
                          );
                        }

                        // Close the dialog ONLY if everything succeeded
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF23A718), // Green
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        existingCartItem != null ? "Update".tr : "Confirm".tr,
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
  final CartItemModel? existingCartItem;

  ItemDetailController(this.item, {this.existingCartItem});

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

    if (existingCartItem != null) {
      _loadExistingData();
    } else {
      _setDefaults();
    }
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
        extraPrice: item.price,
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

  void _setDefaults() {
    final Map<int, OptionModel> defaultSelections = {};

    groupedOptions.forEach((typeId, options) {
      if (options.isNotEmpty) {
        bool contains1Pax = options.any((opt) => opt.id == -1);

        if (typeId == 1 || typeId == 3 || contains1Pax) {
          defaultSelections[typeId] = options.first;
        }
      }
    });

    selectedOptions.assignAll(defaultSelections);
  }

  void _loadExistingData() {
    quantity.value = existingCartItem!.quantity;
    remarksController.text = existingCartItem!.remarks;

    if (item.isOpenPrice == true) {
      // openPriceController.text = existingCartItem!.customOpenPrice?.toString() ?? "";

      if (existingCartItem!.weight != null) {
        weightController.text = existingCartItem!.weight.toString();
      }
    }

    final Map<int, OptionModel> existingSelections = {};
    for (var option in existingCartItem!.selectedOptions) {
      existingSelections[option.optionTypeId] = option;
    }

    selectedOptions.assignAll(existingSelections);
  }

  void selectOption(int typeId, OptionModel option) {
    if (selectedOptions[typeId]?.id == option.id) {
      selectedOptions.remove(typeId);
    } else {
      selectedOptions[typeId] = option;
    }
  }

  void increment() => quantity.value++;

  void decrement() {
    if (quantity.value > 1) quantity.value--;
  }
}