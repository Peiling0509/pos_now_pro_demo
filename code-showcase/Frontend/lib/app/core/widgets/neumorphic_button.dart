import 'package:flutter/material.dart';

class NeumorphicButton extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  final Color textColor;

  const NeumorphicButton({
    super.key,
    required this.text,
    required this.isActive,
    required this.onTap,
    this.activeColor = Colors.red,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor : const Color(0xFFF6F5F2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: activeColor.withOpacity(0.5),
              offset: const Offset(2, 2),
              blurRadius: 6,
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-2, -2),
              blurRadius: 6,
            ),
          ]
              : [
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-4, -4),
              blurRadius: 6,
            ),
            BoxShadow(
              color: Colors.grey.shade300,
              offset: const Offset(4, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? textColor : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}