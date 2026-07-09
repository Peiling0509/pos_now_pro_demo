import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:pos_now_pro/app/core/constants/url.dart';
import 'package:pos_now_pro/app/data/providers/api_provider.dart';

import '../models/order_model.dart';
import '../models/payment_model.dart';

class OrderRepository {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  Future<List<OrderModel>> getOrder(String status) async {
    try {
      Response response = await _apiProvider.get(
        "${UrlStorage.order}?status=$status",
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final orders = (response.data['data'] as List)
            .map((e) => OrderModel.fromJson(e))
            .toList();
        return orders;
      } else {
        throw Exception("Failed to load orders");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendOrder(dynamic data) async {
    try {
      await _apiProvider.post(UrlStorage.order, data: data);
    } catch (e) {
      Get.log("❌ Error sending order: $e");
      rethrow;
    }
  }

  Future<void> payments(dynamic data) async {
    try {
      await _apiProvider.post(UrlStorage.payments, data: data);
    } catch (e) {
      Get.log("❌ Error sending payments: $e");
      rethrow;
    }
  }

  Future<void> updateOrderItem(int orderId, Map<String, dynamic> data) async {
    try {
      // Append ID to the base URL: /api/orders/15
      final url = "${UrlStorage.order}/$orderId";

      Response response = await _apiProvider.put(url, data: data);

      if (response.statusCode == 200 && response.data['success'] == true) {
        return;
      } else {
        throw Exception(response.data['message'] ?? "Failed to update order");
      }
    } catch (e) {
      Get.log("❌ Error updating order: $e");
      rethrow;
    }
  }

  Future<void> updateOrderStatus(Map<String, dynamic> data) async {
    try {
      Response response = await _apiProvider.post(
        UrlStorage.update_order_status,
        data: data,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return;
      } else {
        throw Exception(
          response.data['message'] ?? "Failed to update order status",
        );
      }
    } catch (e) {
      Get.log("❌ Error update order status: $e");
      rethrow;
    }
  }

  Future<void> deleteOrderItem(Map<String, dynamic> data) async {
    try {
      Response response = await _apiProvider.post(
        UrlStorage.delete_order_item,
        data: data,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return;
      } else {
        throw Exception(
          response.data['message'] ?? "Failed to delete order item",
        );
      }
    } catch (e) {
      Get.log("❌ Error deleting order item: $e");
      rethrow;
    }
  }

  Future<void> clearTable(Map<String, dynamic> data) async {
    try {
      Response response = await _apiProvider.post(
        UrlStorage.clear_table,
        data: data,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return;
      } else {
        throw Exception(
          response.data['message'] ?? "Failed to delete order item",
        );
      }
    } catch (e) {
      Get.log("❌ Error deleting order item: $e");
      rethrow;
    }
  }

  Future<PaymentModel> getPayment(Map<String, dynamic> data) async {
    try {
      Response response = await _apiProvider.post(
        UrlStorage.get_payment,
        data: data,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final payment = PaymentModel.fromJson(response.data['data']);
        return payment;
      } else {
        throw Exception(
          response.data['message'] ?? "Failed to delete order item",
        );
      }
    } catch (e) {
      Get.log("❌ Error get payment: $e");
      rethrow;
    }
  }

  Future<String?> getMagicLink() async {
    try {
      // Use the AUTHENTICATED provider because Laravel requires auth:sanctum
      final response = await _apiProvider.get(UrlStorage.getMagicLink);

      // Parse the Laravel JSON response: {'success': true, 'magic_url': 'https...'}
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['magic_url'];
      }
      return null;
    } on DioException catch (e) {
      print("Dio Error fetching magic link: ${e.message}");
      return null;
    } catch (e) {
      print("Unexpected error fetching magic link: $e");
      return null;
    }
  }
}
