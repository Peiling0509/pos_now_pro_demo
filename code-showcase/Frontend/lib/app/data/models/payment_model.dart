import 'package:pos_now_pro/app/data/models/payment_method_enum.dart';

class PaymentModel {
  final int id;
  final int orderId;
  final PaymentMethod method;
  final double amount;
  final double tenderedAmount;
  final double changeAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.method,
    required this.amount,
    required this.tenderedAmount,
    required this.changeAmount,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor to create a PaymentModel from your Laravel API JSON response
  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      method: PaymentMethod.fromString(json['method']?.toString() ?? ''),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      tenderedAmount: double.tryParse(json['tendered_amount']?.toString() ?? '0') ?? 0.0,
      changeAmount: double.tryParse(json['change_amount']?.toString() ?? '0') ?? 0.0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  /// Method to convert a PaymentModel instance back into a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'method': method.jsonValue,
      'amount': amount,
      'tendered_amount': tenderedAmount,
      'change_amount': changeAmount,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Creates a copy of this model with the given fields replaced with new values
  PaymentModel copyWith({
    int? id,
    int? orderId,
    PaymentMethod? method,
    double? amount,
    double? tenderedAmount,
    double? changeAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      method: method ?? this.method,
      amount: amount ?? this.amount,
      tenderedAmount: tenderedAmount ?? this.tenderedAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}