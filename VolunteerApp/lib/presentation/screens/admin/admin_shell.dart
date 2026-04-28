import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isReviewer = auth.isReviewer;
        final navItems = isReviewer ? _reviewerNavItems : _adminNavItems;

        return Scaffold(
          body: Stack(
            children: [
              child,
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomNavBar(
                  navItems: navItems,
                  selectedIndex: _getSelectedIndex(
                    GoRouterState.of(context).matchedLocation,
                    navItems,
                  ),
                  onTap: (index) {
                    HapticFeedback.lightImpact();
                    context.go(navItems[index].paths.first);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static int _getSelectedIndex(String location, List<_NavItem> navItems) {
    for (int i = 0; i < navItems.length; i++) {
      for (final path in navItems[i].paths) {
        if (location == path || location.startsWith('$path/')) {
          return i;
        }
      }
    }
    return 0;
  }

  static final List<_NavItem> _adminNavItems = [
    _NavItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
      paths: ['/admin'],
    ),
    _NavItem(
      icon: Icons.psychology_outlined,
      selectedIcon: Icons.psychology,
      label: 'Cal điểm',
      paths: ['/admin/trust-eval'],
    ),
    _NavItem(
      icon: Icons.people_outlined,
      selectedIcon: Icons.people,
      label: 'Người dùng',
      paths: ['/admin/users'],
    ),
    _NavItem(
      icon: Icons.category_outlined,
      selectedIcon: Icons.category,
      label: 'Danh mục',
      paths: ['/admin/categories'],
    ),
    _NavItem(
      icon: Icons.more_horiz,
      selectedIcon: Icons.more_horiz,
      label: 'Khác',
      paths: ['/admin/permissions', '/admin/user-permissions'],
      isMore: true,
    ),
  ];

  static final List<_NavItem> _reviewerNavItems = [
    _NavItem(
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag,
      label: 'Chiến dịch',
      paths: ['/reviewer/campaigns'],
    ),
    _NavItem(
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      label: 'Thống kê',
      paths: ['/reviewer/statistics'],
    ),
  ];
}

class _BottomNavBar extends StatelessWidget {
  final List<_NavItem> navItems;
  final int selectedIndex;
  final void Function(int) onTap;

  const _BottomNavBar({
    required this.navItems,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isSelected = index == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    height: 60,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? item.selectedIcon : item.icon,
                          color: isSelected ? const Color(0xFF4F8CF7) : Colors.grey[500],
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? const Color(0xFF4F8CF7) : Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final List<String> paths;
  final bool isMore;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.paths,
    this.isMore = false,
  });
}
