import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_now_pro/app/core/theme/app_color.dart';
import 'package:pos_now_pro/app/modules/order/order_controller.dart';
import 'package:pos_now_pro/app/routes/app_route.dart';
import '../../core/widgets/neumorphic_button.dart';
import '../../core/widgets/neumorphic_container.dart';
import '../../data/models/order_model.dart';
import '../../services/user_preference_service.dart';
import '../login/auth_controller.dart';

class OrderView extends GetView<OrderController> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  OrderView({super.key});

  final ScrollController _tableScrollController = ScrollController();
  final ScrollController _foodScrollController = ScrollController();
  final ScrollController _beverageScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildSideDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.background,
          onRefresh: () async {
            await controller.load();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TOP NAVIGATION BAR ---
                _buildTopBar(),

                const SizedBox(height: 24),

                // --- MAIN CONTENT AREA (3 Columns) ---
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // COLUMN 1: Table List (Left Panel)
                      Expanded(flex: 3, child: _buildTableListPanel()),
                      const SizedBox(width: 24),

                      // COLUMN 2 & 3: Details (Center & Right Panel)
                      Expanded(
                        flex: 7,
                        child: Obx(() {
                          if (controller.selectedOrder.value == null) {
                            return _buildEmptyState(
                              icon: Icons.receipt_long_outlined,
                              message: "Add orders to view details".tr,
                            );
                          }
                          return _buildOrderDetailPanel(
                            controller.selectedOrder.value!,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- SIDE MENU WIDGET ---
  Widget _buildSideDrawer() {
    return Drawer(
      backgroundColor: AppColors.background,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 1. HEADER
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        const BoxShadow(
                          color: Colors.white,
                          offset: Offset(-5, -5),
                          blurRadius: 10,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          offset: const Offset(5, 5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Version 1.0.0",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),

            // 2. NEUMORPHIC NAVIGATION ITEMS
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildNeumorphicTile(
                    icon: Icons.insert_chart_outlined,
                    title: "Sales History".tr,
                    onTap: () async {
                      Get.back();
                      await controller.openWebDashboard();
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildNeumorphicTile(
                    icon: Icons.settings_outlined,
                    title: "Settings".tr,
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoute.SETTING);
                    },
                  ),
                ],
              ),
            ),

            // 3. NEUMORPHIC LOGOUT BUTTON
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildNeumorphicTile(
                icon: Icons.logout_rounded,
                title: "Logout".tr,
                isDestructive: true,
                onTap: () {
                  Get.back();
                  Get.find<AuthController>().logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to create Neumorphic List Tiles
  Widget _buildNeumorphicTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final Color itemColor = isDestructive
        ? AppColors.primary
        : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDestructive
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.06),
              offset: const Offset(5, 5),
              blurRadius: 10,
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-5, -5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: itemColor, size: 26),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: itemColor,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: itemColor.withValues(alpha: 0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        // Menu Button
        NeumorphicContainer(
          padding: const EdgeInsets.all(12),
          borderRadius: 16,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            child: const Icon(
              Icons.menu_rounded,
              color: AppColors.textSecondary,
              size: 28,
            ),
          ),
        ),

        const SizedBox(width: 24),

        // Title
        Text(
          "Dashboard".tr,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 30),

        // Tabs
        Obx(
          () => Row(
            children: [
              NeumorphicButton(
                text: "${controller.ordersPending.length} ${"Orders".tr}",
                isActive: controller.currentTabIndex.value == 0,
                activeColor: AppColors.primary,
                onTap: () => controller.switchTab(0),
              ),
              const SizedBox(width: 16),
              NeumorphicButton(
                text: "${controller.ordersServed.length} ${"Pay".tr}",
                isActive: controller.currentTabIndex.value == 1,
                activeColor: AppColors.primary,
                onTap: () => controller.switchTab(1),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Print History Button
        NeumorphicContainer(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          borderRadius: 20,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Get.toNamed(AppRoute.PRINT_HISTORY),
            child: Row(
              children: [
                const Icon(
                  Icons.print_outlined,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  "Print History".tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableListPanel() {
    return NeumorphicContainer(
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Obx(
              () => Text(
                controller.currentTabIndex.value == 0
                    ? "Pending Orders".tr
                    : "Unpaid Orders".tr,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final list = controller.currentTabIndex.value == 0
                  ? controller.ordersPending
                  : controller.ordersServed;

              if (controller.isLoading.isTrue) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (list.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.table_restaurant_outlined,
                  message: "No order added".tr,
                );
              }

              return RawScrollbar(
                controller: _tableScrollController,
                thumbVisibility: true,
                trackVisibility: true,
                thumbColor: AppColors.primary,
                trackColor: AppColors.primary.withValues(alpha: 0.1),
                thickness: 6.0,
                radius: const Radius.circular(10),
                child: ListView.builder(
                  controller: _tableScrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final order = list[index];

                    return Obx(() {
                      final isSelected =
                          controller.selectedOrder.value?.id == order.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18.0),
                        child: GestureDetector(
                          onTap: () => controller.selectOrder(order),
                          onLongPress: () => _showClearTableDialog(order),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 15,
                                        offset: const Offset(4, 6),
                                      ),
                                    ]
                                  : [
                                      const BoxShadow(
                                        color: Colors.white,
                                        offset: Offset(-5, -5),
                                        blurRadius: 10,
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.06,
                                        ),
                                        offset: const Offset(5, 5),
                                        blurRadius: 10,
                                      ),
                                    ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // --- LEFT SIDE: Order Type Badge & Table Number ---
                                    Row(
                                      children: [
                                        // Order Type Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.onPrimary.withValues(
                                                    alpha: 0.2,
                                                  ) // Translucent white if selected
                                                : (order.orderType == 'take_away'
                                                      ? Colors.orange.shade50
                                                      : Colors.blue.shade50),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            order.orderType == 'take_away'
                                                ? "Takeaway".tr
                                                : "Dine In".tr,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? AppColors.onPrimary
                                                  : (order.orderType ==
                                                            'take_away'
                                                        ? Colors.orange.shade700
                                                        : Colors.blue.shade700),
                                            ),
                                          ),
                                        ),

                                        // Table Number (Only show if tableId exists)
                                        if (order.tableId != null) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            "${"Table".tr}-${order.tableId}",
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: isSelected
                                                  ? AppColors.onPrimary
                                                  : AppColors.text,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),

                                    // --- RIGHT SIDE: Total Price ---
                                    Text(
                                      // Added .toStringAsFixed(2) for clean currency formatting
                                      "RM${order.totalPrice.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? AppColors.onPrimary
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // --- BOTTOM ROW: Staff Name ---
                                Text(
                                  "order_by".trParams({"name": order.staffName}),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.onPrimary.withValues(
                                            alpha: 0.8,
                                          )
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    });
                  },
                ),
              );
            }),
          ),
          // Add Order Button
          Obx(
            () => controller.currentTabIndex.value == 0
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 24.0, top: 10.0),
                    child: Center(
                      child: _buildNeumorphicAddButton(controller.goToNewOrder),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailPanel(OrderModel order) {
    return Obx(() {
      final foodItems = order.orderItems
          .where((item) => item.categoryName == "Food")
          .toList();

      final drinkItems = order.orderItems
          .where((item) => item.categoryName == "Beverage")
          .toList();

      return Row(
        children: [
          // Middle Column (Food)
          Expanded(
            child: NeumorphicContainer(
              borderRadius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      "${"Food".tr}  •  ${"Table".tr} ${order.tableId}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  if (foodItems.isEmpty)
                    Expanded(
                      child: _buildEmptyState(
                        icon: Icons.fastfood_outlined,
                        message: "No food added".tr,
                      ),
                    ),
                  if (foodItems.isNotEmpty)
                    Expanded(child: _buildItemsList(foodItems, _foodScrollController)),

                  if (controller.currentTabIndex.value == 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0, top: 10.0),
                      child: Center(
                        child: _buildNeumorphicAddButton(
                          controller.goToAddItemsToExistingOrder,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),

          // Right Column (Beverages + Actions)
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: NeumorphicContainer(
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            "${"Beverages".tr}  •  ${"Table".tr} ${order.tableId}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        if (drinkItems.isEmpty)
                          Expanded(
                            child: _buildEmptyState(
                              icon: Icons.local_cafe_outlined,
                              message: "No beverages added".tr,
                            ),
                          ),
                        if (drinkItems.isNotEmpty)
                          Expanded(child: _buildItemsList(drinkItems, _beverageScrollController)),

                        if (controller.currentTabIndex.value == 0)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 24.0,
                              top: 10.0,
                            ),
                            child: Center(
                              child: _buildNeumorphicAddButton(
                                () => controller.goToAddItemsToExistingOrder(
                                  targetCategoryName: 'beverage',
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                if (controller.currentTabIndex.value == 1)
                  _buildPrimaryActionButton(
                    title: "Pay".tr,
                    icon: Icons.payments_outlined,
                    onTap: () => controller.goToPayment(),
                  ),
                if (controller.currentTabIndex.value == 0)
                  _buildPrimaryActionButton(
                    title: "Send To Kitchen".tr,
                    icon: Icons.send_rounded,
                    onTap: () => controller.printTicket(),
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildItemsList(List<OrderItem> items, ScrollController scrollController) {
    bool isChineseUI = UserPreferenceService.instance.getAppLanguage() == 'zh';
    return RawScrollbar(
      controller: scrollController,
      thumbVisibility: true,
      trackVisibility: true,
      thumbColor: AppColors.primary,
      trackColor: AppColors.primary.withValues(alpha: 0.1),
      thickness: 6.0,
      radius: const Radius.circular(10),
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => controller.openEditProductDialog(item),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Food Code Badge
                            // Column(
                            //   children: [
                            //     Container(
                            //       padding: const EdgeInsets.symmetric(
                            //         horizontal: 8,
                            //         vertical: 4,
                            //       ),
                            //       margin: const EdgeInsets.only(right: 8, top: 1),
                            //       decoration: BoxDecoration(
                            //         color: Colors.blue.shade50,
                            //         borderRadius: BorderRadius.circular(8),
                            //       ),
                            //       child: Text(
                            //         item.foodCode,
                            //         style: TextStyle(
                            //           fontSize: 15,
                            //           fontWeight: FontWeight.bold,
                            //           color: Colors.blue.shade700,
                            //         ),
                            //       ),
                            //     ),
                            //     const SizedBox(height: 5),
                            //
                            //   ],
                            // ),

                            // Quantity Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              margin: const EdgeInsets.only(right: 8, top: 1),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'x${item.quantity}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),


                            // Food Name - WRAPPED IN EXPANDED to push price to the right
                            Expanded(
                              child: Text(
                                isChineseUI
                                    ? item.menuItemSubName
                                    : item.menuItemName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                              ),
                            ),

                            // --- NEW: Item Total Price ---
                            Padding(
                              padding: const EdgeInsets.only(right: 12.0, top: 2),
                              child: Text(
                                "RM${item.total.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        if (item.options.isEmpty &&
                            item.categoryName == "Food" &&
                            item.weight == null)
                          _buildPillBadge(isChineseUI ? "1 人份" : "1 Pax"),

                        if (item.weight != null)
                          _buildPillBadge("${item.weight} KG"),

                        if (item.options.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: item.options
                                .map(
                                  (option) => _buildPillBadge(
                                isChineseUI ? option.subName : option.name,
                              ),
                            )
                                .toList(),
                          ),

                        if (item.remark != null && item.remark!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              "${"Remarks".tr}: ${item.remark}",
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  _buildSmallIconButton(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.primary,
                    onTap: () => controller.deleteOrderItem(orderItemId: item.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- REUSABLE MODERN COMPONENTS ---
  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 60, color: AppColors.border),
          const SizedBox(height: 16),
          Text(
            message,
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

  Widget _buildNeumorphicAddButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
          boxShadow: [
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-5, -5),
              blurRadius: 10,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(5, 5),
              blurRadius: 10,
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          size: 36,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSmallIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-2, -2),
              blurRadius: 5,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(2, 2),
              blurRadius: 5,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildPrimaryActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 75,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-2, -2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.onPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 12),
            Icon(icon, color: AppColors.onPrimary, size: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPillBadge(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  void _showClearTableDialog(OrderModel order) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Clear Table".tr,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "${"Are you sure you want to delete the entire order for".tr} ${"Table".tr}-${order.tableId}?\n\n${"This action cannot be undone.".tr}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Cancel".tr,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Get.back();
                        controller.clearTable(tableId: order.tableId!);
                      },
                      child: Text(
                        "Delete".tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String getOptionsDisplayText(OrderItem item) {
    List<String> printedOptions = [];
    bool hasSizeOption = false;
    if ((item.options as List?)?.isNotEmpty ?? false) {
      hasSizeOption = true;
    }
    if (!hasSizeOption) {
      printedOptions.add("1 Pax");
    }
    for (var opt in item.options) {
      printedOptions.add(opt.name);
    }
    return printedOptions.join(", ");
  }
}
