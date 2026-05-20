import 'package:defsystem/core/theme/app_colors.dart';
import 'package:defsystem/core/theme/app_spacing.dart';
import 'package:defsystem/providers/auth_provider.dart';
import 'package:defsystem/providers/rider_provider.dart';
import 'package:defsystem/screens/shared/buttons/primary_button.dart';
import 'package:defsystem/screens/shared/buttons/secondary_button.dart';
import 'package:defsystem/screens/shared/components/app_card.dart';
import 'package:defsystem/screens/shared/components/date_time_header.dart';
import 'package:defsystem/screens/shared/forms/form_text_field.dart';
import 'package:defsystem/screens/shared/status/reference_badge.dart';
import 'package:defsystem/screens/shared/status/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DeliveryHistory extends ConsumerStatefulWidget {
  const DeliveryHistory({super.key});

  @override
  ConsumerState<DeliveryHistory> createState() => _DeliveryHistoryState();
}

class _DeliveryHistoryState extends ConsumerState<DeliveryHistory> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      final riderID = authState.userID;

      if (riderID.isNotEmpty) {
        ref.read(riderProvider.notifier).loadRiderHistory(riderID);
      }
    });
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  String _customerFullName(Map<String, dynamic>? customer) {
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
    if (rawDate == null || rawDate.isEmpty) return 'N/A';

    try {
      return DateFormat('MMM dd, yyyy • hh:mm a')
          .format(DateTime.parse(rawDate).toLocal());
    } catch (_) {
      return rawDate;
    }
  }

  DateTime? _historyDate(Map<String, dynamic> item) {
    final rawDate = item['completeddatetime']?.toString() ??
        item['assignmentdatetime']?.toString();

    if (rawDate == null || rawDate.trim().isEmpty) return null;

    try {
      return DateTime.parse(rawDate).toLocal();
    } catch (_) {
      return null;
    }
  }

  bool _isCompleted(Map<String, dynamic> item) {
    return item['assignmentstatus']?.toString().toLowerCase() == 'completed';
  }

  bool _isCancelled(Map<String, dynamic> item) {
    return item['assignmentstatus']?.toString().toLowerCase() == 'cancelled';
  }

  List<Map<String, dynamic>> _filteredHistory(
      List<Map<String, dynamic>> history,
      ) {
    return history.where((item) {
      final date = _historyDate(item);

      if (date == null) return false;

      if (_startDate != null) {
        final start = DateTime(
          _startDate!.year,
          _startDate!.month,
          _startDate!.day,
        );

        if (date.isBefore(start)) return false;
      }

      if (_endDate != null) {
        final end = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          23,
          59,
          59,
        );

        if (date.isAfter(end)) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _reloadHistory() async {
    final authState = ref.read(authProvider);
    final riderID = authState.userID;

    if (riderID.isNotEmpty) {
      await ref.read(riderProvider.notifier).loadRiderHistory(riderID);
    }
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

    setState(() {
      _startDate = startDate;
      _endDate = endDate;
    });
  }

  void _clearFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _startDateController.clear();
      _endDateController.clear();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.cancelled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final riderState = ref.watch(riderProvider);
    final authState = ref.watch(authProvider);

    final history = riderState.deliveryHistory;
    final filteredHistory = _filteredHistory(history);

    final riderName =
    authState.displayName.isNotEmpty ? authState.displayName : 'Rider';

    final completedCount = filteredHistory.where(_isCompleted).length;
    final cancelledCount = filteredHistory.where(_isCancelled).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 760;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _reloadHistory,
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
                    riderName: riderName,
                    totalCount: filteredHistory.length,
                    completedCount: completedCount,
                    cancelledCount: cancelledCount,
                  ),
                  SizedBox(height: isMobile ? 18 : 24),
                  _buildFilterSection(isMobile),
                  SizedBox(height: isMobile ? 18 : 24),
                  _buildHistorySection(
                    isMobile: isMobile,
                    isLoading: riderState.isLoading,
                    error: riderState.error,
                    history: filteredHistory,
                    originalCount: history.length,
                  ),
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
    required String riderName,
    required int totalCount,
    required int completedCount,
    required int cancelledCount,
  }) {
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
              _buildHeaderIcon(Icons.history_rounded),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'History',
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
            'Hello, $riderName',
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Delivery History',
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
            'Review your completed and cancelled delivery records.',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          _buildHeaderStats(
            totalCount: totalCount,
            completedCount: completedCount,
            cancelledCount: cancelledCount,
          ),
        ],
      )
          : Row(
        children: [
          _buildHeaderIcon(Icons.history_rounded, large: true),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery History',
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
                  'Welcome, $riderName. Review your completed and cancelled delivery records.',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                _buildHeaderStats(
                  totalCount: totalCount,
                  completedCount: completedCount,
                  cancelledCount: cancelledCount,
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
    required int totalCount,
    required int completedCount,
    required int cancelledCount,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _HeaderStatPill(
            icon: Icons.list_alt_outlined,
            label: 'Showing',
            value: '$totalCount',
          ),
          const SizedBox(width: 10),
          _HeaderStatPill(
            icon: Icons.check_circle_outline_rounded,
            label: 'Completed',
            value: '$completedCount',
          ),
          const SizedBox(width: 10),
          _HeaderStatPill(
            icon: Icons.cancel_outlined,
            label: 'Cancelled',
            value: '$cancelledCount',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(bool isMobile) {
    return AppCard(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: isMobile
          ? Column(
        children: [
          FormTextField(
            label: 'Start Date',
            icon: Icons.calendar_today_outlined,
            hint: 'YYYY-MM-DD',
            controller: _startDateController,
          ),
          const SizedBox(height: 14),
          FormTextField(
            label: 'End Date',
            icon: Icons.calendar_today_outlined,
            hint: 'YYYY-MM-DD',
            controller: _endDateController,
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Apply Filter',
            icon: Icons.filter_alt_outlined,
            onPressed: _applyFilter,
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Clear Filter',
            icon: Icons.close_rounded,
            onPressed: _clearFilter,
          ),
        ],
      )
          : Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: FormTextField(
              label: 'Start Date',
              icon: Icons.calendar_today_outlined,
              hint: 'YYYY-MM-DD',
              controller: _startDateController,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormTextField(
              label: 'End Date',
              icon: Icons.calendar_today_outlined,
              hint: 'YYYY-MM-DD',
              controller: _endDateController,
            ),
          ),
          const SizedBox(width: 16),
          PrimaryButton(
            label: 'Apply',
            icon: Icons.filter_alt_outlined,
            onPressed: _applyFilter,
            width: 130,
          ),
          const SizedBox(width: 10),
          SecondaryButton(
            label: 'Clear',
            icon: Icons.close_rounded,
            onPressed: _clearFilter,
            width: 120,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection({
    required bool isMobile,
    required bool isLoading,
    required String? error,
    required List<Map<String, dynamic>> history,
    required int originalCount,
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
                    Icons.route_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Records',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _startDate == null && _endDate == null
                            ? 'Completed and cancelled assignments'
                            : 'Showing ${history.length} of $originalCount records',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isMobile)
                  TextButton.icon(
                    onPressed: _reloadHistory,
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
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            )
          else if (error != null)
            _buildErrorBox(error)
          else if (history.isEmpty)
              _buildEmptyState()
            else
              Padding(
                padding: EdgeInsets.all(isMobile ? 14 : 18),
                child: Column(
                  children: history.map((item) {
                    return _buildHistoryCard(
                      item: item,
                      isMobile: isMobile,
                    );
                  }).toList(),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard({
    required Map<String, dynamic> item,
    required bool isMobile,
  }) {
    final request = item['delivery_request'];
    final customer = request?['customer'];

    final requestID = item['requestid']?.toString() ?? 'N/A';
    final status = item['assignmentstatus']?.toString() ?? 'Unknown';

    final date = _formatDate(
      item['completeddatetime']?.toString() ??
          item['assignmentdatetime']?.toString(),
    );

    final customerName = _customerFullName(customer);
    final itemDescription = request?['itemdescription']?.toString() ?? 'N/A';
    final pickupAddress = request?['pickupaddress']?.toString() ?? 'N/A';
    final deliveryAddress = request?['deliveryaddress']?.toString() ?? 'N/A';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 16 : 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReferenceBadge(referenceNumber: requestID),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusBadge(status: status),
                        _SmallInfoPill(
                          icon: Icons.access_time_rounded,
                          label: date,
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    ReferenceBadge(referenceNumber: requestID),
                    const SizedBox(width: 10),
                    StatusBadge(status: status),
                    const Spacer(),
                    _SmallInfoPill(
                      icon: Icons.access_time_rounded,
                      label: date,
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.person_outline,
                label: 'Customer',
                value: customerName,
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.inventory_2_outlined,
                label: 'Item',
                value: itemDescription,
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Pickup',
                value: pickupAddress,
                color: AppColors.completed,
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.flag_outlined,
                label: 'Drop-off',
                value: deliveryAddress,
                color: AppColors.assigned,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBox(String error) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cancelledBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.cancelled.withValues(alpha: 0.18),
          ),
        ),
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(42),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.history_rounded,
              size: 52,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 16),
            Text(
              'No Delivery History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No delivery records matched your selected date filter.',
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

class _SmallInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SmallInfoPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final rowColor = color ?? AppColors.textMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: rowColor,
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 72,
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