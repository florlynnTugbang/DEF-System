import 'package:defsystem/core/theme/app_colors.dart';
import 'package:defsystem/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class StatusStepper extends StatelessWidget {
  final int currentStep;
  final bool isCancelled;

  const StatusStepper({
    super.key,
    required this.currentStep,
    this.isCancelled = false,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        'label': 'Pending',
        'icon': Icons.inventory_2_outlined,
      },
      {
        'label': 'Assigned',
        'icon': Icons.assignment_turned_in_outlined,
      },
      {
        'label': 'In Transit',
        'icon': Icons.local_shipping_outlined,
      },
      {
        'label': isCancelled ? 'Cancelled' : 'Completed',
        'icon': isCancelled ? Icons.cancel_outlined : Icons.check_circle_outline,
      },
    ];

    final safeStep = currentStep.clamp(1, steps.length);
    final activeColor = isCancelled ? AppColors.cancelled : AppColors.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 520;
        final circleSize = isMobile ? 40.0 : 48.0;
        final lineTop = circleSize / 2;
        final totalWidth = constraints.maxWidth;
        final progressWidth =
            ((safeStep - 1) / (steps.length - 1)) * (totalWidth - circleSize);

        return SizedBox(
          height: isMobile ? 96 : 104,
          child: Stack(
            children: [
              Positioned(
                top: lineTop,
                left: circleSize / 2,
                right: circleSize / 2,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                top: lineTop,
                left: circleSize / 2,
                child: Container(
                  width: progressWidth.clamp(0, totalWidth),
                  height: 4,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  steps.length,
                      (index) {
                    final stepNumber = index + 1;
                    final isActive = stepNumber <= safeStep;
                    final isCurrent = stepNumber == safeStep;

                    return SizedBox(
                      width: isMobile ? 72 : 90,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: circleSize,
                            height: circleSize,
                            decoration: BoxDecoration(
                              color: isActive ? activeColor : AppColors.border,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isActive
                                    ? activeColor
                                    : AppColors.borderDark,
                                width: 2,
                              ),
                              boxShadow: isCurrent
                                  ? [
                                BoxShadow(
                                  color: activeColor.withValues(alpha: 0.25),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                                  : null,
                            ),
                            child: Icon(
                              steps[index]['icon'] as IconData,
                              color: isActive ? AppColors.white : AppColors.textMuted,
                              size: isMobile ? 20 : 23,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            steps[index]['label'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isMobile ? 10 : 12,
                              fontWeight:
                              isCurrent ? FontWeight.w900 : FontWeight.w600,
                              color: isCurrent
                                  ? activeColor
                                  : isActive
                                  ? AppColors.textDark
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}