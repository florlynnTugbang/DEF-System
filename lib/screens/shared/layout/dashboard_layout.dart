import 'package:defsystem/core/theme/app_colors.dart';
import 'package:defsystem/core/theme/app_spacing.dart';
import 'package:defsystem/providers/auth_provider.dart';
import 'package:defsystem/screens/auth/landing_screen.dart';
import 'package:defsystem/screens/dispatcher/dispatcher_dashboard_screen.dart';
import 'package:defsystem/screens/dispatcher/requests_list_screen.dart';
import 'package:defsystem/screens/dispatcher/rider_management_screen.dart';
import 'package:defsystem/screens/management/customers_screen.dart';
import 'package:defsystem/screens/management/issues_log_screen.dart';
import 'package:defsystem/screens/management/management_dashboard_screen.dart';
import 'package:defsystem/screens/management/reports_screen.dart';
import 'package:defsystem/screens/management/user_management_screen.dart';
import 'package:defsystem/screens/rider/rider_dashboard_screen.dart';
import 'package:defsystem/screens/rider/rider_history_screen.dart';
import 'package:defsystem/screens/shared/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardLayout extends ConsumerStatefulWidget {
  const DashboardLayout({super.key});

  @override
  ConsumerState<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends ConsumerState<DashboardLayout> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = false;

  static const double _collapsedWidth = 86;
  static const double _expandedWidth = 286;

  List<Map<String, dynamic>> _getNavItems(String role) {
    switch (role) {
      case 'admin':
        return [
          {
            'icon': Icons.dashboard_outlined,
            'label': 'Dashboard',
            'body': const ManagementDashboardScreen(),
          },
          {
            'icon': Icons.assessment_outlined,
            'label': 'Reports',
            'body': const ReportsScreen(),
          },
          {
            'icon': Icons.report_gmailerrorred_outlined,
            'label': 'Issues Log',
            'body': const IssuesLogScreen(),
          },
          {
            'icon': Icons.people_outline,
            'label': 'Customers',
            'body': const CustomersScreen(),
          },
          {
            'icon': Icons.manage_accounts_outlined,
            'label': 'Users',
            'body': const UserManagementScreen(),
          },
          {
            'icon': Icons.person_outline,
            'label': 'Profile',
            'body': const ProfileScreen(),
          },
        ];

      case 'dispatcher':
        return [
          {
            'icon': Icons.grid_view_rounded,
            'label': 'Dashboard',
            'body': const DispatcherDashboard(),
          },
          {
            'icon': Icons.inventory_2_outlined,
            'label': 'Deliveries',
            'body': const RequestListScreen(),
          },
          {
            'icon': Icons.report_problem_outlined,
            'label': 'Issues',
            'body': const IssuesLogScreen(),
          },
          {
            'icon': Icons.people_outline,
            'label': 'Riders',
            'body': const RiderManagementScreen(),
          },
          {
            'icon': Icons.person_outline,
            'label': 'Profile',
            'body': const ProfileScreen(),
          },
        ];

      case 'rider':
        return [
          {
            'icon': Icons.directions_bike_outlined,
            'label': 'My Tasks',
            'body': const RiderDashboard(),
          },
          {
            'icon': Icons.history_rounded,
            'label': 'History',
            'body': const DeliveryHistory(),
          },
          {
            'icon': Icons.person_outline,
            'label': 'Profile',
            'body': const ProfileScreen(),
          },
        ];

      default:
        return [
          {
            'icon': Icons.error_outline,
            'label': 'Invalid Role',
            'body': const Center(
              child: Text(
                'Invalid user role. Please contact the administrator.',
              ),
            ),
          },
        ];
    }
  }

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _expandSidebar() {
    if (!_isSidebarExpanded) {
      setState(() {
        _isSidebarExpanded = true;
      });
    }
  }

  void _collapseSidebar() {
    if (_isSidebarExpanded) {
      setState(() {
        _isSidebarExpanded = false;
      });
    }
  }

  int _profileIndex(List<Map<String, dynamic>> navItems) {
    return navItems.indexWhere((item) => item['label'] == 'Profile');
  }

  List<Map<String, dynamic>> _mobileNavItems(List<Map<String, dynamic>> navItems) {
    return navItems.where((item) => item['label'] != 'Profile').toList();
  }

  int _realIndexFromMobileItem(
      List<Map<String, dynamic>> allItems,
      Map<String, dynamic> mobileItem,
      ) {
    return allItems.indexWhere((item) => item['label'] == mobileItem['label']);
  }

  Future<void> _handleLogout() async {
    await ref.read(authProvider.notifier).signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingPage()),
          (route) => false,
    );
  }

  Future<void> _confirmLogout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _handleLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final role = authState.role ?? '';
    final navItems = _getNavItems(role);

    if (_selectedIndex >= navItems.length) {
      _selectedIndex = 0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 800;

        if (isMobile) {
          return _buildMobileLayout(authState, navItems);
        }

        return _buildDesktopLayout(authState, navItems);
      },
    );
  }

  Widget _buildDesktopLayout(
      AuthState authState,
      List<Map<String, dynamic>> navItems,
      ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _buildDesktopSidebar(authState, navItems),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _collapseSidebar,
              child: ColoredBox(
                color: AppColors.background,
                child: navItems[_selectedIndex]['body'] as Widget,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(
      AuthState authState,
      List<Map<String, dynamic>> navItems,
      ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _expandSidebar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: _isSidebarExpanded ? _expandedWidth : _collapsedWidth,
        decoration: const BoxDecoration(
          color: AppColors.primary,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildDesktopHeader(),
              if (_isSidebarExpanded) _buildUserSection(authState),
              const Divider(
                color: Colors.white12,
                height: 1,
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  itemCount: navItems.length,
                  itemBuilder: (context, index) {
                    return _buildDesktopNavItem(navItems, index);
                  },
                ),
              ),
              _buildDesktopLogoutTile(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
      AuthState authState,
      List<Map<String, dynamic>> navItems,
      ) {
    final mobileItems = _mobileNavItems(navItems);
    final profileIndex = _profileIndex(navItems);

    final selectedLabel = navItems[_selectedIndex]['label'].toString();

    int mobileCurrentIndex = mobileItems.indexWhere(
          (item) => item['label'] == selectedLabel,
    );

    if (mobileCurrentIndex < 0) {
      mobileCurrentIndex = 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(85),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: AppColors.primary,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 20,
          toolbarHeight: 85,
          title: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedLabel,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  authState.roleLabel,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 14, right: 8),
              child: _buildMobileProfileCircle(
                authState: authState,
                onTap: profileIndex == -1
                    ? null
                    : () {
                  setState(() {
                    _selectedIndex = profileIndex;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 14, right: 16),
              child: _buildMobileIconCircle(
                icon: Icons.logout_rounded,
                onTap: _confirmLogout,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: navItems[_selectedIndex]['body'] as Widget,
      ),
      bottomNavigationBar: _buildMobileBottomNav(
        allItems: navItems,
        mobileItems: mobileItems,
        currentIndex: mobileCurrentIndex,
      ),
    );
  }

  Widget _buildMobileBottomNav({
    required List<Map<String, dynamic>> allItems,
    required List<Map<String, dynamic>> mobileItems,
    required int currentIndex,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            final realIndex = _realIndexFromMobileItem(
              allItems,
              mobileItems[index],
            );

            if (realIndex != -1) {
              _selectPage(realIndex);
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          items: mobileItems.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item['icon'] as IconData),
              label: item['label'].toString(),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileProfileCircle({
    required AuthState authState,
    required VoidCallback? onTap,
  }) {
    final name = authState.displayName.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileIconCircle({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    if (!_isSidebarExpanded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 30, 18, 24),
        child: Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: const Icon(
            Icons.local_shipping_outlined,
            color: AppColors.white,
            size: 26,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: AppColors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEF',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3),
                Text(
                  'DispatchTrack',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSection(AuthState authState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
      child: Container(
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
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.white.withValues(alpha: 0.16),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authState.displayName.isNotEmpty
                        ? authState.displayName
                        : 'User',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    authState.roleLabel,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopNavItem(List<Map<String, dynamic>> items, int index) {
    final bool isActive = _selectedIndex == index;
    final icon = items[index]['icon'] as IconData;
    final label = items[index]['label'].toString();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _isSidebarExpanded ? AppSpacing.lg : 14,
        vertical: 4,
      ),
      child: Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 350),
        child: InkWell(
          onTap: () {
            _expandSidebar();
            _selectPage(index);
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 48,
            padding: EdgeInsets.symmetric(
              horizontal: _isSidebarExpanded ? 14 : 0,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.white.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: _isSidebarExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isActive ? AppColors.white : AppColors.textLight,
                  size: 22,
                ),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isActive
                            ? AppColors.white
                            : AppColors.textLight,
                        fontWeight:
                        isActive ? FontWeight.w900 : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLogoutTile() {
    return Padding(
      padding: EdgeInsets.all(_isSidebarExpanded ? AppSpacing.lg : 14),
      child: Tooltip(
        message: 'Logout',
        waitDuration: const Duration(milliseconds: 350),
        child: InkWell(
          onTap: _handleLogout,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(
              horizontal: _isSidebarExpanded ? 14 : 0,
            ),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: _isSidebarExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  color: AppColors.textLight,
                  size: 22,
                ),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}