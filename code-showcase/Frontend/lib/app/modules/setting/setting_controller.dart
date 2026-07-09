import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos_now_pro/app/core/theme/app_color.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import 'package:pos_now_pro/app/services/printer_service.dart';
import 'package:pos_now_pro/app/services/sync_services.dart';
import '../../services/user_preference_service.dart';

class SettingController extends GetxController {
  // --- SERVICES ---
  final UserPreferenceService prefs = UserPreferenceService.instance;

  // --- STATE ---
  var selectedIndex = 0.obs; // 0: General, 1: Printer, 2: Security, 3: Menu
  var isLoading = false.obs;

  // --- STORAGE ---
  final box = GetStorage();

  // --- CONTROLLERS & STATE: PRINTER ---
  var kitchenPrinterType = 'ip'.obs;
  var drinkPrinterType = 'ip'.obs;
  var counterPrinterType = 'ip'.obs;

  var isCounterPrinterEnabled = true.obs;
  var isKitchenPrinterEnabled = true.obs;
  var isDrinkPrinterEnabled = true.obs;

  final kitchenPrinterCtrl = TextEditingController();
  final drinkPrinterCtrl = TextEditingController();
  final counterPrinterCtrl = TextEditingController();

  final kitchenBluetoothCtrl = TextEditingController();
  final drinkBluetoothCtrl = TextEditingController();
  final counterBluetoothCtrl = TextEditingController();

  // --- CONTROLLERS: SECURITY & GENERAL ---
  final adminPassCtrl = TextEditingController();
  final staffPinCtrl = TextEditingController();
  final serverUrlCtrl = TextEditingController();
  var selectedLanguage = UserPreferenceService.instance.getAppLanguage().obs;

  var hasPrinterChanges = false.obs;

  // --- BLUETOOTH STATE ---
  var pairedDevices = <BluetoothInfo>[].obs;
  var isScanningBluetooth = false.obs;

  // Snapshot variables
  String _origKitchenType = '';
  String _origKitchenIp = '';
  String _origKitchenBt = '';

  String _origDrinkType = '';
  String _origDrinkIp = '';
  String _origDrinkBt = '';

  String _origCounterType = '';
  String _origCounterIp = '';
  String _origCounterBt = '';

  bool _origCounterEnabled = true;
  bool _origKitchenEnabled = true;
  bool _origDrinkEnabled = true;

  @override
  void onInit() {
    super.onInit();
    loadSettings();

    kitchenPrinterCtrl.addListener(_checkForPrinterChanges);
    kitchenBluetoothCtrl.addListener(_checkForPrinterChanges);

    drinkPrinterCtrl.addListener(_checkForPrinterChanges);
    drinkBluetoothCtrl.addListener(_checkForPrinterChanges);

    counterPrinterCtrl.addListener(_checkForPrinterChanges);
    counterBluetoothCtrl.addListener(_checkForPrinterChanges);

    ever(kitchenPrinterType, (_) => _checkForPrinterChanges());
    ever(drinkPrinterType, (_) => _checkForPrinterChanges());
    ever(counterPrinterType, (_) => _checkForPrinterChanges());

    //Listen to toggle changes
    ever(isCounterPrinterEnabled, (_) => _checkForPrinterChanges());
    ever(isKitchenPrinterEnabled, (_) => _checkForPrinterChanges());
    ever(isDrinkPrinterEnabled, (_) => _checkForPrinterChanges());
  }

  @override
  void onClose() {
    kitchenPrinterCtrl.dispose();
    drinkPrinterCtrl.dispose();
    kitchenBluetoothCtrl.dispose();
    drinkBluetoothCtrl.dispose();
    counterPrinterCtrl.dispose();
    counterBluetoothCtrl.dispose();
    adminPassCtrl.dispose();
    staffPinCtrl.dispose();
    serverUrlCtrl.dispose();
    super.onClose();
  }

  void _checkForPrinterChanges() {
    hasPrinterChanges.value =
        kitchenPrinterType.value != _origKitchenType ||
            kitchenPrinterCtrl.text != _origKitchenIp ||
            kitchenBluetoothCtrl.text != _origKitchenBt ||
            drinkPrinterType.value != _origDrinkType ||
            drinkPrinterCtrl.text != _origDrinkIp ||
            drinkBluetoothCtrl.text != _origDrinkBt ||
            counterPrinterType.value != _origCounterType ||
            counterPrinterCtrl.text != _origCounterIp ||
            counterBluetoothCtrl.text != _origCounterBt ||
            isCounterPrinterEnabled.value != _origCounterEnabled ||
            isKitchenPrinterEnabled.value != _origKitchenEnabled ||
            isDrinkPrinterEnabled.value != _origDrinkEnabled;
  }

