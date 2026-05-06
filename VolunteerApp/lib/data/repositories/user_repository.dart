import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/user_model.dart';

class UserRepository {
  final ApiClient _apiClient = ApiClient.instance;

  // ============ GET MY PROFILE ============
  Future<UserResult> getMyProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.userInfo);
      final raw = response.data;
      // Backend có thể trả: {status:1, data:{...}} HOẶC trực tiếp {...}
      final dataMap = raw is Map<String, dynamic>
          ? (raw['data'] is Map<String, dynamic>
              ? raw['data'] as Map<String, dynamic>
              : raw)
          : <String, dynamic>{};
      // ignore: avoid_print
      print('[getMyProfile] payload keys: ${dataMap.keys.toList()}');
      final user = User.fromJson(dataMap);
      return UserResult.success(user);
    } catch (e, st) {
      // ignore: avoid_print
      print('[getMyProfile] error: $e\n$st');
      return UserResult.failure('Không thể tải thông tin cá nhân: $e');
    }
  }

  // ============ UPDATE PROFILE (multipart, hỗ trợ avatar) ============
  Future<UserResult> updateProfile({
    String? hoTen,
    String? soDienThoai,
    String? gioiTinh,
    String? ngaySinh,
    String? soCccd,
    String? gioiThieu,
    String? diaChiDuong,
    String? viDo,
    String? kinhDo,
    String? tinhThanhId,
    String? phuongXaId,
    Map<String, bool>? tuyChonThongBao,
    File? avatarFile,
  }) async {
    try {
      final fields = <String, dynamic>{};
      if (hoTen != null) fields['ho_ten'] = hoTen;
      if (soDienThoai != null) fields['so_dien_thoai'] = soDienThoai;
      if (gioiTinh != null) fields['gioi_tinh'] = gioiTinh;
      if (ngaySinh != null) fields['ngay_sinh'] = ngaySinh;
      if (soCccd != null) fields['so_cccd'] = soCccd;
      if (gioiThieu != null) fields['gioi_thieu'] = gioiThieu;
      if (diaChiDuong != null) fields['dia_chi_duong'] = diaChiDuong;
      if (viDo != null) fields['vi_do'] = viDo;
      if (kinhDo != null) fields['kinh_do'] = kinhDo;
      if (tinhThanhId != null) fields['tinh_thanh_id'] = tinhThanhId;
      if (phuongXaId != null) fields['phuong_xa_id'] = phuongXaId;
      if (tuyChonThongBao != null) {
        tuyChonThongBao.forEach((k, v) {
          fields['tuy_chon_thong_bao[$k]'] = v ? '1' : '0';
        });
      }
      if (avatarFile != null) {
        fields['anh_dai_dien'] = await MultipartFile.fromFile(
          avatarFile.path,
          filename: avatarFile.path.split(RegExp(r'[\\/]')).last,
        );
      }

      final formData = FormData.fromMap(fields);
      final response = await _apiClient.postFormData(
        ApiEndpoints.updateUserInfo,
        data: formData,
      );
      if (response.data['status'] == 1) {
        final data = response.data['data'];
        return UserResult.success(
          data is Map<String, dynamic> ? User.fromJson(data) : null,
          message: response.data['message'],
        );
      }
      return UserResult.failure(response.data['message'] ?? 'Cập nhật thất bại');
    } catch (e) {
      return UserResult.failure('Không thể cập nhật thông tin');
    }
  }

  // ============ CHANGE PASSWORD ============
  Future<OperationResult> changePassword({
    String? currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.changePassword,
        data: {
          if (currentPassword != null && currentPassword.isNotEmpty)
            'mat_khau_cu': currentPassword,
          'mat_khau_moi': newPassword,
          'mat_khau_moi_confirmation': newPasswordConfirmation,
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

  // ============ PROVINCES / WARDS ============
  Future<List<ProvinceItem>> getProvinces() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.categoryProvinces);
      final list = (response.data['data'] as List? ?? [])
          .map((e) => ProvinceItem.fromJson(e))
          .toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<List<WardItem>> getWards(int tinhThanhId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.categoryWards,
        queryParameters: {'tinh_thanh_id': tinhThanhId},
      );
      final list = (response.data['data'] as List? ?? [])
          .map((e) => WardItem.fromJson(e))
          .toList();
      return list;
    } catch (_) {
      return [];
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
    List<ExperienceItem> kinhNghiems = const [],
    List<CertificateItem> chungChis = const [],
  }) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.userProfile,
        data: {
          'ky_nang_ids': kyNangIds,
          'khu_vuc_ids': khuVucIds,
          'lich_ranh': lichRanh,
          'khung_gio_uu_tien': khungGioUuTien,
          'kinh_nghiems': kinhNghiems
              .where((e) => e.tieuDe.trim().isNotEmpty)
              .map((e) => {
                    'tieu_de': e.tieuDe,
                    'to_chuc': (e.toChuc ?? '').isEmpty ? null : e.toChuc,
                    'thoi_gian': (e.thoiGian ?? '').isEmpty ? null : e.thoiGian,
                    'mo_ta': (e.moTa ?? '').isEmpty ? null : e.moTa,
                  })
              .toList(),
          'chung_chis': chungChis
              .where((c) => c.ten.trim().isNotEmpty)
              .map((c) => {
                    'ten': c.ten,
                    'don_vi_cap': (c.donViCap ?? '').isEmpty ? null : c.donViCap,
                  })
              .toList(),
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

  // ============ GET SKILLS (catalog) ============
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

  // ============ GET REGIONS (catalog) ============
  Future<RegionListResult> getRegions() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.categoryAreas);
      final regions = (response.data['data'] as List)
          .map((e) => RegionItem.fromJson(e))
          .toList();
      return RegionListResult.success(regions);
    } catch (e) {
      return RegionListResult.failure('Không thể tải danh sách khu vực');
    }
  }

  // ============ CREATE SKILL (volunteer self-add) ============
  Future<SkillCreateResult> createSkill(String ten, {String? moTa}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.userSkill,
        data: {
          'ten': ten,
          if (moTa != null) 'mo_ta': moTa,
        },
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return SkillCreateResult.success(Skill.fromJson(data));
      }
      return SkillCreateResult.failure(response.data?['message'] ?? 'Không thể thêm kỹ năng');
    } catch (e) {
      return SkillCreateResult.failure('Không thể thêm kỹ năng mới');
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

class RegionItem {
  final int id;
  final String ten;
  const RegionItem({required this.id, required this.ten});
  factory RegionItem.fromJson(Map<String, dynamic> json) => RegionItem(
        id: json['id'] ?? 0,
        ten: json['ten'] ?? '',
      );
}

class ProvinceItem {
  final int id;
  final String ten;
  final double? viDo;
  final double? kinhDo;
  const ProvinceItem({required this.id, required this.ten, this.viDo, this.kinhDo});
  factory ProvinceItem.fromJson(Map<String, dynamic> json) => ProvinceItem(
        id: json['id'] ?? 0,
        ten: json['ten'] ?? '',
        viDo: (json['vi_do'] as num?)?.toDouble(),
        kinhDo: (json['kinh_do'] as num?)?.toDouble(),
      );
}

class WardItem {
  final int id;
  final String ten;
  final double? viDo;
  final double? kinhDo;
  const WardItem({required this.id, required this.ten, this.viDo, this.kinhDo});
  factory WardItem.fromJson(Map<String, dynamic> json) => WardItem(
        id: json['id'] ?? 0,
        ten: json['ten'] ?? '',
        viDo: (json['vi_do'] as num?)?.toDouble(),
        kinhDo: (json['kinh_do'] as num?)?.toDouble(),
      );
}

class RegionListResult {
  final bool success;
  final List<RegionItem> regions;
  final String? message;
  RegionListResult({required this.success, this.regions = const [], this.message});
  factory RegionListResult.success(List<RegionItem> regions) =>
      RegionListResult(success: true, regions: regions);
  factory RegionListResult.failure(String message) =>
      RegionListResult(success: false, message: message);
}

class SkillCreateResult {
  final bool success;
  final Skill? skill;
  final String? message;
  SkillCreateResult({required this.success, this.skill, this.message});
  factory SkillCreateResult.success(Skill skill) =>
      SkillCreateResult(success: true, skill: skill);
  factory SkillCreateResult.failure(String message) =>
      SkillCreateResult(success: false, message: message);
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
