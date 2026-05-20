import 'package:defsystem/core/theme/app_colors.dart';
import 'package:defsystem/core/theme/app_spacing.dart';
import 'package:defsystem/providers/auth_provider.dart';
import 'package:defsystem/providers/report_provider.dart';
import 'package:defsystem/screens/shared/buttons/export_button.dart';
import 'package:defsystem/screens/shared/buttons/primary_button.dart';
import 'package:defsystem/screens/shared/buttons/secondary_button.dart';
import 'package:defsystem/screens/shared/cards/summary_card.dart';
import 'package:defsystem/screens/shared/components/app_card.dart';
import 'package:defsystem/screens/shared/components/date_time_header.dart';
import 'package:defsystem/screens/shared/forms/form_text_field.dart';
import 'package:defsystem/screens/shared/status/status_badge.dart';
import 'package:defsystem/services/delivery_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class IssuesLogScreen extends ConsumerStatefulWidget {
  const IssuesLogScreen({super.key});

  @override
  ConsumerState<IssuesLogScreen> createState() => _IssuesLogScreenState();
}

class _IssuesLogScreenState extends ConsumerState<IssuesLogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  final ScrollController _customerScrollController = ScrollController();
  final ScrollController _riderCompletedScrollController = ScrollController();
  final ScrollController _riderCancelledScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportProvider.notifier).loadIssues();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _customerScrollController.dispose();
    _riderCompletedScrollController.dispose();
    _riderCancelledScrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshIssues() async {
    await ref.read(reportProvider.notifier).loadIssues();
  }

  void _applyFilter() {
    final startDate = DateTime.tryParse(_startDateController.text.trim());
    final endDate = DateTime.tryParse(_endDateController.text.trim());

    ref.read(reportProvider.notifier).setDateRange(startDate, endDate);
    ref.read(reportProvider.notifier).loadIssues();
  }

  void _clearFilter() {
    _startDateController.clear();
    _endDateController.clear();

    ref.read(reportProvider.notifier).clearDateRange();
  }

  String _cleanText(String text) {
    return text
        .replaceAll('\u0000', '')
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
        .trim();
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return 'N/A';

    try {
      return DateFormat('MMM dd, yyyy • hh:mm a')
          .format(DateTime.parse(dateStr).toLocal());
    } catch (_) {
      return 'N/A';
    }
  }

  String _personName(Map<String, dynamic>? person) {
    if (person == null) return 'N/A';

    final parts = [
      person['first_name'],
      person['middle_name'],
      person['last_name'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).toList();

    if (parts.isEmpty) return 'N/A';

    return parts.join(' ');
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

  String _issueTypeLabel(String type) {
    switch (type) {
      case 'customer':
        return 'Customer Complaint';
      case 'rider_completed':
        return 'Rider Issue - Completed Delivery';
      case 'rider_cancelled':
        return 'Rider Issue - Cancelled Delivery';
      default:
        return type;
    }
  }

  String _resolverLabel(String issueType) {
    switch (issueType) {
      case 'customer':
        return 'Dispatcher or Management';
      case 'rider_completed':
        return 'Management only';
      case 'rider_cancelled':
        return 'Dispatcher or Management';
      default:
        return 'Authorized Staff';
    }
  }

  bool _canResolveIssue({
    required String userRole,
    required String issueType,
  }) {
    if (issueType == 'customer') {
      return userRole == 'dispatcher' || userRole == 'admin';
    }

    if (issueType == 'rider_cancelled') {
      return userRole == 'dispatcher' || userRole == 'admin';
    }

    if (issueType == 'rider_completed') {
      return userRole == 'admin';
    }

    return false;
  }

  String _permissionMessage(String issueType) {
    if (issueType == 'customer') {
      return 'Only dispatchers or management can resolve customer complaints.';
    }

    if (issueType == 'rider_cancelled') {
      return 'Only dispatchers or management can resolve cancelled delivery issues.';
    }

    if (issueType == 'rider_completed') {
      return 'Only management can resolve rider issues on completed deliveries.';
    }

    return 'You do not have permission to resolve this issue.';
  }

  Future<void> _showResolveDialog(Map<String, dynamic> issue) async {
    final authState = ref.read(authProvider);

    final userRole = authState.role ?? authState.userData?['role'] ?? '';
    final issueType = issue['issue_type']?.toString() ?? '';
    final issueID = issue['issueid']?.toString() ?? '';

    final canResolve = _canResolveIssue(
      userRole: userRole,
      issueType: issueType,
    );

    if (!canResolve) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_permissionMessage(issueType)),
          backgroundColor: AppColors.cancelled,
        ),
      );
      return;
    }

    final notesController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bool isMobile = MediaQuery.of(context).size.width < 700;

            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 40,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 20 : 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: AppColors.completedBg,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                            child: const Icon(
                              Icons.check_circle_outline_rounded,
                              color: AppColors.completed,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Resolve Issue',
                                  style: TextStyle(
                                    color: AppColors.textDark,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'Issue ID: $issueID',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Type: ${_issueTypeLabel(issueType)}',
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Resolver: ${_resolverLabel(issueType)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textBody,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Description: ${issue['description'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      FormTextField(
                        label: 'Resolution Notes',
                        icon: Icons.notes_outlined,
                        hint: 'Describe how this issue was resolved...',
                        maxLines: 4,
                        controller: notesController,
                      ),
                      const SizedBox(height: 24),
                      if (isSubmitting)
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PrimaryButton(
                              label: 'Mark as Resolved',
                              icon: Icons.check_circle_outline_rounded,
                              onPressed: () async {
                                final cleanNotes =
                                _cleanText(notesController.text);

                                if (cleanNotes.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please add resolution notes.',
                                      ),
                                      backgroundColor: AppColors.cancelled,
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() {
                                  isSubmitting = true;
                                });

                                try {
                                  await DeliveryService().resolveIssue(
                                    issueID: issueID,
                                    resolvedBy: authState.userID,
                                    resolutionNotes: cleanNotes,
                                  );

                                  if (!mounted) return;

                                  Navigator.pop(dialogContext);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Issue resolved successfully.',
                                      ),
                                      backgroundColor: AppColors.completed,
                                    ),
                                  );

                                  ref
                                      .read(reportProvider.notifier)
                                      .loadIssues();
                                } catch (e) {
                                  if (!mounted) return;

                                  setDialogState(() {
                                    isSubmitting = false;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e
                                            .toString()
                                            .replaceFirst('Exception: ', ''),
                                      ),
                                      backgroundColor: AppColors.cancelled,
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 46,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: AppColors.textBody,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);
    final authState = ref.watch(authProvider);
    final userRole = authState.role ?? authState.userData?['role'] ?? '';

    final customerIssues = reportState.customerIssues;
    final riderCompletedIssues = reportState.riderCompletedIssues;
    final riderCancelledIssues = reportState.riderCancelledIssues;

    final totalIssues = reportState.issues.length;
    final resolvedCount = reportState.resolvedCount;
    final unresolvedCount = totalIssues - resolvedCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 760;

        return Container(
          color: AppColors.background,
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshIssues,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 32,
                isMobile ? 18 : 32,
                isMobile ? 16 : 32,
                isMobile ? 110 : 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavyHeader(
                    isMobile: isMobile,
                    totalIssues: totalIssues,
                    resolvedCount: resolvedCount,
                    unresolvedCount: unresolvedCount,
                  ),
                  SizedBox(height: isMobile ? 18 : 24),
                  _buildFilters(isMobile),
                  SizedBox(height: isMobile ? 18 : 24),
                  _buildSummaryCarousel(
                    isMobile: isMobile,
                    totalIssues: totalIssues,
                    customerCount: customerIssues.length,
                    riderCompletedCount: riderCompletedIssues.length,
                    riderCancelledCount: riderCancelledIssues.length,
                    resolvedCount: resolvedCount,
                  ),
                  SizedBox(height: isMobile ? 18 : 24),
                  _buildIssuePanel(
                    isMobile: isMobile,
                    isLoading: reportState.isLoading,
                    error: reportState.error,
                    userRole: userRole,
                    customerIssues: customerIssues,
                    riderCompletedIssues: riderCompletedIssues,
                    riderCancelledIssues: riderCancelledIssues,
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
    required int totalIssues,
    required int resolvedCount,
    required int unresolvedCount,
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
              _buildHeaderIcon(Icons.report_problem_outlined),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Issues',
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
          const Text(
            'Delivery Incident Reports',
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
            'Monitor customer complaints and rider-submitted incidents.',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          _buildHeaderStats(
            totalIssues: totalIssues,
            resolvedCount: resolvedCount,
            unresolvedCount: unresolvedCount,
          ),
        ],
      )
          : Row(
        children: [
          _buildHeaderIcon(
            Icons.report_problem_outlined,
            large: true,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Incident Reports',
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
                  'Monitor customer complaints and rider-submitted incidents.',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                _buildHeaderStats(
                  totalIssues: totalIssues,
                  resolvedCount: resolvedCount,
                  unresolvedCount: unresolvedCount,
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
    required int totalIssues,
    required int resolvedCount,
    required int unresolvedCount,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _HeaderStatPill(
            icon: Icons.report_problem_outlined,
            label: 'Total',
            value: '$totalIssues',
          ),
          const SizedBox(width: 10),
          _HeaderStatPill(
            icon: Icons.pending_actions_outlined,
            label: 'Unresolved',
            value: '$unresolvedCount',
          ),
          const SizedBox(width: 10),
          _HeaderStatPill(
            icon: Icons.verified_outlined,
            label: 'Resolved',
            value: '$resolvedCount',
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isMobile) {
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

  Widget _buildSummaryCarousel({
    required bool isMobile,
    required int totalIssues,
    required int customerCount,
    required int riderCompletedCount,
    required int riderCancelledCount,
    required int resolvedCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const gap = 14.0;

        final desktopCardWidth = ((availableWidth - (gap * 3)) / 4).clamp(
          220.0,
          320.0,
        );

        final cardWidth = isMobile ? 235.0 : desktopCardWidth;

        final cards = [
          SummaryCard(
            title: 'Total Issues',
            value: '$totalIssues',
            icon: Icons.report_problem_outlined,
            color: AppColors.cancelled,
            subtitle: 'All incident records',
            width: cardWidth,
          ),
          SummaryCard(
            title: 'Customer',
            value: '$customerCount',
            icon: Icons.person_outline,
            color: AppColors.pending,
            subtitle: 'Customer complaints',
            width: cardWidth,
          ),
          SummaryCard(
            title: 'Rider Completed',
            value: '$riderCompletedCount',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.primary,
            subtitle: 'Completed delivery issues',
            width: cardWidth,
          ),
          SummaryCard(
            title: 'Rider Cancelled',
            value: '$riderCancelledCount',
            icon: Icons.cancel_outlined,
            color: AppColors.inTransit,
            subtitle: 'Cancelled delivery issues',
            width: cardWidth,
          ),
          SummaryCard(
            title: 'Resolved',
            value: '$resolvedCount',
            icon: Icons.verified_outlined,
            color: AppColors.completed,
            subtitle: 'Closed issue records',
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

  Widget _buildIssuePanel({
    required bool isMobile,
    required bool isLoading,
    required String? error,
    required String userRole,
    required List<Map<String, dynamic>> customerIssues,
    required List<Map<String, dynamic>> riderCompletedIssues,
    required List<Map<String, dynamic>> riderCancelledIssues,
  }) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: _buildTabs(
              isMobile: isMobile,
              customerCount: customerIssues.length,
              riderCompletedCount: riderCompletedIssues.length,
              riderCancelledCount: riderCancelledIssues.length,
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
          else
            SizedBox(
              height: isMobile ? 740 : 620,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildIssueContent(
                    issues: customerIssues,
                    scrollController: _customerScrollController,
                    resolverLabel: 'Dispatcher or Management',
                    isMobile: isMobile,
                    userRole: userRole,
                  ),
                  _buildIssueContent(
                    issues: riderCompletedIssues,
                    scrollController: _riderCompletedScrollController,
                    resolverLabel: 'Management only',
                    isMobile: isMobile,
                    userRole: userRole,
                  ),
                  _buildIssueContent(
                    issues: riderCancelledIssues,
                    scrollController: _riderCancelledScrollController,
                    resolverLabel: 'Dispatcher or Management',
                    isMobile: isMobile,
                    userRole: userRole,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabs({
    required bool isMobile,
    required int customerCount,
    required int riderCompletedCount,
    required int riderCancelledCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline, size: 16),
                const SizedBox(width: 6),
                Text('Customer ($customerCount)'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, size: 16),
                const SizedBox(width: 6),
                Text('Rider Completed ($riderCompletedCount)'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cancel_outlined, size: 16),
                const SizedBox(width: 6),
                Text('Rider Cancelled ($riderCancelledCount)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueContent({
    required List<Map<String, dynamic>> issues,
    required ScrollController scrollController,
    required String resolverLabel,
    required bool isMobile,
    required String userRole,
  }) {
    return _buildIssueCards(
      issues: issues,
      resolverLabel: resolverLabel,
      userRole: userRole,
    );
  }

  Widget _buildIssueCards({
    required List<Map<String, dynamic>> issues,
    required String resolverLabel,
    required String userRole,
  }) {
    if (issues.isEmpty) {
      return _buildEmptyIssues();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: issues.length,
      itemBuilder: (context, index) {
        final issue = issues[index];
        final request = issue['delivery_request'];
        final customer = request?['customer'];
        final rider = issue['rider'];
        final resolved = issue['resolvedflag'] == true;
        final issueType = issue['issue_type']?.toString() ?? '';
        final canResolve = _canResolveIssue(
          userRole: userRole,
          issueType: issueType,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _IssueTypeIcon(issueType: issueType),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          issue['issueid']?.toString() ?? 'N/A',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      StatusBadge(
                        status: resolved ? 'Resolved' : 'Pending',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _issueTypeLabel(issueType),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _MobileInfoRow(
                    label: 'Reference',
                    value: issue['requestid']?.toString() ?? 'N/A',
                  ),
                  _MobileInfoRow(
                    label: 'Customer',
                    value: _customerName(customer),
                  ),
                  _MobileInfoRow(
                    label: 'Rider',
                    value: _personName(rider),
                  ),
                  _MobileInfoRow(
                    label: 'Reported',
                    value: _formatDateTime(
                      issue['datetimereported']?.toString(),
                    ),
                  ),
                  _MobileInfoRow(
                    label: 'Resolved By',
                    value: resolved
                        ? issue['resolvedby']?.toString() ?? 'N/A'
                        : '—',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    issue['description']?.toString() ?? 'N/A',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Resolver: $resolverLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!resolved) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: canResolve
                            ? () => _showResolveDialog(issue)
                            : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _permissionMessage(issueType),
                              ),
                              backgroundColor: AppColors.cancelled,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: canResolve
                              ? AppColors.completed
                              : AppColors.textMuted,
                          side: BorderSide(
                            color: canResolve
                                ? AppColors.completed
                                : AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                        ),
                        icon: Icon(
                          canResolve
                              ? Icons.check_circle_outline
                              : Icons.lock_outline,
                        ),
                        label: Text(
                          canResolve ? 'Resolve Issue' : 'Restricted',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
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

  Widget _buildIssuesTable({
    required List<Map<String, dynamic>> issues,
    required ScrollController scrollController,
    required String resolverLabel,
    required String userRole,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Issue Records • Resolved by: $resolverLabel',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ExportButton(
                label: 'Export CSV',
                color: AppColors.primary,
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              ExportButton(
                label: 'Export PDF',
                color: AppColors.textMuted,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: issues.isEmpty
              ? _buildEmptyIssues()
              : Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    AppColors.surfaceSoft,
                  ),
                  columnSpacing: 24,
                  horizontalMargin: 20,
                  headingTextStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                  dataTextStyle: const TextStyle(
                    color: AppColors.textBody,
                    fontSize: 13,
                  ),
                  columns: const [
                    DataColumn(label: Text('ISSUE ID')),
                    DataColumn(label: Text('REFERENCE')),
                    DataColumn(label: Text('CUSTOMER')),
                    DataColumn(label: Text('RIDER')),
                    DataColumn(label: Text('DESCRIPTION')),
                    DataColumn(label: Text('REPORTED')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('RESOLVED BY')),
                    DataColumn(label: Text('ACTION')),
                  ],
                  rows: issues.map((issue) {
                    final request = issue['delivery_request'];
                    final customer = request?['customer'];
                    final rider = issue['rider'];
                    final resolved = issue['resolvedflag'] == true;
                    final issueType =
                        issue['issue_type']?.toString() ?? '';
                    final canResolve = _canResolveIssue(
                      userRole: userRole,
                      issueType: issueType,
                    );

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            issue['issueid']?.toString() ?? 'N/A',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            issue['requestid']?.toString() ?? 'N/A',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        DataCell(Text(_customerName(customer))),
                        DataCell(Text(_personName(rider))),
                        DataCell(
                          SizedBox(
                            width: 260,
                            child: Text(
                              issue['description']?.toString() ?? 'N/A',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatDateTime(
                              issue['datetimereported']?.toString(),
                            ),
                          ),
                        ),
                        DataCell(
                          StatusBadge(
                            status: resolved ? 'Resolved' : 'Pending',
                          ),
                        ),
                        DataCell(
                          resolved
                              ? Text(
                            issue['resolvedby']?.toString() ??
                                'N/A',
                            style: const TextStyle(fontSize: 12),
                          )
                              : const Text(
                            '—',
                            style: TextStyle(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        DataCell(
                          resolved
                              ? const SizedBox.shrink()
                              : TextButton.icon(
                            onPressed: canResolve
                                ? () => _showResolveDialog(issue)
                                : () {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _permissionMessage(
                                      issueType,
                                    ),
                                  ),
                                  backgroundColor:
                                  AppColors.cancelled,
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: canResolve
                                  ? AppColors.completed
                                  : AppColors.textMuted,
                            ),
                            icon: Icon(
                              canResolve
                                  ? Icons.check_circle_outline
                                  : Icons.lock_outline,
                              size: 16,
                            ),
                            label: Text(
                              canResolve
                                  ? 'Resolve'
                                  : 'Restricted',
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyIssues() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              color: AppColors.textMuted,
              size: 46,
            ),
            SizedBox(height: 12),
            Text(
              'No issues found',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Issue records will appear here once reported.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
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
                ),
              ),
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

class _IssueTypeIcon extends StatelessWidget {
  final String issueType;

  const _IssueTypeIcon({
    required this.issueType,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;

    if (issueType == 'customer') {
      color = AppColors.pending;
    } else if (issueType == 'rider_completed') {
      color = AppColors.primary;
    } else if (issueType == 'rider_cancelled') {
      color = AppColors.cancelled;
    } else {
      color = AppColors.textMuted;
    }

    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.16),
        ),
      ),
      child: Icon(
        Icons.report_problem_outlined,
        color: color,
        size: 20,
      ),
    );
  }
}

class _MobileInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _MobileInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}