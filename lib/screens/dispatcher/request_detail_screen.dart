import 'package:defsystem/core/theme/app_colors.dart';
import 'package:defsystem/core/theme/app_spacing.dart';
import 'package:defsystem/providers/auth_provider.dart';
import 'package:defsystem/providers/delivery_provider.dart';
import 'package:defsystem/providers/user_provider.dart';
import 'package:defsystem/screens/shared/buttons/primary_button.dart';
import 'package:defsystem/screens/shared/cards/address_card.dart';
import 'package:defsystem/screens/shared/cards/info_column.dart';
import 'package:defsystem/screens/shared/components/app_card.dart';
import 'package:defsystem/screens/shared/status/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class RequestDetailScreen extends ConsumerStatefulWidget {
  final String requestID;

  const RequestDetailScreen({
    super.key,
    required this.requestID,
  });

  @override
  ConsumerState<RequestDetailScreen> createState() =>
      _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  String? _selectedRiderID;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(deliveryProvider.notifier).loadRequest(widget.requestID);
      await ref.read(userProvider.notifier).loadAll();
    });
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dt.toLocal());
  }

  String _staffFullName(Map<String, dynamic>? staff) {
    if (staff == null) return 'N/A';

    final parts = [
      staff['first_name'],
      staff['middle_name'],
      staff['last_name'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).toList();

    if (parts.isEmpty) return 'N/A';
    return parts.join(' ');
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

  Future<void> _assignRider() async {
    if (_isAssigning) return;

    if (_selectedRiderID == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rider first.'),
          backgroundColor: AppColors.cancelled,
        ),
      );
      return;
    }

    final authState = ref.read(authProvider);
    final dispatcherID = authState.userID;

    if (dispatcherID.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dispatcher account not found. Please log in again.'),
          backgroundColor: AppColors.cancelled,
        ),
      );
      return;
    }

    setState(() {
      _isAssigning = true;
    });

    try {
      await ref.read(deliveryProvider.notifier).assignRider(
        requestID: widget.requestID,
        riderID: _selectedRiderID!,
        dispatcherID: dispatcherID,
      );

      await ref.read(deliveryProvider.notifier).loadRequest(widget.requestID);
      await ref.read(userProvider.notifier).loadAll();

      if (!mounted) return;

      setState(() {
        _selectedRiderID = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rider assigned successfully!'),
          backgroundColor: AppColors.completed,
        ),
      );
    } catch (e) {
      await ref.read(deliveryProvider.notifier).loadRequest(widget.requestID);
      await ref.read(userProvider.notifier).loadAll();

      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.cancelled,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAssigning = false;
        });
      }
    }
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(deliveryProvider);
    final userState = ref.watch(userProvider);
    final request = deliveryState.selectedRequest;

    final availableRiders = userState.staff.where((staff) {
      return staff['role'] == 'rider' &&
          staff['is_active'] == true &&
          staff['availability_status'] == true;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 760;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: deliveryState.isLoading
              ? const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          )
              : request == null
              ? _buildNotFound()
              : SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 32,
                isMobile ? 18 : 32,
                isMobile ? 16 : 32,
                isMobile ? 110 : 32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildNavyHeader(isMobile),
                      SizedBox(height: isMobile ? 18 : 24),
                      _buildMainDetailsCard(isMobile),
                      SizedBox(height: isMobile ? 18 : 24),
                      if (request.statusID == 1)
                        _buildAssignRiderSection(
                          availableRiders: availableRiders,
                          userStateLoading: userState.isLoading,
                          isMobile: isMobile,
                        ),
                      if (request.statusID != 1 &&
                          request.assignment != null)
                        _buildAssignedRiderSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: AppCard(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: const BoxDecoration(
                color: AppColors.cancelledBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppColors.cancelled,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Request not found',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The selected delivery request could not be loaded.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Back to Deliveries',
              icon: Icons.arrow_back_rounded,
              onPressed: _goBack,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavyHeader(bool isMobile) {
    final request = ref.watch(deliveryProvider).selectedRequest!;
    final status = request.deliveryStatus?['statusname'] ?? 'Pending';

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
              _buildHeaderIcon(),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Request Details',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _buildHeaderBackButton(isMobile: true),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            request.requestID,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge(status: status, large: true),
              _HeaderPill(
                icon: Icons.access_time_rounded,
                label: _formatDateTime(request.requestDateTime),
              ),
            ],
          ),
        ],
      )
          : Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHeaderIcon(large: true),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Request Details',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  request.requestID,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(status: status, large: true),
                    _HeaderPill(
                      icon: Icons.access_time_rounded,
                      label: _formatDateTime(request.requestDateTime),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildHeaderBackButton(isMobile: false),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon({bool large = false}) {
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
        Icons.receipt_long_outlined,
        color: AppColors.white,
        size: large ? 28 : 23,
      ),
    );
  }

  Widget _buildHeaderBackButton({required bool isMobile}) {
    if (isMobile) {
      return SizedBox(
        height: 44,
        width: 44,
        child: IconButton(
          onPressed: _goBack,
          tooltip: 'Back',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          icon: const Icon(
            Icons.arrow_back_rounded,
            size: 22,
          ),
        ),
      );
    }

    return SizedBox(
      width: 170,
      height: 44,
      child: TextButton.icon(
        onPressed: _goBack,
        icon: const Icon(Icons.arrow_back_rounded, size: 18),
        label: const Text('Back to Deliveries'),
        style: TextButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.textBody,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildMainDetailsCard(bool isMobile) {
    return AppCard(
      padding: EdgeInsets.all(isMobile ? 18 : 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.info_outline_rounded,
            title: 'Delivery Information',
            subtitle: 'Customer, item, instructions, and address details.',
          ),
          SizedBox(height: isMobile ? 18 : 24),
          _buildCustomerAndItemInfo(isMobile),
          _buildSpecialInstructions(),
          _buildAddresses(isMobile),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 21,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
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

  Widget _buildCustomerAndItemInfo(bool isMobile) {
    final request = ref.watch(deliveryProvider).selectedRequest!;
    final customer = request.customer;

    final customerName = _customerFullName(customer);
    final customerContact = customer?['contactnumber']?.toString();

    if (isMobile) {
      return Column(
        children: [
          InfoColumn(
            label: 'Customer Information',
            value: customerName,
            subValue: customerContact,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 14),
          InfoColumn(
            label: 'Item Details',
            value: request.itemDescription ?? 'N/A',
            icon: Icons.inventory_2_outlined,
          ),
          const SizedBox(height: 24),
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InfoColumn(
                label: 'Customer Information',
                value: customerName,
                subValue: customerContact,
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InfoColumn(
                label: 'Item Details',
                value: request.itemDescription ?? 'N/A',
                icon: Icons.inventory_2_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSpecialInstructions() {
    final request = ref.watch(deliveryProvider).selectedRequest!;

    if (request.specialInstructions == null ||
        request.specialInstructions!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.issueBg,
            border: Border.all(
              color: AppColors.issue.withValues(alpha: 0.18),
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: AppColors.issue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppColors.issue,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Special Instructions',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.issue,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.specialInstructions!,
                      style: const TextStyle(
                        color: AppColors.textBody,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAddresses(bool isMobile) {
    final request = ref.watch(deliveryProvider).selectedRequest!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Addresses',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 14),
        if (isMobile)
          Column(
            children: [
              AddressCard(
                label: 'Pickup Location',
                address: request.pickupAddress,
                color: AppColors.completed,
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),
              AddressCard(
                label: 'Delivery Location',
                address: request.deliveryAddress,
                color: AppColors.assigned,
                icon: Icons.flag_outlined,
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: AddressCard(
                  label: 'Pickup Location',
                  address: request.pickupAddress,
                  color: AppColors.completed,
                  icon: Icons.location_on_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AddressCard(
                  label: 'Delivery Location',
                  address: request.deliveryAddress,
                  color: AppColors.assigned,
                  icon: Icons.flag_outlined,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildAssignRiderSection({
    required List<Map<String, dynamic>> availableRiders,
    required bool userStateLoading,
    required bool isMobile,
  }) {
    return AppCard(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.directions_bike_outlined,
            title: 'Assign Rider',
            subtitle:
            'Select an available rider to handle this delivery request.',
          ),
          SizedBox(height: isMobile ? 18 : 22),
          if (isMobile)
            Column(
              children: [
                _buildRiderDropdown(
                  availableRiders: availableRiders,
                  userStateLoading: userStateLoading,
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: _isAssigning ? 'Assigning...' : 'Assign Rider',
                  icon: Icons.assignment_turned_in_outlined,
                  isLoading: _isAssigning,
                  onPressed: _assignRider,
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _buildRiderDropdown(
                    availableRiders: availableRiders,
                    userStateLoading: userStateLoading,
                  ),
                ),
                const SizedBox(width: 16),
                PrimaryButton(
                  label: 'Assign',
                  icon: Icons.assignment_turned_in_outlined,
                  isLoading: _isAssigning,
                  onPressed: _assignRider,
                  width: 150,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRiderDropdown({
    required List<Map<String, dynamic>> availableRiders,
    required bool userStateLoading,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedRiderID,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: userStateLoading
            ? 'Loading riders...'
            : availableRiders.isEmpty
            ? 'No available riders'
            : 'Select a rider...',
        prefixIcon: const Icon(
          Icons.person_search_outlined,
          color: AppColors.primary,
        ),
      ),
      items: availableRiders.map((rider) {
        final riderName = _staffFullName(rider);
        final vehicle = rider['vehicle_details']?.toString();

        return DropdownMenuItem<String>(
          value: rider['id']?.toString(),
          child: Text(
            vehicle != null && vehicle.isNotEmpty
                ? '$riderName • $vehicle'
                : riderName,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: availableRiders.isEmpty || _isAssigning
          ? null
          : (value) {
        setState(() {
          _selectedRiderID = value;
        });
      },
    );
  }

  Widget _buildAssignedRiderSection() {
    final request = ref.watch(deliveryProvider).selectedRequest!;
    final rider = request.assignment?['rider'];

    final riderName = _staffFullName(rider);
    final riderContact = rider?['contact_number']?.toString() ?? '';
    final riderVehicle = rider?['vehicle_details']?.toString() ?? '';

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.verified_outlined,
            title: 'Assigned Rider',
            subtitle: 'This request already has a rider assigned.',
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.directions_bike_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        riderName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (riderContact.isNotEmpty)
                        Text(
                          riderContact,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      if (riderVehicle.isNotEmpty)
                        Text(
                          riderVehicle,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderPill({
    required this.icon,
    required this.label,
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
            label,
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