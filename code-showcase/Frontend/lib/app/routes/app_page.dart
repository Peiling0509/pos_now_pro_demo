import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:pos_now_pro/app/modules/menu/menu_binding.dart';
import 'package:pos_now_pro/app/modules/order/order_binding.dart';
import 'package:pos_now_pro/app/modules/payment/payment_binding.dart';
import 'package:pos_now_pro/app/modules/payment/payment_view.dart';
import 'package:pos_now_pro/app/modules/setting/setting_binding.dart';
import 'package:pos_now_pro/app/modules/setting/setting_view.dart';
import 'package:pos_now_pro/app/routes/role_route_middleware.dart';

import '../modules/login/login_binding.dart';
import '../modules/login/login_view.dart';
import '../modules/menu/menu_view.dart';
import '../modules/order/order_view.dart';
import '../modules/order/print_history_view.dart';
import 'app_route.dart';

class AppPage {
  static final routes = [
    GetPage(
      name: "/",
      page: () => const SizedBox.shrink(),
      middlewares: [RoleRouteMiddleware()],
    ),

    GetPage(
      name: AppRoute.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),

    // Admin-only pages
    GetPage(
      name: AppRoute.ORDER,
      page: () => OrderView(),
      binding: OrderBinding(),
    ),
    GetPage(
      name: AppRoute.PRINT_HISTORY,
      page: () => const PrintHistoryView(),
    ),
    GetPage(
      name: AppRoute.PAYMENT,
      page: () => PaymentView(),
      binding: PaymentBinding()
    ),

    // Shared pages (staff + admin)
    GetPage(
      name: AppRoute.MENU,
      page: () => MenuView(),
      binding: MenuBinding(),
    ),
    GetPage(
      name: AppRoute.SETTING,
      page: () => SettingView(),
      binding: SettingBinding(),
    ),
  ];
}
