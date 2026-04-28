import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  static final List<_NavItem> _navItems = [
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

  static int _getSelectedIndex(String location) {
    for (int i = 0; i < _navItems.length; i++) {
      for (final path in _navItems[i].paths) {
        if (location == path || location.startsWith('$path/')) {
          return i;
        }
      }
    }
    return 0;
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Khác',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Color(0xFF4F8CF7)),
              title: const Text('Phân quyền'),
              subtitle: const Text('Quản lý quyền kiểm duyệt viên'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/admin/permissions');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_pin, color: Color(0xFF4F8CF7)),
              title: const Text('Phân quyền User'),
              subtitle: const Text('Quản lý quyền người dùng'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/admin/user-permissions');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _getSelectedIndex(location);

    return Scaffold(
      body: Stack(
        children: [
          child,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomNavBar(
              navItems: _navItems,
              selectedIndex: selectedIndex,
              onTap: (index) {
                HapticFeedback.lightImpact();
                if (_navItems[index].isMore) {
                  _showMoreMenu(context);
                } else {
                  context.go(_navItems[index].paths.first);
                }
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
        bottom: true,
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