  void loadSettings() {
    kitchenPrinterType.value = prefs.getKitchenPrinterType().isEmpty ? 'ip' : prefs.getKitchenPrinterType();
    String savedKitchenIp = prefs.getKitchenPrinterIp();
    kitchenPrinterCtrl.text = savedKitchenIp.isNotEmpty ? savedKitchenIp : '192.168.0.210';
    kitchenBluetoothCtrl.text = prefs.getKitchenBluetoothAddress();

    drinkPrinterType.value = prefs.getDrinkPrinterType().isEmpty ? 'ip' : prefs.getDrinkPrinterType();
    String savedDrinkIp = prefs.getDrinkPrinterIp();
    drinkPrinterCtrl.text = savedDrinkIp.isNotEmpty ? savedDrinkIp : '192.168.0.220';
    drinkBluetoothCtrl.text = prefs.getDrinkBluetoothAddress();

    counterPrinterType.value = prefs.getCounterPrinterType().isEmpty ? 'ip' : prefs.getCounterPrinterType();
    String savedCounterIp = prefs.getCounterPrinterIp();
    counterPrinterCtrl.text = savedCounterIp.isNotEmpty ? savedCounterIp : '192.168.0.200';
    counterBluetoothCtrl.text = prefs.getCounterBluetoothAddress();

    serverUrlCtrl.text = box.read('server_url') ?? 'http://192.168.0.100:8000';

    _origKitchenType = kitchenPrinterType.value;
    _origKitchenIp = kitchenPrinterCtrl.text;
    _origKitchenBt = kitchenBluetoothCtrl.text;
    _origDrinkType = drinkPrinterType.value;
    _origDrinkIp = drinkPrinterCtrl.text;
    _origDrinkBt = drinkBluetoothCtrl.text;
    _origCounterType = counterPrinterType.value;
    _origCounterIp = counterPrinterCtrl.text;
    _origCounterBt = counterBluetoothCtrl.text;

    isCounterPrinterEnabled.value = prefs.getIsCounterPrinterEnabled();
    isKitchenPrinterEnabled.value = prefs.getIsKitchenPrinterEnabled();
    isDrinkPrinterEnabled.value = prefs.getIsDrinkPrinterEnabled();

    _origCounterEnabled = isCounterPrinterEnabled.value;
    _origKitchenEnabled = isKitchenPrinterEnabled.value;
    _origDrinkEnabled = isDrinkPrinterEnabled.value;
  }

  void changeTab(int index) {
    selectedIndex.value = index;
  }

  // ==========================================
  // BLUETOOTH DISCOVERY & SELECTION
  // ==========================================
  Future<void> scanBluetoothDevices(TextEditingController targetCtrl) async {
    // 1. Request permissions
    var btScan = await Permission.bluetoothScan.request();
    var btConnect = await Permission.bluetoothConnect.request();
    var loc = await Permission.location.request();

    // 2. Check if all permissions are granted
    if (btScan.isGranted && btConnect.isGranted && loc.isGranted) {
      isScanningBluetooth.value = true;
      try {
        bool isBlueOn = await PrintBluetoothThermal.bluetoothEnabled;
        if (!isBlueOn) {
          Get.snackbar("Bluetooth Off".tr, "Please turn on Bluetooth to scan.".tr);
          return;
        }

        // Fetch paired devices from the OS
        final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
        pairedDevices.value = devices;

        if (devices.isEmpty) {
          Get.snackbar("Notice".tr, "No paired Bluetooth devices found.".tr);
        } else {
          _showDeviceSelectionDialog(targetCtrl);
        }
      } catch (e) {
        Get.snackbar("Error".tr, "Failed to scan devices: $e");
      } finally {
        isScanningBluetooth.value = false;
      }
    }
    else {
      Get.defaultDialog(
        title: "Permissions Required".tr,
        middleText: "Bluetooth and Location permissions are required to scan for printers. Please ensure they are allowed in your device settings.".tr,
        textConfirm: "Open Settings".tr,
        textCancel: "Cancel".tr,
        buttonColor: AppColors.primary,
        confirmTextColor: Colors.white,
        cancelTextColor: AppColors.primary,
        onConfirm: () {
          openAppSettings(); // Takes them directly to the app's permission page
          Get.back(); // Closes the dialog
        },
      );
    }
  }

