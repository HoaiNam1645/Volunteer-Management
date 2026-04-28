/// API endpoints matching Laravel backend
/// Base path: /api

class ApiEndpoints {
  ApiEndpoints._();

  // ============ AUTH ============
  static const String login = '/xac-thuc/dang-nhap';
  static const String register = '/xac-thuc/dang-ky';
  static const String logout = '/xac-thuc/dang-xuat';
  static const String forgotPassword = '/xac-thuc/quen-mat-khau';
  static const String resetPassword = '/xac-thuc/dat-lai-mat-khau';
  static const String emailVerify = '/xac-thuc/xac-thuc-email';
  static const String googleAuth = '/xac-thuc/google';
  static const String me = '/xac-thuc/thong-tin';

  // ============ USER ============
  static const String userInfo = '/nguoi-dung/thong-tin';
  static const String updateUserInfo = '/nguoi-dung/cap-nhat-thong-tin';
  static const String changePassword = '/nguoi-dung/doi-mat-khau';
  static const String userProfile = '/nguoi-dung/ho-so-nang-luc';
  static const String userSkill = '/nguoi-dung/ky-nang';

  // ============ CAMPAIGNS (Public) ============
  static const String campaigns = '/chien-dich';
  static const String campaignFilter = '/chien-dich/bo-loc';
  static const String campaignSearch = '/chien-dich/tim-kiem';
  static String campaignDetail(int id) => '/chien-dich/$id';

  // Campaign registration (auth required)
  static String campaignRegister(int id) => '/chien-dich/$id/dang-ky';
  static String campaignCancel(int id) => '/chien-dich/$id/huy-dang-ky';
  static String campaignConfirm(int id) => '/chien-dich/$id/xac-nhan-tham-gia';
  static String campaignInviteVolunteer(int id) => '/chien-dich/$id/moi-tinh-nguyen-vien';

  // Volunteer campaigns
  static const String volunteerCampaigns = '/tinh-nguyen-vien/chien-dich';
  static String volunteerCampaignDetail(int id) => '/tinh-nguyen-vien/chien-dich/$id';
  static String volunteerCampaignStatus(int id) => '/tinh-nguyen-vien/chien-dich/$id/trang-thai';
  static String volunteerCampaignCancel(int id) => '/tinh-nguyen-vien/chien-dich/$id/huy';
  static String volunteerCampaignRegistrationStatus(int id, int registrationId) =>
      '/tinh-nguyen-vien/chien-dich/$id/dang-ky/$registrationId/trang-thai';
  static String volunteerCampaignMonitor(int id) =>
      '/tinh-nguyen-vien/chien-dich/$id/giam-sat-bao-cao';

  static String createVolunteerCampaign() => '/tinh-nguyen-vien/chien-dich';
  static String updateVolunteerCampaign(int id) => '/tinh-nguyen-vien/chien-dich/$id';

  // ============ REGISTRATIONS ============
  static const String registrations = '/dang-ky';
  static String registrationDetail(int id) => '/dang-ky/$id';
  static String registrationCancel(int id) => '/dang-ky/$id/huy';

  // ============ FEEDBACK ============
  static const String feedback = '/phan-hoi';
  static const String feedbackTracking = '/tinh-nguyen-vien/theo-doi-phan-hoi';
  static const String feedbackCampaign = '/tinh-nguyen-vien/theo-doi-phan-hoi/danh-gia-chien-dich';
  static const String feedbackReport = '/tinh-nguyen-vien/theo-doi-phan-hoi/bao-cao';

  // ============ CATEGORIES (Public) ============
  static const String categories = '/danh-muc';
  static const String categorySkills = '/danh-muc/ky-nang';
  static const String categoryAreas = '/danh-muc/khu-vuc';
  static const String categoryProvinces = '/danh-muc/tinh-thanh';
  static const String categoryWards = '/danh-muc/phuong-xa';
  static const String categoryCampaignTypes = '/danh-muc/loai-chien-dich';

  // ============ HOME ============
  static const String home = '/trang-chu';

  // ============ RECOMMENDATION ============
  static const String recommendations = '/goi-y';

  // ============ REVIEWER ============
  static const String reviewerCampaigns = '/kiem-duyet/chien-dich';
  static const String reviewerCampaignFilter = '/kiem-duyet/chien-dich/bo-loc';
  static String reviewerCampaignDetail(int id) => '/kiem-duyet/chien-dich/$id';
  static String reviewerCampaignFeedback(int id) => '/kiem-duyet/chien-dich/$id/feedback';
  static String reviewerCampaignReports(int id) => '/kiem-duyet/chien-dich/$id/bao-cao';
  static String reviewerApprove(int id) => '/kiem-duyet/chien-dich/$id/duyet';
  static String reviewerReject(int id) => '/kiem-duyet/chien-dich/$id/tu-choi';
  static String reviewerApproveCancel(int id) => '/kiem-duyet/chien-dich/$id/yeu-cau-huy/duyet';
  static String reviewerRejectCancel(int id) => '/kiem-duyet/chien-dich/$id/yeu-cau-huy/tu-choi';
  static String reviewerReportProcess(int id) => '/kiem-duyet/bao-cao/$id/xu-ly';
  static const String reviewerStats = '/kiem-duyet/thong-ke';

  // ============ ADMIN ============
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/nguoi-dung';
  static String adminUserDetail(int id) => '/admin/nguoi-dung/$id';
  static String adminUserStatus(int id) => '/admin/nguoi-dung/$id/trang-thai';
  static String adminUserDelete(int id) => '/admin/nguoi-dung/$id';
  static const String adminPermissions = '/admin/phan-quyen';
  static String adminPermissionDetail(int id) => '/admin/phan-quyen/$id';
  static const String adminCategories = '/admin/danh-muc';
  static String adminCategoryCreate(String type) => '/admin/danh-muc/$type';
  static String adminCategoryUpdate(String type, int id) => '/admin/danh-muc/$type/$id';
  static String adminCategoryDelete(String type, int id) => '/admin/danh-muc/$type/$id';

  // ============ TRUST EVAL ============
  static const String trustEvalDashboard = '/trust-eval/campaigns/pending';
  static String trustEvalCampaign(int id) => '/trust-eval/campaign/$id';
  static String trustEvalVolunteer(int id) => '/trust-eval/volunteer/$id';
  static String trustEvalRefresh(int id) => '/trust-eval/campaign/$id/refresh';
  static const String trustEvalStats = '/trust-eval/statistics';
  static const String trustEvalHealth = '/trust-eval/ml-health';
  static const String trustEvalAgreement = '/trust-eval/agreement-stats';
  static const String trustEvalFeedback = '/trust-eval/feedback';
}
