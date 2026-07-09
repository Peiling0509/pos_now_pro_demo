class OrderModel {
  final int id;
  final int? tableId;
  final String orderType; // dine_in or take_away
  final String staffName;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final List<OrderItem> orderItems;

  OrderModel({
    required this.id,
    this.tableId,
    required this.orderType,
    required this.staffName,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.orderItems,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var itemsList = <OrderItem>[];
    if (json['order_items'] != null) {
      itemsList = List<OrderItem>.from(
        json['order_items'].map((x) => OrderItem.fromJson(x)),
      );
    }

    return OrderModel(
      id: json['id'],
      tableId: json['table_id'],
      orderType: json['order_type'] ?? 'dine_in',
      staffName: json['staff_name'] ?? 'Unknown',
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      orderItems: itemsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_id': tableId,
      'order_type': orderType,
      'total': totalPrice,
      'status': status,
      'created_at': createdAt,
      'order_items': orderItems.map((x) => x.toJson()).toList(),
    };
  }
}

class OrderItem {
  final int id;
  final int orderId;
  final int menuItemId;
  final String foodCode;
  final String menuItemName;
  final String menuItemSubName;
  final String categoryName; // e.g., "Food", "Beverage"
  final int quantity;
  final double? weight;
  final String? remark;
  final double price;
  final double total; // Line Total (Price + Options) * Qty
  final DateTime createdAt;
  final List<Option> options;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.foodCode,
    required this.menuItemName,
    required this.menuItemSubName,
    required this.categoryName,
    required this.quantity,
    this.weight,
    this.remark,
    required this.price,
    required this.total,
    required this.createdAt,
    required this.options,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    var optionsList = <Option>[];
    if (json['options'] != null) {
      optionsList = List<Option>.from(
        json['options'].map((x) => Option.fromJson(x)),
      );
    }

    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      menuItemId: json['menu_item_id'],
      foodCode: json['food_code'] ?? 'Unknow Item',
      menuItemName: json['menu_item_name'] ?? 'Unknown Item',
      menuItemSubName: json['menu_item_sub_name'] ?? 'Unknown Item',
      categoryName: json['category_name'] ?? 'Uncategorized',
      quantity: json['quantity'],
      weight: json['weight'] != null ? double.tryParse(json['weight'].toString()) : null,
      remark: json['remark'],
      price: (json['price'] as num).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      options: optionsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'food_code': foodCode,
      'menu_item_id': menuItemId,
      'menu_item_name': menuItemName,
      'menu_item_sub_name': menuItemSubName,
      'category_name': categoryName,
      'quantity': quantity,
      'weight': weight,
      'remark': remark,
      'price': price,
      'total': total,
      'created_at': createdAt.toIso8601String(),
      'options': options.map((x) => x.toJson()).toList(),
    };
  }
}

class Option {
  final int id;
  final String name;
  final String subName;
  final int optionTypeID;
  final double additionalPrice;

  Option({
    required this.id,
    required this.name,
    required this.subName,
    required this.optionTypeID,
    required this.additionalPrice,
  });

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      subName: json['sub_name'] ?? '',
      optionTypeID: json['option_type_id'] ?? 0,
      additionalPrice: double.tryParse(json['additional_price']?.toString() ?? '0') ?? 0.0,
    );
  }

  // 2. Pivot Factory
  factory Option.fromPivotJson(Map<String, dynamic> json) {
    final optionDetail = json['option'] ?? {};

    return Option(
      id: optionDetail['id'] ?? 0,
      name: optionDetail['name'] ?? '',
      subName: optionDetail['sub_name'] ?? '',
      optionTypeID: optionDetail['option_type_id'] ?? 0,
      additionalPrice: double.tryParse(json['additional_price']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sub_name': subName,
      'option_type_id': optionTypeID,
      'additional_price': additionalPrice,
    };
  }
}