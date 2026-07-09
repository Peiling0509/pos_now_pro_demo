import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/widgets/loading_dialog.dart';
import '../../data/models/loader_state_model.dart';
import '../../data/repositories/login_repository.dart';
import '../../services/sync_services.dart';
import '../../services/user_preference_service.dart';
import 'auth_controller.dart';

class LoginController extends GetxController {
  final UserPreferenceService prefs = UserPreferenceService.instance;
  final LoginRepository repository = LoginRepository();
  final auth = Get.find<AuthController>();
  final syncService = Get.find<SyncService>();

  final Rx<LoaderState> state = LoaderState.initial.obs;

  // For the username text field
  late TextEditingController usernameController;
  var selectedRole = ''.obs; // holds either "Counter" or "Waiter"


  // For the 6-digit PIN
  final RxString _pin = ''.obs;
  String get pin => _pin.value;

  @override
  void onInit() {
    super.onInit();
    usernameController = TextEditingController();

    // Auto-login when PIN reaches 6 digits
    _pin.listen((value) {
      if (value.length == 6) {
        submitLogin();
      }
    });

    state.listen((v) {
      switch (v) {
        case LoaderState.initial:
        case LoaderState.loading:
          LoadingDialog.show();
          break;
        case LoaderState.loaded:
        case LoaderState.failure:
          LoadingDialog.hide();
          break;
      }
    });
  }

  // Called when a keypad button is pressed
  void onKeypadTapped(String value) {
    if (_pin.value.length < 6) {
      _pin.value += value;
    }
  }

  // Called for the backspace button
  void onBackspaceTapped() {
    if (_pin.value.isNotEmpty) {
      _pin.value = _pin.value.substring(0, _pin.value.length - 1);
    }
  }

  // Called to submit
  void submitLogin() async {
    if (usernameController.text.isEmpty || _pin.value.length != 6) {
      Get.snackbar(
        "Error",
        "Please enter a username and a 6-digit PIN.",
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    state.value = LoaderState.loading;
    final data = await repository.login(usernameController.text, _pin.value);
    if (data.status == false) {
      state.value = LoaderState.loaded;
      Get.snackbar(
        "Login Failed",
        data.message ?? "Unknown error occurred.",
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    state.value = LoaderState.loaded;
    await prefs.saveUserName(usernameController.text);
    await auth.login(data);
    await syncService.syncAll();
    Get.offAllNamed("/");
    // Get.snackbar(
    //   "Login Successful",
    //   data.message,
    //   snackPosition: SnackPosition.TOP,
    // );

    // Fake delay for demo
    await Future.delayed(const Duration(seconds: 1));

    // For demo, just log it and clear
    debugPrint("Login attempt: ${usernameController.text} / ${_pin.value}");
    _pin.value = ''; // Clear pin after attempt
  }
}
