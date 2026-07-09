
import 'package:get/get.dart';

import '../menu/menu_controller.dart';
import 'order_controller.dart';

class OrderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderController>(
          () => OrderController(),
    );
  }
}