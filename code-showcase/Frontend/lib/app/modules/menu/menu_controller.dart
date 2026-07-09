import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:pos_now_pro/app/data/repositories/menu_repository.dart';
import 'package:pos_now_pro/app/data/repositories/order_repository.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/main_menu_model.dart';
import '../../data/models/table_model.dart';
import '../../services/local_storage_service.dart';
import '../order/order_controller.dart';
import 'option_product_dialog.dart';

// Define view states for clarity
enum PosViewState { table, menu }

class MenuController extends GetxController {
  final LocalStorageService _localDb = Get.find<LocalStorageService>();

  // --- VIEW SWITCHING STATE ---
  var currentView = PosViewState.table.obs; // Default to Table View

  // --- DATA STATE ---
  var tables = <TableModel>[].obs;
  var cart = <CartItemModel>[].obs;
  var fullMenu = <MainMenuModel>[].obs;
  var selectedSearchCode = "".obs;
  var orderType = 'dine_in'.obs;
  var isLoading = true.obs;

  // --- SELECTION STATE ---
  var selectedTable = Rxn<TableModel>();
  var selectedMainCategory = Rxn<MainMenuModel>();
  var selectedSubCategory = Rxn<CategoryItemModel>();

  // --- REPOSITORY --
  final orderRes = OrderRepository();
  final menuRes = MenuRepository();

  // --- TEXT BOX --
  final searchTextController = TextEditingController();

  @override
  void onInit() async {
    super.onInit();

    await loadTables();
    await loadMenu();
  }

  // ==============================
  // NAVIGATION ACTIONS
  // ==============================

  void openTable(TableModel table) {
    selectedTable.value = table;
    // Optional: Clear cart when opening a new table?
    // cart.clear();
    currentView.value = PosViewState.menu;
  }

  void backToTables() {
    currentView.value = PosViewState.table;
    loadTables();
    // selectedTable.value = null; // Optional: keep selected or clear
  }

  // ==============================
  // DATA LOADING
  // ==============================
  Future<void> loadTables() async {
    try {
      tables.clear();
      final data = await menuRes.getTables();
      Get.log("Table reload !");
      tables.assignAll(data);
    } catch (e) {
      Get.log("Error loading local tables: $e");
    }
  }

