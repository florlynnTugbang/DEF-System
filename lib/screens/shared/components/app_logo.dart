import 'package:defsystem/core/theme/app_colors.dart';
import 'package:defsystem/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final bool light;

  const AppLogo({
    super.key,
    this.iconSize = 32,
    this.fontSize = 24,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = light ? AppColors.white : AppColors.primary;
    final textColor = light ? AppColors.white : AppColors.textDark;
    final subColor = light ? AppColors.textLight : AppColors.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: iconSize + 12,
          width: iconSize + 12,
          decoration: BoxDecoration(
            color: light
                ? AppColors.white.withValues(alpha: 0.14)
                : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            Icons.local_shipping_outlined,
            color: iconColor,
            size: iconSize,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DEF',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: textColor,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'DispatchTrack',
              style: TextStyle(
                fontSize: fontSize * 0.52,
                fontWeight: FontWeight.w700,
                color: subColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}