import 'package:defsystem/core/theme/app_colors.dart';
import 'package:defsystem/core/theme/app_spacing.dart';
import 'package:defsystem/providers/user_provider.dart';
import 'package:defsystem/screens/shared/buttons/primary_button.dart';
import 'package:defsystem/screens/shared/components/app_card.dart';
import 'package:defsystem/screens/shared/components/date_time_header.dart';
import 'package:defsystem/screens/shared/forms/form_text_field.dart';
import 'package:defsystem/screens/shared/status/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _searchController = TextEditingController();

  int _selectedTabIndex = 0;
  String _searchQuery = '';

  final List<Map<String, String>> _tabs = const [
    {'label': 'Admins', 'role': 'admin'},
    {'label': 'Dispatchers', 'role': 'dispatcher'},
    {'label': 'Riders', 'role': 'rider'},
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: _tabs.length, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String get _activeRole => _tabs[_selectedTabIndex]['role']!;

  Future<void> _refreshUsers() async {
    await ref.read(userProvider.notifier).loadAll();
  }

  String _fullName(Map<String, dynamic> user) {
    final parts = [
      user['first_name'],
      user['middle_name'],
      user['last_name'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).toList();

    if (parts.isEmpty) return 'Unnamed Staff';
    return parts.join(' ');
  }

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  String _safeText(dynamic value, {String fallback = 'Not provided'}) {
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString();
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Management';
      case 'dispatcher':
        return 'Dispatcher';
      case 'rider':
        return 'Rider';
      default:
        return role;
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

  List<Map<String, dynamic>> _usersByRole(
      List<Map<String, dynamic>> staff,
      String role,
      ) {
    final normalizedQuery = _searchQuery.trim().toLowerCase();

    final byRole = staff.where((user) {
      return user['role']?.toString() == role;
    }).toList();

    if (normalizedQuery.isEmpty) return byRole;

    return byRole.where((user) {
      final name = _fullName(user).toLowerCase();
      final contact = _safeText(user['contact_number']).toLowerCase();
      final roleLabel = _roleLabel(user['role']?.toString() ?? '').toLowerCase();
      final id = _safeText(user['id']).toLowerCase();
      final vehicle = _safeText(user['vehicle_details']).toLowerCase();

      return name.contains(normalizedQuery) ||
          contact.contains(normalizedQuery) ||
          roleLabel.contains(normalizedQuery) ||
          id.contains(normalizedQuery) ||
          vehicle.contains(normalizedQuery);
    }).toList();
  }

  int _countRole(List<Map<String, dynamic>> staff, String role) {
    return staff.where((user) => user['role']?.toString() == role).length;
  }

  int _countActive(List<Map<String, dynamic>> staff) {
    return staff.where((user) => user['is_active'] == true).length;
  }

  int _countAvailableRiders(List<Map<String, dynamic>> staff) {
    return staff.where((user) {
      return user['role'] == 'rider' && user['availability_status'] == true;
    }).length;
  }

  void _showAddDialog(String role) {
    showDialog(
      context: context,
      builder: (context) => _StaffProfileDialog(role: role),
    );
  }

  void _showEditDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => _StaffProfileDialog(existingUser: user),
    );
  }

  Future<void> _toggleActiveStatus(Map<String, dynamic> user) async {
    final id = user['id']?.toString() ?? '';
    final isActive = user['is_active'] == true;
    final name = _fullName(user);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isActive ? 'Deactivate Account' : 'Activate Account'),
        content: Text(
          isActive
              ? 'Deactivate $name? This staff member will no longer be able to access the system.'
              : 'Activate $name? This staff member will be able to access the system again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
              isActive ? AppColors.cancelled : AppColors.completed,
            ),
            child: Text(
              isActive ? 'Deactivate' : 'Activate',
              style: const TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ref.read(userProvider.notifier).setStaffActiveStatus(
      id: id,
      isActive: !isActive,
    );

    if (!mounted) return;

    final userState = ref.read(userProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? userState.successMessage ?? 'Status updated.'
              : userState.error ?? 'Failed to update status.',
        ),
        backgroundColor: success ? AppColors.completed : AppColors.cancelled,
      ),
    );

    ref.read(userProvider.notifier).clearMessages();
  }

  Future<void> _deleteProfile(Map<String, dynamic> user) async {
    final id = user['id']?.toString() ?? '';
    final name = _fullName(user);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff Profile'),
        content: Text(
          'Delete the staff profile of $name?\n\n'
              'Note: This will not delete the Supabase Auth login account. '
              'For normal use, deactivate is recommended instead.',
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
              'Delete Profile',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ref.read(userProvider.notifier).deleteStaffProfile(id);

    if (!mounted) return;

    final userState = ref.read(userProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? userState.successMessage ?? 'Profile deleted.'
              : userState.error ?? 'Failed to delete profile.',
        ),
        backgroundColor: success ? AppColors.completed : AppColors.cancelled,
      ),
    );

    ref.read(userProvider.notifier).clearMessages();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final staff = userState.staff;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 760;

        final activeRoleUsers = _usersByRole(staff, _activeRole);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshUsers,
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
                  _buildHeader(
                    isMobile: isMobile,
                    staff: staff,
                  ),
                  SizedBox(height: isMobile ? 18 : 24),
                  _buildSearchAndActions(
                    isMobile: isMobile,
                    staff: staff,
                  ),
                  SizedBox(height: isMobile ? 18 : 24),
                  _buildOverviewCarousel(
                    isMobile: isMobile,
                    staff: staff,
                  ),
                  SizedBox(height: isMobile ? 18 : 24),
                  _buildTabs(),
                  const SizedBox(height: 16),
                  if (userState.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(36),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (activeRoleUsers.isEmpty)
                    _buildEmptyState(_activeRole)
                  else
                    _buildUserGrid(
                      users: activeRoleUsers,
                      isMobile: isMobile,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({
    required bool isMobile,
    required List<Map<String, dynamic>> staff,
  }) {
    final totalStaff = staff.length;
    final activeStaff = _countActive(staff);
    final ridersAvailable = _countAvailableRiders(staff);

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
                const _HeaderIcon(icon: Icons.manage_accounts_outlined),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Management',
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
            const Text(
              'User Management',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 1.05,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Manage staff profiles connected to Supabase Auth accounts.',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            _buildHeaderStats(
              totalStaff: totalStaff,
              activeStaff: activeStaff,
              ridersAvailable: ridersAvailable,
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
          const _HeaderIcon(
            icon: Icons.manage_accounts_outlined,
            large: true,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User Management',
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
                  'Manage staff profiles connected to Supabase Auth accounts.',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                _buildHeaderStats(
                  totalStaff: totalStaff,
                  activeStaff: activeStaff,
                  ridersAvailable: ridersAvailable,
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

  Widget _buildHeaderStats({
    required int totalStaff,
    required int activeStaff,
    required int ridersAvailable,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _HeaderStatPill(
            icon: Icons.groups_2_outlined,
            label: 'Staff',
            value: '$totalStaff',
          ),
          const SizedBox(width: 10),
          _HeaderStatPill(
            icon: Icons.check_circle_outline_rounded,
            label: 'Active',
            value: '$activeStaff',
          ),
          const SizedBox(width: 10),
          _HeaderStatPill(
            icon: Icons.directions_bike_outlined,
            label: 'Available Riders',
            value: '$ridersAvailable',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndActions({
    required bool isMobile,
    required List<Map<String, dynamic>> staff,
  }) {
    return AppCard(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          SizedBox(
            width: isMobile ? double.infinity : 540,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name, role, contact, vehicle, or UUID...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.surfaceSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: isMobile ? double.infinity : 240,
            child: PrimaryButton(
              label: 'Add ${_roleLabel(_activeRole)} Profile',
              icon: Icons.add,
              onPressed: () => _showAddDialog(_activeRole),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCarousel({
    required bool isMobile,
    required List<Map<String, dynamic>> staff,
  }) {
    final items = [
      _OverviewItem(
        title: 'Management',
        value: '${_countRole(staff, 'admin')}',
        subtitle: 'Admin profiles',
        icon: Icons.admin_panel_settings_outlined,
        color: AppColors.primary,
      ),
      _OverviewItem(
        title: 'Dispatchers',
        value: '${_countRole(staff, 'dispatcher')}',
        subtitle: 'Dispatcher profiles',
        icon: Icons.headset_mic_outlined,
        color: AppColors.assigned,
      ),
      _OverviewItem(
        title: 'Riders',
        value: '${_countRole(staff, 'rider')}',
        subtitle: 'Rider profiles',
        icon: Icons.directions_bike_outlined,
        color: AppColors.inTransit,
      ),
      _OverviewItem(
        title: 'Active Staff',
        value: '${_countActive(staff)}',
        subtitle: 'Can access system',
        icon: Icons.verified_user_outlined,
        color: AppColors.completed,
      ),
      _OverviewItem(
        title: 'Available Riders',
        value: '${_countAvailableRiders(staff)}',
        subtitle: 'Ready for delivery',
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.completed,
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
                right: index == items.length - 1 ? 0 : 14,
              ),
              child: _OverviewCard(
                item: items[index],
                width: isMobile ? 235 : 260,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return AppCard(
      padding: const EdgeInsets.all(8),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        tabs: _tabs.map((tab) {
          final role = tab['role']!;
          return Tab(
            icon: Icon(_roleIcon(role), size: 18),
            text: tab['label']!,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUserGrid({
    required List<Map<String, dynamic>> users,
    required bool isMobile,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final cardWidth = isMobile
            ? width
            : width < 1100
            ? (width - 16) / 2
            : (width - 32) / 3;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: users.map((user) {
            return SizedBox(
              width: cardWidth,
              child: _buildUserCard(user: user),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildUserCard({
    required Map<String, dynamic> user,
  }) {
    final role = user['role']?.toString() ?? '';
    final fullName = _fullName(user);
    final contact = _safeText(user['contact_number']);
    final vehicle = _safeText(
      user['vehicle_details'],
      fallback: role == 'rider' ? 'No vehicle details' : 'Not applicable',
    );
    final isActive = user['is_active'] == true;
    final isRider = role == 'rider';
    final roleColor = _roleColor(role);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: roleColor.withValues(alpha: 0.10),
                  child: Text(
                    _initial(fullName),
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tooltip(
                        message: user['id']?.toString() ?? '',
                        child: Text(
                          fullName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      _RolePill(
                        icon: _roleIcon(role),
                        label: _roleLabel(role),
                        color: roleColor,
                      ),
                    ],
                  ),
                ),
                _buildActionButtons(user),
              ],
            ),
            const SizedBox(height: 18),
            _StaffInfoBox(
              icon: Icons.phone_outlined,
              label: 'Contact',
              value: contact,
              color: AppColors.completed,
            ),
            const SizedBox(height: 10),
            _StaffInfoBox(
              icon: Icons.key_outlined,
              label: 'Auth ID',
              value: _safeText(user['id']),
              color: AppColors.primary,
            ),
            if (isRider) ...[
              const SizedBox(height: 10),
              _StaffInfoBox(
                icon: Icons.two_wheeler_outlined,
                label: 'Vehicle',
                value: vehicle,
                color: AppColors.inTransit,
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusBadge(status: isActive ? 'Active' : 'Inactive'),
                if (isRider)
                  StatusBadge(
                    status: user['availability_status'] == true
                        ? 'Available'
                        : 'Unavailable',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> user) {
    final isActive = user['is_active'] == true;

    return PopupMenuButton<String>(
      tooltip: 'Actions',
      icon: const Icon(
        Icons.more_vert_rounded,
        color: AppColors.textMuted,
      ),
      onSelected: (value) {
        if (value == 'edit') {
          _showEditDialog(user);
        } else if (value == 'toggle') {
          _toggleActiveStatus(user);
        } else if (value == 'delete') {
          _deleteProfile(user);
        }
      },
      itemBuilder: (context) {
        return [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, color: AppColors.primary),
                SizedBox(width: 10),
                Text('Edit'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'toggle',
            child: Row(
              children: [
                Icon(
                  isActive ? Icons.block_outlined : Icons.check_circle_outline,
                  color: isActive ? AppColors.pending : AppColors.completed,
                ),
                const SizedBox(width: 10),
                Text(isActive ? 'Deactivate' : 'Activate'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: AppColors.cancelled),
                SizedBox(width: 10),
                Text('Delete Profile'),
              ],
            ),
          ),
        ];
      },
    );
  }

  Widget _buildEmptyState(String role) {
    return AppCard(
      padding: const EdgeInsets.all(36),
      child: Center(
        child: Column(
          children: [
            Icon(
              _roleIcon(role),
              size: 54,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${_roleLabel(role).toLowerCase()} profiles found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.trim().isEmpty
                  ? 'Add a staff profile to display it here.'
                  : 'Try using a different search keyword.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffProfileDialog extends ConsumerStatefulWidget {
  final String? role;
  final Map<String, dynamic>? existingUser;

  const _StaffProfileDialog({
    this.role,
    this.existingUser,
  });

  @override
  ConsumerState<_StaffProfileDialog> createState() =>
      _StaffProfileDialogState();
}

class _StaffProfileDialogState extends ConsumerState<_StaffProfileDialog> {
  final _authUserIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _vehicleController = TextEditingController();

  late String _selectedRole;
  bool _availabilityStatus = true;
  bool _isActive = true;

  bool get _isEditing => widget.existingUser != null;

  @override
  void initState() {
    super.initState();

    final user = widget.existingUser;

    _selectedRole = widget.role ?? user?['role']?.toString() ?? 'dispatcher';

    if (user != null) {
      _authUserIdController.text = user['id']?.toString() ?? '';
      _firstNameController.text = user['first_name']?.toString() ?? '';
      _middleNameController.text = user['middle_name']?.toString() ?? '';
      _lastNameController.text = user['last_name']?.toString() ?? '';
      _contactController.text = user['contact_number']?.toString() ?? '';
      _vehicleController.text = user['vehicle_details']?.toString() ?? '';
      _availabilityStatus = user['availability_status'] == true;
      _isActive = user['is_active'] == true;
    }
  }

  @override
  void dispose() {
    _authUserIdController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  bool _validate() {
    if (!_isEditing && _authUserIdController.text.trim().isEmpty) {
      _showError('Please enter the Supabase Auth User ID.');
      return false;
    }

    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty) {
      _showError('Please enter the required name fields.');
      return false;
    }

    if (_selectedRole == 'rider' && _vehicleController.text.trim().isEmpty) {
      _showError('Please enter vehicle details for the rider.');
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

  Future<void> _submit() async {
    if (!_validate()) return;

    bool success;

    if (_isEditing) {
      success = await ref.read(userProvider.notifier).updateStaffProfile(
        id: _authUserIdController.text.trim(),
        role: _selectedRole,
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim().isEmpty
            ? null
            : _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        contactNumber: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        vehicleDetails:
        _selectedRole == 'rider' ? _vehicleController.text.trim() : null,
        availabilityStatus:
        _selectedRole == 'rider' ? _availabilityStatus : null,
        isActive: _isActive,
      );
    } else {
      success = await ref.read(userProvider.notifier).addStaffProfile(
        authUserId: _authUserIdController.text.trim(),
        role: _selectedRole,
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim().isEmpty
            ? null
            : _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        contactNumber: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        vehicleDetails:
        _selectedRole == 'rider' ? _vehicleController.text.trim() : null,
        availabilityStatus:
        _selectedRole == 'rider' ? _availabilityStatus : null,
      );
    }

    if (!mounted) return;

    Navigator.pop(context);

    final userState = ref.read(userProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? userState.successMessage ?? 'Staff profile saved.'
              : userState.error ?? 'Failed to save staff profile.',
        ),
        backgroundColor: success ? AppColors.completed : AppColors.cancelled,
      ),
    );

    ref.read(userProvider.notifier).clearMessages();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(userProvider).isLoading;
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 24,
      ),
      title: Text(_isEditing ? 'Edit Staff Profile' : 'Add Staff Profile'),
      content: SizedBox(
        width: isMobile ? double.maxFinite : 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isEditing) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Text(
                    'Create the staff login first in Supabase Authentication, then paste the Auth User ID here.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FormTextField(
                  label: 'Supabase Auth User ID',
                  icon: Icons.key_outlined,
                  hint: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                  controller: _authUserIdController,
                ),
                const SizedBox(height: 16),
              ],
              DropdownButtonFormField<String>(
                value: _selectedRole,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Role',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Management'),
                  ),
                  DropdownMenuItem(
                    value: 'dispatcher',
                    child: Text('Dispatcher'),
                  ),
                  DropdownMenuItem(
                    value: 'rider',
                    child: Text('Rider'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedRole = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (isMobile)
                Column(
                  children: [
                    FormTextField(
                      label: 'First Name',
                      icon: Icons.person_outline,
                      hint: 'Maria',
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
                      hint: 'Santos',
                      controller: _lastNameController,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: FormTextField(
                        label: 'First Name',
                        icon: Icons.person_outline,
                        hint: 'Maria',
                        controller: _firstNameController,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FormTextField(
                        label: 'Middle Name',
                        icon: Icons.person_outline,
                        hint: 'Optional',
                        controller: _middleNameController,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FormTextField(
                        label: 'Last Name',
                        icon: Icons.person_outline,
                        hint: 'Santos',
                        controller: _lastNameController,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              FormTextField(
                label: 'Contact Number',
                icon: Icons.phone_outlined,
                hint: '09170000001',
                keyboardType: TextInputType.phone,
                controller: _contactController,
              ),
              if (_selectedRole == 'rider') ...[
                const SizedBox(height: 16),
                FormTextField(
                  label: 'Vehicle Details',
                  icon: Icons.two_wheeler_outlined,
                  hint: 'Motorcycle - Honda Click 125',
                  controller: _vehicleController,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Available for deliveries'),
                  value: _availabilityStatus,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      _availabilityStatus = value;
                    });
                  },
                ),
              ],
              if (_isEditing) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active account'),
                  subtitle: Text(
                    _isActive
                        ? 'This staff member can access the system.'
                        : 'This staff member is disabled.',
                  ),
                  value: _isActive,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: isMobile
          ? [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: isLoading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
                  : const Text(
                'Save',
                style: TextStyle(color: AppColors.white),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ]
          : [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: isLoading
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.white,
            ),
          )
              : const Text(
            'Save',
            style: TextStyle(color: AppColors.white),
          ),
        ),
      ],
    );
  }
}

class _OverviewItem {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _OverviewItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _OverviewCard extends StatelessWidget {
  final _OverviewItem item;
  final double width;

  const _OverviewCard({
    required this.item,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 22,
                ),
              ),
              const Spacer(),
              Text(
                item.value,
                style: TextStyle(
                  color: item.color,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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

class _StaffInfoBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StaffInfoBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}