  void _showDeviceSelectionDialog(TextEditingController targetCtrl) {
    Get.dialog(
      AlertDialog(
        title: Text("Select Bluetooth Printer".tr),
        content: SizedBox(
          width: 400, // Constrain width for tablets/desktop
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: pairedDevices.length,
            itemBuilder: (context, index) {
              final device = pairedDevices[index];
              return ListTile(
                leading: const Icon(Icons.bluetooth),
                title: Text(device.name.isNotEmpty ? device.name : "Unknown Device".tr),
                subtitle: Text(device.macAdress),
                onTap: () {
                  // Set the MAC address to the selected text controller
                  targetCtrl.text = device.macAdress;
                  Get.back(); // Close dialog
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancel".tr),
          ),
        ],
      ),
    );
  }

  // --- PRINTER ACTIONS ---
  Future<void> testPrinter(String address, String type) async {
    if (address.isEmpty) {
      Get.snackbar("Error".tr, "Please enter a valid Address / MAC".tr);
      return;
    }
    Get.find<PrinterService>().testPrint(address, type: type);
  }

  Future<void> savePrinterSettings() async {
    await prefs.setKitchenPrinterType(kitchenPrinterType.value);
    await prefs.setKitchenPrinterIp(kitchenPrinterCtrl.text);
    await prefs.setKitchenBluetoothAddress(kitchenBluetoothCtrl.text);

    await prefs.setDrinkPrinterType(drinkPrinterType.value);
    await prefs.setDrinkPrinterIp(drinkPrinterCtrl.text);
    await prefs.setDrinkBluetoothAddress(drinkBluetoothCtrl.text);

    await prefs.setCounterPrinterType(counterPrinterType.value);
    await prefs.setCounterPrinterIp(counterPrinterCtrl.text);
    await prefs.setCounterBluetoothAddress(counterBluetoothCtrl.text);

    await prefs.setIsCounterPrinterEnabled(isCounterPrinterEnabled.value);
    await prefs.setIsKitchenPrinterEnabled(isKitchenPrinterEnabled.value);
    await prefs.setIsDrinkPrinterEnabled(isDrinkPrinterEnabled.value);

    _origKitchenType = kitchenPrinterType.value;
    _origKitchenIp = kitchenPrinterCtrl.text;
    _origKitchenBt = kitchenBluetoothCtrl.text;

    _origDrinkType = drinkPrinterType.value;
    _origDrinkIp = drinkPrinterCtrl.text;
    _origDrinkBt = drinkBluetoothCtrl.text;

    _origCounterType = counterPrinterType.value;
    _origCounterIp = counterPrinterCtrl.text;
    _origCounterBt = counterBluetoothCtrl.text;

    _origCounterEnabled = isCounterPrinterEnabled.value;
    _origKitchenEnabled = isKitchenPrinterEnabled.value;
    _origDrinkEnabled = isDrinkPrinterEnabled.value;

    hasPrinterChanges.value = false;
    Get.snackbar("Success".tr, "Printer settings saved".tr);
  }

  // --- OTHERS ---
  Future<void> onSyncButtonPressed() async {
    if (isLoading.value) return;
    isLoading.value = true;
    await Get.find<SyncService>().syncMenu();
    isLoading.value = false;
  }

  void saveSecuritySettings() {
    Get.snackbar("Success".tr, "Security settings updated".tr);
    adminPassCtrl.clear();
  }

  void updateLanguage(String code) async {
    selectedLanguage.value = code;
    var selectedLocale = _localeFromCode(code);
    Get.updateLocale(selectedLocale);
    await prefs.setAppLanguage(selectedLocale.languageCode);
  }

  Locale _localeFromCode(String code) {
    switch (code) {
      case 'zh': return const Locale('zh', 'CN');
      case 'ms': return const Locale('ms', 'MY');
      default: return const Locale('en', 'US');
    }
  }

  // ==========================================
  // NAVIGATION & EXIT CONFIRMATION
  // ==========================================
  bool _isHandlingBack = false;

  Future<void> handleBackNavigation() async {
    if (_isHandlingBack) return;   // guard against re‑entrance
    _isHandlingBack = true;

    if (!hasPrinterChanges.value) {
      Get.back();
      _isHandlingBack = false;
      return;
    }

    final shouldExit = await _showUnsavedChangesDialog();
    if (shouldExit == true) {
      Get.back();
    }
    _isHandlingBack = false;
  }

  Future<bool?> _showUnsavedChangesDialog() {
    return Get.dialog<bool>(
      AlertDialog(
        title: Text("Unsaved Changes".tr),
        content: Text(
          "You have unsaved printer settings. Are you sure you want to exit without saving?"
              .tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text("Cancel".tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text("Exit".tr),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}