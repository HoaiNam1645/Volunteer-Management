import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _volunteerNav = [
    _NavItem(path: '/', label: 'Trang chủ', icon: Icons.home_outlined, selectedIcon: Icons.home),
    _NavItem(path: '/campaigns', label: 'Danh sách', icon: Icons.flag_outlined, selectedIcon: Icons.flag),
    _NavItem(path: '/my-campaigns', label: 'Quản lý', icon: Icons.folder_outlined, selectedIcon: Icons.folder),
    _NavItem(path: '/feedback', label: 'Đánh giá', icon: Icons.star_outline, selectedIcon: Icons.star),
    _NavItem(path: '/profile', label: 'Tài khoản', icon: Icons.person_outline, selectedIcon: Icons.person),
  ];

  static const _reviewerNav = [
    _NavItem(path: '/coordinator', label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard),
    _NavItem(path: '/campaigns', label: 'Chiến dịch', icon: Icons.search_outlined, selectedIcon: Icons.search),
    _NavItem(path: '/dieu-phoi-nhan-su', label: 'Điều phối', icon: Icons.sync_alt_outlined, selectedIcon: Icons.sync_alt),
    _NavItem(path: '/giam-sat-bao-cao', label: 'Giám sát', icon: Icons.assessment_outlined, selectedIcon: Icons.assessment),
    _NavItem(path: '/profile', label: 'Tài khoản', icon: Icons.person_outline, selectedIcon: Icons.person),
  ];

  static const _adminNav = [
    _NavItem(path: '/admin', label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard),
    _NavItem(path: '/admin/users', label: 'Người dùng', icon: Icons.people_outline, selectedIcon: Icons.people),
    _NavItem(path: '/admin/trust-eval', label: 'Cal điểm', icon: Icons.psychology_outlined, selectedIcon: Icons.psychology),
    _NavItem(path: '/admin/categories', label: 'Danh mục', icon: Icons.category_outlined, selectedIcon: Icons.category),
  ];

  static int _getSelectedIndex(String location, List<_NavItem> nav) {
    for (int i = 0; i < nav.length; i++) {
      if (location == nav[i].path || location.startsWith('${nav[i].path}/')) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final location = GoRouterState.of(context).matchedLocation;
    final navItems = authProvider.isAdmin
        ? _adminNav
        : (authProvider.isReviewer ? _reviewerNav : _volunteerNav);
    final selectedIndex = _getSelectedIndex(location, navItems);

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
              selectedIndex: selectedIndex,
              onTap: (index) {
                HapticFeedback.lightImpact();
                context.go(navItems[index].path);
              },
            ),
          ),
        ],
      ),
    );
  }
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
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}
