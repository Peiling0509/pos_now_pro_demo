import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:pos_now_pro/app/modules/login/auth_controller.dart';
import 'app_route.dart';

class RoleRouteMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();

    if (!auth.isLogin()) {
      return const RouteSettings(name: AppRoute.LOGIN);
    }

    final role = auth.getUserRole();
    if (role == 'staff') return const RouteSettings(name: AppRoute.MENU);
    if (role == 'admin') return const RouteSettings(name: AppRoute.ORDER);

    return const RouteSettings(name: AppRoute.LOGIN);
  }
}

