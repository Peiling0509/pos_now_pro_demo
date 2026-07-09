import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_now_pro/app/core/theme/app_color.dart';
import 'package:pos_now_pro/app/core/widgets/neumorphic_container.dart';
import 'package:pos_now_pro/app/modules/setting/setting_controller.dart';

class SettingView extends GetView<SettingController> {
  const SettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        await controller.handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- CUSTOM NEUMORPHIC TOP BAR ---
                _buildTopBar(),
                const SizedBox(height: 32),
      
                // --- MAIN CONTENT AREA ---
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- LEFT SIDEBAR (Navigation) ---
                      Expanded(
                        flex: 1,
                        child: Obx(
                              () => ListView(
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildNavTile(0, Icons.tune_rounded, "General".tr),
                              _buildNavTile(1, Icons.print_outlined, "Printers".tr),
                              _buildNavTile(2, Icons.restaurant_menu_rounded, "Menu Management".tr),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
      
                      // --- RIGHT CONTENT AREA ---
                      Expanded(
                        flex: 3,
                        child: NeumorphicContainer(
                          borderRadius: 28,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.all(32),
                              child: Obx(() {
                                switch (controller.selectedIndex.value) {
                                  case 0:
                                    return _buildGeneralSection();
                                  case 1:
                                    return _buildPrinterSection();
                                  case 2:
                                    return _buildMenuSection();
                                  default:
                                    return _buildGeneralSection();
                                }
                              }),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= TOP BAR =================
  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => controller.handleBackNavigation(),
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
        const SizedBox(width: 24),
        Text(
          "Settings".tr,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ================= NAVIGATION =================
  Widget _buildNavTile(int index, IconData icon, String title) {
    final isSelected = controller.selectedIndex.value == index;
    return GestureDetector(
      onTap: () => controller.changeTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(4, 6),
            ),
          ]
              : [
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-5, -5),
              blurRadius: 10,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(5, 5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
              size: 26,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SECTIONS =================

  Widget _buildGeneralSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("General".tr),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              const BoxShadow(color: Colors.white, offset: Offset(-5, -5), blurRadius: 10),
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(5, 5), blurRadius: 10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Language".tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildLangChip("English", "en"),
                  _buildLangChip("中文", "zh"),
                  _buildLangChip("Bahasa Melayu", "ms"),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrinterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle("Printer Configuration".tr),
            Obx(() {
              final isEnabled = controller.hasPrinterChanges.value;
              return _buildActionButton(
                text: "Update".tr,
                icon: Icons.save_rounded,
                color: isEnabled ? AppColors.primary : Colors.grey.shade400,
                onTap: isEnabled ? controller.savePrinterSettings : () {},
                isShadowed: isEnabled,
              );
            }),
          ],
        ),
        const SizedBox(height: 32),
        _buildPrinterCard(
          title: "Counter Printer".tr,
          isEnabledObs: controller.isCounterPrinterEnabled,
          typeObs: controller.counterPrinterType,
          ipCtrl: controller.counterPrinterCtrl,
          btCtrl: controller.counterBluetoothCtrl,
        ),
        const SizedBox(height: 24),
        _buildPrinterCard(
          title: "Kitchen Printer".tr,
          isEnabledObs: controller.isKitchenPrinterEnabled,
          typeObs: controller.kitchenPrinterType,
          ipCtrl: controller.kitchenPrinterCtrl,
          btCtrl: controller.kitchenBluetoothCtrl,
        ),
        const SizedBox(height: 24),
        _buildPrinterCard(
          title: "Drink Printer".tr,
          isEnabledObs: controller.isDrinkPrinterEnabled,
          typeObs: controller.drinkPrinterType,
          ipCtrl: controller.drinkPrinterCtrl,
          btCtrl: controller.drinkBluetoothCtrl,
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Menu Data".tr),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              const BoxShadow(color: Colors.white, offset: Offset(-5, -5), blurRadius: 10),
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(5, 5), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  boxShadow: [
                    const BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 8),
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), offset: const Offset(4, 4), blurRadius: 8),
                  ],
                ),
                child: const Icon(
                  Icons.cloud_sync_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Sync Local Database".tr,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Download the latest menu items from the server.".tr,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 40),
              Obx(
                    () => controller.isLoading.value
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : _buildActionButton(
                  text: "Sync Now".tr,
                  icon: Icons.download_rounded,
                  color: AppColors.primary,
                  onTap: controller.onSyncButtonPressed,
                  isShadowed: true,
                  width: 200,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= HELPERS & COMPONENTS =================

  Widget _buildPrinterCard({
    required String title,
    required RxBool isEnabledObs,
    required RxString typeObs,
    required TextEditingController ipCtrl,
    required TextEditingController btCtrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          const BoxShadow(color: Colors.white, offset: Offset(-5, -5), blurRadius: 10),
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(5, 5), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.text),
              ),
              Obx(() => Switch(
                value: isEnabledObs.value,
                onChanged: (val) => isEnabledObs.value = val,
                activeColor: AppColors.onPrimary,
                activeTrackColor: AppColors.primary,
                inactiveThumbColor: AppColors.textSecondary,
                inactiveTrackColor: AppColors.border.withValues(alpha: 0.3),
              )),
            ],
          ),
          Obx(() {
            if (!isEnabledObs.value) {
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  "Printer is disabled".tr,
                  style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic, fontSize: 15),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildToggleChip(
                      label: "IP / Network".tr,
                      isSelected: typeObs.value == 'ip',
                      onTap: () => typeObs.value = 'ip',
                    ),
                    const SizedBox(width: 16),
                    _buildToggleChip(
                      label: "Bluetooth".tr,
                      isSelected: typeObs.value == 'bluetooth',
                      onTap: () => typeObs.value = 'bluetooth',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Builder(builder: (context) {
                  final isIp = typeObs.value == 'ip';
                  final activeCtrl = isIp ? ipCtrl : btCtrl;
                  final hintText = isIp ? "e.g. 192.168.0.200" : "Select device or enter MAC...".tr;

                  Widget? suffix;
                  if (!isIp) {
                    suffix = Obx(() => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextButton(
                        onPressed: controller.isScanningBluetooth.value
                            ? null
                            : () => controller.scanBluetoothDevices(activeCtrl),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: controller.isScanningBluetooth.value
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                        )
                            : Text(
                          "Search".tr,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ));
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _buildTextField(activeCtrl, hintText, suffixIcon: suffix),
                      ),
                      const SizedBox(width: 16),
                      _buildActionButton(
                        text: "Test".tr,
                        icon: Icons.print_rounded,
                        color: Colors.orange.shade400,
                        onTap: () => controller.testPrinter(activeCtrl.text, typeObs.value),
                        isShadowed: true,
                      ),
                    ],
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {bool isPassword = false, Widget? suffixIcon}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // Inner shadow illusion
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), offset: const Offset(2, 2), blurRadius: 4, blurStyle: BlurStyle.inner),
          const BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4, blurStyle: BlurStyle.inner),
          // Outer subtle drop
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), offset: const Offset(4, 4), blurRadius: 8),
          const BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 8),
        ],
      ),
      child: TextField(
        controller: ctrl,
        obscureText: isPassword,
        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isShadowed = false,
    double? width,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isShadowed
              ? [
            BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6)),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangChip(String label, String code) {
    return Obx(() {
      final isSelected = controller.selectedLanguage.value == code;
      return _buildToggleChip(
        label: label,
        isSelected: isSelected,
        onTap: () => controller.updateLanguage(code),
      );
    });
  }

  Widget _buildToggleChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(2, 4)),
          ]
              : [
            const BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(3, 3), blurRadius: 6),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}