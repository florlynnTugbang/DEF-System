import 'package:defsystem/core/theme/app_colors.dart';
import 'package:defsystem/core/theme/app_spacing.dart';
import 'package:defsystem/screens/shared/status/status_badge.dart';
import 'package:flutter/material.dart';

class DeliveryHistoryCard extends StatelessWidget {
  final String referenceNumber;
  final String status;
  final String date;
  final String customerName;
  final String itemDescription;
  final String pickupAddress;
  final String deliveryAddress;

  const DeliveryHistoryCard({
    super.key,
    required this.referenceNumber,
    required this.status,
    required this.date,
    required this.customerName,
    required this.itemDescription,
    required this.pickupAddress,
    required this.deliveryAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 620;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isMobile ? _buildMobileHeader() : _buildDesktopHeader(),
              const SizedBox(height: AppSpacing.lg),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.lg),
              _InfoLine(
                icon: Icons.inventory_2_outlined,
                label: 'Item',
                value: itemDescription,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              if (isMobile)
                Column(
                  children: [
                    _InfoLine(
                      icon: Icons.location_on_outlined,
                      label: 'Pickup',
                      value: pickupAddress,
                      color: AppColors.completed,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _InfoLine(
                      icon: Icons.flag_outlined,
                      label: 'Drop-off',
                      value: deliveryAddress,
                      color: AppColors.assigned,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _InfoLine(
                        icon: Icons.location_on_outlined,
                        label: 'Pickup',
                        value: pickupAddress,
                        color: AppColors.completed,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: _InfoLine(
                        icon: Icons.flag_outlined,
                        label: 'Drop-off',
                        value: deliveryAddress,
                        color: AppColors.assigned,
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      children: [
        Expanded(
          child: _HeaderInfo(
            referenceNumber: referenceNumber,
            customerName: customerName,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusBadge(status: status),
            const SizedBox(height: AppSpacing.sm),
            Text(
              date,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderInfo(
          referenceNumber: referenceNumber,
          customerName: customerName,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            StatusBadge(status: status),
            Text(
              date,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  final String referenceNumber;
  final String customerName;

  const _HeaderInfo({
    required this.referenceNumber,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          referenceNumber,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Customer: $customerName',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            icon,
            size: 17,
            color: color,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textBody,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}