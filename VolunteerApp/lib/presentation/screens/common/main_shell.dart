import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../config/tnv_menu_spec.dart';
import '../../providers/auth_provider.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _reviewerNav = [
    _NavItem(path: '/reviewer/campaigns', label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard),
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

  // Icon mapping cho 4 nhóm cha của TNV (theo TnvMenuSpec.topLevel)
  static const Map<String, _NavIcon> _tnvIcons = {
    'home': _NavIcon(Icons.home_outlined, Icons.home),
    'campaigns': _NavIcon(Icons.flag_outlined, Icons.flag),
    'coordination': _NavIcon(Icons.people_alt_outlined, Icons.people_alt),
    'profile': _NavIcon(Icons.person_outline, Icons.person),
  };

  // Label hiển thị ngắn gọn cho bottom nav
  static const Map<String, String> _tnvShortLabel = {
    'home': 'Trang chủ',
    'campaigns': 'Chiến dịch',
    'coordination': 'Điều phối',
    'profile': 'Hồ sơ',
  };

  List<_NavItem> _buildVolunteerNav(AuthProvider auth) {
    final tree = auth.visibleTnvMenuTree();
    return tree.map((item) {
      final icon = _tnvIcons[item.key] ?? const _NavIcon(Icons.circle_outlined, Icons.circle);
      return _NavItem(
        path: item.path,
        label: _tnvShortLabel[item.key] ?? item.label,
        icon: icon.outlined,
        selectedIcon: icon.filled,
        children: item.children,
      );
    }).toList();
  }

  static int _getSelectedIndex(String location, List<_NavItem> nav) {
    int? exactIdx;
    int bestPrefixIdx = 0;
    int bestPrefixLen = -1;

    for (int i = 0; i < nav.length; i++) {
      final item = nav[i];
      // Match path đúng của nhóm cha hoặc các mục con
      final allPaths = <String>[item.path, ...item.children.map((c) => c.path)];
      for (final p in allPaths) {
        if (location == p) {
          exactIdx = i;
        } else if (p != '/' && location.startsWith('$p/') && p.length > bestPrefixLen) {
          bestPrefixLen = p.length;
          bestPrefixIdx = i;
        }
      }
    }
    return exactIdx ?? bestPrefixIdx;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final location = GoRouterState.of(context).matchedLocation;
    final List<_NavItem> navItems = authProvider.isAdmin
        ? _adminNav
        : (authProvider.isReviewer ? _reviewerNav : _buildVolunteerNav(authProvider));
    final selectedIndex = navItems.isEmpty ? 0 : _getSelectedIndex(location, navItems);

    return Scaffold(
      body: Stack(
        children: [
          child,
          if (navItems.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomNavBar(
                navItems: navItems,
                selectedIndex: selectedIndex,
                onTap: (index) {
                  HapticFeedback.lightImpact();
                  final item = navItems[index];
                  // Nếu là tab cha có nhiều mục con
                  if (item.children.length > 1) {
                    if (index == selectedIndex) {
                      // Tap lại tab đang chọn → mở sheet chọn mục con
                      _showChildSheet(context, item);
                    } else {
                      // Lần đầu tap tab cha → đi tới mục con đầu tiên có quyền
                      context.go(item.children.first.path);
                    }
                  } else {
                    context.go(item.path);
                  }
                },
                onLongPress: (index) {
                  final item = navItems[index];
                  if (item.children.length > 1) {
                    _showChildSheet(context, item);
                  } else {
                    _showQuickMenu(context, authProvider, navItems);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showChildSheet(BuildContext context, _NavItem parent) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(parent.label, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Chọn mục để mở'),
            ),
            for (final child in parent.children)
              ListTile(
                leading: Icon(_iconForChild(child.key)),
                title: Text(child.label),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  context.go(child.path);
                },
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForChild(String key) {
    switch (key) {
      case 'campaign_list':
        return Icons.list_alt;
      case 'my_campaigns':
        return Icons.folder_outlined;
      case 'hr_coordination':
        return Icons.sync_alt;
      case 'report_monitoring':
        return Icons.assessment_outlined;
      case 'account_profile':
        return Icons.account_circle_outlined;
      case 'competency_profile':
        return Icons.badge_outlined;
      case 'feedback_tracking':
        return Icons.history;
      default:
        return Icons.chevron_right;
    }
  }

  void _showQuickMenu(
    BuildContext context,
    AuthProvider authProvider,
    List<_NavItem> navItems,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Menu nhanh'),
              subtitle: Text('Điều hướng và tài khoản'),
            ),
            for (final item in navItems)
              ListTile(
                leading: Icon(item.icon),
                title: Text(item.label),
                onTap: () {
                  Navigator.pop(context);
                  context.go(item.children.isNotEmpty ? item.children.first.path : item.path);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await authProvider.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
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
  final void Function(int)? onLongPress;

  const _BottomNavBar({
    required this.navItems,
    required this.selectedIndex,
    required this.onTap,
    this.onLongPress,
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
              final hasChildren = item.children.length > 1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  onLongPress: onLongPress != null ? () => onLongPress!(index) : null,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    height: 60,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              color: isSelected ? const Color(0xFF4F8CF7) : Colors.grey[500],
                              size: 24,
                            ),
                            if (hasChildren)
                              Positioned(
                                right: -6,
                                top: -2,
                                child: Icon(
                                  Icons.arrow_drop_down,
                                  size: 14,
                                  color: isSelected ? const Color(0xFF4F8CF7) : Colors.grey[500],
                                ),
                              ),
                          ],
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
  final List<TnvMenuItem> children;

  const _NavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.children = const [],
  });
}

class _NavIcon {
  final IconData outlined;
  final IconData filled;
  const _NavIcon(this.outlined, this.filled);
}
