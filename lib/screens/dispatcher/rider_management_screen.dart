import 'package:defsystem/core/theme/app_colors.dart';
import 'package:defsystem/core/theme/app_spacing.dart';
import 'package:defsystem/providers/rider_provider.dart';
import 'package:defsystem/screens/shared/components/app_card.dart';
import 'package:defsystem/screens/shared/components/date_time_header.dart';
import 'package:defsystem/screens/shared/status/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RiderManagementScreen extends ConsumerStatefulWidget {
  const RiderManagementScreen({super.key});

  @override
  ConsumerState<RiderManagementScreen> createState() =>
      _RiderManagementScreenState();
}

class _RiderManagementScreenState extends ConsumerState<RiderManagementScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderProvider.notifier).loadRiders();
    });
  }

  Future<void> _refreshRiders() async {
    await ref.read(riderProvider.notifier).loadRiders();
  }

  String _staffFullName(Map<String, dynamic> rider) {
    final parts = [
      rider['first_name'],
      rider['middle_name'],
      rider['last_name'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).toList();

    if (parts.isEmpty) return 'Unnamed Rider';
    return parts.join(' ');
  }

  String _contactNumber(Map<String, dynamic> rider) {
    final value = rider['contact_number'];
    if (value == null || value.toString().trim().isEmpty) return 'N/A';
    return value.toString();
  }

  String _vehicleDetails(Map<String, dynamic> rider) {
    final value = rider['vehicle_details'];
    if (value == null || value.toString().trim().isEmpty) return 'N/A';
    return value.toString();
  }

  bool _isAvailable(Map<String, dynamic> rider) {
    return rider['availability_status'] == true;
  }

  bool _isActive(Map<String, dynamic> rider) {
    return rider['is_active'] == true;
  }

  String _riderStatus(Map<String, dynamic> rider) {
    final isAvailable = _isAvailable(rider);
    final isActive = _isActive(rider);

    if (!isActive) return 'Inactive';
    if (isAvailable) return 'Available';
    return 'On Delivery';
  }

  @override
  Widget build(BuildContext context) {
    final riderState = ref.watch(riderProvider);
    final riders = riderState.riders;

    final activeCount = riders.where(_isActive).length;
    final availableCount = riders.where((r) => _isActive(r) && _isAvailable(r)).length;
    final onDeliveryCount =
        riders.where((r) => _isActive(r) && !_isAvailable(r)).length;
    final inactiveCount = riders.where((r) => !_isActive(r)).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 760;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshRiders,
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
                    totalCount: riders.length,
                    activeCount: activeCount,
                    availableCount: availableCount,
                    onDeliveryCount: onDeliveryCount,
                    inactiveCount: inactiveCount,
                  ),
                  SizedBox(height: isMobile ? 18 : 24),
                  _buildRiderSection(
                    isMobile: isMobile,
                    isLoading: riderState.isLoading,
                    error: riderState.error,
                    riders: riders,
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
    required int totalCount,
    required int activeCount,
    required int availableCount,
    required int onDeliveryCount,
    required int inactiveCount,
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
              _buildHeaderIcon(Icons.people_outline),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Riders',
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
            'Rider Management',
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
            'View rider availability, vehicle details, and account status.',
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
            activeCount: activeCount,
            availableCount: availableCount,
            onDeliveryCount: onDeliveryCount,
            inactiveCount: inactiveCount,
          ),
        ],
      )
          : Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHeaderIcon(Icons.people_outline, large: true),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rider Management',
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
                  'View rider availability, vehicle details, and account status.',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                _buildHeaderStats(
                  totalCount: totalCount,
                  activeCount: activeCount,
                  availableCount: availableCount,
                  onDeliveryCount: onDeliveryCount,
                  inactiveCount: inactiveCount,
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
    required int activeCount,
    required int availableCount,
    required int onDeliveryCount,
    required int inactiveCount,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _HeaderStatPill(
            icon: Icons.groups_outlined,
            label: 'Total',
            value: '$totalCount',
          ),
          const SizedBox(width: 10),
          _HeaderStatPill(
            icon: Icons.verified_outlined,
            label: 'Active',
            value: '$activeCount',
          ),
          const SizedBox(width: 10),
          _HeaderStatPill(
            icon: Icons.check_circle_outline_rounded,
            label: 'Available',
            value: '$availableCount',
          ),
          const SizedBox(width: 10),
          _HeaderStatPill(
            icon: Icons.local_shipping_outlined,
            label: 'On Delivery',
            value: '$onDeliveryCount',
          ),
          const SizedBox(width: 10),
          _HeaderStatPill(
            icon: Icons.block_outlined,
            label: 'Inactive',
            value: '$inactiveCount',
          ),
        ],
      ),
    );
  }

  Widget _buildRiderSection({
    required bool isMobile,
    required bool isLoading,
    required String? error,
    required List<Map<String, dynamic>> riders,
  }) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    Icons.directions_bike_outlined,
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
                        'Rider Directory',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'All registered delivery riders',
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
                    onPressed: _refreshRiders,
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
          else if (riders.isEmpty)
              _buildEmptyState()
            else
              Padding(
                padding: EdgeInsets.all(isMobile ? 14 : 18),
                child: isMobile
                    ? _buildMobileList(riders)
                    : _buildResponsiveGrid(riders),
              ),
        ],
      ),
    );
  }

  Widget _buildResponsiveGrid(List<Map<String, dynamic>> riders) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        int crossAxisCount = 1;
        if (width >= 1100) {
          crossAxisCount = 3;
        } else if (width >= 700) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: riders.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 225,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            return _buildRiderCard(
              riders[index],
              isMobile: false,
            );
          },
        );
      },
    );
  }

  Widget _buildMobileList(List<Map<String, dynamic>> riders) {
    return Column(
      children: riders.map((rider) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRiderCard(
            rider,
            isMobile: true,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRiderCard(
      Map<String, dynamic> rider, {
        required bool isMobile,
      }) {
    final fullName = _staffFullName(rider);
    final contactNumber = _contactNumber(rider);
    final vehicleDetails = _vehicleDetails(rider);
    final isAvailable = _isAvailable(rider);
    final isActive = _isActive(rider);
    final status = _riderStatus(rider);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(fullName, isActive),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRiderHeader(
                  fullName: fullName,
                  contactNumber: contactNumber,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.motorcycle_outlined,
            label: 'Vehicle',
            value: vehicleDetails,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: isActive ? Icons.verified_outlined : Icons.block_outlined,
            label: 'Account',
            value: isActive ? 'Active account' : 'Inactive account',
            color: isActive ? AppColors.completed : AppColors.cancelled,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: isAvailable
                ? Icons.check_circle_outline_rounded
                : Icons.local_shipping_outlined,
            label: 'Availability',
            value: isAvailable && isActive
                ? 'Available for assignment'
                : isActive
                ? 'Currently on delivery'
                : 'Unavailable',
            color: isAvailable && isActive
                ? AppColors.completed
                : isActive
                ? AppColors.inTransit
                : AppColors.cancelled,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String fullName, bool isActive) {
    final initial = fullName.trim().isNotEmpty ? fullName.trim()[0].toUpperCase() : 'R';

    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryLight : AppColors.surfaceSoft,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? AppColors.primary.withValues(alpha: 0.18) : AppColors.border,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: isActive ? AppColors.primary : AppColors.textMuted,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildRiderHeader({
    required String fullName,
    required String contactNumber,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fullName,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: AppColors.textDark,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          contactNumber,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(
                  color: AppColors.cancelled,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
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
              Icons.directions_bike_outlined,
              size: 52,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 16),
            Text(
              'No Riders Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Registered riders will appear here.',
              style: TextStyle(color: AppColors.textMuted),
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
          size: 17,
          color: rowColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textBody,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: rowColor == AppColors.textMuted
                        ? AppColors.textBody
                        : rowColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}