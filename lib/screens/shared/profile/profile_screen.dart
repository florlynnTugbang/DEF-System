import 'package:defsystem/core/theme/app_colors.dart';
import 'package:defsystem/core/theme/app_spacing.dart';
import 'package:defsystem/providers/auth_provider.dart';
import 'package:defsystem/screens/shared/buttons/primary_button.dart';
import 'package:defsystem/screens/shared/components/app_card.dart';
import 'package:defsystem/screens/shared/components/date_time_header.dart';
import 'package:defsystem/screens/shared/forms/form_text_field.dart';
import 'package:defsystem/screens/shared/status/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _vehicleController = TextEditingController();

  bool _populated = false;
  bool _availabilityStatus = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  void _populateFields(AuthState authState) {
    if (_populated || authState.userData == null) return;

    final data = authState.userData!;

    _firstNameController.text = data['first_name']?.toString() ?? '';
    _middleNameController.text = data['middle_name']?.toString() ?? '';
    _lastNameController.text = data['last_name']?.toString() ?? '';
    _contactController.text = data['contact_number']?.toString() ?? '';
    _vehicleController.text = data['vehicle_details']?.toString() ?? '';

    _availabilityStatus = data['availability_status'] == true;

    _populated = true;
  }

  String _safeText(dynamic value, {String fallback = 'Not provided'}) {
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString();
  }

  String _initial(AuthState authState) {
    final name = authState.displayName.trim();

    if (name.isNotEmpty) return name[0].toUpperCase();

    final firstName = authState.userData?['first_name']?.toString().trim() ?? '';
    if (firstName.isNotEmpty) return firstName[0].toUpperCase();

    return '?';
  }

  String _roleLabel(AuthState authState) {
    if (authState.roleLabel.trim().isNotEmpty) return authState.roleLabel;

    final role = authState.role ?? '';

    switch (role) {
      case 'admin':
        return 'Management';
      case 'dispatcher':
        return 'Dispatcher';
      case 'rider':
        return 'Rider';
      default:
        return 'Staff';
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      case 'dispatcher':
        return Icons.headset_mic_outlined;
      case 'rider':
        return Icons.directions_bike_outlined;
      default:
        return Icons.badge_outlined;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.primary;
      case 'dispatcher':
        return AppColors.assigned;
      case 'rider':
        return AppColors.inTransit;
      default:
        return AppColors.textMuted;
    }
  }

  Future<void> _saveChanges() async {
    if (_firstNameController.text.trim().isEmpty) {
      _showSnackbar('Please enter your first name.', isError: true);
      return;
    }

    if (_lastNameController.text.trim().isEmpty) {
      _showSnackbar('Please enter your last name.', isError: true);
      return;
    }

    final authState = ref.read(authProvider);
    final isRider = (authState.role ?? '') == 'rider';

    final success = await ref.read(authProvider.notifier).updateProfile(
      fname: _firstNameController.text.trim(),
      mname: _middleNameController.text.trim().isEmpty
          ? null
          : _middleNameController.text.trim(),
      lname: _lastNameController.text.trim(),
      contactNumber: _contactController.text.trim().isEmpty
          ? null
          : _contactController.text.trim(),
      vehicleDetails: isRider
          ? (_vehicleController.text.trim().isEmpty
          ? null
          : _vehicleController.text.trim())
          : null,
      availabilityStatus: isRider ? _availabilityStatus : null,
    );

    if (!mounted) return;

    if (success) {
      _populated = false;
      _showSnackbar('Profile updated successfully.');
    } else {
      final error = ref.read(authProvider).error;
      _showSnackbar(error ?? 'Failed to update profile.', isError: true);
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text(
          'Are you sure you want to log out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cancelled,
            ),
            child: const Text(
              'Log out',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref.read(authProvider.notifier).signOut();
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.cancelled : AppColors.completed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    _populateFields(authState);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 760;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SingleChildScrollView(
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
                _buildHeader(authState, isMobile),
                SizedBox(height: isMobile ? 18 : 24),
                _buildProfileSummary(authState, isMobile),
                SizedBox(height: isMobile ? 18 : 24),
                _buildAccountInfo(authState, isMobile),
                SizedBox(height: isMobile ? 18 : 24),
                _buildEditProfileCard(authState, isMobile),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AuthState authState, bool isMobile) {
    final role = authState.role ?? '';
    final roleLabel = _roleLabel(authState);

    if (isMobile) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
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
                _HeaderIcon(icon: _roleIcon(role)),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Profile',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const DateTimeHeader(compact: true),
              ],
            ),
            const SizedBox(height: 26),
            Text(
              authState.displayName.isNotEmpty
                  ? authState.displayName
                  : 'My Account',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 1.05,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Manage your staff account information and profile settings.',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _HeaderStatPill(
                    icon: _roleIcon(role),
                    label: 'Role',
                    value: roleLabel,
                  ),
                  const SizedBox(width: 10),
                  const _HeaderStatPill(
                    icon: Icons.verified_user_outlined,
                    label: 'Status',
                    value: 'Active',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          _HeaderIcon(
            icon: _roleIcon(role),
            large: true,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authState.displayName.isNotEmpty
                      ? authState.displayName
                      : 'Profile & Settings',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage your staff account information and profile settings.',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _HeaderStatPill(
                        icon: _roleIcon(role),
                        label: 'Role',
                        value: roleLabel,
                      ),
                      const SizedBox(width: 10),
                      const _HeaderStatPill(
                        icon: Icons.verified_user_outlined,
                        label: 'Status',
                        value: 'Active',
                      ),
                    ],
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

  Widget _buildProfileSummary(AuthState authState, bool isMobile) {
    final role = authState.role ?? '';
    final roleColor = _roleColor(role);
    final roleLabel = _roleLabel(authState);

    return AppCard(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      child: isMobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileIdentity(authState, roleColor, roleLabel),
          const SizedBox(height: 20),
          _buildLogoutButton(fullWidth: true),
        ],
      )
          : Row(
        children: [
          Expanded(
            child: _buildProfileIdentity(authState, roleColor, roleLabel),
          ),
          const SizedBox(width: 18),
          _buildLogoutButton(fullWidth: false),
        ],
      ),
    );
  }

  Widget _buildProfileIdentity(
      AuthState authState,
      Color roleColor,
      String roleLabel,
      ) {
    final role = authState.role ?? '';
    final isRider = role == 'rider';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: roleColor.withValues(alpha: 0.10),
          child: Text(
            _initial(authState),
            style: TextStyle(
              color: roleColor,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authState.displayName.isNotEmpty
                    ? authState.displayName
                    : 'User',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _RolePill(
                    icon: _roleIcon(role),
                    label: roleLabel,
                    color: roleColor,
                  ),
                  StatusBadge(status: 'Active'),
                  if (isRider)
                    StatusBadge(
                      status: _availabilityStatus ? 'Available' : 'Unavailable',
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton({required bool fullWidth}) {
    return SizedBox(
      width: fullWidth ? double.infinity : 150,
      child: ElevatedButton.icon(
        onPressed: _confirmLogout,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Log out'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cancelled,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountInfo(AuthState authState, bool isMobile) {
    final data = authState.userData;
    final role = authState.role ?? '';
    final isRider = role == 'rider';

    final items = [
      _InfoItem(
        icon: Icons.phone_outlined,
        label: 'Contact Number',
        value: _safeText(data?['contact_number']),
        color: AppColors.completed,
      ),
      _InfoItem(
        icon: Icons.badge_outlined,
        label: 'Role',
        value: _roleLabel(authState),
        color: _roleColor(role),
      ),
      _InfoItem(
        icon: Icons.verified_user_outlined,
        label: 'Account Status',
        value: 'Active',
        color: AppColors.completed,
      ),
      if (isRider)
        _InfoItem(
          icon: Icons.two_wheeler_outlined,
          label: 'Vehicle Details',
          value: _safeText(data?['vehicle_details']),
          color: AppColors.inTransit,
        ),
    ];

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(items.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                right: index == items.length - 1 ? 0 : 12,
              ),
              child: _InfoBox(
                item: items[index],
                width: isMobile ? 250 : 280,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEditProfileCard(AuthState authState, bool isMobile) {
    final bool isRider = (authState.role ?? '') == 'rider';

    return AppCard(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
              ),
              SizedBox(width: 10),
              Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (isMobile)
            Column(
              children: [
                FormTextField(
                  label: 'First Name',
                  icon: Icons.person_outline,
                  hint: 'First name',
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
                  hint: 'Last name',
                  controller: _lastNameController,
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FormTextField(
                    label: 'First Name',
                    icon: Icons.person_outline,
                    hint: 'First name',
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
                    hint: 'Last name',
                    controller: _lastNameController,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          FormTextField(
            label: 'Contact Number',
            icon: Icons.phone_outlined,
            hint: '0912 345 6789',
            keyboardType: TextInputType.phone,
            controller: _contactController,
          ),
          const SizedBox(height: 16),
          FormTextField(
            label: 'Role',
            icon: Icons.badge_outlined,
            controller: TextEditingController(text: _roleLabel(authState)),
          ),
          if (isRider) ...[
            const SizedBox(height: 16),
            FormTextField(
              label: 'Vehicle Details',
              icon: Icons.two_wheeler_outlined,
              hint: 'Motorcycle - Honda Click 125',
              controller: _vehicleController,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Available for Deliveries',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              subtitle: Text(
                _availabilityStatus
                    ? 'You are currently marked as available.'
                    : 'You are currently marked as unavailable.',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              value: _availabilityStatus,
              activeColor: AppColors.primary,
              onChanged: (value) {
                setState(() {
                  _availabilityStatus = value;
                });
              },
            ),
          ],
          const SizedBox(height: 28),
          authState.isLoading
              ? const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          )
              : SizedBox(
            width: isMobile ? double.infinity : 180,
            child: PrimaryButton(
              label: 'Save Changes',
              icon: Icons.save_outlined,
              onPressed: _saveChanges,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _InfoBox extends StatelessWidget {
  final _InfoItem item;
  final double width;

  const _InfoBox({
    required this.item,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 104,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: item.color.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.icon,
            size: 18,
            color: item.color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
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

class _RolePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RolePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final bool large;

  const _HeaderIcon({
    required this.icon,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
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