import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoadingDialog {
  static bool _isOpen = false;

  static void show({String message = "Loading"}) {
    if (_isOpen) return;
    _isOpen = true;

    Get.dialog(
      PopScope(
        canPop: false, // ❌ Don't allow closing via back button
        child: Stack(
          children: [
            // Dim background
            Container(color: Colors.black.withOpacity(0.45)),

            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(strokeWidth: 4),
                    ),
                    const SizedBox(width: 18),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        decoration: TextDecoration.none, // ✅ No underline
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void hide() {
    if (_isOpen) {
      _isOpen = false;
      Get.back();
    }
  }
}
