import 'package:defsystem/core/theme/app_colors.dart';
import 'package:defsystem/core/theme/app_spacing.dart';
import 'package:defsystem/providers/auth_provider.dart';
import 'package:defsystem/providers/report_provider.dart';
import 'package:defsystem/screens/shared/cards/summary_card.dart';
import 'package:defsystem/screens/shared/components/app_card.dart';
import 'package:defsystem/screens/shared/components/date_time_header.dart';
import 'package:defsystem/screens/shared/status/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ManagementDashboardScreen extends ConsumerStatefulWidget {
  const ManagementDashboardScreen({super.key});

  @override
  ConsumerState<ManagementDashboardScreen> createState() =>
      _ManagementDashboardScreenState();
}

class _ManagementDashboardScreenState
    extends ConsumerState<ManagementDashboardScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportProvider.notifier).loadAll();
    });
  }

  Future<void> _refreshDashboard() async {
    await ref.read(reportProvider.notifier).loadAll();
  }

  String _customerName(Map<String, dynamic>? customer) {
    if (customer == null) return 'N/A';

    final parts = [
      customer['custfname'],
      customer['custmname'],
      customer['custlname'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).toList();

    if (parts.isEmpty) return 'N/A';
    return parts.join(' ');
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return 'N/A';

    try {
      return DateFormat('MMM dd, yyyy')
          .format(DateTime.parse(rawDate).toLocal());
    } catch (_) {
      return rawDate;
    }
  }

  String _formatTime(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return 'N/A';

    try {
      return DateFormat('hh:mm a').format(DateTime.parse(rawDate).toLocal());
    } catch (_) {
      return 'N/A';
    }
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);
    final authState = ref.watch(authProvider);

    final summary = reportState.summary;
    final ridersSummary = reportState.ridersSummary;
    final records = reportState.deliveryRecords;

    final adminName =
    authState.displayName.isNotEmpty ? authState.displayName : 'Admin';

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 760;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 32,
                isMobile ? 18 : 32,
                isMobile ? 16 : 32,
                isMobile ? 110 : 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildNavyHeader(
                    isMobile: isMobile,
                    adminName: adminName,
                    summary: summary,
                    ridersSummary: ridersSummary,
                  ),
                  SizedBox(height: isMobile ? 18 : 24),
                  if (reportState.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (reportState.error != null)
                    _buildErrorBox(reportState.error!)
                  else ...[
                      _buildSummaryCarousel(
                        isMobile: isMobile,
                        summary: summary,
                        ridersSummary: ridersSummary,
                      ),
                      SizedBox(height: isMobile ? 18 : 24),
                      _buildChartSection(isMobile),
                      SizedBox(height: isMobile ? 18 : 24),
                      _buildRecentDeliveriesSection(
                        isMobile: isMobile,
                        records: records.take(6).toList(),
                      ),
                    ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavyHeader({
    required bool isMobile,
    required String adminName,
    required Map<String, dynamic> summary,
    required Map<String, int> ridersSummary,
  }) {
    final totalDeliveries = _toInt(summary['total']);
    final completed = _toInt(summary['completed']);
    final activeRiders = _toInt(ridersSummary['total']);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 22 : 30),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: isMobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildHeaderIcon(Icons.admin_panel_settings_outlined),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Management',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const DateTimeHeader(compact: true),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome, $adminName',
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Management Dashboard',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Monitor system performance, rider availability, and delivery records.',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          _buildHeaderStats(
            totalDeliveries: totalDeliveries,
            completed: completed,
            activeRiders: activeRiders,
          ),
        ],
      )
          : Row(
        children: [
          _buildHeaderIcon(
            Icons.admin_panel_settings_outlined,
            large: true,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Management Dashboard',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome, $adminName. Monitor system performance, rider availability, and delivery records.',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                _buildHeaderStats(
                  totalDeliveries: totalDeliveries,
                  completed: completed,
                  activeRiders: activeRiders,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const DateTimeHeader(),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, {bool large = false}) {
    return Container(
      height: large ? 54 : 44,
      width: large ? 54 : 44,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(
          large ? AppSpacing.radiusLg : AppSpacing.radiusMd,
        ),
      ),
      child: Icon(
        icon,
        color: AppColors.white,
        size: large ? 28 : 23,
      ),
    );
  }

  Widget _buildHeaderStats({
    required int totalDeliveries,
    required int completed,
    required int activeRiders,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _HeaderStatPill(
            icon: Icons.inventory_2_outlined,
            label: 'Deliveries',
            value: '$totalDeliveries',
          ),
          const SizedBox(width: 10),
          _HeaderStatPill(
            icon: Icons.check_circle_outline_rounded,
            label: 'Completed',
            value: '$completed',
          ),
          const SizedBox(width: 10),
          _HeaderStatPill(
            icon: Icons.people_outline,
            label: 'Riders',
            value: '$activeRiders',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCarousel({
    required bool isMobile,
    required Map<String, dynamic> summary,
    required Map<String, int> ridersSummary,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const gap = 14.0;

        final desktopCardWidth = ((availableWidth - (gap * 3)) / 4).clamp(
          220.0,
          340.0,
        );

        final cardWidth = isMobile ? 235.0 : desktopCardWidth;

        final cards = [
          SummaryCard(
            title: 'Total Deliveries',
            value: '${summary['total'] ?? 0}',
            subtitle: 'All delivery records',
            icon: Icons.inventory_2_outlined,
            color: AppColors.primary,
            width: cardWidth,
          ),
          SummaryCard(
            title: 'Completion Rate',
            value: '${summary['completionrate'] ?? 0}%',
            subtitle: '${summary['completed'] ?? 0} delivered',
            icon: Icons.trending_up_rounded,
            color: AppColors.completed,
            width: cardWidth,
          ),
          SummaryCard(
            title: 'Active Riders',
            value: '${ridersSummary['total'] ?? 0}',
            subtitle: '${ridersSummary['available'] ?? 0} available',
            icon: Icons.people_outline,
            color: AppColors.assigned,
            width: cardWidth,
          ),
          SummaryCard(
            title: 'Pending / In Transit',
            value: '${summary['pending'] ?? 0}',
            subtitle: '${summary['inTransit'] ?? 0} in transit',
            icon: Icons.access_time_rounded,
            color: AppColors.pending,
            width: cardWidth,
          ),
        ];

        return SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(cards.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == cards.length - 1 ? 0 : gap,
                  ),
                  child: cards[index],
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChartSection(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildChartPlaceholder(
            title: 'Deliveries Per Day',
            icon: Icons.show_chart_rounded,
            subtitle: 'Daily delivery activity overview',
          ),
          const SizedBox(height: 14),
          _buildChartPlaceholder(
            title: 'Status Breakdown',
            icon: Icons.pie_chart_outline_rounded,
            subtitle: 'Pending, assigned, in-transit, and completed records',
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildChartPlaceholder(
            title: 'Deliveries Per Day',
            icon: Icons.show_chart_rounded,
            subtitle: 'Daily delivery activity overview',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildChartPlaceholder(
            title: 'Status Breakdown',
            icon: Icons.pie_chart_outline_rounded,
            subtitle: 'Pending, assigned, in-transit, and completed records',
          ),
        ),
      ],
    );
  }

  Widget _buildChartPlaceholder({
    required String title,
    required IconData icon,
    required String subtitle,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Chart Placeholder',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDeliveriesSection({
    required bool isMobile,
    required List<Map<String, dynamic>> records,
  }) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 18 : 24),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Deliveries',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Latest delivery request records',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isMobile)
                  TextButton.icon(
                    onPressed: _refreshDashboard,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Refresh'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (records.isEmpty)
            _buildEmptyDeliveries()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final bool compact = isMobile || constraints.maxWidth < 980;

                if (compact) {
                  return Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: records.map((record) {
                        return _buildCompactDeliveryCard(record);
                      }).toList(),
                    ),
                  );
                }

                return Column(
                  children: records.map((record) {
                    return _buildWideDeliveryTile(record);
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyDeliveries() {
    return const Padding(
      padding: EdgeInsets.all(42),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 52,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 16),
            Text(
              'No Recent Deliveries',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Recent delivery records will appear here.',
              style: TextStyle(
                color: AppColors.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideDeliveryTile(Map<String, dynamic> record) {
    final customer = record['customer'];
    final status = record['delivery_status']?['statusname'] ?? 'Pending';
    final requestID = record['requestid']?.toString() ?? 'N/A';
    final customerName = _customerName(customer);
    final date = _formatDate(record['requestdatetime']?.toString());
    final time = _formatTime(record['requestdatetime']?.toString());

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          _DeliveryIcon(status: status),
          const SizedBox(width: 14),
          SizedBox(
            width: 110,
            child: Text(
              requestID,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 136,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: StatusBadge(status: status),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              customerName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Text(
            date,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 18),
          SizedBox(
            width: 78,
            child: Text(
              time,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDeliveryCard(Map<String, dynamic> record) {
    final customer = record['customer'];
    final status = record['delivery_status']?['statusname'] ?? 'Pending';
    final requestID = record['requestid']?.toString() ?? 'N/A';
    final customerName = _customerName(customer);
    final date = _formatDate(record['requestdatetime']?.toString());
    final time = _formatTime(record['requestdatetime']?.toString());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _DeliveryIcon(status: status),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      requestID,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 14),
              _InfoRow(
                icon: Icons.person_outline,
                label: 'Customer',
                value: customerName,
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: date,
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.access_time_rounded,
                label: 'Time',
                value: time,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBox(String error) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.cancelled,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: AppColors.cancelled,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeaderStatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.white,
            size: 16,
          ),
          const SizedBox(width: 7),
          Text(
            '$label: $value',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryIcon extends StatelessWidget {
  final String status;

  const _DeliveryIcon({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    final Color iconColor;
    final Color bgColor;

    if (normalized == 'pending') {
      iconColor = AppColors.pending;
      bgColor = AppColors.pendingBg;
    } else if (normalized == 'assigned') {
      iconColor = AppColors.assigned;
      bgColor = AppColors.assignedBg;
    } else if (normalized == 'in-transit' || normalized == 'in transit') {
      iconColor = AppColors.inTransit;
      bgColor = AppColors.inTransitBg;
    } else if (normalized == 'completed') {
      iconColor = AppColors.completed;
      bgColor = AppColors.completedBg;
    } else if (normalized == 'cancelled' || normalized == 'canceled') {
      iconColor = AppColors.cancelled;
      bgColor = AppColors.cancelledBg;
    } else {
      iconColor = AppColors.primary;
      bgColor = AppColors.primaryLight;
    }

    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.16),
        ),
      ),
      child: Icon(
        Icons.receipt_long_outlined,
        color: iconColor,
        size: 20,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 74,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}