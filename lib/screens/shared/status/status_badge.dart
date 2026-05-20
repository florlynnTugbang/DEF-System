import 'package:defsystem/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool large;

  const StatusBadge({
    super.key,
    required this.status,
    this.large = false,
  });

  String get _normalizedStatus {
    return status.toLowerCase().trim().replaceAll('-', ' ');
  }

  Color get _bgColor {
    switch (_normalizedStatus) {
      case 'pending':
        return AppColors.pendingBg;
      case 'assigned':
        return AppColors.assignedBg;
      case 'in transit':
      case 'in-transit':
        return AppColors.inTransitBg;
      case 'completed':
      case 'delivered':
        return AppColors.completedBg;
      case 'cancelled':
      case 'canceled':
        return AppColors.cancelledBg;
      case 'issue reported':
        return AppColors.issueBg;
      case 'resolved':
        return AppColors.resolvedBg;
      default:
        return AppColors.surfaceSoft;
    }
  }

  Color get _textColor {
    switch (_normalizedStatus) {
      case 'pending':
        return AppColors.pending;
      case 'assigned':
        return AppColors.assigned;
      case 'in transit':
      case 'in-transit':
        return AppColors.inTransit;
      case 'completed':
      case 'delivered':
        return AppColors.completed;
      case 'cancelled':
      case 'canceled':
        return AppColors.cancelled;
      case 'issue reported':
        return AppColors.issue;
      case 'resolved':
        return AppColors.resolved;
      default:
        return AppColors.textMuted;
    }
  }

  IconData get _icon {
    switch (_normalizedStatus) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'assigned':
        return Icons.assignment_turned_in_outlined;
      case 'in transit':
      case 'in-transit':
        return Icons.local_shipping_outlined;
      case 'completed':
      case 'delivered':
        return Icons.check_circle_outline_rounded;
      case 'cancelled':
      case 'canceled':
        return Icons.cancel_outlined;
      case 'issue reported':
        return Icons.report_problem_outlined;
      case 'resolved':
        return Icons.verified_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 8 : 5,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _textColor.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon,
            color: _textColor,
            size: large ? 15 : 12,
          ),
          const SizedBox(width: 5),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: large ? 12 : 10,
              color: _textColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}