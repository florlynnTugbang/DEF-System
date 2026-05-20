import 'package:defsystem/core/theme/app_colors.dart';
import 'package:defsystem/core/theme/app_spacing.dart';
import 'package:defsystem/providers/auth_provider.dart';
import 'package:defsystem/providers/delivery_provider.dart';
import 'package:defsystem/providers/rider_provider.dart';
import 'package:defsystem/screens/shared/buttons/primary_button.dart';
import 'package:defsystem/screens/shared/components/app_card.dart';
import 'package:defsystem/screens/shared/components/date_time_header.dart';
import 'package:defsystem/screens/shared/forms/form_text_field.dart';
import 'package:defsystem/screens/shared/status/reference_badge.dart';
import 'package:defsystem/screens/shared/status/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RiderDashboard extends ConsumerStatefulWidget {
  const RiderDashboard({super.key});

  @override
  ConsumerState<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends ConsumerState<RiderDashboard> {
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      final riderID = authState.userID;

      if (riderID.isNotEmpty) {
        ref.read(riderProvider.notifier).loadActiveDelivery(riderID);
      }
    });
  }

  Future<void> _reloadDelivery(String riderID) async {
    if (riderID.isEmpty) return;
    await ref.read(riderProvider.notifier).loadActiveDelivery(riderID);
  }

  Future<void> _afterFinalDeliveryAction(String riderID) async {
    ref.read(riderProvider.notifier).clearActiveDelivery();

    if (mounted) {
      setState(() {
        _isUpdating = false;
      });
    }

    await ref.read(riderProvider.notifier).loadRiderHistory(riderID);
    await _reloadDelivery(riderID);
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

  Future<void> _markInTransit({
    required String requestID,
    required String assignmentID,
    required String riderID,
  }) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    final success = await ref.read(riderProvider.notifier).markInTransit(
      requestID: requestID,
      assignmentID: assignmentID,
    );

    await _reloadDelivery(riderID);

    if (!mounted) return;

    setState(() {
      _isUpdating = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery marked as In-Transit.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      final error = ref.read(riderProvider).error;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to update delivery status.'),
          backgroundColor: AppColors.cancelled,
        ),
      );
    }
  }

  Future<void> _showDeliveryActionDialog({
    required String requestID,
    required String riderID,
    required String assignmentID,
    required bool isCancellation,
  }) async {
    final controller = TextEditingController();
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
                      _buildDialogHeader(isCancellation),
                      const SizedBox(height: 20),
                      _buildReferenceBox(requestID),
                      const SizedBox(height: 20),
                      FormTextField(
                        label: isCancellation
                            ? 'Cancellation Reason *'
                            : 'Issue Description (Optional)',
                        icon: Icons.description_outlined,
                        hint: isCancellation
                            ? 'Explain why the delivery is being cancelled...'
                            : 'Describe any issue encountered during delivery...',
                        maxLines: 5,
                        controller: controller,
                      ),
                      if (isCancellation) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'A cancellation incident report will be automatically logged for dispatcher review.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
                              label: isCancellation
                                  ? 'Confirm Cancellation'
                                  : 'No Issues — Complete Delivery',
                              icon: isCancellation
                                  ? Icons.cancel_outlined
                                  : Icons.check_circle_outline_rounded,
                              color: isCancellation
                                  ? AppColors.cancelled
                                  : AppColors.completed,
                              onPressed: () async {
                                if (_isUpdating) return;

                                if (isCancellation &&
                                    controller.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please provide a cancellation reason.',
                                      ),
                                      backgroundColor: AppColors.cancelled,
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() {
                                  isSubmitting = true;
                                });

                                if (mounted) {
                                  setState(() {
                                    _isUpdating = true;
                                  });
                                }

                                Navigator.pop(dialogContext);

                                try {
                                  if (isCancellation) {
                                    await ref
                                        .read(deliveryProvider.notifier)
                                        .cancelDelivery(
                                      requestID: requestID,
                                      riderID: riderID,
                                      assignmentID: assignmentID,
                                      cancellationReason:
                                      controller.text.trim(),
                                    );

                                    if (!mounted) return;

                                    ref
                                        .read(riderProvider.notifier)
                                        .clearActiveDelivery();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Delivery cancelled. Incident report logged.',
                                        ),
                                        backgroundColor: AppColors.cancelled,
                                      ),
                                    );
                                  } else {
                                    await ref
                                        .read(deliveryProvider.notifier)
                                        .completeDelivery(
                                      requestID: requestID,
                                      riderID: riderID,
                                      assignmentID: assignmentID,
                                    );

                                    if (!mounted) return;

                                    ref
                                        .read(riderProvider.notifier)
                                        .clearActiveDelivery();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Delivery completed successfully.',
                                        ),
                                        backgroundColor: AppColors.completed,
                                      ),
                                    );
                                  }

                                  await _afterFinalDeliveryAction(riderID);
                                } catch (e) {
                                  if (!mounted) return;

                                  setState(() {
                                    _isUpdating = false;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceFirst(
                                          'Exception: ',
                                          '',
                                        ),
                                      ),
                                      backgroundColor: AppColors.cancelled,
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            if (!isCancellation)
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.pending,
                                    side: const BorderSide(
                                      color: AppColors.pending,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd,
                                      ),
                                    ),
                                  ),
                                  onPressed: _isUpdating
                                      ? null
                                      : () async {
                                    if (controller.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please describe the issue.',
                                          ),
                                          backgroundColor:
                                          AppColors.cancelled,
                                        ),
                                      );
                                      return;
                                    }

                                    setDialogState(() {
                                      isSubmitting = true;
                                    });

                                    if (mounted) {
                                      setState(() {
                                        _isUpdating = true;
                                      });
                                    }

                                    Navigator.pop(dialogContext);

                                    try {
                                      await ref
                                          .read(
                                        deliveryProvider.notifier,
                                      )
                                          .reportIssue(
                                        requestID: requestID,
                                        riderID: riderID,
                                        assignmentID: assignmentID,
                                        description:
                                        controller.text.trim(),
                                      );

                                      if (!mounted) return;

                                      ref
                                          .read(riderProvider.notifier)
                                          .clearActiveDelivery();

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Delivery completed and issue report submitted.',
                                          ),
                                          backgroundColor:
                                          AppColors.pending,
                                        ),
                                      );

                                      await _afterFinalDeliveryAction(
                                        riderID,
                                      );
                                    } catch (e) {
                                      if (!mounted) return;

                                      setState(() {
                                        _isUpdating = false;
                                      });

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            e.toString().replaceFirst(
                                              'Exception: ',
                                              '',
                                            ),
                                          ),
                                          backgroundColor:
                                          AppColors.cancelled,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.error_outline),
                                  label: const Text(
                                    'Report an Issue Instead',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton(
                                onPressed: _isUpdating
                                    ? null
                                    : () => Navigator.pop(dialogContext),
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
                                  'Close',
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

  Widget _buildDialogHeader(bool isCancellation) {
    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: isCancellation
                ? AppColors.cancelledBg
                : AppColors.completedBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            isCancellation
                ? Icons.cancel_outlined
                : Icons.check_circle_outline_rounded,
            color: isCancellation ? AppColors.cancelled : AppColors.completed,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCancellation ? 'Cancel Delivery' : 'Delivery Confirmation',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                isCancellation
                    ? 'Provide a reason for cancellation.'
                    : 'Complete the delivery or report an issue.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReferenceBox(String requestID) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Reference: $requestID',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final riderState = ref.watch(riderProvider);
    final authState = ref.watch(authProvider);

    final activeDelivery = riderState.activeDelivery;
    final riderID = authState.userID;
    final riderName =
    authState.displayName.isNotEmpty ? authState.displayName : 'Rider';

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 760;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                if (riderID.isNotEmpty) {
                  await _reloadDelivery(riderID);
                }
              },
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
                      riderName: riderName,
                      isMobile: isMobile,
                      hasActiveDelivery: activeDelivery != null,
                    ),
                    SizedBox(height: isMobile ? 18 : 24),
                    if (riderState.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (!riderState.isLoading && riderState.error != null)
                      _buildErrorBox(riderState.error!),
                    if (!riderState.isLoading && activeDelivery == null)
                      _buildEmptyState(),
                    if (!riderState.isLoading && activeDelivery != null)
                      _buildActiveDeliveryCard(
                        activeDelivery: activeDelivery,
                        riderID: riderID,
                        isMobile: isMobile,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavyHeader({
    required String riderName,
    required bool isMobile,
    required bool hasActiveDelivery,
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
              _buildHeaderIcon(Icons.directions_bike_outlined),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Rider',
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
            'My Delivery Task',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hasActiveDelivery
                ? 'You have an active delivery assigned. Update the status as you progress.'
                : 'You have no active delivery assigned at the moment.',
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      )
          : Row(
        children: [
          _buildHeaderIcon(
            Icons.directions_bike_outlined,
            large: true,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rider Dashboard',
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
                  hasActiveDelivery
                      ? 'Welcome, $riderName. Review your active delivery and update its progress.'
                      : 'Welcome, $riderName. You have no assigned delivery right now.',
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

  Widget _buildEmptyState() {
    return AppCard(
      padding: const EdgeInsets.all(32),
      child: const Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 52,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 16),
          Text(
            'No Active Delivery',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You have no delivery assigned at the moment.',
            style: TextStyle(
              color: AppColors.textMuted,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDeliveryCard({
    required Map<String, dynamic> activeDelivery,
    required String riderID,
    required bool isMobile,
  }) {
    final request = activeDelivery['delivery_request'];
    final customer = request?['customer'];

    final assignmentID = activeDelivery['assignmentid']?.toString() ?? '';
    final requestID = activeDelivery['requestid']?.toString() ?? '';
    final assignmentStatus =
        activeDelivery['assignmentstatus']?.toString() ?? '';

    final specialInstructions = request?['specialinstructions'];

    final statusName =
        request?['delivery_status']?['statusname']?.toString() ??
            assignmentStatus;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildCardHeader(
            requestID: requestID,
            statusName: statusName,
            isMobile: isMobile,
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 22),
            child: Column(
              children: [
                _InfoBox(
                  icon: Icons.location_on_outlined,
                  title: 'Pickup Location',
                  content: request?['pickupaddress'] ?? 'N/A',
                  iconColor: AppColors.completed,
                  backgroundColor: AppColors.completedBg,
                  borderColor: AppColors.completed.withValues(alpha: 0.18),
                ),
                const SizedBox(height: 12),
                _InfoBox(
                  icon: Icons.flag_outlined,
                  title: 'Delivery Location',
                  content: request?['deliveryaddress'] ?? 'N/A',
                  iconColor: AppColors.assigned,
                  backgroundColor: AppColors.assignedBg,
                  borderColor: AppColors.assigned.withValues(alpha: 0.18),
                ),
                const SizedBox(height: 12),
                _InfoBox(
                  icon: Icons.inventory_2_outlined,
                  title: 'Item Details',
                  content: request?['itemdescription'] ?? 'N/A',
                  iconColor: AppColors.primary,
                  backgroundColor: AppColors.primaryLight,
                  borderColor: AppColors.primary.withValues(alpha: 0.18),
                ),
                const SizedBox(height: 12),
                _InfoBox(
                  icon: Icons.phone_outlined,
                  title: 'Customer Contact',
                  content: customer != null
                      ? '${_customerFullName(customer)}\n${customer['contactnumber'] ?? 'N/A'}'
                      : 'N/A',
                  iconColor: AppColors.textMuted,
                  backgroundColor: AppColors.surfaceSoft,
                  borderColor: AppColors.border,
                ),
                if (specialInstructions != null &&
                    specialInstructions.toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSpecialInstructionsBox(
                    specialInstructions.toString(),
                  ),
                ],
                SizedBox(height: isMobile ? 20 : 24),
                _buildActionButtons(
                  assignmentStatus: assignmentStatus,
                  requestID: requestID,
                  assignmentID: assignmentID,
                  riderID: riderID,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader({
    required String requestID,
    required String statusName,
    required bool isMobile,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusLg),
          topRight: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: isMobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Delivery',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Active delivery in progress',
            style: TextStyle(
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ReferenceBadge(referenceNumber: requestID),
              StatusBadge(status: statusName),
            ],
          ),
        ],
      )
          : Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Delivery',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Active delivery in progress',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ReferenceBadge(referenceNumber: requestID),
          const SizedBox(width: 8),
          StatusBadge(status: statusName),
        ],
      ),
    );
  }

  Widget _buildActionButtons({
    required String assignmentStatus,
    required String requestID,
    required String assignmentID,
    required String riderID,
  }) {
    if (assignmentStatus == 'Assigned') {
      return PrimaryButton(
        label: 'I\'ve Picked Up the Item',
        isLoading: _isUpdating,
        onPressed: () {
          if (_isUpdating) return;

          _markInTransit(
            requestID: requestID,
            assignmentID: assignmentID,
            riderID: riderID,
          );
        },
        color: AppColors.primary,
        icon: Icons.directions_bike_outlined,
      );
    }

    if (assignmentStatus == 'In-Transit') {
      return Column(
        children: [
          PrimaryButton(
            label: 'Item Delivered',
            isLoading: _isUpdating,
            onPressed: () {
              if (_isUpdating) return;

              _showDeliveryActionDialog(
                requestID: requestID,
                riderID: riderID,
                assignmentID: assignmentID,
                isCancellation: false,
              );
            },
            color: AppColors.completed,
            icon: Icons.check_circle_outline_rounded,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.cancelled,
                backgroundColor: AppColors.cancelledBg,
                side: BorderSide(
                  color: AppColors.cancelled.withValues(alpha: 0.20),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              onPressed: _isUpdating
                  ? null
                  : () => _showDeliveryActionDialog(
                requestID: requestID,
                riderID: riderID,
                assignmentID: assignmentID,
                isCancellation: true,
              ),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text(
                'Delivery Cancelled',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSpecialInstructionsBox(String instructions) {
    return Container(
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
          const Icon(
            Icons.info_outline,
            color: AppColors.issue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instructions,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;

  const _InfoBox({
    required this.icon,
    required this.title,
    required this.content,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 23,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    height: 1.4,
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