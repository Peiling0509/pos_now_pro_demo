import 'main_menu_model.dart';

class CartItemModel {
  final String uniqueId;
  final MenuItemModel menuItem;
  int quantity;
  double? weight;
  List<OptionModel> selectedOptions;
  String remarks;
  double? customOpenPrice; //To store the manually entered price

  CartItemModel({
    required this.menuItem,
    this.quantity = 1,
    this.weight,
    this.selectedOptions = const [],
    this.remarks = '',
    this.customOpenPrice,
  }) : uniqueId = _generateId(menuItem.id, selectedOptions, remarks, customOpenPrice, weight); // 🌟 ADDED WEIGHT HERE

  double get totalItemPrice {
    // 1. Calculate the total extra price from selected options (e.g., Hot/Cold, Add-ons)
    double optionsPrice = selectedOptions.fold(0, (sum, opt) => sum + opt.extraPrice);

    // 2. Determine the base price (Use Open Price if entered, otherwise fallback to standard price)
    double basePrice = customOpenPrice ?? menuItem.price;

    // 3. Return the final math
    return (basePrice + optionsPrice) * quantity;
  }

  // Generate a unique key based on ID + Options + Remarks + Open Price + Weight
  static String _generateId(int itemId, List<OptionModel> options, String remarks, double? customOpenPrice, double? weight) {
    options.sort((a, b) => a.id.compareTo(b.id)); // Ensure consistent order
    String optIds = options.map((e) => e.id).join('-');

    // Ensure different open prices don't merge together in the cart!
    String priceKey = customOpenPrice != null ? customOpenPrice.toStringAsFixed(2) : 'standard';

    // Ensure different weights don't merge together in the cart!
    String weightKey = weight != null ? weight.toStringAsFixed(3) : 'noweight';

    return "$itemId|$optIds|$remarks|$priceKey|$weightKey";
  }
}