import 'package:defsystem/core/theme/app_colors.dart';
import 'package:defsystem/core/theme/app_spacing.dart';
import 'package:defsystem/providers/report_provider.dart';
import 'package:defsystem/screens/shared/buttons/export_button.dart';
import 'package:defsystem/screens/shared/buttons/primary_button.dart';
import 'package:defsystem/screens/shared/buttons/secondary_button.dart';
import 'package:defsystem/screens/shared/components/app_card.dart';
import 'package:defsystem/screens/shared/components/date_time_header.dart';
import 'package:defsystem/screens/shared/forms/form_text_field.dart';
import 'package:defsystem/screens/shared/status/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum ReportPeriod {
  daily,
  weekly,
  monthly,
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  ReportPeriod _selectedPeriod = ReportPeriod.daily;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _refreshReports() async {
    await ref.read(reportProvider.notifier).loadAll();
  }

  void _applyFilter() {
    final startText = _startDateController.text.trim();
    final endText = _endDateController.text.trim();

    final startDate = startText.isEmpty ? null : DateTime.tryParse(startText);
    final endDate = endText.isEmpty ? null : DateTime.tryParse(endText);

    if (startText.isNotEmpty && startDate == null) {
      _showError('Invalid start date. Use YYYY-MM-DD.');
      return;
    }

    if (endText.isNotEmpty && endDate == null) {
      _showError('Invalid end date. Use YYYY-MM-DD.');
      return;
    }

    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      _showError('Start date cannot be later than end date.');
      return;
    }

    ref.read(reportProvider.notifier).setDateRange(startDate, endDate);
    ref.read(reportProvider.notifier).loadAll();
  }

  void _clearFilter() {
    _startDateController.clear();
    _endDateController.clear();
    ref.read(reportProvider.notifier).clearDateRange();
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.cancelled,
      ),
    );
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return 'N/A';

    try {
      return DateFormat('MMM dd, yyyy • hh:mm a').format(
        DateTime.parse(dateStr).toLocal(),
      );
    } catch (_) {
      return 'N/A';
    }
  }

  String? _firstValue(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return null;

    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return null;
  }

  String _customerName(Map<String, dynamic>? customer) {
    if (customer == null) return 'N/A';

    final parts = [
      customer['custfname'],
      customer['custmname'],
      customer['custlname'],
    ].where((value) {
      return value != null && value.toString().trim().isNotEmpty;
    }).toList();

    if (parts.isEmpty) return 'N/A';
    return parts.join(' ');
  }

  String _staffName(Map<String, dynamic>? staff) {
    if (staff == null) return 'N/A';

    final parts = [
      staff['first_name'],
      staff['middle_name'],
      staff['last_name'],
    ].where((value) {
      return value != null && value.toString().trim().isNotEmpty;
    }).toList();

    if (parts.isEmpty) return 'N/A';
    return parts.join(' ');
  }

  Map<String, dynamic>? _latestAssignment(Map<String, dynamic> record) {
    final assignment = record['delivery_assignment'];

    if (assignment is List) {
      if (assignment.isEmpty) return null;

      final first = assignment.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);

      return null;
    }

    if (assignment is Map<String, dynamic>) return assignment;
    if (assignment is Map) return Map<String, dynamic>.from(assignment);

    return null;
  }

  String _statusName(Map<String, dynamic> record) {
    return record['delivery_status']?['statusname']?.toString() ?? 'Pending';
  }

  DateTime? _requestDate(Map<String, dynamic> record) {
    final raw = record['requestdatetime']?.toString();

    if (raw == null || raw.trim().isEmpty) return null;

    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _periodLabel(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.daily:
        return 'Daily';
      case ReportPeriod.weekly:
        return 'Weekly';
      case ReportPeriod.monthly:
        return 'Monthly';
    }
  }

  DateTime _weekStart(DateTime date) {
    return DateTime(date.year, date.month, date.day).subtract(
      Duration(days: date.weekday - 1),
    );
  }

  String _reportKey(DateTime date) {
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        return DateFormat('yyyy-MM-dd').format(date);
      case ReportPeriod.weekly:
        return DateFormat('yyyy-MM-dd').format(_weekStart(date));
      case ReportPeriod.monthly:
        return DateFormat('yyyy-MM').format(date);
    }
  }

  String _reportLabel(DateTime date) {
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        return DateFormat('MMM dd, yyyy').format(date);

      case ReportPeriod.weekly:
        final start = _weekStart(date);
        final end = start.add(const Duration(days: 6));

        return '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd, yyyy').format(end)}';

      case ReportPeriod.monthly:
        return DateFormat('MMMM yyyy').format(date);
    }
  }

  List<_PeriodReport> _buildPeriodReports(List<Map<String, dynamic>> records) {
    final grouped = <String, _PeriodReport>{};

    for (final record in records) {
      final date = _requestDate(record);
      if (date == null) continue;

      final key = _reportKey(date);
      final label = _reportLabel(date);
      final status = _statusName(record).toLowerCase();

      grouped.putIfAbsent(
        key,
            () => _PeriodReport(
          key: key,
          label: label,
        ),
      );

      final report = grouped[key]!;
      report.total++;

      if (status == 'pending') {
        report.pending++;
      } else if (status == 'assigned') {
        report.assigned++;
      } else if (status == 'in-transit' || status == 'in transit') {
        report.inTransit++;
      } else if (status == 'completed' || status == 'delivered') {
        report.completed++;
      } else if (status == 'cancelled' || status == 'canceled') {
        report.cancelled++;
      }
    }

    return grouped.values.toList()..sort((a, b) => b.key.compareTo(a.key));
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

    final records = reportState.deliveryRecords;
    final riderPerformance = reportState.riderPerformance;
    final summary = reportState.summary;
    final periodReports = _buildPeriodReports(records);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 760;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshReports,
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
                  _buildHeader(
                    isMobile: isMobile,
                    summary: summary,
                    periodReports: periodReports,
                  ),
                  SizedBox(height: isMobile ? 18 : 24),
                  _buildFilters(isMobile),
                  SizedBox(height: isMobile ? 18 : 24),
                  _buildOverviewCards(
                    summary: summary,
                    isMobile: isMobile,
                  ),
                  SizedBox(height: isMobile ? 18 : 24),
                  _buildTabs(),
                  const SizedBox(height: 16),
                  if (reportState.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(36),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (reportState.error != null)
                    _buildErrorBox(reportState.error!)
                  else
                    _buildActiveTabContent(
                      periodReports: periodReports,
                      records: records,
                      riderPerformance: riderPerformance,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({
    required bool isMobile,
    required Map<String, dynamic> summary,
    required List<_PeriodReport> periodReports,
  }) {
    final total = _toInt(summary['total']);
    final completed = _toInt(summary['completed']);
    final reports = periodReports.length;

    if (isMobile) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.20),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _HeaderIcon(
                  icon: Icons.assessment_outlined,
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Reports',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const DateTimeHeader(compact: true),
              ],
            ),
            const SizedBox(height: 26),
            const Text(
              'Performance Reports',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 1.05,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'View delivery summaries, delivery records, and rider performance.',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _HeaderStatPill(
                    icon: Icons.inventory_2_outlined,
                    label: 'Total',
                    value: '$total',
                  ),
                  const SizedBox(width: 10),
                  _HeaderStatPill(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Completed',
                    value: '$completed',
                  ),
                  const SizedBox(width: 10),
                  _HeaderStatPill(
                    icon: Icons.table_chart_outlined,
                    label: 'Reports',
                    value: '$reports',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          const _HeaderIcon(
            icon: Icons.assessment_outlined,
            large: true,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Performance Reports',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'View delivery summaries, delivery records, and rider performance.',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _HeaderStatPill(
                        icon: Icons.inventory_2_outlined,
                        label: 'Total',
                        value: '$total',
                      ),
                      const SizedBox(width: 10),
                      _HeaderStatPill(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Completed',
                        value: '$completed',
                      ),
                      const SizedBox(width: 10),
                      _HeaderStatPill(
                        icon: Icons.table_chart_outlined,
                        label: 'Reports',
                        value: '$reports',
                      ),
                    ],
                  ),
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

  Widget _buildFilters(bool isMobile) {
    return AppCard(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReportNotice(),
          const SizedBox(height: 18),
          Wrap(
            spacing: 16,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : 210,
                child: _buildPeriodSelector(),
              ),
              SizedBox(
                width: isMobile ? double.infinity : 260,
                child: FormTextField(
                  label: 'Start Date',
                  icon: Icons.calendar_today_outlined,
                  hint: 'YYYY-MM-DD',
                  controller: _startDateController,
                ),
              ),
              SizedBox(
                width: isMobile ? double.infinity : 260,
                child: FormTextField(
                  label: 'End Date',
                  icon: Icons.calendar_today_outlined,
                  hint: 'YYYY-MM-DD',
                  controller: _endDateController,
                ),
              ),
              PrimaryButton(
                label: isMobile ? 'Apply Filter' : 'Apply',
                icon: Icons.filter_alt_outlined,
                onPressed: _applyFilter,
                width: isMobile ? double.infinity : 130,
              ),
              SecondaryButton(
                label: 'Clear',
                onPressed: _clearFilter,
                width: isMobile ? double.infinity : 120,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          const SizedBox(
            width: 620,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reports are displayed as responsive cards. Printed and exported reports can use table format for formal comparison.',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ExportButton(
                label: 'Export CSV',
                color: AppColors.primary,
                onPressed: () {},
              ),
              ExportButton(
                label: 'Export PDF',
                color: AppColors.textMuted,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.date_range_outlined,
              size: 16,
              color: AppColors.textBody,
            ),
            SizedBox(width: 4),
            Text(
              'Report Type',
              style: TextStyle(
                color: AppColors.textBody,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ReportPeriod>(
          initialValue: _selectedPeriod,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.table_chart_outlined),
          ),
          items: ReportPeriod.values.map((period) {
            return DropdownMenuItem(
              value: period,
              child: Text('${_periodLabel(period)} Report'),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedPeriod = value);
          },
        ),
      ],
    );
  }

  Widget _buildOverviewCards({
    required Map<String, dynamic> summary,
    required bool isMobile,
  }) {
    final items = [
      _OverviewItem(
        title: 'Total Deliveries',
        value: '${summary['total'] ?? 0}',
        subtitle: 'All delivery records',
        icon: Icons.inventory_2_outlined,
        color: AppColors.primary,
      ),
      _OverviewItem(
        title: 'Completed',
        value: '${summary['completed'] ?? 0}',
        subtitle: 'Successfully delivered',
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.completed,
      ),
      _OverviewItem(
        title: 'Pending',
        value: '${summary['pending'] ?? 0}',
        subtitle: 'Waiting for assignment',
        icon: Icons.access_time_rounded,
        color: AppColors.pending,
      ),
      _OverviewItem(
        title: 'In Transit',
        value: '${summary['inTransit'] ?? 0}',
        subtitle: 'Currently delivering',
        icon: Icons.local_shipping_outlined,
        color: AppColors.inTransit,
      ),
      _OverviewItem(
        title: 'Cancelled',
        value: '${summary['cancelled'] ?? 0}',
        subtitle: 'Cancelled deliveries',
        icon: Icons.cancel_outlined,
        color: AppColors.cancelled,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(items.length, (index) {
          return Padding(
            padding: EdgeInsets.only(right: index == items.length - 1 ? 0 : 14),
            child: _OverviewCard(
              item: items[index],
              width: isMobile ? 235 : 260,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabs() {
    return AppCard(
      padding: const EdgeInsets.all(8),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        onTap: (index) {
          setState(() => _selectedTabIndex = index);
        },
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.table_chart_outlined, size: 18),
            text: 'Summary Report',
          ),
          Tab(
            icon: Icon(Icons.receipt_long_outlined, size: 18),
            text: 'Delivery Records',
          ),
          Tab(
            icon: Icon(Icons.directions_bike_outlined, size: 18),
            text: 'Rider Performance',
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent({
    required List<_PeriodReport> periodReports,
    required List<Map<String, dynamic>> records,
    required List<Map<String, dynamic>> riderPerformance,
  }) {
    if (_selectedTabIndex == 0) {
      return _buildSummaryReportCards(periodReports);
    }

    if (_selectedTabIndex == 1) {
      return _buildDeliveryCards(records);
    }

    return _buildRiderCards(riderPerformance);
  }

  Widget _buildSummaryReportCards(List<_PeriodReport> reports) {
    if (reports.isEmpty) {
      return _buildEmptyState('No summary report data found.');
    }

    return Column(
      children: reports.map((report) {
        final rateColor = report.completionRate >= 80
            ? AppColors.completed
            : report.completionRate >= 50
            ? AppColors.pending
            : AppColors.cancelled;

        final metrics = [
          _ReportMetric(
            label: 'Total',
            value: '${report.total}',
            icon: Icons.inventory_2_outlined,
            color: AppColors.primary,
          ),
          _ReportMetric(
            label: 'Completed',
            value: '${report.completed}',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.completed,
          ),
          _ReportMetric(
            label: 'Pending',
            value: '${report.pending}',
            icon: Icons.access_time_rounded,
            color: AppColors.pending,
          ),
          _ReportMetric(
            label: 'Assigned',
            value: '${report.assigned}',
            icon: Icons.assignment_ind_outlined,
            color: AppColors.assigned,
          ),
          _ReportMetric(
            label: 'In Transit',
            value: '${report.inTransit}',
            icon: Icons.local_shipping_outlined,
            color: AppColors.inTransit,
          ),
          _ReportMetric(
            label: 'Cancelled',
            value: '${report.cancelled}',
            icon: Icons.cancel_outlined,
            color: AppColors.cancelled,
          ),
        ];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppSpacing.radiusLg),
                      topRight: Radius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.14),
                          borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(
                          Icons.calendar_month_outlined,
                          color: AppColors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_periodLabel(_selectedPeriod)} delivery performance summary',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${report.completionRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: rateColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final cardWidth = width < 520
                          ? width
                          : width < 900
                          ? (width - 12) / 2
                          : (width - 24) / 3;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: metrics.map((metric) {
                          return _EqualReportMetricCard(
                            metric: metric,
                            width: cardWidth,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDeliveryCards(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      return _buildEmptyState('No delivery records found.');
    }

    return Column(
      children: records.map((record) {
        final customer = record['customer'];
        final status = record['delivery_status']?['statusname'] ?? 'Pending';
        final assignment = _latestAssignment(record);
        final rider = assignment?['rider'];
        final dispatcher = record['dispatcher'];

        final requestedAt = record['requestdatetime']?.toString();
        final assignedAt = _firstValue(
          assignment,
          [
            'assignmentdatetime',
            'assigneddatetime',
            'assigned_at',
            'created_at',
          ],
        );

        final finalAt = _firstValue(
          assignment,
          [
            'completeddatetime',
            'completed_datetime',
            'completed_at',
            'delivered_at',
            'deliverydatetime',
          ],
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DeliveryCardHeader(
                  requestID: record['requestid']?.toString() ?? 'N/A',
                  customerName: _customerName(customer),
                  status: status,
                ),
                const SizedBox(height: 18),
                _DetailBox(
                  icon: Icons.inventory_2_outlined,
                  label: 'Item',
                  value: record['itemdescription']?.toString() ?? 'N/A',
                  color: AppColors.primary,
                ),
                const SizedBox(height: 10),
                _DetailBox(
                  icon: Icons.location_on_outlined,
                  label: 'Pickup',
                  value: record['pickupaddress']?.toString() ?? 'N/A',
                  color: AppColors.completed,
                ),
                const SizedBox(height: 10),
                _DetailBox(
                  icon: Icons.flag_outlined,
                  label: 'Delivery',
                  value: record['deliveryaddress']?.toString() ?? 'N/A',
                  color: AppColors.assigned,
                ),
                const SizedBox(height: 10),
                _DetailBox(
                  icon: Icons.person_outline,
                  label: 'Dispatcher',
                  value: _staffName(dispatcher),
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 10),
                _DetailBox(
                  icon: Icons.directions_bike_outlined,
                  label: 'Rider',
                  value: _staffName(rider),
                  color: AppColors.inTransit,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _TimelineBox(
                      icon: Icons.edit_calendar_outlined,
                      label: 'Requested',
                      value: _formatDateTime(requestedAt),
                      color: AppColors.primary,
                    ),
                    _TimelineBox(
                      icon: Icons.assignment_turned_in_outlined,
                      label: 'Assigned',
                      value: _formatDateTime(assignedAt),
                      color: AppColors.assigned,
                    ),
                    _TimelineBox(
                      icon: Icons.event_available_outlined,
                      label: 'Final Time',
                      value: _formatDateTime(finalAt),
                      color: status.toString().toLowerCase() == 'cancelled' ||
                          status.toString().toLowerCase() == 'canceled'
                          ? AppColors.cancelled
                          : AppColors.completed,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRiderCards(List<Map<String, dynamic>> riders) {
    if (riders.isEmpty) {
      return _buildEmptyState('No rider performance data found.');
    }

    return Column(
      children: riders.map((rider) {
        final total = _toInt(rider['total']);
        final completed = _toInt(rider['completed']);
        final issues = _toInt(rider['issues']);

        final rate = total == 0
            ? '0%'
            : '${(completed / total * 100).toStringAsFixed(1)}%';

        final rateValue = total == 0 ? 0.0 : completed / total;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RiderCardHeader(
                  name: rider['name']?.toString() ?? 'N/A',
                  contact: rider['contactnumber']?.toString() ?? 'N/A',
                  rate: rate,
                  rateValue: rateValue,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ReportMetricPill(
                      label: 'Total',
                      value: '$total',
                      icon: Icons.inventory_2_outlined,
                      color: AppColors.primary,
                    ),
                    _ReportMetricPill(
                      label: 'Completed',
                      value: '$completed',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.completed,
                    ),
                    _ReportMetricPill(
                      label: 'In Transit',
                      value: '${rider['inTransit'] ?? 0}',
                      icon: Icons.local_shipping_outlined,
                      color: AppColors.inTransit,
                    ),
                    _ReportMetricPill(
                      label: 'Issues',
                      value: '$issues',
                      icon: Icons.report_problem_outlined,
                      color:
                      issues > 0 ? AppColors.cancelled : AppColors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _DetailBox(
                  icon: Icons.motorcycle_outlined,
                  label: 'Vehicle',
                  value: rider['vehicledetails']?.toString() ?? 'N/A',
                  color: AppColors.assigned,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String message) {
    return AppCard(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
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

class _PeriodReport {
  final String key;
  final String label;

  int total = 0;
  int completed = 0;
  int pending = 0;
  int assigned = 0;
  int inTransit = 0;
  int cancelled = 0;

  _PeriodReport({
    required this.key,
    required this.label,
  });

  double get completionRate {
    if (total == 0) return 0;
    return completed / total * 100;
  }
}

class _OverviewItem {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _OverviewItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _ReportMetric {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ReportMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final bool large;

  const _HeaderIcon({
    required this.icon,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
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

class _OverviewCard extends StatelessWidget {
  final _OverviewItem item;
  final double width;

  const _OverviewCard({
    required this.item,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 22,
                ),
              ),
              const Spacer(),
              Text(
                item.value,
                style: TextStyle(
                  color: item.color,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EqualReportMetricCard extends StatelessWidget {
  final _ReportMetric metric;
  final double width;

  const _EqualReportMetricCard({
    required this.metric,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 118,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: metric.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: metric.color.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              metric.icon,
              color: metric.color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value,
                  style: TextStyle(
                    color: metric.color,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  metric.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportMetricPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ReportMetricPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: color.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TimelineBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryCardHeader extends StatelessWidget {
  final String requestID;
  final String customerName;
  final String status;

  const _DeliveryCardHeader({
    required this.requestID,
    required this.customerName,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatusIcon(status: status),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                requestID,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                customerName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        StatusBadge(status: status),
      ],
    );
  }
}

class _RiderCardHeader extends StatelessWidget {
  final String name;
  final String contact;
  final String rate;
  final double rateValue;

  const _RiderCardHeader({
    required this.name,
    required this.contact,
    required this.rate,
    required this.rateValue,
  });

  @override
  Widget build(BuildContext context) {
    final rateColor =
    rateValue >= 0.8 ? AppColors.completed : AppColors.pending;

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'R',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                contact,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: rateColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            rate,
            style: TextStyle(
              color: rateColor,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final String status;

  const _StatusIcon({
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
    } else if (normalized == 'completed' || normalized == 'delivered') {
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
      height: 48,
      width: 48,
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
        size: 22,
      ),
    );
  }
}

class _DetailBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
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
      ),
    );
  }
}