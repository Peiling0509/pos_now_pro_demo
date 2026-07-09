import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_now_pro/app/core/theme/app_color.dart';
import 'package:pos_now_pro/app/services/printer_service.dart';
import '../../data/models/print_log_model.dart';
import '../../services/print_log_service.dart';
import 'package:intl/intl.dart';

class PrintHistoryView extends StatefulWidget {
  const PrintHistoryView({super.key});

  @override
  State<PrintHistoryView> createState() => _PrintHistoryViewState();
}

class _PrintHistoryViewState extends State<PrintHistoryView> {
  // Local state for the filter
  String _statusFilter = 'All'; // Options: 'All', 'Success', 'Failed'

  // --- UNIFIED NEUMORPHIC PALETTE ---
  Color get neuBackground => AppColors.background;
  Color get neuShadowDark => AppColors.border.withValues(alpha: 0.4);
  Color get neuShadowLight => Colors.white;
  Color get themeRed => AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final service = Get.find<PrintLogService>();

    return Scaffold(
      backgroundColor: neuBackground,
      body: SafeArea(
        child: Column(
          children: [
            // 1. CUSTOM NEUMORPHIC TOP BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: _buildTopBar(service),
            ),

            // 2. FILTER BAR
            _buildFilterBar(),

            // 3. LIST VIEW
            Expanded(
              child: Obx(() {
                // Apply filtering logic based on the selected chip
                final filteredLogs = service.logs.where((log) {
                  final isSuccess = log.status == PrintStatus.success;
                  if (_statusFilter == 'Success') return isSuccess;
                  if (_statusFilter == 'Failed') return !isSuccess;
                  return true; // 'All'
                }).toList();

                if (filteredLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.print_disabled_rounded, size: 80, color: AppColors.border.withValues(alpha: 0.5)),
                        const SizedBox(height: 24),
                        Text(
                          _statusFilter == 'All'
                              ? "No print jobs recorded".tr
                              : "No print jobs found".tr,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 8, bottom: 32),
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    return _buildLogCard(filteredLogs[index]);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ================= WIDGETS =================

  Widget _buildTopBar(PrintLogService service) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-4, -4),
                  blurRadius: 8,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  offset: const Offset(4, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary, size: 22),
          ),
        ),
        Text(
          "Print History".tr,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
            letterSpacing: 0.5,
          ),
        ),
        GestureDetector(
          onTap: () => _showClearDialog(service),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: neuBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: neuShadowDark, offset: const Offset(4, 4), blurRadius: 8),
                BoxShadow(color: neuShadowLight, offset: const Offset(-4, -4), blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded, color: themeRed, size: 24),
                const SizedBox(width: 8),
                Text("Clear All".tr, style: TextStyle(color: themeRed, fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            Text(
              "${"Filter".tr}:",
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.text,
              ),
            ),
            const SizedBox(width: 16),
            _buildFilterChip('All', "All".tr),
            const SizedBox(width: 16),
            _buildFilterChip('Success', "Success".tr),
            const SizedBox(width: 16),
            _buildFilterChip('Failed', "Failed".tr),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _statusFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? themeRed : neuBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
            BoxShadow(color: themeRed.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4)),
          ]
              : [
            BoxShadow(color: neuShadowDark, offset: const Offset(4, 4), blurRadius: 8),
            BoxShadow(color: neuShadowLight, offset: const Offset(-4, -4), blurRadius: 8),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildLogCard(PrintLogModel log) {
    final printer = Get.find<PrinterService>();
    final isSuccess = log.status == PrintStatus.success;
    final timeStr = DateFormat('hh:mm:ss a , dd/MM/yyyy').format(log.timestamp);

    final String tableDisplay = log.order?.tableId != null
        ? "${"Table".tr} #${log.order!.tableId}"
        : "Takeaway".tr;

    String titleDisplay = log.printerType.toString();
    if (titleDisplay.contains('.')) {
      String rawType = titleDisplay.split('.').last.toUpperCase();
      titleDisplay = "${rawType.tr} ${"PRINTER".tr}";
    }

    // Set colors based on status
    final statusColor = isSuccess ? const Color(0xFF23A718) : themeRed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: neuBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: neuShadowDark, offset: const Offset(6, 6), blurRadius: 12),
          BoxShadow(color: neuShadowLight, offset: const Offset(-6, -6), blurRadius: 12),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Neumorphic Status Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: neuBackground,
              shape: BoxShape.circle,
              boxShadow: [
                // Inner pushed-in shadow illusion for the icon wrapper
                BoxShadow(color: neuShadowDark.withValues(alpha: 0.3), offset: const Offset(2, 2), blurRadius: 4),
                BoxShadow(color: neuShadowLight, offset: const Offset(-2, -2), blurRadius: 4),
              ],
            ),
            child: Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
              color: statusColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Middle: Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$titleDisplay ($tableDisplay)",
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.settings_ethernet_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      "${"IP/MAC".tr}: ${log.printerIp}",
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      "${"Time".tr}: $timeStr",
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                // Highlighted Error Message Box
                if (!isSuccess && log.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12.0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: themeRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: themeRed.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 18, color: themeRed),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${log.errorMessage}",
                            style: TextStyle(color: themeRed, fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Right: Neumorphic Reprint Button
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => printer.reprintFromLog(log),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: neuBackground,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: neuShadowDark, offset: const Offset(4, 4), blurRadius: 8),
                  BoxShadow(color: neuShadowLight, offset: const Offset(-4, -4), blurRadius: 8),
                ],
              ),
              child: const Icon(Icons.print_rounded, color: Colors.blueAccent, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  // --- DIALOG: CONFIRM CLEAR HISTORY ---
  void _showClearDialog(PrintLogService service) {
    Get.dialog(
      AlertDialog(
        backgroundColor: neuBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Clear History".tr,
          style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800),
        ),
        content: Text(
          "Are you sure you want to clear all print logs?".tr,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "Cancel".tr,
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () {
              service.clearLogs();
              Get.back();
            },
            child: Text(
              "Clear".tr,
              style: TextStyle(color: themeRed, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}