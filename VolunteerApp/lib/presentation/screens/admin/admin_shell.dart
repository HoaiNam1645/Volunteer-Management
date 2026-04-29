import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  final String location;

  const AdminShell({super.key, required this.child, required this.location});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isReviewer = auth.isReviewer;
        final navItems = isReviewer ? _reviewerNavItems : _adminNavItems;

        return Scaffold(
          body: child,
          bottomNavigationBar: _BottomNavBar(
            navItems: navItems,
            selectedIndex: _getSelectedIndex(
              location,
              navItems,
            ),
            onTap: (index) async {
              HapticFeedback.lightImpact();
              final item = navItems[index];
              if (item.isMore) {
                await _showMoreMenu(context, auth);
                return;
              }
              context.go(item.paths.first);
            },
          ),
        );
      },
    );
  }

  static int _getSelectedIndex(String location, List<_NavItem> navItems) {
    for (int i = 0; i < navItems.length; i++) {
      for (final path in navItems[i].paths) {
        if (location == path) {
          return i;
        }
        if (path != '/admin' && location.startsWith('$path/')) {
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

  static Future<void> _showMoreMenu(
      BuildContext context, AuthProvider auth) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Phan quyen kiem duyet'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/admin/permissions');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_pin_outlined),
              title: const Text('Phan quyen nguoi dung'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/admin/user-permissions');
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title:
                  const Text('Dang xuat', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                await auth.logout();
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
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
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF4F8CF7)
                                    .withValues(alpha: 0.14)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            scale: isSelected ? 1.08 : 1.0,
                            child: Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              color: isSelected
                                  ? const Color(0xFF4F8CF7)
                                  : Colors.grey[500],
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          style: TextStyle(
                            fontSize: isSelected ? 10.5 : 10,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF4F8CF7)
                                : Colors.grey[500],
                          ),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
