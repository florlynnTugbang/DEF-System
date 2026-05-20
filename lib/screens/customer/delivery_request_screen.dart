import 'package:defsystem/core/theme/app_colors.dart';
import 'package:defsystem/core/theme/app_spacing.dart';
import 'package:defsystem/providers/delivery_provider.dart';
import 'package:defsystem/screens/auth/landing_screen.dart';
import 'package:defsystem/screens/customer/track_delivery_screen.dart';
import 'package:defsystem/screens/shared/buttons/primary_button.dart';
import 'package:defsystem/screens/shared/buttons/secondary_button.dart';
import 'package:defsystem/screens/shared/components/app_background.dart';
import 'package:defsystem/screens/shared/components/app_card.dart';
import 'package:defsystem/screens/shared/forms/form_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeliveryRequestScreen extends ConsumerStatefulWidget {
  const DeliveryRequestScreen({super.key});

  @override
  ConsumerState<DeliveryRequestScreen> createState() =>
      _DeliveryRequestScreenState();
}

class _DeliveryRequestScreenState extends ConsumerState<DeliveryRequestScreen> {
  bool _isSubmitted = false;
  String _referenceNumber = '';

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _pickupController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _itemController = TextEditingController();
  final _instructionsController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _pickupController.dispose();
    _deliveryController.dispose();
    _itemController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    if (_firstNameController.text.trim().isEmpty) {
      _showError('Please enter your first name.');
      return false;
    }

    if (_lastNameController.text.trim().isEmpty) {
      _showError('Please enter your last name.');
      return false;
    }

    if (_contactController.text.trim().isEmpty) {
      _showError('Please enter your contact number.');
      return false;
    }

    if (_pickupController.text.trim().isEmpty) {
      _showError('Please enter a pickup address.');
      return false;
    }

    if (_deliveryController.text.trim().isEmpty) {
      _showError('Please enter a delivery address.');
      return false;
    }

    if (_itemController.text.trim().isEmpty) {
      _showError('Please enter an item description.');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.cancelled,
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_validateFields()) return;

    final request = await ref.read(deliveryProvider.notifier).createRequest(
      custFname: _firstNameController.text.trim(),
      custMname: _middleNameController.text.trim().isEmpty
          ? null
          : _middleNameController.text.trim(),
      custLname: _lastNameController.text.trim(),
      contactNumber: _contactController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      pickupAddress: _pickupController.text.trim(),
      deliveryAddress: _deliveryController.text.trim(),
      itemDescription: _itemController.text.trim(),
      specialInstructions: _instructionsController.text.trim().isEmpty
          ? null
          : _instructionsController.text.trim(),
    );

    if (!mounted) return;

