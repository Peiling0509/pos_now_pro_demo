import 'package:get/get.dart';
import 'package:pos_now_pro/app/modules/setting/setting_controller.dart';

class SettingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingController>(
          () => SettingController(),
    );
  }
}