import 'package:defsystem/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppBackButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AppBackButton({
    super.key,
    this.label = 'Back',
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed ?? () => Navigator.pop(context),
      icon: const Icon(Icons.arrow_back_rounded, size: 20),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}