import 'package:defsystem/core/theme/app_colors.dart';
import 'package:defsystem/core/theme/app_spacing.dart';
import 'package:defsystem/providers/auth_provider.dart';
import 'package:defsystem/screens/auth/landing_screen.dart';
import 'package:defsystem/screens/shared/buttons/primary_button.dart';
import 'package:defsystem/screens/shared/components/app_background.dart';
import 'package:defsystem/screens/shared/components/app_card.dart';
import 'package:defsystem/screens/shared/components/app_logo.dart';
import 'package:defsystem/screens/shared/forms/form_text_field.dart';
import 'package:defsystem/screens/shared/layout/dashboard_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email and password.'),
          backgroundColor: AppColors.cancelled,
        ),
      );
      return;
    }

    await ref.read(authProvider.notifier).signIn(
      email: email,
      password: password,
    );

    final authState = ref.read(authProvider);

    if (!mounted) return;

    if (authState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error!),
          backgroundColor: AppColors.cancelled,
        ),
      );
      return;
    }

    if (authState.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const DashboardLayout(),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isMobile = constraints.maxWidth < 820;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 32,
                  vertical: isMobile ? 20 : 32,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - (isMobile ? 40 : 64),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: isMobile
                          ? _buildMobileLayout(authState)
                          : _buildDesktopLayout(authState),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(AuthState authState) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _buildNavyPanel(isMobile: false),
        ),
        const SizedBox(width: 28),
        Expanded(
          child: _buildLoginCard(authState, isMobile: false),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildNavyPanel(isMobile: true),
        const SizedBox(height: 18),
        _buildLoginCard(authState, isMobile: true),
      ],
    );
  }

  Widget _buildNavyPanel({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 22 : 34),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(isMobile ? 24 : 30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: AppLogo(
                  light: true,
                  iconSize: 30,
                  fontSize: 22,
                ),
              ),
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
              ),
            ],
          ),
          SizedBox(height: isMobile ? 28 : 48),
          Text(
            'Welcome back,\nDEF Staff',
            style: TextStyle(
              color: AppColors.white,
              fontSize: isMobile ? 32 : 44,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sign in to manage dispatching, rider assignments, delivery reports, and issue logs.',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: isMobile ? 14 : 15,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isMobile ? 24 : 40),
          _buildPanelItem(
            icon: Icons.dashboard_outlined,
            title: 'Admin Dashboard',
            subtitle: 'Monitor operations and reports',
          ),
          const SizedBox(height: 12),
          _buildPanelItem(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Dispatcher Tools',
            subtitle: 'Assign riders and manage deliveries',
          ),
          const SizedBox(height: 12),
          _buildPanelItem(
            icon: Icons.directions_bike_outlined,
            title: 'Rider Workspace',
            subtitle: 'Update delivery status and history',
          ),
        ],
      ),
    );
  }

  Widget _buildPanelItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
          Icon(
            icon,
            color: AppColors.white,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(AuthState authState, {required bool isMobile}) {
    return AppCard(
      padding: EdgeInsets.all(isMobile ? 20 : 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Staff Sign In',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Access your DEF DispatchTrack account.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 26),
          FormTextField(
            label: 'Email',
            icon: Icons.email_outlined,
            hint: 'Enter your email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 18),
          FormTextField(
            label: 'Password',
            icon: Icons.lock_outline,
            hint: 'Enter your password',
            controller: _passwordController,
            obscureText: true,
          ),
          const SizedBox(height: 22),
          if (authState.error != null) ...[
            _buildErrorBox(authState.error!),
            const SizedBox(height: 16),
          ],
          PrimaryButton(
            label: 'Sign In',
            icon: Icons.login_rounded,
            isLoading: authState.isLoading,
            onPressed: _signIn,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: AppColors.cancelled,
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