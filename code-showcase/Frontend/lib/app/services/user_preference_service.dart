import 'package:get_storage/get_storage.dart';

class UserPreferenceService {
  // Singleton pattern
  UserPreferenceService._privateConstructor();
  static final UserPreferenceService instance =
  UserPreferenceService._privateConstructor();

  // GENERAL KEYS
  static const String _keyAppLanguage = "app_language";
  static const String _keyUserName = "user_name";

  // -- PRINTER KEYS --
  static const String _keyKitchenPrinterType = "kitchen_printer_type";
  static const String _keyKitchenPrinterIp = "kitchen_printer_ip";
  static const String _keyKitchenBluetoothAddress = "kitchen_bluetooth_address";

  static const String _keyDrinkPrinterType = "drink_printer_type";
  static const String _keyDrinkPrinterIp = "drink_printer_ip";
  static const String _keyDrinkBluetoothAddress = "drink_bluetooth_address";

  static const String _keyCounterPrinterType = "counter_printer_type";
  static const String _keyCounterPrinterIp = "counter_printer_ip";
  static const String _keyCounterBluetoothAddress = "counter_bluetooth_address";

  static const String _keyCounterEnabled = "counter_printer_enabled";
  static const String _keyKitchenEnabled = "kitchen_printer_enabled";
  static const String _keyDrinkEnabled = "drink_printer_enabled";

  // Reference to GetStorage
  final GetStorage _storage = GetStorage();

  // -------------------------
  // USER NAME SECTIONS
  // -------------------------

  /// Save user name to the list if it doesn't already exist.
  Future<void> saveUserName(String userName) async {
    final existingUserNames = getUserName();
    if (!existingUserNames.contains(userName)) {
      existingUserNames.add(userName);
      await _storage.write(_keyUserName, existingUserNames);
    }
  }

  /// Get user name list
  List<String> getUserName() {
    return _storage.read<List<dynamic>>(_keyUserName)?.cast<String>() ?? [];
  }

  /// Clear saved user name
  Future<void> clearUserName() async {
    await _storage.remove(_keyUserName);
  }

  // -------------------------
  // APP LANGUAGE SECTIONS
  // -------------------------

  /// Save app language
  Future<void> setAppLanguage(String languageCode) async {
    await _storage.write(_keyAppLanguage, languageCode);
  }

  /// Get app language, default to 'en' if not set
  String getAppLanguage() {
    return _storage.read(_keyAppLanguage) ?? 'en';
  }

  /// Clear saved app language
  Future<void> clearAppLanguage() async {
    await _storage.remove(_keyAppLanguage);
  }

  // -------------------------
  // KITCHEN PRINTER SECTIONS
  // -------------------------

  /// Save Kitchen Printer Type ('ip' or 'bluetooth')
  Future<void> setKitchenPrinterType(String type) async {
    await _storage.write(_keyKitchenPrinterType, type);
  }

  /// Get Kitchen Printer Type (defaults to 'ip')
  String getKitchenPrinterType() {
    return _storage.read(_keyKitchenPrinterType) ?? 'ip';
  }

  /// Save Kitchen Printer IP
  Future<void> setKitchenPrinterIp(String ip) async {
    await _storage.write(_keyKitchenPrinterIp, ip);
  }

  /// Get Kitchen Printer IP
  String getKitchenPrinterIp() {
    return _storage.read(_keyKitchenPrinterIp) ?? '192.168.10.210';
  }

  /// Save Kitchen Bluetooth Address
  Future<void> setKitchenBluetoothAddress(String address) async {
    await _storage.write(_keyKitchenBluetoothAddress, address);
  }

  /// Get Kitchen Bluetooth Address
  String getKitchenBluetoothAddress() {
    return _storage.read(_keyKitchenBluetoothAddress) ?? '';
  }

  /// Clear all Kitchen Printer settings
  Future<void> clearKitchenPrinterSettings() async {
    await _storage.remove(_keyKitchenPrinterType);
    await _storage.remove(_keyKitchenPrinterIp);
    await _storage.remove(_keyKitchenBluetoothAddress);
  }

  // -------------------------
  // DRINK PRINTER SECTIONS
  // -------------------------

  /// Save Drink Printer Type ('ip' or 'bluetooth')
  Future<void> setDrinkPrinterType(String type) async {
    await _storage.write(_keyDrinkPrinterType, type);
  }

  /// Get Drink Printer Type (defaults to 'ip')
  String getDrinkPrinterType() {
    return _storage.read(_keyDrinkPrinterType) ?? 'ip';
  }

  /// Save Drink Printer IP
  Future<void> setDrinkPrinterIp(String ip) async {
    await _storage.write(_keyDrinkPrinterIp, ip);
  }

  /// Get Drink Printer IP
  String getDrinkPrinterIp() {
    return _storage.read(_keyDrinkPrinterIp) ?? '192.168.10.220';
  }

  /// Save Drink Bluetooth Address
  Future<void> setDrinkBluetoothAddress(String address) async {
    await _storage.write(_keyDrinkBluetoothAddress, address);
  }

  /// Get Drink Bluetooth Address
  String getDrinkBluetoothAddress() {
    return _storage.read(_keyDrinkBluetoothAddress) ?? '';
  }

  /// Clear all Drink Printer settings
  Future<void> clearDrinkPrinterSettings() async {
    await _storage.remove(_keyDrinkPrinterType);
    await _storage.remove(_keyDrinkPrinterIp);
    await _storage.remove(_keyDrinkBluetoothAddress);
  }

  // -------------------------
  // COUNTER PRINTER SECTIONS
  // -------------------------

  /// Save Counter Printer Type ('ip' or 'bluetooth')
  Future<void> setCounterPrinterType(String type) async {
    await _storage.write(_keyCounterPrinterType, type);
  }

  /// Get Counter Printer Type (defaults to 'ip')
  String getCounterPrinterType() {
    return _storage.read(_keyCounterPrinterType) ?? 'ip';
  }

  /// Save Counter Printer IP
  Future<void> setCounterPrinterIp(String ip) async {
    await _storage.write(_keyCounterPrinterIp, ip);
  }

  /// Get Counter Printer IP
  String getCounterPrinterIp() {
    return _storage.read(_keyCounterPrinterIp) ?? '192.168.10.230';
  }

  /// Save Counter Bluetooth Address
  Future<void> setCounterBluetoothAddress(String address) async {
    await _storage.write(_keyCounterBluetoothAddress, address);
  }

  /// Get Counter Bluetooth Address
  String getCounterBluetoothAddress() {
    return _storage.read(_keyCounterBluetoothAddress) ?? '';
  }

  // -------------------------
  // PRINTER ENABLED
  // -------------------------
  bool getIsCounterPrinterEnabled() => _storage.read(_keyCounterEnabled) ?? true;
  Future<void> setIsCounterPrinterEnabled(bool val) async => await _storage.write(_keyCounterEnabled, val);

  bool getIsKitchenPrinterEnabled() => _storage.read(_keyKitchenEnabled) ?? true;
  Future<void> setIsKitchenPrinterEnabled(bool val) async => await _storage.write(_keyKitchenEnabled, val);

  bool getIsDrinkPrinterEnabled() => _storage.read(_keyDrinkEnabled) ?? true;
  Future<void> setIsDrinkPrinterEnabled(bool val) async => await _storage.write(_keyDrinkEnabled, val);



  /// Clear all Counter Printer settings
  Future<void> clearCounterPrinterSettings() async {
    await _storage.remove(_keyCounterPrinterType);
    await _storage.remove(_keyCounterPrinterIp);
    await _storage.remove(_keyCounterBluetoothAddress);
  }

}