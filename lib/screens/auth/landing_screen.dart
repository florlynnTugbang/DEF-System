import 'package:defsystem/core/theme/app_colors.dart';
import 'package:defsystem/core/theme/app_spacing.dart';
import 'package:defsystem/screens/auth/login_screen.dart';
import 'package:defsystem/screens/customer/delivery_request_screen.dart';
import 'package:defsystem/screens/customer/track_delivery_screen.dart';
import 'package:defsystem/screens/shared/buttons/outlined_button.dart';
import 'package:defsystem/screens/shared/buttons/primary_button.dart';
import 'package:defsystem/screens/shared/components/app_background.dart';
import 'package:defsystem/screens/shared/components/app_logo.dart';
import 'package:defsystem/screens/shared/components/feature_card.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'title': 'Request Easily',
        'desc': 'Customers can submit delivery details in a simple guided form.',
        'icon': Icons.edit_location_alt_outlined,
        'color': AppColors.primary,
      },
      {
        'title': 'Track Delivery',
        'desc':
        'Track delivery progress using a reference number and contact verification.',
        'icon': Icons.route_outlined,
        'color': AppColors.accent,
      },
      {
        'title': 'Report Issues',
        'desc':
        'Customers and riders can report delivery concerns for proper review.',
        'icon': Icons.report_problem_outlined,
        'color': AppColors.issue,
      },
    ];

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final bool isMobile = width < 760;
              final bool isTablet = width >= 760 && width < 1100;
              final bool isDesktop = width >= 1100;

              return Column(
                children: [
                  _buildHeader(context, isMobile),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 32,
                        vertical: isMobile ? 18 : 28,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isDesktop ? 1180 : 760,
                          ),
                          child: Column(
                            children: [
                              if (isDesktop)
                                _buildDesktopHero(context, features)
                              else
                                _buildStackedHero(
                                  context,
                                  features,
                                  isMobile: isMobile,
                                  isTablet: isTablet,
                                ),
                              SizedBox(height: isMobile ? 28 : 36),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildFooter(isMobile),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 42,
        vertical: isMobile ? 18 : 24,
      ),
      child: Row(
        children: [
          const Expanded(
            child: AppLogo(),
          ),
          SizedBox(
            width: isMobile ? 118 : 140,
            child: AppOutlinedButton(
              label: 'Login',
              icon: Icons.login_rounded,
              height: 46,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LoginPage(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHero(
      BuildContext context,
      List<Map<String, dynamic>> features,
      ) {
    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 11,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: _HeroText(
                      isMobile: false,
                      isTablet: false,
                      onRequest: () =>
                          _goTo(context, const DeliveryRequestScreen()),
                      onTrack: () =>
                          _goTo(context, const TrackDeliveryScreen()),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
              Expanded(
                flex: 9,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: _HeroPanel(isMobile: false),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: features.map((feature) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FeatureCard(
                    title: feature['title'] as String,
                    description: feature['desc'] as String,
                    icon: feature['icon'] as IconData,
                    color: feature['color'] as Color,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStackedHero(
      BuildContext context,
      List<Map<String, dynamic>> features, {
        required bool isMobile,
        required bool isTablet,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: isMobile ? 16 : 28),
        _HeroText(
          isMobile: isMobile,
          isTablet: isTablet,
          onRequest: () => _goTo(context, const DeliveryRequestScreen()),
          onTrack: () => _goTo(context, const TrackDeliveryScreen()),
        ),
        SizedBox(height: isMobile ? 28 : 36),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 560,
            ),
            child: _HeroPanel(isMobile: isMobile),
          ),
        ),
        SizedBox(height: isMobile ? 28 : 36),
        if (isMobile)
          ...features.map(
                (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: FeatureCard(
                title: feature['title'] as String,
                description: feature['desc'] as String,
                icon: feature['icon'] as IconData,
                color: feature['color'] as Color,
              ),
            ),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: features.map((feature) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FeatureCard(
                    title: feature['title'] as String,
                    description: feature['desc'] as String,
                    icon: feature['icon'] as IconData,
                    color: feature['color'] as Color,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isMobile ? 14 : 18,
      ),
      color: AppColors.background.withValues(alpha: 0.72),
      child: const Text(
        '© 2026 DEF Digital Dispatch & Tracking System',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _goTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _HeroText extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;
  final VoidCallback onRequest;
  final VoidCallback onTrack;

  const _HeroText({
    required this.isMobile,
    required this.isTablet,
    required this.onRequest,
    required this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    final bool centered = isMobile || isTablet;

    return Column(
      crossAxisAlignment:
      centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
          child: const Text(
            'Modern Delivery Dispatch & Tracking',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Fast, Reliable\nDelivery Service',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: isMobile
                ? 38
                : isTablet
                ? 48
                : 54,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
            height: 1.04,
            letterSpacing: -1.1,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Submit delivery requests, track deliveries, and report concerns through one clean digital system.',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: isMobile ? 15 : 17,
            color: AppColors.textMuted,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 28),
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrimaryButton(
                label: 'Request a Delivery',
                icon: Icons.add_location_alt_outlined,
                onPressed: onRequest,
              ),
              const SizedBox(height: 12),
              AppOutlinedButton(
                label: 'Track My Delivery',
                icon: Icons.search_rounded,
                onPressed: onTrack,
              ),
            ],
          )
        else
          Wrap(
            spacing: 14,
            runSpacing: 12,
            alignment: centered ? WrapAlignment.center : WrapAlignment.start,
            children: [
              SizedBox(
                width: 220,
                child: PrimaryButton(
                  label: 'Request a Delivery',
                  icon: Icons.add_location_alt_outlined,
                  onPressed: onRequest,
                ),
              ),
              SizedBox(
                width: 220,
                child: AppOutlinedButton(
                  label: 'Track My Delivery',
                  icon: Icons.search_rounded,
                  onPressed: onTrack,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final bool isMobile;

  const _HeroPanel({
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 30),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(isMobile ? 26 : 28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: isMobile ? 92 : 102,
            width: isMobile ? 92 : 102,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_shipping_outlined,
              color: AppColors.white,
              size: isMobile ? 52 : 58,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'DEF DispatchTrack',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: isMobile ? 23 : 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'A digital delivery request, dispatching, tracking, and incident reporting system.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textLight,
              height: 1.5,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          const _PanelStat(
            icon: Icons.receipt_long_outlined,
            label: 'Request',
            value: 'Submit delivery details',
          ),
          const SizedBox(height: 12),
          const _PanelStat(
            icon: Icons.person_search_outlined,
            label: 'Dispatch',
            value: 'Assign available rider',
          ),
          const SizedBox(height: 12),
          const _PanelStat(
            icon: Icons.route_outlined,
            label: 'Track',
            value: 'Monitor delivery progress',
          ),
        ],
      ),
    );
  }
}

class _PanelStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PanelStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}