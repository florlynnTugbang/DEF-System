import 'package:defsystem/core/theme/app_colors.dart';
import 'package:defsystem/core/theme/app_spacing.dart';
import 'package:defsystem/screens/shared/buttons/primary_button.dart';
import 'package:defsystem/screens/shared/components/app_background.dart';
import 'package:defsystem/screens/shared/components/app_card.dart';
import 'package:defsystem/screens/shared/forms/form_text_field.dart';
import 'package:defsystem/services/delivery_service.dart';
import 'package:flutter/material.dart';

class IssueReportScreen extends StatefulWidget {
  final String requestID;
  final String contactNumber;

  const IssueReportScreen({
    super.key,
    required this.requestID,
    required this.contactNumber,
  });

  @override
  State<IssueReportScreen> createState() => _IssueReportScreenState();
}

class _IssueReportScreenState extends State<IssueReportScreen> {
  final _descriptionController = TextEditingController();

  bool _isSubmitting = false;
  bool _isSubmitted = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _cleanText(String value) {
    return value
        .replaceAll('\u0000', '')
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
        .trim();
  }

  Future<void> _submitReport() async {
    final description = _cleanText(_descriptionController.text);

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe the issue.'),
          backgroundColor: AppColors.cancelled,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await DeliveryService().reportCustomerIssue(
        requestID: widget.requestID,
        contactNumber: widget.contactNumber,
        description: description,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit report: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: AppColors.cancelled,
        ),
      );
    }
  }

  void _goBackToTrack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        useGradient: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 700;
            final double maxWidth = isMobile ? double.infinity : 540;

            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 20 : 32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: _isSubmitted
                        ? _buildSuccessView(isMobile)
                        : _buildFormView(isMobile),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormView(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildNavyHeader(isMobile),
        const SizedBox(height: 18),
        AppCard(
          padding: EdgeInsets.all(isMobile ? 18 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReferenceBox(),
              const SizedBox(height: 14),
              _buildVerificationBox(),
              const SizedBox(height: 24),
              FormTextField(
                label: 'Issue Description',
                icon: Icons.description_outlined,
                hint:
                'Describe the issue, such as damaged item, wrong item, cancellation concern, or delivery problem.',
                maxLines: 5,
                controller: _descriptionController,
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Submit Issue Report',
                icon: Icons.send_outlined,
                isLoading: _isSubmitting,
                onPressed: _submitReport,
              ),
            ],
          ),
        ),
      ],
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
                  Icons.report_problem_outlined,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Issue Report',
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
                    onPressed: _isSubmitting ? null : _goBackToTrack,
                    tooltip: 'Cancel',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.border,
                      disabledForegroundColor: AppColors.textMuted,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 22,
                    ),
                  ),
                )
              else
                SizedBox(
                  width: 118,
                  height: 44,
                  child: TextButton.icon(
                    onPressed: _isSubmitting ? null : _goBackToTrack,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.textBody,
                      disabledForegroundColor: AppColors.textMuted,
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
            'Tell us what happened',
            style: TextStyle(
              color: AppColors.white,
              fontSize: isMobile ? 31 : 38,
              fontWeight: FontWeight.w900,
              height: 1.06,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Customer reports are accepted only for completed or cancelled deliveries.',
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

  Widget _buildReferenceBox() {
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
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 19,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Reference: ${widget.requestID}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.issueBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.issue.withValues(alpha: 0.18),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 20,
            color: AppColors.issue,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This report is verified using the contact number used to track this delivery.',
              style: TextStyle(
                color: AppColors.issue,
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

  Widget _buildSuccessView(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
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
                'Report Submitted!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 23 : 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thank you for your feedback. Your concern has been recorded for review.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Back to Tracking',
                icon: Icons.arrow_back_rounded,
                onPressed: _goBackToTrack,
              ),
            ],
          ),
        ),
      ],
    );
  }
}