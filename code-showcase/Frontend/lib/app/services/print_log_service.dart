import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../data/models/print_log_model.dart';

class PrintLogService extends GetxService {
  final GetStorage _box = GetStorage();
  final _key = 'print_history';

  // Observable list so UI updates automatically
  RxList<PrintLogModel> logs = <PrintLogModel>[].obs;

  Future<PrintLogService> init() async {
    loadLogs();
    return this;
  }

  void loadLogs() {
    try {
      List<dynamic>? stored = _box.read<List<dynamic>>(_key);

      if (stored != null) {
        Get.log("Found ${stored.length} logs in storage. Attempting to parse...");

        // We parse items individually so if ONE log is corrupted,
        // it doesn't crash the whole list!
        List<PrintLogModel> parsedLogs = [];
        for (var item in stored) {
          try {
            parsedLogs.add(PrintLogModel.fromJson(item));
          } catch (e) {
            Get.log("Failed to parse a single print log: $e");
            // It will skip the corrupted log and continue loading the rest
          }
        }

        logs.value = parsedLogs;
        logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        Get.log("Successfully loaded ${logs.length} print logs.");
      } else {
        Get.log("No print history found in storage.");
      }
    } catch (e) {
      Get.log("CRITICAL ERROR loading print logs from GetStorage: $e");
    }
  }

  Future<void> addLog(PrintLogModel log) async {
    logs.insert(0, log); // Add to top of list
    // Optional: Limit history to last 50 items to save space
    if (logs.length > 50) logs.removeLast();
    await _save();
  }

  Future<void> updateLogStatus(String id, PrintStatus newStatus, {String? errorMsg}) async {
    final index = logs.indexWhere((item) => item.id == id);

    if (index != -1) {
      final oldLog = logs[index];

      // Create a new instance with updated status/time
      // Assuming your model has a copyWith, otherwise construct manually:
      final updatedLog = PrintLogModel(
        id: oldLog.id,
        orderId: oldLog.orderId,
        printerType: oldLog.printerType,
        printerIp: oldLog.printerIp,
        timestamp: DateTime.now(), // Update time to show when it was retried
        status: newStatus,
        order: oldLog.order, // Keep the order snapshot
        errorMessage: errorMsg ?? (newStatus == PrintStatus.success ? null : oldLog.errorMessage),
      );

      logs[index] = updatedLog; // This triggers UI update
      await _save();
    }
  }

  Future<void> clearLogs() async {
    logs.clear();
    await _box.remove(_key);
  }

  Future<void> _save() async {
    try {
      // 1. Convert logs to JSON
      final dataToSave = logs.map((e) => e.toJson()).toList();

      // 2. Write to storage
      await _box.write(_key, dataToSave);
      Get.log("✅ Successfully saved ${logs.length} logs to storage.");
    } catch (e) {
      Get.log("❌ CRITICAL ERROR SAVING TO GETSTORAGE: $e");
    }
  }
}