    if (request != null) {
      setState(() {
        _isSubmitted = true;
        _referenceNumber = request.requestID;
      });
    } else {
      final error = ref.read(deliveryProvider).error;
      _showError(error ?? 'Failed to submit request. Please try again.');
    }
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LandingPage(),
      ),
          (route) => false,
    );
  }

  void _goToTracker() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrackDeliveryScreen(
          initialReference: _referenceNumber,
          initialContactNumber: _contactController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(deliveryProvider);

    return Scaffold(
      body: AppBackground(
        useGradient: false,
        child: _isSubmitted
            ? _buildSuccessView()
            : _buildFormView(deliveryState.isLoading),
      ),
    );
  }

  Widget _buildFormView(bool isLoading) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 760;
        final double maxWidth = isMobile ? double.infinity : 820;

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

                    AppCard(
                      padding: EdgeInsets.all(isMobile ? 18 : 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(
                            icon: Icons.person_outline,
                            title: 'Customer Information',
                            subtitle:
                            'These details will be used to verify tracking and reporting.',
                          ),
                          const SizedBox(height: 20),

                          if (isMobile)
                            _buildMobileNameFields()
                          else
                            _buildDesktopNameFields(),

                          const SizedBox(height: 18),

                          if (isMobile)
                            _buildMobileContactFields()
                          else
                            _buildDesktopContactFields(),

                          const SizedBox(height: 32),

                          _buildSectionTitle(
                            icon: Icons.local_shipping_outlined,
                            title: 'Delivery Details',
                            subtitle:
                            'Add complete addresses and item information.',
                          ),
                          const SizedBox(height: 20),

                          FormTextField(
                            label: 'Pickup Address',
                            icon: Icons.location_on_outlined,
                            hint: 'Enter pickup location',
                            controller: _pickupController,
                          ),
                          const SizedBox(height: 18),

                          FormTextField(
                            label: 'Delivery Address',
                            icon: Icons.flag_outlined,
                            hint: 'Enter delivery location',
                            controller: _deliveryController,
                          ),
                          const SizedBox(height: 18),

                          FormTextField(
                            label: 'Item Description',
                            icon: Icons.inventory_2_outlined,
                            hint: 'Documents, package, food, medicine, etc.',
                            controller: _itemController,
                          ),
                          const SizedBox(height: 18),

                          FormTextField(
                            label: 'Special Instructions (Optional)',
                            icon: Icons.notes_outlined,
                            hint: 'Any special handling or delivery instruction',
                            maxLines: 3,
                            controller: _instructionsController,
                          ),

                          const SizedBox(height: 30),

                          PrimaryButton(
                            label: 'Submit Delivery Request',
                            icon: Icons.send_outlined,
                            isLoading: isLoading,
                            onPressed: _submitRequest,
                          ),
                        ],
                      ),
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
                  Icons.add_location_alt_outlined,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'New Delivery Request',
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
                    onPressed: _goHome,
                    tooltip: 'Back Home',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                  child: SecondaryButton(
                    label: 'Back Home',
                    icon: Icons.home_outlined,
                    height: 44,
                    onPressed: _goHome,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            'Where should we deliver?',
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
            'Fill in the delivery details below. Your reference number will be generated after submission.',
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

  Widget _buildSectionTitle({
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
                  fontSize: 18,
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

  Widget _buildMobileNameFields() {
    return Column(
      children: [
        FormTextField(
          label: 'First Name',
          icon: Icons.person_outline,
          hint: 'Juan',
          controller: _firstNameController,
        ),
        const SizedBox(height: 16),
        FormTextField(
          label: 'Middle Name',
          icon: Icons.person_outline,
          hint: 'Optional',
          controller: _middleNameController,
        ),
        const SizedBox(height: 16),
        FormTextField(
          label: 'Last Name',
          icon: Icons.person_outline,
          hint: 'Dela Cruz',
          controller: _lastNameController,
        ),
      ],
    );
  }

  Widget _buildDesktopNameFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: FormTextField(
            label: 'First Name',
            icon: Icons.person_outline,
            hint: 'Juan',
            controller: _firstNameController,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FormTextField(
            label: 'Middle Name',
            icon: Icons.person_outline,
            hint: 'Optional',
            controller: _middleNameController,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FormTextField(
            label: 'Last Name',
            icon: Icons.person_outline,
            hint: 'Dela Cruz',
            controller: _lastNameController,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileContactFields() {
    return Column(
      children: [
        FormTextField(
          label: 'Contact Number',
          icon: Icons.phone_outlined,
          hint: '09170000001',
          keyboardType: TextInputType.phone,
          controller: _contactController,
        ),
        const SizedBox(height: 16),
        FormTextField(
          label: 'Email (Optional)',
          icon: Icons.email_outlined,
          hint: 'juan@email.com',
          keyboardType: TextInputType.emailAddress,
          controller: _emailController,
        ),
      ],
    );
  }

  Widget _buildDesktopContactFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: FormTextField(
            label: 'Contact Number',
            icon: Icons.phone_outlined,
            hint: '09170000001',
            keyboardType: TextInputType.phone,
            controller: _contactController,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FormTextField(
            label: 'Email (Optional)',
            icon: Icons.email_outlined,
            hint: 'juan@email.com',
            keyboardType: TextInputType.emailAddress,
            controller: _emailController,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 700;

        return SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: AppCard(
                  padding: EdgeInsets.all(isMobile ? 22 : 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 72,
                        width: 72,
                        decoration: const BoxDecoration(
                          color: AppColors.completedBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline_rounded,
                          color: AppColors.completed,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Request Submitted!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 23 : 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your delivery request has been received and is ready for dispatching.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.20),
                            width: 1.4,
                          ),
                          borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Reference Number',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _referenceNumber,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.issueBg,
                          borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: AppColors.issue.withValues(alpha: 0.18),
                          ),
                        ),
                        child: const Text(
                          'Use this reference number together with your contact number to track your delivery.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.issue,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: 'Track Delivery',
                        icon: Icons.route_outlined,
                        onPressed: _goToTracker,
                      ),
                      const SizedBox(height: 12),
                      SecondaryButton(
                        label: 'Back to Home',
                        icon: Icons.home_outlined,
                        onPressed: _goHome,
                      ),
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
}