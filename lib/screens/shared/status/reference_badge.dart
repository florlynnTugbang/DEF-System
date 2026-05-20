import 'package:defsystem/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ReferenceBadge extends StatelessWidget {
  final String referenceNumber;
  final bool compact;

  const ReferenceBadge({
    super.key,
    required this.referenceNumber,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: compact ? 13 : 15,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            referenceNumber,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 12 : 13,
            ),
          ),
        ],
      ),
    );
  }
}