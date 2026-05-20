import 'package:defsystem/core/theme/app_colors.dart';
import 'package:defsystem/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class SectionTable extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final List<String> columns;
  final List<DataRow> rows;
  final String emptyMessage;

  const SectionTable({
    super.key,
    required this.title,
    required this.columns,
    this.actions = const [],
    this.rows = const [],
    this.emptyMessage = 'No records found',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                if (actions.isNotEmpty)
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: actions,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Text(
                  emptyMessage,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  AppColors.surfaceSoft,
                ),
                columnSpacing: 28,
                horizontalMargin: 24,
                dataRowMinHeight: 54,
                dataRowMaxHeight: 72,
                headingTextStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
                dataTextStyle: const TextStyle(
                  color: AppColors.textBody,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                columns: columns
                    .map(
                      (c) => DataColumn(
                    label: Text(c.toUpperCase()),
                  ),
                )
                    .toList(),
                rows: rows,
              ),
            ),
        ],
      ),
    );
  }
}