  Future<void> loadMenu() async {
    isLoading.value = true;
    try {
      final data = await _localDb.getFullMenu();
      fullMenu.assignAll(data);

      // Set default selections for the menu UI
      if (fullMenu.isNotEmpty) {
        selectedMainCategory.value = fullMenu.first;
        if (fullMenu.first.categoryItems.isNotEmpty) {
          selectedSubCategory.value = fullMenu.first.categoryItems.first;
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  // ==============================
  // CATEGORY LOGIC
  // ==============================
  void selectMainCategory(MainMenuModel category) {
    selectedMainCategory.value = category;
    if (category.categoryItems.isNotEmpty) {
      selectedSubCategory.value = category.categoryItems.first;
    } else {
      selectedSubCategory.value = null;
    }
  }

  void selectSubCategory(CategoryItemModel subCategory) {
    selectedSubCategory.value = subCategory;
  }

  // ==============================
  // CART LOGIC
  // ==============================
  void addToCart(MenuItemModel item) {
    // Check BOTH options AND open price before deciding to skip the dialog
    if (item.options.isEmpty && item.isOpenPrice == false) {
      confirmAddToCart(item, 1, [], "", null, null);
    } else {
      Get.dialog(OptionProductDialog(item: item)); // Needs options OR a manual price/weight
    }
  }

  void openEditCartItem(CartItemModel cartItem) {
    Get.dialog(
      OptionProductDialog(
        item: cartItem.menuItem,
        existingCartItem: cartItem,
      ),
      barrierDismissible: true,
    );
  }

  void updateCartItem(
      CartItemModel oldItem,
      int newQty,
      List<OptionModel> newOpts,
      String newRemarks,
      double? newCustomOpenPrice,
      double? newWeight,
      )
  {
    //Remove the old item completely
    int index = cart.indexOf(oldItem);
    if (index != -1) {
      cart.removeAt(index);
    }

    confirmAddToCart(oldItem.menuItem, newQty, newOpts, newRemarks, newCustomOpenPrice, newWeight);
  }

  void setOrderType(String type) {
    orderType.value = type;
  }

  /// Bulk updates all items in the cart to a specific size string (e.g. "Small", "Large")
  void updateAllItemsToSize(String sizeName) {
    // 1. CONFIG: Define which Option Type ID represents "Size" in your DB
    const int sizeTypeId = 1;

    // 2. Create a temporary holder for the new cart state
    List<CartItemModel> itemsToReprocess = [];

    for (var cartItem in cart) {
      final targetOption = cartItem.menuItem.options.firstWhereOrNull(
            (opt) => opt.optionTypeId == sizeTypeId && opt.name.tr == sizeName,
      );

      if (targetOption != null) {
        List<OptionModel> newOptions = cartItem.selectedOptions
            .where((opt) => opt.optionTypeId != sizeTypeId)
            .toList();

        newOptions.add(targetOption);

        itemsToReprocess.add(CartItemModel(
          menuItem: cartItem.menuItem,
          quantity: cartItem.quantity,
          selectedOptions: newOptions,
          remarks: cartItem.remarks,
          customOpenPrice: cartItem.customOpenPrice,
          weight: cartItem.weight,
        ));
      } else {
        itemsToReprocess.add(cartItem);
      }
    }

    cart.clear();

    for (var item in itemsToReprocess) {
      confirmAddToCart(
        item.menuItem,
        item.quantity,
        item.selectedOptions,
        item.remarks,
        item.customOpenPrice,
        item.weight,
      );
    }
  }

  void confirmAddToCart(
      MenuItemModel item,
      int qty,
      List<OptionModel> options,
      String remarks,
      double? customOpenPrice,
      double? weight,
      )
  {
    final newItem = CartItemModel(
      menuItem: item,
      quantity: qty,
      selectedOptions: options,
      remarks: remarks,
      customOpenPrice: customOpenPrice,
      weight: weight,
    );

    // Check if exactly this combo (including the price & weight) exists in cart
    final existingIndex = cart.indexWhere(
          (c) => c.uniqueId == newItem.uniqueId,
    );

    if (existingIndex != -1) {
      // Update quantity
      var existingItem = cart[existingIndex];
      existingItem.quantity += qty;
      cart[existingIndex] = existingItem; // Trigger update
      cart.refresh();
    } else {
      cart.add(newItem);
    }
  }

  void removeFromCart(CartItemModel cartItem) {
    final index = cart.indexOf(cartItem);
    if (index == -1) return;

    if (cart[index].quantity > 1) {
      cart[index].quantity--;
      cart.refresh();
    } else {
      cart.removeAt(index);
    }
  }

  void addOneToCart(CartItemModel cartItem) {
    final index = cart.indexOf(cartItem);
    if (index != -1) {
      cart[index].quantity++;
      cart.refresh();
    }
  }

  // ==============================
  // ORDER LOGIC
  // ==============================

  Future<void> sendOrder() async {
    if (selectedTable.value == null) {
      Get.snackbar("Error".tr, "No table selected".tr);
      return;
    }

    if (cart.isEmpty) {
      Get.snackbar("Error".tr, "Cart is empty".tr);
      return;
    }

    isLoading.value = true;
    try {
      final orderData = {
        "table_id": selectedTable.value?.id,
        "pad_time": DateTime.now().toIso8601String(),
        "order_type": orderType.value,
        "items": cart.map((item) {

          // PREPARE THE DATA TO SEND TO LARAVEL
          var itemData = {
            "menu_item_id": item.menuItem.id,
            "quantity": item.quantity,
            "menu_item_option": item.selectedOptions.map((opt) => opt.id).where((id) => id != -1).toList(),
            "remark": item.remarks,
          };

          // Only send the custom price if it exists
          if (item.customOpenPrice != null) {
            itemData["custom_price"] = item.customOpenPrice!;
          }

          if (item.weight != null) {
            itemData["weight"] = item.weight!;
          }

          return itemData;
        }).toList()
      };

      Get.log(jsonEncode(orderData));
      await orderRes.sendOrder(orderData);
      Get.snackbar("Success".tr, "Order sent to counter successfully".tr);
      cart.clear();

      // Force the Order Screen to refresh its data behind the scenes!
      if (Get.isRegistered<OrderController>()) {
        Get.find<OrderController>().load();
      }

    } catch (e) {
      Get.log("Order Error: $e");
      Get.snackbar("Error".tr, "Failed to send order: $e");
    } finally {
      isLoading.value = false;
    }
  }

  double get totalAmount {
    return cart.fold(0, (sum, item) => sum + item.totalItemPrice);
  }

  int get totalQuantity {
    return cart.fold(0, (sum, item) => sum + item.quantity);
  }

  // ==============================
  // NEW HELPER METHODS FOR NAVIGATION
  // ==============================

  void resetToTableSelection() {
    selectedTable.value = null;
    cart.clear();
    loadTables();
    currentView.value = PosViewState.table;
  }

  void resumeOrderForTable(int tableId, {String? targetCategoryName}) {
    final table = tables.firstWhereOrNull((t) => t.id == tableId);

    if (table != null) {
      selectedTable.value = table;
      cart.clear();

      //Pre-select the target category if requested
      if (targetCategoryName != null && fullMenu.isNotEmpty) {
        // Look for the category (case-insensitive just to be safe)
        final targetCategory = fullMenu.firstWhereOrNull(
                (cat) => cat.name.toLowerCase() == targetCategoryName.toLowerCase()
        );

        if (targetCategory != null) {
          selectMainCategory(targetCategory);
        } else {
          // Fallback: If category wasn't found, select the first one
          selectMainCategory(fullMenu.first);
        }
      } else if (fullMenu.isNotEmpty) {
        // Default behavior if no target was passed
        selectMainCategory(fullMenu.first);
      }

      currentView.value = PosViewState.menu;
    } else {
      resetToTableSelection();
    }
  }
}