import 'package:get/get.dart';

import 'login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(
          () => LoginController(),
    );

    // Note: Ensure your AuthService is already put, e.g., in main.dart
    // Get.lazyPut<AuthService>(() => AuthService());
  }
}