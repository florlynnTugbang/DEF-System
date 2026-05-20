import 'package:defsystem/core/theme/app_colors.dart';
import 'package:defsystem/core/theme/app_spacing.dart';
import 'package:defsystem/providers/auth_provider.dart';
import 'package:defsystem/providers/delivery_provider.dart';
import 'package:defsystem/screens/dispatcher/request_detail_screen.dart';
import 'package:defsystem/screens/shared/cards/summary_card.dart';
import 'package:defsystem/screens/shared/components/app_card.dart';
import 'package:defsystem/screens/shared/components/date_time_header.dart';
import 'package:defsystem/screens/shared/status/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DispatcherDashboard extends ConsumerStatefulWidget {
  const DispatcherDashboard({super.key});

  @override
  ConsumerState<DispatcherDashboard> createState() =>
      _DispatcherDashboardState();
}

class _DispatcherDashboardState extends ConsumerState<DispatcherDashboard> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deliveryProvider.notifier).loadSummary();
      ref.read(deliveryProvider.notifier).loadRequests();
    });
  }

  Future<void> _refreshDashboard() async {
    await ref.read(deliveryProvider.notifier).loadSummary();
    await ref.read(deliveryProvider.notifier).loadRequests();
  }

  String _customerName(Map<String, dynamic>? customer) {
    if (customer == null) return 'Unknown';

    final parts = [
      customer['custfname'],
      customer['custmname'],
      customer['custlname'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).toList();

    if (parts.isEmpty) return 'Unknown';
    return parts.join(' ');
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(deliveryProvider);
    final authState = ref.watch(authProvider);

    final summary = deliveryState.summary;
    final requests = deliveryState.requests;

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavyHeader(
                    isMobile: isMobile,
                    displayName: authState.displayName.isNotEmpty
                        ? authState.displayName
                        : 'Dispatcher',
                  ),
                  SizedBox(height: isMobile ? 18 : 24),
                  _buildSummaryCarousel(
                    isMobile: isMobile,
                    summary: summary,
                  ),
                  SizedBox(height: isMobile ? 22 : 28),
                  _buildRecentActivity(
                    isMobile: isMobile,
                    isLoading: deliveryState.isLoading,
                    requests: requests,
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
    required String displayName,
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
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.14),
                  borderRadius:
                  BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: AppColors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Dispatcher',
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
            'Hello, $displayName',
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Dashboard',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Monitor new requests, active deliveries, and recent dispatch activity.',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      )
          : Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              color: AppColors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dispatcher Dashboard',
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
                  'Welcome, $displayName. Monitor delivery requests and dispatch activity.',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
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

  Widget _buildSummaryCarousel({
    required bool isMobile,
    required Map<String, int> summary,
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
            title: 'Total Today',
            value: '${summary['total'] ?? 0}',
            icon: Icons.inventory_2_outlined,
            color: AppColors.primary,
            subtitle: 'Requests recorded today',
            width: cardWidth,
          ),
          SummaryCard(
            title: 'Pending',
            value: '${summary['pending'] ?? 0}',
            icon: Icons.schedule_rounded,
            color: AppColors.pending,
            subtitle: 'Waiting for assignment',
            width: cardWidth,
          ),
          SummaryCard(
            title: 'In Transit',
            value: '${summary['inTransit'] ?? 0}',
            icon: Icons.local_shipping_outlined,
            color: AppColors.inTransit,
            subtitle: 'Currently being delivered',
            width: cardWidth,
          ),
          SummaryCard(
            title: 'Completed',
            value: '${summary['completed'] ?? 0}',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.completed,
            subtitle: 'Successfully delivered',
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

  Widget _buildRecentActivity({
    required bool isMobile,
    required bool isLoading,
    required List requests,
  }) {
    return AppCard(
      padding: EdgeInsets.zero,
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 18 : 24),
            child: Row(
              children: [
                Container(
                  height: isMobile ? 48 : 42,
                  width: isMobile ? 48 : 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.timeline_outlined,
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
                        'Recent Activity',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Latest delivery requests and status updates',
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
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            )
          else if (requests.isEmpty)
            _buildEmptyState()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final compactDesktop = constraints.maxWidth < 1020;

                if (isMobile || compactDesktop) {
                  return Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: requests.take(6).map<Widget>((request) {
                        return _buildCompactRequestCard(request);
                      }).toList(),
                    ),
                  );
                }

                return Column(
                  children: requests.take(6).map<Widget>((request) {
                    return _buildWideDesktopRequestTile(request);
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Container(
              height: 58,
              width: 58,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No recent activity',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'New delivery requests will appear here.',
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

  Widget _buildWideDesktopRequestTile(dynamic request) {
    final customerName = _customerName(request.customer);
    final status = request.deliveryStatus?['statusname'] ?? 'Pending';
    final time = _formatTime(request.requestDateTime);

    return InkWell(
      onTap: () => _openRequestDetails(request.requestID),
      child: Container(
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
            _buildRequestIcon(),
            const SizedBox(width: 14),
            SizedBox(
              width: 95,
              child: Text(
                request.requestID,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 132,
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
              flex: 2,
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
            Expanded(
              flex: 4,
              child: Text(
                '${request.pickupAddress} → ${request.deliveryAddress}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 48,
              child: Text(
                time,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactRequestCard(dynamic request) {
    final customerName = _customerName(request.customer);
    final status = request.deliveryStatus?['statusname'] ?? 'Pending';
    final time = _formatTime(request.requestDateTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: () => _openRequestDetails(request.requestID),
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
                    _buildRequestIcon(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        request.requestID,
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
                const SizedBox(height: 12),
                Text(
                  customerName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.route_outlined,
                      color: AppColors.textMuted,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${request.pickupAddress} → ${request.deliveryAddress}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: AppColors.textMuted,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Requested at $time',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestIcon() {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: const Icon(
        Icons.receipt_long_outlined,
        color: AppColors.primary,
        size: 20,
      ),
    );
  }

  void _openRequestDetails(String requestID) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestDetailScreen(
          requestID: requestID,
        ),
      ),
    );
  }
}