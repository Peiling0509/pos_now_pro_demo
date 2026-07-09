import 'package:flutter/material.dart' hide MenuController;
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pos_now_pro/app/core/theme/app_color.dart';
import 'package:pos_now_pro/app/lang/translations.dart';
import 'package:pos_now_pro/app/services/print_log_service.dart';
 
import 'AppLifecycleController.dart';
import 'app/data/providers/api_provider.dart';
import 'app/data/providers/no_auth_provider.dart';
import 'app/modules/login/auth_controller.dart';
import 'app/routes/app_page.dart';
import 'app/services/local_storage_service.dart';
import 'app/services/polling_services.dart';
import 'app/services/printer_service.dart';
import 'app/services/sync_services.dart';
import 'app/services/user_preference_service.dart';
import 'app/services/web_socket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await GetStorage.init("Auth");

  // Initialize DB Service before running app
  await Get.putAsync(() => LocalStorageService().init());

  // Lock the orientation
  SystemChrome.setPreferredOrientations([
    //DeviceOrientation.portraitUp,
    // DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    // DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const MainApp());
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get saved language code from storage
    final savedLang = UserPreferenceService.instance.getAppLanguage();
    final initialLocale = _localeFromCode(savedLang);

    return GetMaterialApp(
      title: 'POS Now',
      onInit: onInit,
      onReady: onReady,
      onDispose: onDispose,
      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: const Locale('en', 'US'),
      initialRoute: "/",
      getPages: AppPage.routes,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.onPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary, // CircularProgressIndicator
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
        ),
      ),
    );
  }

  /// Map language code to Locale
  Locale _localeFromCode(String code) {
    switch (code) {
      case 'zh':
        return const Locale('zh', 'CN');
      case 'ms':
        return const Locale('ms', 'MY');
      default:
        return const Locale('en', 'US');
    }
  }

  void onInit() {
    Get.put(NoAuthProvider());
    Get.put(AuthController());
    Get.put(ApiProvider());
    Get.put(LocalStorageService(), permanent: true);
    Get.put(SyncService());
    Get.put(WebSocketService(), permanent: true);
    Get.put(PollingService(), permanent: true);
    Get.put(PrintLogService(), permanent: true).init();
    Get.put(PrinterService(), permanent: true).init();
    Get.put(AppLifecycleController());

  }

  void onReady() {
    if(Get.find<AuthController>().getUserRole() == "admin"){
      // Trigger time sync immediately on fresh app launch from Admin pad
      //Get.find<SyncService>().syncServerTime();
    }
  }

  void onDispose() {
    Get.delete<NoAuthProvider>();
    Get.delete<ApiProvider>();
    Get.delete<AuthController>();
    Get.delete<LocalStorageService>();
    Get.delete<SyncService>();
    Get.delete<WebSocketService>();
    Get.delete<PollingService>();
    Get.delete<PrinterService>();
  }
}
