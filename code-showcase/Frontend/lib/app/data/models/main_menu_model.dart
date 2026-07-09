import 'dart:convert';

List<MainMenuModel> categoryModelFromJson(String str) =>
    List<MainMenuModel>.from(
      json.decode(str).map((x) => MainMenuModel.fromJson(x)),
    );

class MainMenuModel {
  final int id;
  final String name;
  final String subName;
  final List<CategoryItemModel> categoryItems;

  MainMenuModel({
    required this.id,
    required this.name,
    required this.subName,
    this.categoryItems = const [],
  });

  factory MainMenuModel.fromJson(Map<String, dynamic> json) {
    return MainMenuModel(
      id: json['id'],
      name: json['name'],
      subName: json['sub_name'],
      categoryItems: json['category_items'] == null
          ? []
          : List<CategoryItemModel>.from(
              json['category_items'].map((x) => CategoryItemModel.fromJson(x)),
            ),
    );
  }
}

class CategoryItemModel {
  final int id;
  final int categoryId;
  final String name;
  final String subName;
  final List<MenuItemModel> menuItems;

  CategoryItemModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.subName,
    this.menuItems = const [],
  });

  factory CategoryItemModel.fromJson(Map<String, dynamic> json) {
    return CategoryItemModel(
      id: json['id'],
      categoryId: int.tryParse(json['category_id'].toString()) ?? 0,
      name: json['name'],
      subName: json['sub_name'],
      menuItems: json['menu_items'] == null
          ? []
          : List<MenuItemModel>.from(
              json['menu_items'].map((x) => MenuItemModel.fromJson(x)),
            ),
    );
  }
}

class MenuItemModel {
  final int id;
  final int categoryItemId;
  final String foodCode;
  final String name;
  final String subName;
  final double price;
  final bool isOpenPrice;
  final String? image;
  final bool isAvailable;
  final String? remarks;
  final List<OptionModel> options;

  MenuItemModel({
    required this.id,
    required this.categoryItemId,
    required this.foodCode,
    required this.name,
    required this.subName,
    required this.price,
    required this.isOpenPrice,
    this.image,
    required this.isAvailable,
    this.remarks,
    this.options = const [],
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'],
      categoryItemId: int.tryParse(json['category_item_id'].toString()) ?? 0,
      foodCode: json['food_code'],
      name: json['name'],
      subName: json['sub_name'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      isOpenPrice: json['is_open_price'] == 1 || json['is_open_price'] == true,
      image: json['image'],
      isAvailable: json['is_available'] == 1 || json['is_available'] == true,
      remarks: json['remarks'],
      options: json['options'] == null
          ? []
          : List<OptionModel>.from(
              json['options'].map((x) => OptionModel.fromJson(x)),
            ),
    );
  }
}

class OptionModel {
  final int id;
  final int optionTypeId;
  final String name;
  final String subName;
  final double extraPrice;

  OptionModel({
    required this.id,
    required this.optionTypeId,
    required this.name,
    required this.subName,
    this.extraPrice = 0.0,
  });

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    double pivotPrice = 0.0;
    if (json['pivot'] != null && json['pivot']['extra_price'] != null) {
      pivotPrice = double.tryParse(json['pivot']['extra_price'].toString()) ?? 0.0;
    }

    return OptionModel(
      id: json['id'],
      optionTypeId: int.tryParse(json['option_type_id'].toString()) ?? 0,
      name: json['name'],
      subName: json['sub_name'],
      extraPrice: pivotPrice,
    );
  }

  // 🌟 NEW: Convert object back to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'option_type_id': optionTypeId,
      'name': name,
      'sub_name': subName,
      // Wrap extraPrice back into a pivot object so fromJson can read it later!
      'pivot': {
        'extra_price': extraPrice,
      },
    };
  }
}
