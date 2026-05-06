class TnvMenuItem {
  final String key;
  final String path;
  final String label;
  final List<String> requiredPermissions;
  final bool isGuestAllowed;
  final List<TnvMenuItem> children;

  const TnvMenuItem({
    required this.key,
    required this.path,
    required this.label,
    this.requiredPermissions = const [],
    this.isGuestAllowed = false,
    this.children = const [],
  });

  bool get hasChildren => children.isNotEmpty;
}

class TnvMenuSpec {
  static const home = TnvMenuItem(
    key: 'home',
    path: '/',
    label: 'Home',
    isGuestAllowed: true,
  );

  static const campaigns = TnvMenuItem(
    key: 'campaigns',
    path: '/campaigns',
    label: 'Chiến dịch',
    isGuestAllowed: true,
    children: [
      TnvMenuItem(
        key: 'campaign_list',
        path: '/campaigns',
        label: 'Danh sách chiến dịch',
        isGuestAllowed: true,
      ),
      TnvMenuItem(
        key: 'my_campaigns',
        path: '/my-campaigns',
        label: 'Quản lý chiến dịch',
        requiredPermissions: ['volunteer_campaigns.view'],
      ),
    ],
  );

  static const coordination = TnvMenuItem(
    key: 'coordination',
    path: '/dieu-phoi-nhan-su',
    label: 'Điều phối',
    children: [
      TnvMenuItem(
        key: 'hr_coordination',
        path: '/dieu-phoi-nhan-su',
        label: 'Điều phối nhân sự',
        requiredPermissions: ['campaign_coordination.view'],
      ),
      TnvMenuItem(
        key: 'report_monitoring',
        path: '/giam-sat-bao-cao',
        label: 'Giám sát báo cáo',
        requiredPermissions: ['campaign_report_monitoring.view'],
      ),
    ],
  );

  static const profile = TnvMenuItem(
    key: 'profile',
    path: '/profile',
    label: 'Hồ sơ',
    children: [
      TnvMenuItem(
        key: 'account_profile',
        path: '/profile',
        label: 'Thông tin cá nhân',
        requiredPermissions: ['account_center.view'],
      ),
      TnvMenuItem(
        key: 'competency_profile',
        path: '/competency-profile',
        label: 'Hồ sơ năng lực',
        requiredPermissions: ['competency_profile.view'],
      ),
      TnvMenuItem(
        key: 'feedback_tracking',
        path: '/feedback',
        label: 'Theo dõi phản hồi',
        requiredPermissions: ['feedback_tracking.view'],
      ),
    ],
  );

  static const topLevel = <TnvMenuItem>[
    home,
    campaigns,
    coordination,
    profile,
  ];

  static const publicGuestRoutes = <String>{
    '/',
    '/campaigns',
    '/terms',
    '/privacy',
  };

  static const protectedRoutes = <String>{
    '/my-campaigns',
    '/feedback',
    '/profile',
    '/competency-profile',
    '/dieu-phoi-nhan-su',
    '/giam-sat-bao-cao',
  };
}

