import 'package:flutter/material.dart' hide MenuController;
import 'package:get/get.dart';
import '../../core/theme/app_color.dart';

import '../../routes/app_route.dart';
import '../../services/user_preference_service.dart';
import '../login/auth_controller.dart';
import 'menu_controller.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  final controller = Get.find<MenuController>();
  final auth = Get.find<AuthController>();

  final bool _isChineseUI =
      UserPreferenceService.instance.getAppLanguage() == "zh";

  final ScrollController _cartScrollController = ScrollController();

  // --- INTEGRATING YOUR APP COLORS WITH NEUMORPHISM ---
  //final Color neuBackground = AppColors.background;
  final Color neuBackground = const Color(0xFFF6F5F2);
  final Color neuShadowDark = AppColors.border.withValues(alpha: 0.4);
  final Color neuShadowLight = Colors.white;
  final Color themeRed = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: themeRed));
        }
        return SafeArea(
          child: Row(
            children: [
              // =================================================
              // LEFT PANEL
              // =================================================
              Expanded(
                flex: 7,
                child: controller.currentView.value == PosViewState.table
                    ? _buildTableView()
                    : _buildMenuView(),
              ),

              // =================================================
              // RIGHT PANEL
              // =================================================
              Expanded(flex: 3, child: _buildCart()),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTableView() {
    return Obx(() {
      if (controller.tables.isEmpty) {
        return Center(
          child: Text(
            "No tables loaded, please make sure your network is connected.".tr,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.loadTables(),
        color: themeRed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ROW ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 0, 10),
              child: Row(
                children: [
                  if (Navigator.canPop(context))
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: neuBackground,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: neuShadowDark,
                                offset: const Offset(3, 3),
                                blurRadius: 6,
                              ),
                              BoxShadow(
                                color: neuShadowLight,
                                offset: const Offset(-3, -3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 28,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    "Hi @assessname, Welcome to Pos Now Pro".trParams({
                      'assessname': ?auth.accessName(),
                    }),
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 25,
                  crossAxisSpacing: 25,
                  childAspectRatio: 1.1,
                ),
                itemCount: controller.tables.length,
                itemBuilder: (context, index) {
                  final table = controller.tables[index];
                  final isOccupied = table.status == "occupied";

                  return GestureDetector(
                    onTap: () => controller.openTable(table),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isOccupied ? themeRed : neuBackground,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: isOccupied
                            ? [
                          BoxShadow(
                            color: themeRed.withValues(alpha: 0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ]
                            : [
                          BoxShadow(
                            color: neuShadowDark,
                            offset: const Offset(8, 8),
                            blurRadius: 15,
                          ),
                          BoxShadow(
                            color: neuShadowLight,
                            offset: const Offset(-8, -8),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isOccupied)
                              Text(
                                "Occupied".tr,
                                style: const TextStyle(
                                  color: AppColors.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const SizedBox(height: 5),
                            Text(
                              table.name,
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: isOccupied
                                    ? AppColors.onPrimary
                                    : AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMenuView() {
    return Row(
      children: [
        // Sidebar Sub-categories
        Expanded(flex: 2, child: _buildSubCategories()),
        // Main categories & Grid
        Expanded(
          flex: 8,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                child: Row(
                  children: [
                    Expanded(child: _buildMainCategories()),
                    _buildSearchBar(),
                  ],
                ),
              ),
              Expanded(child: _buildItemsGrid()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainCategories() {
    return SizedBox(
      height: 60,
      child: Obx(() {
        if (controller.fullMenu.isEmpty) return const SizedBox();

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.fullMenu.length,
          itemBuilder: (context, index) {
            final cat = controller.fullMenu[index];

            return Obx(() {
              final isSelected = controller.selectedMainCategory.value == cat;

              return GestureDetector(
                onTap: () => controller.selectMainCategory(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(right: 20, bottom: 5, top: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  decoration: BoxDecoration(
                    color: isSelected ? themeRed : neuBackground,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: themeRed.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ]
                        : [
                      BoxShadow(
                        color: neuShadowDark,
                        offset: const Offset(4, 4),
                        blurRadius: 8,
                      ),
                      BoxShadow(
                        color: neuShadowLight,
                        offset: const Offset(-4, -4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize
                        .min, // Keeps the row wrapped tightly around its content
                    children: [
                      Icon(
                        _getCategoryIcon(
                          cat.name,
                        ), // Calls the helper method below
                        color: isSelected
                            ? AppColors.onPrimary
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 8), // Spacing between icon and text
                      Text(
                        _isChineseUI ? cat.subName : cat.name,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.onPrimary
                              : AppColors.textSecondary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
          },
        );
      }),
    );
  }

  // Helper method to map category names to icons
  IconData _getCategoryIcon(String categoryName) {
    // Convert to lowercase to make matching easier
    final name = categoryName.toLowerCase();

    if (name.contains('chicken')) {
      return Icons.set_meal; // Or any suitable icon
    } else if (name.contains('pork')) {
      return Icons.savings; // Just an example, choose what fits best!
    } else if (name.contains('fish') || name.contains('seafood')) {
      return Icons.phishing;
    } else if (name.contains('vegetable') || name.contains('veg')) {
      return Icons.eco;
    } else if (name.contains('soup')) {
      return Icons.ramen_dining;
    } else if (name.contains('drink') || name.contains('beverage')) {
      return Icons.emoji_food_beverage;
    } else if (name.contains('rice') || name.contains('noodle')) {
      return Icons.rice_bowl;
    }

    // Default icon if no match is found
    return Icons.restaurant_menu;
  }

  Widget _buildSubCategories() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: neuBackground,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: neuShadowDark,
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: neuShadowLight,
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () {
                final args = Get.arguments;
                if (args != null && args['from'] == 'order_view') {
                  Get.offNamed(AppRoute.ORDER);
                } else {
                  controller.backToTables();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: neuBackground,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: neuShadowDark,
                      offset: const Offset(3, 3),
                      blurRadius: 6,
                    ),
                    BoxShadow(
                      color: neuShadowLight,
                      offset: const Offset(-3, -3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: AppColors.text),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final mainCat = controller.selectedMainCategory.value;
              if (mainCat == null || mainCat.categoryItems.isEmpty) {
                return const SizedBox();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: mainCat.categoryItems.length,
                itemBuilder: (context, index) {
                  final subCat = mainCat.categoryItems[index];

                  return Obx(() {
                    final isSelected =
                        controller.selectedSubCategory.value == subCat;

                    return GestureDetector(
                      onTap: () => controller.selectSubCategory(subCat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        height: 65,
                        decoration: BoxDecoration(
                          color: isSelected ? themeRed : neuBackground,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: themeRed.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                              : [
                            BoxShadow(
                              color: neuShadowDark,
                              offset: const Offset(3, 3),
                              blurRadius: 5,
                            ),
                            BoxShadow(
                              color: neuShadowLight,
                              offset: const Offset(-3, -3),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _isChineseUI ? subCat.subName : subCat.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.onPrimary
                                  : AppColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  });
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsGrid() {
    return Obx(() {
      final subCat = controller.selectedSubCategory.value;
      final searchVal = controller.selectedSearchCode.value;

      // 1. Get the base items
      List items = subCat?.menuItems ?? [];

      // 2. ENHANCED FILTER LOGIC: Normalize strings to ignore leading zeros (e.g., b05 == b5)
      if (searchVal.isNotEmpty) {
        // Removes leading zeros from numbers (e.g. "b05" -> "b5")
        final normalizedSearch = searchVal.toLowerCase().trim().replaceAll(
          RegExp(r'0+(?=\d)'),
          '',
        );

        items = items.where((item) {
          final normalizedFoodCode = item.foodCode.toLowerCase().replaceAll(
            RegExp(r'0+(?=\d)'),
            '',
          );
          return normalizedFoodCode.contains(normalizedSearch);
        }).toList();
      }

      if (subCat == null) {
        return const Center(child: Text("Please select a category"));
      }

      if (items.isEmpty) {
        // Dynamic empty message based on whether they are searching or not
        return Center(
          child: Text(
            searchVal.isNotEmpty
                ? "No matching food code found".tr
                : "No food code entered in this category".tr,
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.0,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            return GestureDetector(
              onTap: () {
                controller.addToCart(item);
                controller.selectedSearchCode.value = "";
                controller.searchTextController.clear();
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  // Keep the border highlight if it's a search result
                  border: searchVal.isNotEmpty
                      ? Border.all(color: AppColors.primary, width: 5)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // LAYER 1: BACKGROUND IMAGE
                      item.image != null && item.image!.isNotEmpty
                          ? Image.network(
                        "http://192.168.10.196/storage/${item.image!}",
                        fit: BoxFit.cover,
                        errorBuilder: (c, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.fastfood,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                          : Container(
                        color: AppColors.textSecondary,
                        child: const SizedBox(),
                      ),

                      // LAYER 2: GRADIENT OVERLAY
                      item.image != null && item.image!.isNotEmpty
                          ? Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.9),
                                Colors.black.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      )
                          : const SizedBox(),

                      // LAYER 3: TEXT INFO
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text(
                            item.foodCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isChineseUI ? item.subName : item.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildSearchBar() {
    return Container(
      width: 250,
      height: 50,
      decoration: BoxDecoration(
        color: neuBackground,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          // Simulated inner shadow / inset feel
          BoxShadow(
            color: neuShadowDark.withValues(alpha: 0.5),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: neuShadowLight,
            offset: const Offset(-2, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: TextField(
        controller: controller.searchTextController,
        style: const TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: "Search food code...".tr,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(Icons.search, color: themeRed),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (val) {
          controller.selectedSearchCode.value = val;
          if (val.isEmpty) return;

          // ENHANCED: Normalize input by removing leading zeros
          final normalizedSearch = val.toLowerCase().trim().replaceAll(
            RegExp(r'0+(?=\d)'),
            '',
          );

          for (var mainCat in controller.fullMenu) {
            for (var subCat in mainCat.categoryItems) {
              for (var item in subCat.menuItems) {
                // ENHANCED: Normalize target by removing leading zeros
                final normalizedFoodCode = item.foodCode
                    .toLowerCase()
                    .replaceAll(RegExp(r'0+(?=\d)'), '');

                if (normalizedFoodCode.contains(normalizedSearch)) {
                  controller.selectMainCategory(mainCat);
                  controller.selectSubCategory(subCat);
                  return; // Stop at first match to switch categories
                }
              }
            }
          }
        },
      ),
    );
  }

  Widget _buildCart() {
    return Column(
      children: [
        // Top Bar for Logout
        Padding(
          padding: const EdgeInsets.only(top: 10, right: 10),
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                Get.dialog(
                  AlertDialog(
                    backgroundColor: neuBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      "Confirm Logout".tr,
                      style: const TextStyle(color: AppColors.text),
                    ),
                    content: Text(
                      "Are you sure you want to log out?".tr,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text(
                          "Cancel".tr,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.back();
                          auth.logout();
                        },
                        child: Text(
                          "Logout".tr,
                          style: TextStyle(
                            color: themeRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: neuBackground,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: neuShadowDark,
                      offset: const Offset(3, 3),
                      blurRadius: 5,
                    ),
                    BoxShadow(
                      color: neuShadowLight,
                      offset: const Offset(-3, -3),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Logout".tr,
                      style: TextStyle(
                        color: themeRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.power_settings_new, color: themeRed, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
            decoration: BoxDecoration(
              color: neuBackground,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: neuShadowDark,
                  offset: const Offset(8, 8),
                  blurRadius: 5,
                ),
                BoxShadow(
                  color: neuShadowLight,
                  offset: const Offset(-8, -8),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Obx(() {
                    if (controller.currentView.value == PosViewState.table) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_shopping_cart,
                              size: 80,
                              color: AppColors.border,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Select a table to\nstart ordering".tr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        // Cart Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Dine In / Takeaway Toggle
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: neuBackground,
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: neuShadowDark.withValues(
                                          alpha: 0.5,
                                        ),
                                        offset: const Offset(2, 2),
                                        blurRadius: 4,
                                      ),
                                      BoxShadow(
                                        color: neuShadowLight,
                                        offset: const Offset(-2, -2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => controller.setOrderType(
                                            'dine_in',
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                              controller.orderType.value ==
                                                  'dine_in'
                                                  ? themeRed
                                                  : Colors.transparent,
                                              borderRadius:
                                              BorderRadius.circular(25),
                                            ),
                                            child: Center(
                                              child: Text(
                                                "Dine In".tr,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                  controller
                                                      .orderType
                                                      .value ==
                                                      'dine_in'
                                                      ? AppColors.onPrimary
                                                      : AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => controller.setOrderType(
                                            'take_away',
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                              controller.orderType.value ==
                                                  'take_away'
                                                  ? themeRed
                                                  : Colors.transparent,
                                              borderRadius:
                                              BorderRadius.circular(25),
                                            ),
                                            child: Center(
                                              child: Text(
                                                "Takeaway".tr,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                  controller
                                                      .orderType
                                                      .value ==
                                                      'take_away'
                                                      ? AppColors.onPrimary
                                                      : AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (controller.cart.isNotEmpty &&
                                  controller.cart.any(
                                        (item) => !item.menuItem.foodCode
                                        .toUpperCase()
                                        .startsWith('B'),
                                  ))
                                PopupMenuButton<String>(
                                  icon: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 15,
                                    ),
                                    decoration: BoxDecoration(
                                      color: neuBackground,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: neuShadowDark,
                                          offset: const Offset(2, 2),
                                          blurRadius: 4,
                                        ),
                                        BoxShadow(
                                          color: neuShadowLight,
                                          offset: const Offset(-2, -2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      "Set Food Size".tr,
                                      style: TextStyle(
                                        color: themeRed,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  onSelected: (val) =>
                                      controller.updateAllItemsToSize(val),
                                  itemBuilder: (context) =>
                                      ["Small".tr, "Medium".tr, "Large".tr]
                                          .map(
                                            (choice) => PopupMenuItem<String>(
                                          value: choice,
                                          child: Text(choice),
                                        ),
                                      )
                                          .toList(),
                                ),
                            ],
                          ),
                        ),

                        // Cart Items
                        Expanded(
                          child: controller.cart.isEmpty
                              ? Center(
                            child: Text(
                              "No items selected".tr,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                              : RawScrollbar(
                            controller: _cartScrollController,
                            thumbVisibility: true,
                            trackVisibility: true,
                            thumbColor: themeRed,
                            trackColor: themeRed.withValues(alpha: 0.1),
                            thickness: 6.0,
                            radius: const Radius.circular(10),
                            child: ListView.builder(
                              controller: _cartScrollController,
                              itemCount: controller.cart.length,
                              itemBuilder: (context, index) {
                                final cartItem = controller.cart[index];

                                // --- CHECK FOR EXTRAS (Options, Weight, or Remarks) ---
                                bool hasExtras = cartItem.selectedOptions.isNotEmpty ||
                                    cartItem.remarks.isNotEmpty ||
                                    (cartItem.weight != null && cartItem.weight! > 0);

                                return GestureDetector(
                                  onTap: () => controller
                                      .openEditCartItem(cartItem),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 8,
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: neuBackground,
                                      borderRadius: BorderRadius.circular(
                                        20,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: neuShadowDark,
                                          blurRadius: 6,
                                          offset: const Offset(4, 4),
                                        ),
                                        BoxShadow(
                                          color: neuShadowLight,
                                          blurRadius: 6,
                                          offset: const Offset(-4, -4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                                children: [
                                                  // Food Code Badge
                                                  Container(
                                                    padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    margin:
                                                    const EdgeInsets.only(
                                                      right: 8,
                                                      top: 1,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .blue
                                                          .shade50,
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                        8,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      cartItem
                                                          .menuItem
                                                          .foodCode,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                        FontWeight
                                                            .bold,
                                                        color: Colors
                                                            .blue
                                                            .shade700,
                                                      ),
                                                    ),
                                                  ),
                                                  // The Food Name
                                                  Expanded(
                                                    child: Text(
                                                      _isChineseUI
                                                          ? cartItem
                                                          .menuItem
                                                          .subName
                                                          : cartItem
                                                          .menuItem
                                                          .name,
                                                      style:
                                                      const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                        FontWeight
                                                            .bold,
                                                        color:
                                                        AppColors
                                                            .text,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              // Added spacing if options/remarks/weight exist so it breathes better
                                              if (hasExtras)
                                                const SizedBox(height: 6),

                                              if (cartItem
                                                  .selectedOptions
                                                  .isNotEmpty)
                                                Text(
                                                  cartItem.selectedOptions
                                                      .map(
                                                        (e) =>
                                                    _isChineseUI
                                                        ? e.subName
                                                        : e.name,
                                                  )
                                                      .join(', '),
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    color: AppColors
                                                        .textSecondary,
                                                  ),
                                                ),

                                              // --- NEW: DISPLAY WEIGHT ---
                                              if (cartItem.weight != null && cartItem.weight! > 0)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2.0),
                                                  child: Text(
                                                    "${_isChineseUI ? '重量' : 'Weight'}: ${cartItem.weight} Kg",
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: AppColors.textSecondary,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),

                                              if (cartItem
                                                  .remarks
                                                  .isNotEmpty)
                                                Padding(
                                                  padding:
                                                  const EdgeInsets.only(
                                                    top: 2.0,
                                                  ),
                                                  child: Text(
                                                    "${"Remarks".tr}: ${cartItem.remarks}",
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: themeRed
                                                          .withValues(
                                                        alpha: 0.8,
                                                      ),
                                                      fontStyle: FontStyle
                                                          .italic,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),

                                        // Quantity Controls
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                size: 30,
                                                Icons.remove_circle,
                                                color: AppColors
                                                    .textSecondary,
                                              ),
                                              onPressed: () => controller
                                                  .removeFromCart(
                                                cartItem,
                                              ),
                                            ),
                                            Text(
                                              "${cartItem.quantity}",
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight:
                                                FontWeight.bold,
                                                color: AppColors.text,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                size: 30,
                                                Icons.add_circle,
                                                color: themeRed,
                                              ),
                                              onPressed: () => controller
                                                  .addOneToCart(cartItem),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Footer (Total & Button)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: neuBackground,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total".tr,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Obx(
                                        () => Text(
                                      "${controller.totalQuantity} ${"items".tr}",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: themeRed,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: () {
                                  if (controller.totalQuantity == 0) {
                                    Get.snackbar(
                                      "Error".tr,
                                      "Cart is empty".tr,
                                    );
                                    return;
                                  }
                                  controller.sendOrder();
                                  final args = Get.arguments;
                                  if (args != null &&
                                      args['from'] == 'order_view') {
                                    Get.offNamed(AppRoute.ORDER);
                                  } else {
                                    controller.backToTables();
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: controller.totalQuantity == 0
                                        ? Colors.grey
                                        : themeRed,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: controller.totalQuantity == 0
                                            ? Colors.grey.withValues(alpha: 0.4)
                                            : themeRed.withValues(alpha: 0.4),
                                        offset: const Offset(0, 6),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 25,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Place Order".tr,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.onPrimary,
                                          letterSpacing: 1.2,
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
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}