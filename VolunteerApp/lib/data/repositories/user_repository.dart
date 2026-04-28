import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/user_model.dart';

class UserRepository {
  final ApiClient _apiClient = ApiClient.instance;

  // ============ GET MY PROFILE ============
  Future<UserResult> getMyProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.userInfo);
      final user = User.fromJson(response.data['data']);
      return UserResult.success(user);
    } catch (e) {
      return UserResult.failure('Không thể tải thông tin cá nhân');
    }
  }

  // ============ UPDATE PROFILE ============
  Future<UserResult> updateProfile({
    String? hoTen,
    String? soDienThoai,
    String? gioiTinh,
    String? ngaySinh,
    String? soCccd,
    String? gioiThieu,
    String? diaChiDuong,
    double? viDo,
    double? kinhDo,
    int? tinhThanhId,
    int? phuongXaId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.updateUserInfo,
        data: {
          if (hoTen != null) 'ho_ten': hoTen,
          if (soDienThoai != null) 'so_dien_thoai': soDienThoai,
          if (gioiTinh != null) 'gioi_tinh': gioiTinh,
          if (ngaySinh != null) 'ngay_sinh': ngaySinh,
          if (soCccd != null) 'so_cccd': soCccd,
          if (gioiThieu != null) 'gioi_thieu': gioiThieu,
          if (diaChiDuong != null) 'dia_chi_duong': diaChiDuong,
          if (viDo != null) 'vi_do': viDo,
          if (kinhDo != null) 'kinh_do': kinhDo,
          if (tinhThanhId != null) 'tinh_thanh_id': tinhThanhId,
          if (phuongXaId != null) 'phuong_xa_id': phuongXaId,
        },
      );
      if (response.data['status'] == 1) {
        return UserResult.success(null);
      }
      return UserResult.failure(response.data['message'] ?? 'Cập nhật thất bại');
    } catch (e) {
      return UserResult.failure('Không thể cập nhật thông tin');
    }
  }

  // ============ CHANGE PASSWORD ============
  Future<OperationResult> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.changePassword,
        data: {
          'mat_khau_cu': currentPassword,
          'mat_khau': newPassword,
          'mat_khau_xac_nhan': newPasswordConfirmation,
        },
      );
      if (response.data['status'] == 1) {
        return OperationResult.success(response.data['message'] ?? 'Đổi mật khẩu thành công');
      }
      return OperationResult.failure(response.data['message'] ?? 'Đổi mật khẩu thất bại');
    } catch (e) {
      return OperationResult.failure('Không thể đổi mật khẩu');
    }
  }

  // ============ GET COMPETENCY PROFILE ============
  Future<CompetencyResult> getCompetencyProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.userProfile);
      if (response.data['status'] == 1) {
        return CompetencyResult.success(
          CompetencyProfile.fromJson(response.data['data']),
        );
      }
      return CompetencyResult.failure(response.data['message'] ?? 'Không lấy được hồ sơ');
    } catch (e) {
      return CompetencyResult.failure('Không thể tải hồ sơ năng lực');
    }
  }

  // ============ UPDATE COMPETENCY PROFILE ============
  Future<OperationResult> updateCompetencyProfile({
    required List<int> kyNangIds,
    required List<int> khuVucIds,
    required List<String> lichRanh,
    required String khungGioUuTien,
  }) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.userProfile,
        data: {
          'ky_nang_ids': kyNangIds,
          'khu_vuc_ids': khuVucIds,
          'lich_ranh': lichRanh,
          'khung_gio_uu_tien': khungGioUuTien,
        },
      );
      if (response.data['status'] == 1) {
        return OperationResult.success(response.data['message'] ?? 'Cập nhật thành công');
      }
      return OperationResult.failure(response.data['message'] ?? 'Cập nhật thất bại');
    } catch (e) {
      return OperationResult.failure('Không thể cập nhật hồ sơ năng lực');
    }
  }

  // ============ GET SKILLS ============
  Future<SkillListResult> getSkills() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.categorySkills);
      final skills = (response.data['data'] as List)
          .map((e) => Skill.fromJson(e))
          .toList();
      return SkillListResult.success(skills);
    } catch (e) {
      return SkillListResult.failure('Không thể tải danh sách kỹ năng');
    }
  }

  // ============ ADD SKILL ============
  Future<OperationResult> addSkill(String ten, {String? moTa}) async {
    try {
      await _apiClient.post(
        ApiEndpoints.userSkill,
        data: {
          'ten': ten,
          if (moTa != null) 'mo_ta': moTa,
        },
      );
      return OperationResult.success('Đã thêm kỹ năng');
    } catch (e) {
      return OperationResult.failure('Không thể thêm kỹ năng');
    }
  }

  // ============ DELETE SKILL ============
  Future<OperationResult> deleteSkill(int id) async {
    try {
      await _apiClient.delete('${ApiEndpoints.categorySkills}/$id');
      return OperationResult.success('Đã xóa kỹ năng');
    } catch (e) {
      return OperationResult.failure('Không thể xóa kỹ năng');
    }
  }
}

// ============ RESULT CLASSES ============
class UserResult {
  final bool success;
  final User? user;
  final String? message;

  UserResult({required this.success, this.user, this.message});

  factory UserResult.success(User? user, {String? message}) {
    return UserResult(success: true, user: user, message: message);
  }

  factory UserResult.failure(String message) {
    return UserResult(success: false, message: message);
  }
}

class CompetencyResult {
  final bool success;
  final CompetencyProfile? profile;
  final String? message;

  CompetencyResult({required this.success, this.profile, this.message});

  factory CompetencyResult.success(CompetencyProfile profile) {
    return CompetencyResult(success: true, profile: profile);
  }

  factory CompetencyResult.failure(String message) {
    return CompetencyResult(success: false, message: message);
  }
}

class OperationResult {
  final bool success;
  final String? message;

  OperationResult({required this.success, this.message});

  factory OperationResult.success(String message) {
    return OperationResult(success: true, message: message);
  }

  factory OperationResult.failure(String message) {
    return OperationResult(success: false, message: message);
  }
}

class SkillListResult {
  final bool success;
  final List<Skill> skills;
  final String? message;

  SkillListResult({required this.success, this.skills = const [], this.message});

  factory SkillListResult.success(List<Skill> skills) {
    return SkillListResult(success: true, skills: skills);
  }

  factory SkillListResult.failure(String message) {
    return SkillListResult(success: false, message: message);
  }
}
