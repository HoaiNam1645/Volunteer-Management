/// Application-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'Volunteer App';
  static const String appVersion = '1.0.0';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String localeKey = 'locale';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Timeouts
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  static const int maxBioLength = 500;
}

/// User roles matching backend
enum UserRole {
  volunteer('tinh_nguyen_vien', 'Tình nguyện viên'),
  reviewer('kiem_duyet_vien', 'Kiểm duyệt viên'),
  admin('quan_tri_vien', 'Quản trị viên');

  final String value;
  final String displayName;

  const UserRole(this.value, this.displayName);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => UserRole.volunteer,
    );
  }
}

/// User status for admin management
enum UserStatus {
  active('kich_hoat', 'Kích hoạt'),
  inactive('vo_hieu_hoa', 'Vô hiệu hóa');

  final String value;
  final String displayName;

  const UserStatus(this.value, this.displayName);

  static UserStatus fromString(String value) {
    return UserStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => UserStatus.active,
    );
  }
}

/// Campaign status matching backend
enum CampaignStatus {
  nhap('nhap', 'Nháp'),
  choDuyet('cho_duyet', 'Chờ duyệt'),
  daDuyet('da_duyet', 'Đã duyệt'),
  tuChoi('tu_choi', 'Từ chối'),
  dangDienRa('dang_dien_ra', 'Đang diễn ra'),
  daKetThuc('da_ket_thuc', 'Đã kết thúc'),
  daHuy('da_huy', 'Đã hủy');

  final String value;
  final String displayName;

  const CampaignStatus(this.value, this.displayName);

  static CampaignStatus fromString(String value) {
    return CampaignStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => CampaignStatus.nhap,
    );
  }

  bool get isEditable => this == nhap || this == tuChoi;
  bool get isPending => this == choDuyet;
  bool get isActive => this == daDuyet || this == dangDienRa;
}

/// Registration status matching backend
enum RegistrationStatus {
  choXacNhan('cho_xac_nhan', 'Chờ xác nhận'),
  daXacNhan('da_xac_nhan', 'Đã xác nhận'),
  daThamGia('da_tham_gia', 'Đã tham gia'),
  voHieuHoa('vo_hieu_hoa', 'Vô hiệu hóa');

  final String value;
  final String displayName;

  const RegistrationStatus(this.value, this.displayName);

  static RegistrationStatus fromString(String value) {
    return RegistrationStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => RegistrationStatus.choXacNhan,
    );
  }
}

/// Report status
enum ReportStatus {
  choXuLy('cho_xu_ly', 'Chờ xử lý'),
  daXuLy('da_xu_ly', 'Đã xử lý'),
  tuChoi('tu_choi', 'Từ chối');

  final String value;
  final String displayName;

  const ReportStatus(this.value, this.displayName);

  static ReportStatus fromString(String value) {
    return ReportStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ReportStatus.choXuLy,
    );
  }
}

/// Permissions
class Permissions {
  static const String dashboardView = 'dashboard.view';
  static const String accountCenterView = 'account_center.view';
  static const String accountCenterManage = 'account_center.manage';
  static const String competencyProfileView = 'competency_profile.view';
  static const String competencyProfileManage = 'competency_profile.manage';
  static const String volunteerCampaignsView = 'volunteer_campaigns.view';
  static const String volunteerCampaignsManage = 'volunteer_campaigns.manage';
  static const String campaignParticipation = 'campaign_participation.manage';
  static const String campaignCoordinationView = 'campaign_coordination.view';
  static const String campaignCoordinationManage = 'campaign_coordination.manage';
  static const String campaignReportMonitoringView = 'campaign_report_monitoring.view';
  static const String feedbackTrackingView = 'feedback_tracking.view';
  static const String feedbackTrackingManage = 'feedback_tracking.manage';
  static const String aiRecommendationView = 'ai_recommendation.view';
  static const String userManagementView = 'user_management.view';
  static const String userManagementManage = 'user_management.manage';
  static const String permissionManagementView = 'permission_management.view';
  static const String permissionManagementManage = 'permission_management.manage';
  static const String categoryManagementView = 'category_management.view';
  static const String categoryManagementManage = 'category_management.manage';
  static const String aiManagementView = 'ai_management.view';
  static const String statisticsView = 'statistics.view';
  static const String trustEvalView = 'trust_eval.view';
  static const String trustEvalRefresh = 'trust_eval.refresh';
  static const String campaignReviewView = 'campaign_review.view';
  static const String campaignReviewManage = 'campaign_review.manage';
}
