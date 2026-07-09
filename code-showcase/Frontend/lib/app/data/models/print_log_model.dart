import 'order_model.dart';

enum PrintStatus { success, failed }

enum PrinterType { counter, kitchen, drink }

class PrintLogModel {
  final String id;
  final int orderId;
  final PrinterType printerType;
  final String printerIp;
  final DateTime timestamp;
  final PrintStatus status;
  final OrderModel? order;
  final String? errorMessage;

  PrintLogModel({
    required this.id,
    required this.orderId,
    required this.printerType,
    required this.printerIp,
    required this.timestamp,
    required this.status,
    this.order,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'printerType': printerType.toString(),
      'status': status.toString(),
      'printerIp': printerIp,
      'timestamp': timestamp.toIso8601String(),
      'errorMessage': errorMessage,
      'order': order?.toJson(),
    };
  }

  factory PrintLogModel.fromJson(Map<String, dynamic> json) {
    return PrintLogModel(
      id: json['id'],
      orderId: json['orderId'],
      printerType: PrinterType.values.firstWhere(
        (e) => e.toString() == json['printerType'],
      ),
      status: PrintStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      printerIp: json['printerIp'],
      timestamp: DateTime.parse(json['timestamp']),
      errorMessage: json['errorMessage'],
      order: json['order'] != null ? OrderModel.fromJson(json['order']) : null,
    );
  }
}
