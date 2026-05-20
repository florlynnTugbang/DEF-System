import 'package:defsystem/core/theme/app_colors.dart';
import 'package:defsystem/core/theme/app_spacing.dart';
import 'package:defsystem/models/delivery_request_model.dart';
import 'package:defsystem/providers/delivery_provider.dart';
import 'package:defsystem/screens/auth/landing_screen.dart';
import 'package:defsystem/screens/customer/issue_report_screen.dart';
import 'package:defsystem/screens/shared/buttons/primary_button.dart';
import 'package:defsystem/screens/shared/components/app_background.dart';
import 'package:defsystem/screens/shared/components/app_card.dart';
import 'package:defsystem/screens/shared/forms/form_text_field.dart';
import 'package:defsystem/screens/shared/status/reference_badge.dart';
import 'package:defsystem/screens/shared/status/status_badge.dart';
import 'package:defsystem/screens/shared/status/status_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrackDeliveryScreen extends ConsumerStatefulWidget {
  final String? initialReference;
  final String? initialContactNumber;

  const TrackDeliveryScreen({
    super.key,
    this.initialReference,
    this.initialContactNumber,
  });

  @override
  ConsumerState<TrackDeliveryScreen> createState() =>
      _TrackDeliveryScreenState();
}

class _TrackDeliveryScreenState extends ConsumerState<TrackDeliveryScreen> {
  late final TextEditingController _referenceController;
  late final TextEditingController _contactController;

  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();

    _referenceController = TextEditingController(
      text: widget.initialReference ?? '',
    );

    _contactController = TextEditingController(
      text: widget.initialContactNumber ?? '',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deliveryProvider.notifier).clearSelectedRequest();

