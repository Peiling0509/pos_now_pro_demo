
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pos_now_pro/app/routes/app_route.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/models/auth_model.dart';
import '../../services/user_preference_service.dart';
import '../../services/web_socket_service.dart';

class AuthController extends GetxController {
  final box = GetStorage("Auth");

  @override
  void onInit() {
    super.onInit();
    // If the app starts and the user is already logged in,
    // immediately enable the wakelock and init WebSockets.
    if (isLogin()) {
      WakelockPlus.enable();
      if (Get.isRegistered<WebSocketService>()) {
        Get.find<WebSocketService>().init();
      }
    }
  }

  bool isLogin() => _readToken() != null;

  String? accessName() => box.read("name");

  String? accessToken() => _readToken();

  //admin, staff
  String? getUserRole() => box.read("user_role");

  String? _readToken() {
    return box.read("access_token");
  }

  Future<void> login(AuthModel data) async {

    Get.log(data.data!.user.name);
    Get.log(data.data!.token);
    Get.log(data.data!.user.role);

    await box.write("name", data.data?.user.name);
    await box.write("access_token", data.data?.token);
    await box.write("user_role", data.data?.user.role);
    await box.save();

    //KEEP THE SCREEN AWAKE FOREVER
    WakelockPlus.enable();
    if (Get.isRegistered<WebSocketService>()) {
      Get.find<WebSocketService>().init();
    }
  }

  Future<void> logout() async {
    //LET THE SCREEN SLEEP AGAIN
    WakelockPlus.disable();
    if (Get.isRegistered<WebSocketService>()) {
      Get.find<WebSocketService>().disconnect();
    }
    await box.erase();
    await box.save();
    Get.offAllNamed(AppRoute.LOGIN);
  }
}
