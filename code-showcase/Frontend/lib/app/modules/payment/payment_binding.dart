import 'package:get/get.dart';
import 'package:pos_now_pro/app/modules/payment/payment_controller.dart';

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PaymentController>(
          () => PaymentController(),
    );
  }
}