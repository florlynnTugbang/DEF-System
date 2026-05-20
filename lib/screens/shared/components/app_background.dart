import 'package:defsystem/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final bool useGradient;

  const AppBackground({
    super.key,
    required this.child,
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: useGradient
          ? const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.background,
            AppColors.accentLight,
          ],
        ),
      )
          : const BoxDecoration(
        color: AppColors.background,
      ),
      child: child,
    );
  }
}