      if (widget.initialReference != null &&
          widget.initialReference!.trim().isNotEmpty &&
          widget.initialContactNumber != null &&
          widget.initialContactNumber!.trim().isNotEmpty) {
        _trackDelivery();
      }
    });
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _trackDelivery() async {
    final reference = _referenceController.text.trim();
    final contactNumber = _contactController.text.trim();

    if (reference.isEmpty) {
      _showError('Please enter your reference number.');
      return;
    }

    if (contactNumber.isEmpty) {
      _showError('Please enter the contact number used in the request.');
      return;
    }

    setState(() {
      _hasSearched = true;
    });

    await ref.read(deliveryProvider.notifier).trackRequest(
      requestID: reference,
      contactNumber: contactNumber,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.cancelled,
      ),
    );
  }

  int _getStepFromStatus(int? statusID) {
    switch (statusID) {
      case 1:
        return 1;
      case 2:
        return 2;
      case 3:
        return 3;
      case 4:
      case 5:
      case 6:
        return 4;
      default:
        return 1;
    }
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

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(deliveryProvider);
    final request = deliveryState.selectedRequest;

    return Scaffold(
      body: AppBackground(
        useGradient: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 760;
            final double maxWidth = isMobile ? double.infinity : 920;

            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 28,
                  vertical: isMobile ? 20 : 32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildNavyHeader(isMobile),
                        const SizedBox(height: 18),
                        _buildSearchCard(
                          isMobile: isMobile,
                          isLoading: deliveryState.isLoading,
                        ),
                        const SizedBox(height: 20),
                        if (_hasSearched &&
                            request == null &&
                            !deliveryState.isLoading)
                          _buildNotFoundMessage(),
                        if (request != null)
                          _buildTrackingDetails(
                            request: request,
                            isMobile: isMobile,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavyHeader(bool isMobile) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.route_outlined,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Track Delivery',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (isMobile)
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    onPressed: _goBackHome,
                    tooltip: 'Back Home',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    icon: const Icon(
                      Icons.home_outlined,
                      size: 22,
                    ),
                  ),
                )
              else
                SizedBox(
                  width: 142,
                  height: 44,
                  child: TextButton.icon(
                    onPressed: _goBackHome,
                    icon: const Icon(Icons.home_outlined, size: 18),
                    label: const Text('Back Home'),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.textBody,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            'Where is my delivery?',
            style: TextStyle(
              color: AppColors.white,
              fontSize: isMobile ? 31 : 40,
              fontWeight: FontWeight.w900,
              height: 1.06,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Enter your reference number and contact number to view your delivery progress.',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: isMobile ? 14 : 15,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _goBackHome() {
    ref.read(deliveryProvider.notifier).clearSelectedRequest();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LandingPage(),
      ),
          (route) => false,
    );
  }

  Widget _buildSearchCard({
    required bool isMobile,
    required bool isLoading,
  }) {
    return AppCard(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            icon: Icons.verified_user_outlined,
            title: 'Verify Delivery Details',
            subtitle:
            'Use the same contact number entered when the delivery request was submitted.',
          ),
          SizedBox(height: isMobile ? 18 : 22),
          if (isMobile)
            Column(
              children: [
                _buildReferenceField(),
                const SizedBox(height: 14),
                _buildContactField(),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Track Delivery',
                  icon: Icons.search_rounded,
                  isLoading: isLoading,
                  onPressed: _trackDelivery,
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _buildReferenceField()),
                const SizedBox(width: 14),
                Expanded(child: _buildContactField()),
                const SizedBox(width: 14),
                SizedBox(
                  width: 180,
                  child: PrimaryButton(
                    label: 'Track',
                    icon: Icons.search_rounded,
                    isLoading: isLoading,
                    onPressed: _trackDelivery,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildReferenceField() {
    return FormTextField(
      label: 'Reference Number',
      icon: Icons.confirmation_number_outlined,
      hint: 'e.g., REQ1001',
      controller: _referenceController,
    );
  }

  Widget _buildContactField() {
    return FormTextField(
      label: 'Contact Number',
      icon: Icons.phone_outlined,
      hint: 'e.g., 09170000001',
      keyboardType: TextInputType.phone,
      controller: _contactController,
      onChanged: (_) {},
    );
  }

  Widget _buildNotFoundMessage() {
    return _MessageBanner(
      icon: Icons.info_outline,
      message:
      'No delivery found with the provided reference number and contact number. Please check and try again.',
      backgroundColor: AppColors.issueBg,
      borderColor: AppColors.issue.withValues(alpha: 0.18),
      iconColor: AppColors.issue,
      textColor: AppColors.issue,
    );
  }

  Widget _buildTrackingDetails({
    required DeliveryRequestModel request,
    required bool isMobile,
  }) {
    final statusName = request.deliveryStatus?['statusname'] ?? 'Pending';

    final isCompleted = request.statusID == 4;
    final isCancelled = request.statusID == 6;
    final isIssueReported = request.statusID == 5;

    final canReportIssue = isCompleted || isCancelled;

    return AppCard(
      padding: EdgeInsets.all(isMobile ? 18 : 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusHeader(
            request: request,
            statusName: statusName,
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 18 : 22),
          _buildStatusBanner(
            isCancelled: isCancelled,
            isIssueReported: isIssueReported,
          ),
          if (isCancelled || isIssueReported)
            SizedBox(height: isMobile ? 18 : 22),
          StatusStepper(
            currentStep: _getStepFromStatus(request.statusID),
            isCancelled: isCancelled,
          ),
          SizedBox(height: isMobile ? 26 : 34),
          _buildDetailsSection(
            request: request,
            isMobile: isMobile,
          ),
          _buildAssignedRiderCard(request),
          if (canReportIssue)
            _buildReportIssueSection(
              request: request,
              isCancelled: isCancelled,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader({
    required DeliveryRequestModel request,
    required String statusName,
    required bool isMobile,
  }) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Status',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ReferenceBadge(referenceNumber: request.requestID),
              StatusBadge(status: statusName, large: true),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        const Expanded(
          child: Text(
            'Delivery Status',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
        ),
        ReferenceBadge(referenceNumber: request.requestID),
        const SizedBox(width: 10),
        StatusBadge(status: statusName, large: true),
      ],
    );
  }

  Widget _buildStatusBanner({
    required bool isCancelled,
    required bool isIssueReported,
  }) {
    if (!isCancelled && !isIssueReported) {
      return const SizedBox.shrink();
    }

    if (isCancelled) {
      return _MessageBanner(
        icon: Icons.cancel_outlined,
        message: 'This delivery has been cancelled.',
        backgroundColor: AppColors.cancelledBg,
        borderColor: AppColors.cancelled.withValues(alpha: 0.18),
        iconColor: AppColors.cancelled,
        textColor: AppColors.cancelled,
      );
    }

    return _MessageBanner(
      icon: Icons.warning_amber_rounded,
      message: 'An issue has been reported for this delivery.',
      backgroundColor: AppColors.issueBg,
      borderColor: AppColors.issue.withValues(alpha: 0.18),
      iconColor: AppColors.issue,
      textColor: AppColors.issue,
    );
  }

  Widget _buildDetailsSection({
    required DeliveryRequestModel request,
    required bool isMobile,
  }) {
    final customer = request.customer;

    final deliveryDetails = {
      'Customer': _customerFullName(customer),
      'Contact': customer?['contactnumber']?.toString() ?? 'N/A',
      'Item': request.itemDescription ?? 'N/A',
      if (request.specialInstructions != null &&
          request.specialInstructions!.trim().isNotEmpty)
        'Instructions': request.specialInstructions!,
    };

    final addressDetails = {
      'Pickup': request.pickupAddress,
      'Drop-off': request.deliveryAddress,
    };

    if (isMobile) {
      return Column(
        children: [
          _DetailSection(
            title: 'Delivery Details',
            icon: Icons.inventory_2_outlined,
            items: deliveryDetails,
          ),
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Addresses',
            icon: Icons.route_outlined,
            items: addressDetails,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _DetailSection(
            title: 'Delivery Details',
            icon: Icons.inventory_2_outlined,
            items: deliveryDetails,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: _DetailSection(
            title: 'Addresses',
            icon: Icons.route_outlined,
            items: addressDetails,
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedRiderCard(DeliveryRequestModel request) {
    final assignment = request.assignment;
    final rider = assignment?['rider'];

    if (rider == null) return const SizedBox.shrink();

    final bool shouldShowRider = request.statusID == 2 ||
        request.statusID == 3 ||
        request.statusID == 4 ||
        request.statusID == 5 ||
        request.statusID == 6;

    if (!shouldShowRider) return const SizedBox.shrink();

    final riderName = _staffFullName(rider);
    final riderContact = rider['contact_number']?.toString() ?? '';
    final riderVehicle = rider['vehicle_details']?.toString() ?? '';

    return Column(
      children: [
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.16),
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
                    const Text(
                      'Assigned Rider',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      riderName,
                      style: const TextStyle(
                        color: AppColors.textBody,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (riderContact.isNotEmpty)
                      Text(
                        riderContact,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    if (riderVehicle.isNotEmpty)
                      Text(
                        riderVehicle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.verified_outlined,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportIssueSection({
    required DeliveryRequestModel request,
    required bool isCancelled,
  }) {
    return Column(
      children: [
        const SizedBox(height: 28),
        const Divider(),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cancelledBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: AppColors.cancelled.withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCancelled
                    ? 'Was there a problem with the cancellation?'
                    : 'Having a problem with your completed delivery?',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                isCancelled
                    ? 'Let us know if the cancellation caused an issue or needs review.'
                    : 'Let us know and the delivery team will review your concern.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.cancelled,
                    backgroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => IssueReportScreen(
                        requestID: request.requestID,
                        contactNumber: _contactController.text.trim(),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.report_problem_outlined),
                  label: const Text(
                    'Report an Issue',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 40,
          width: 40,
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
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
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

class _MessageBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;

  const _MessageBanner({
    required this.icon,
    required this.message,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Map<String, String> items;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final filteredItems =
    items.entries.where((entry) => entry.value.trim().isNotEmpty).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        border: Border.all(
          color: AppColors.border,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...filteredItems.map(
                (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textBody,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text: '${entry.key}: ',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: entry.value,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}