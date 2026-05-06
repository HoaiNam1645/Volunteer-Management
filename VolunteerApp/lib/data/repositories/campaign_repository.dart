import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/campaign_model.dart';

class CampaignRepository {
  final ApiClient _apiClient = ApiClient.instance;

  /// Parse danh sách campaigns từ response — backend có thể trả 2 dạng:
  /// 1. List trực tiếp: `{status: 1, data: [...]}`
  /// 2. Paginated: `{status: 1, data: {data: [...], current_page, last_page, total}}`
  CampaignListResult _parseCampaignList(dynamic raw, int fallbackPage) {
    if (raw is List) {
      final campaigns = raw.map((e) => Campaign.fromJson(e)).toList();
      return CampaignListResult.success(
        campaigns: campaigns,
        currentPage: 1,
        lastPage: 1,
        total: campaigns.length,
      );
    }
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'];
      final list = inner is List ? inner : const <dynamic>[];
      return CampaignListResult.success(
        campaigns: list.map((e) => Campaign.fromJson(e)).toList(),
        currentPage: (raw['current_page'] is num) ? (raw['current_page'] as num).toInt() : fallbackPage,
        lastPage: (raw['last_page'] is num) ? (raw['last_page'] as num).toInt() : 1,
        total: (raw['total'] is num) ? (raw['total'] as num).toInt() : list.length,
      );
    }
    return CampaignListResult.success(campaigns: const [], currentPage: 1, lastPage: 1, total: 0);
  }

  // ============ GET COORDINATION RECOMMENDATIONS ============
  Future<CoordinationResult> getCoordinationRecommendations({
    required int campaignId,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.recommendations,
        queryParameters: {
          'type': 'tinh_nguyen_vien',
          'mode': 'allocation',
          'campaign_id': campaignId,
          'limit': limit,
          'only_available': 1,
        },
      );
      if (response.data['status'] == 1) {
        return CoordinationResult.success(response.data['data'] ?? {});
      }
      return CoordinationResult.failure(response.data['message'] ?? 'Lỗi');
    } catch (e) {
      return CoordinationResult.failure('Không thể lấy danh sách tình nguyện viên');
    }
  }

  // ============ GET CAMPAIGN MONITORING DATA ============
  Future<MonitoringResult> getCampaignMonitoring(int campaignId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.volunteerCampaignMonitor(campaignId),
      );
      if (response.data['status'] == 1) {
        return MonitoringResult.success(response.data['data'] ?? {});
      }
      return MonitoringResult.failure(response.data['message'] ?? 'Lỗi');
    } catch (e) {
      return MonitoringResult.failure('Không thể lấy dữ liệu giám sát');
    }
  }

  // ============ GET PUBLIC CAMPAIGNS ============
  Future<CampaignListResult> getCampaigns({
    int page = 1,
    int perPage = 20,
    String? search,
    String? trangThai,
    String? loaiChienDich,
    DateTime? tuNgay,
    DateTime? denNgay,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        if (search != null) 'tim_kiem': search,
        if (trangThai != null) 'trang_thai': trangThai,
        if (loaiChienDich != null) 'loai_chien_dich': loaiChienDich,
        if (tuNgay != null) 'tu_ngay': tuNgay.toIso8601String().split('T').first,
        if (denNgay != null) 'den_ngay': denNgay.toIso8601String().split('T').first,
      };

      final response = await _apiClient.get(
        ApiEndpoints.campaigns,
        queryParameters: queryParams,
      );
      return _parseCampaignList(response.data['data'], page);
    } catch (e, st) {
      debugPrint('[getCampaigns] error: $e\n$st');
      return CampaignListResult.failure('Không thể tải danh sách chiến dịch');
    }
  }

  // ============ SEARCH CAMPAIGNS ============
  Future<CampaignListResult> searchCampaigns({
    int page = 1,
    required String query,
    String? trangThai,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.campaignSearch,
        queryParameters: {
          'page': page,
          'q': query,
          if (trangThai != null) 'trang_thai': trangThai,
        },
      );
      return _parseCampaignList(response.data['data'], page);
    } catch (e, st) {
      debugPrint('[searchCampaigns] error: $e\n$st');
      return CampaignListResult.failure('Không thể tìm kiếm chiến dịch');
    }
  }

  // ============ GET CAMPAIGN FILTERS ============
  Future<CampaignFilterResult> getFilters() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.campaignFilter);
      if (response.data['status'] == 1) {
        return CampaignFilterResult.success(response.data['data']);
      }
      return CampaignFilterResult.failure(response.data['message'] ?? 'Lỗi');
    } catch (e) {
      return CampaignFilterResult.failure('Không thể tải bộ lọc');
    }
  }

  // ============ GET CAMPAIGN DETAIL ============
  Future<CampaignResult> getCampaignDetail(int id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.campaignDetail(id));
      final campaign = Campaign.fromJson(response.data['data']);
      return CampaignResult.success(campaign);
    } catch (e) {
      return CampaignResult.failure('Không thể tải chi tiết chiến dịch');
    }
  }

  // ============ GET MY CAMPAIGNS ============
  Future<CampaignListResult> getMyCampaigns({
    int page = 1,
    String? trangThai,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        if (trangThai != null) 'trang_thai': trangThai,
      };

      final response = await _apiClient.get(
        ApiEndpoints.volunteerCampaigns,
        queryParameters: queryParams,
      );
      return _parseCampaignList(response.data['data'], page);
    } catch (e, st) {
      debugPrint('[getMyCampaigns] error: $e\n$st');
      return CampaignListResult.failure('Không thể tải chiến dịch của bạn');
    }
  }

  // ============ CREATE/UPDATE CAMPAIGN (multipart, hỗ trợ ảnh) ============
  /// Match FE behavior: gửi cover (`anh_bia`), ảnh phụ (`anh_phu[]`),
  /// và danh sách URL ảnh đang giữ (`danh_sach_anh_hien_tai[]` cho update).
  /// Khi update, BE Laravel cần `_method=PUT` qua multipart.
  Future<CampaignResult> saveCampaignMultipart({
    int? id, // null = create, có giá trị = update
    required String tieuDe,
    required String moTa,
    int? loaiChienDichId,
    required String diaDiem,
    String? viDo,
    String? kinhDo,
    required DateTime ngayBatDau,
    required DateTime ngayKetThuc,
    DateTime? hanDangKy,
    int soLuongToiThieu = 1,
    int soLuongToiDa = 50,
    String mucDoUuTien = 'trung_binh',
    List<int> kyNangIds = const [],
    File? coverImageFile,
    List<File> detailImageFiles = const [],
    List<String> existingImageUrls = const [],
  }) async {
    try {
      final fields = <String, dynamic>{
        'tieu_de': tieuDe,
        'mo_ta': moTa,
        'dia_diem': diaDiem,
        'ngay_bat_dau': ngayBatDau.toIso8601String().split('T').first,
        'ngay_ket_thuc': ngayKetThuc.toIso8601String().split('T').first,
        'so_luong_toi_thieu': soLuongToiThieu,
        'so_luong_toi_da': soLuongToiDa,
        'muc_do_uu_tien': mucDoUuTien,
        if (loaiChienDichId != null) 'loai_chien_dich_id': loaiChienDichId,
        if (viDo != null && viDo.isNotEmpty) 'vi_do': viDo,
        if (kinhDo != null && kinhDo.isNotEmpty) 'kinh_do': kinhDo,
        if (hanDangKy != null) 'han_dang_ky': hanDangKy.toIso8601String().split('T').first,
      };
      // Skill IDs as kỹ năng_ids[]
      for (var i = 0; i < kyNangIds.length; i++) {
        fields['ky_nang_ids[$i]'] = kyNangIds[i];
      }
      // Existing images (giữ nguyên khi update)
      for (var i = 0; i < existingImageUrls.length; i++) {
        fields['danh_sach_anh_hien_tai[$i]'] = existingImageUrls[i];
      }
      // Cover image
      if (coverImageFile != null) {
        fields['anh_bia'] = await MultipartFile.fromFile(
          coverImageFile.path,
          filename: coverImageFile.path.split(RegExp(r'[\\/]')).last,
        );
      }
      // Detail images
      for (var i = 0; i < detailImageFiles.length; i++) {
        fields['anh_phu[$i]'] = await MultipartFile.fromFile(
          detailImageFiles[i].path,
          filename: detailImageFiles[i].path.split(RegExp(r'[\\/]')).last,
        );
      }
      // Method spoofing cho update qua multipart
      if (id != null) {
        fields['_method'] = 'PUT';
      }

      final formData = FormData.fromMap(fields);
      final url = id == null
          ? ApiEndpoints.createVolunteerCampaign()
          : '${ApiEndpoints.updateVolunteerCampaign(id)}';
      final response = await _apiClient.postFormData(url, data: formData);
      if (response.data['status'] == 1) {
        final c = Campaign.fromJson(response.data['data']);
        return CampaignResult.success(c);
      }
      return CampaignResult.failure(response.data['message'] ?? 'Lưu thất bại');
    } on DioException catch (e) {
      final apiError = _apiClient.handleError(e);
      return CampaignResult.failure(apiError.fullMessage);
    } catch (e, st) {
      debugPrint('[saveCampaignMultipart] error: $e\n$st');
      return CampaignResult.failure('Không thể lưu chiến dịch');
    }
  }

  // ============ CREATE CAMPAIGN (legacy JSON) ============
  Future<CampaignResult> createCampaign(Campaign campaign) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.createVolunteerCampaign(),
        data: campaign.toJson(),
      );
      if (response.data['status'] == 1) {
        final created = Campaign.fromJson(response.data['data']);
        return CampaignResult.success(created);
      }
      return CampaignResult.failure(response.data['message'] ?? 'Tạo thất bại');
    } catch (e) {
      return CampaignResult.failure('Không thể tạo chiến dịch');
    }
  }

  // ============ UPDATE CAMPAIGN (legacy JSON) ============
  Future<CampaignResult> updateCampaign(int id, Campaign campaign) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.updateVolunteerCampaign(id),
        data: campaign.toJson(),
      );
      if (response.data['status'] == 1) {
        final updated = Campaign.fromJson(response.data['data']);
        return CampaignResult.success(updated);
      }
      return CampaignResult.failure(response.data['message'] ?? 'Cập nhật thất bại');
    } catch (e) {
      return CampaignResult.failure('Không thể cập nhật chiến dịch');
    }
  }

  // ============ UPDATE CAMPAIGN STATUS ============
  Future<OperationResult> updateCampaignStatus(int id, String trangThai) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.volunteerCampaignStatus(id),
        data: {'trang_thai': trangThai},
      );
      if (response.data['status'] == 1) {
        return OperationResult.success(response.data['message'] ?? 'Cập nhật thành công');
      }
      return OperationResult.failure(response.data['message'] ?? 'Cập nhật thất bại');
    } on DioException catch (e) {
      final apiError = _apiClient.handleError(e);
      return OperationResult.failure(
        apiError.fullMessage,
        forbidden: apiError.isForbidden,
      );
    } catch (e) {
      return OperationResult.failure('Không thể cập nhật trạng thái');
    }
  }

  // ============ DELETE CAMPAIGN ============
  Future<OperationResult> deleteCampaign(int id) async {
    try {
      // Backend uses DELETE /tinh-nguyen-vien/chien-dich/{id}
      final response = await _apiClient.delete(
        ApiEndpoints.updateVolunteerCampaign(id),
      );
      if (response.data['status'] == 1) {
        return OperationResult.success(response.data['message'] ?? 'Đã xóa chiến dịch');
      }
      return OperationResult.failure(response.data['message'] ?? 'Xóa thất bại');
    } on DioException catch (e) {
      final apiError = _apiClient.handleError(e);
      return OperationResult.failure(
        apiError.fullMessage,
        forbidden: apiError.isForbidden,
      );
    } catch (e) {
      return OperationResult.failure('Không thể xóa chiến dịch');
    }
  }

  // ============ CANCEL CAMPAIGN ============
  Future<OperationResult> cancelCampaign(int id, String lyDo) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.volunteerCampaignCancel(id),
        data: {'ly_do': lyDo},
      );
      if (response.data['status'] == 1) {
        return OperationResult.success(response.data['message'] ?? 'Hủy thành công');
      }
      return OperationResult.failure(response.data['message'] ?? 'Hủy thất bại');
    } on DioException catch (e) {
      final apiError = _apiClient.handleError(e);
      return OperationResult.failure(
        apiError.fullMessage,
        forbidden: apiError.isForbidden,
      );
    } catch (e) {
      return OperationResult.failure('Không thể hủy chiến dịch');
    }
  }

  // ============ GET RECOMMENDED CAMPAIGNS for volunteer ============
  Future<List<RecommendedCampaign>> getRecommendedCampaigns({
    bool nearbyOnly = false,
    String? priority,
    int limit = 6,
  }) async {
    try {
      final params = <String, dynamic>{
        'type': 'chien_dich',
        'limit': limit,
        if (nearbyOnly) 'nearby_only': 1,
        if (priority != null && priority.isNotEmpty) 'priority': priority,
      };
      final response = await _apiClient.get(
        ApiEndpoints.recommendations,
        queryParameters: params,
      );
      final list = (response.data['data'] as List? ?? [])
          .map((e) => RecommendedCampaign.fromJson(e))
          .toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  // ============ GET AI SUGGESTIONS ============
  Future<AISuggestionResult> getAISuggestions(int campaignId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.recommendations,
        queryParameters: {'chien_dich_id': campaignId},
      );
      if (response.data['status'] == 1) {
        return AISuggestionResult.success(
          AISuggestion.fromJson(response.data['data']),
        );
      }
      return AISuggestionResult.failure(response.data['message'] ?? 'Lỗi');
    } catch (e) {
      return AISuggestionResult.failure('Không thể lấy gợi ý AI');
    }
  }

  // ============ GET CAMPAIGNS FOR COORDINATION ============
  Future<CampaignListResult> getCampaignsForCoordination() async {
    try {
      // Giống FE web: per_page=100, trang_thai=da_duyet, for_coordination=1
      // BE dùng for_coordination=1 để chỉ trả campaigns user là người tạo
      // hoặc được phân làm coordinator. Nếu user chỉ đăng ký tham gia (không
      // sở hữu campaign), BE sẽ trả 0 — điều này là chính xác.
      final response = await _apiClient.get(
        ApiEndpoints.volunteerCampaigns,
        queryParameters: {
          'per_page': 100,
          'trang_thai': 'da_duyet',
          'for_coordination': 1,
        },
      );
      final data = response.data['data'];
      int count = 0;
      if (data is List) count = data.length;
      else if (data is Map && data['data'] is List) count = (data['data'] as List).length;
      debugPrint('[getCampaignsForCoordination] BE returned $count campaign(s); data.runtimeType=${data.runtimeType}');

      // Nếu BE trả 0 với for_coordination=1, thử lại không filter để xem
      // user có campaign nào không (giúp debug khi web có data nhưng app không)
      if (count == 0) {
        debugPrint('[getCampaignsForCoordination] retry without for_coordination filter for diagnostic');
        final fallback = await _apiClient.get(
          ApiEndpoints.volunteerCampaigns,
          queryParameters: {'per_page': 100, 'trang_thai': 'da_duyet'},
        );
        final fbData = fallback.data['data'];
        int fbCount = 0;
        if (fbData is List) fbCount = fbData.length;
        else if (fbData is Map && fbData['data'] is List) fbCount = (fbData['data'] as List).length;
        debugPrint('[getCampaignsForCoordination] without for_coordination → $fbCount campaign(s)');
      }
      return _parseCampaignList(data, 1);
    } catch (e, st) {
      debugPrint('[getCampaignsForCoordination] error: $e\n$st');
      return CampaignListResult.failure('Không thể tải danh sách chiến dịch');
    }
  }

  // ============ INVITE VOLUNTEERS ============
  Future<InviteVolunteerResult> inviteVolunteers(int campaignId, List<int> volunteerIds) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.campaignInviteVolunteer(campaignId),
        data: {'volunteer_ids': volunteerIds},
      );
      if (response.data['status'] == 1) {
        final invitedCount = response.data['data']?['invited_count'] ?? volunteerIds.length;
        return InviteVolunteerResult.success(
          response.data['message'] ?? 'Đã gửi lời mời',
          invitedCount: invitedCount,
        );
      }
      return InviteVolunteerResult.failure(response.data['message'] ?? 'Gửi lời mời thất bại');
    } catch (e) {
      return InviteVolunteerResult.failure('Không thể gửi lời mời');
    }
  }
}

// ============ RESULT CLASSES ============
class CampaignListResult {
  final bool success;
  final List<Campaign> campaigns;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? message;

  CampaignListResult({
    required this.success,
    this.campaigns = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.message,
  });

  factory CampaignListResult.success({
    required List<Campaign> campaigns,
    required int currentPage,
    required int lastPage,
    required int total,
  }) {
    return CampaignListResult(
      success: true,
      campaigns: campaigns,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
    );
  }

  factory CampaignListResult.failure(String message) {
    return CampaignListResult(success: false, message: message);
  }
}

class CampaignFilterResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? message;

  CampaignFilterResult({required this.success, this.data, this.message});

  factory CampaignFilterResult.success(Map<String, dynamic> data) {
    return CampaignFilterResult(success: true, data: data);
  }

  factory CampaignFilterResult.failure(String message) {
    return CampaignFilterResult(success: false, message: message);
  }
}

class CampaignResult {
  final bool success;
  final Campaign? campaign;
  final String? message;

  CampaignResult({required this.success, this.campaign, this.message});

  factory CampaignResult.success(Campaign campaign) {
    return CampaignResult(success: true, campaign: campaign);
  }

  factory CampaignResult.failure(String message) {
    return CampaignResult(success: false, message: message);
  }
}

class OperationResult {
  final bool success;
  final String? message;
  final bool forbidden;

  OperationResult({required this.success, this.message, this.forbidden = false});

  factory OperationResult.success(String message) {
    return OperationResult(success: true, message: message, forbidden: false);
  }

  factory OperationResult.failure(String message, {bool forbidden = false}) {
    return OperationResult(success: false, message: message, forbidden: forbidden);
  }
}

class InviteVolunteerResult {
  final bool success;
  final String? message;
  final int invitedCount;

  InviteVolunteerResult({
    required this.success,
    this.message,
    this.invitedCount = 0,
  });

  factory InviteVolunteerResult.success(String message, {int invitedCount = 0}) {
    return InviteVolunteerResult(
      success: true,
      message: message,
      invitedCount: invitedCount,
    );
  }

  factory InviteVolunteerResult.failure(String message) {
    return InviteVolunteerResult(success: false, message: message);
  }
}

// ============ AI SUGGESTION MODEL ============
class AISuggestion {
  final List<VolunteerSuggestion> recommendedVolunteers;
  final Map<String, dynamic>? matchingCriteria;

  AISuggestion({
    required this.recommendedVolunteers,
    this.matchingCriteria,
  });

  factory AISuggestion.fromJson(Map<String, dynamic> json) {
    return AISuggestion(
      recommendedVolunteers: (json['recommended_volunteers'] as List?)
          ?.map((e) => VolunteerSuggestion.fromJson(e))
          .toList() ?? [],
      matchingCriteria: json['matching_criteria'],
    );
  }
}

class VolunteerSuggestion {
  final int volunteerId;
  final String tenNguoiDung;
  final String? avatar;
  final double matchScore;
  final List<String> matchedSkills;

  VolunteerSuggestion({
    required this.volunteerId,
    required this.tenNguoiDung,
    this.avatar,
    required this.matchScore,
    required this.matchedSkills,
  });

  factory VolunteerSuggestion.fromJson(Map<String, dynamic> json) {
    return VolunteerSuggestion(
      volunteerId: json['volunteer_id'] ?? 0,
      tenNguoiDung: json['ho_ten'] ?? '',
      avatar: json['anh_dai_dien'],
      matchScore: (json['diem_khop'] ?? 0).toDouble(),
      matchedSkills: json['ky_nang_khop'] != null
          ? List<String>.from(json['ky_nang_khop'])
          : [],
    );
  }
}

class AISuggestionResult {
  final bool success;
  final AISuggestion? suggestions;
  final String? message;

  AISuggestionResult({
    required this.success,
    this.suggestions,
    this.message,
  });

  factory AISuggestionResult.success(AISuggestion suggestions) {
    return AISuggestionResult(success: true, suggestions: suggestions);
  }

  factory AISuggestionResult.failure(String message) {
    return AISuggestionResult(success: false, message: message);
  }
}

class CoordinationResult {
  final bool success;
  final Map<String, dynamic> data;
  final String? message;

  CoordinationResult({
    required this.success,
    this.data = const {},
    this.message,
  });

  factory CoordinationResult.success(Map<String, dynamic> data) {
    return CoordinationResult(success: true, data: data);
  }

  factory CoordinationResult.failure(String message) {
    return CoordinationResult(success: false, message: message);
  }
}

class MonitoringResult {
  final bool success;
  final Map<String, dynamic> data;
  final String? message;

  MonitoringResult({
    required this.success,
    this.data = const {},
    this.message,
  });

  factory MonitoringResult.success(Map<String, dynamic> data) {
    return MonitoringResult(success: true, data: data);
  }

  factory MonitoringResult.failure(String message) {
    return MonitoringResult(success: false, message: message);
  }
}

// ============ RECOMMENDED CAMPAIGN MODEL ============
class RecommendedCampaign {
  final int id;
  final String tieuDe;
  final String? moTa;
  final String? diaDiem;
  final String? ngayBatDau;
  final String? ngayKetThuc;
  final String? anhBia;
  final String? loaiTen;
  final String? mucDoUuTien;
  final String? matchLevel;
  final int matchScore;
  final List<String> reasons;
  final List<String> warnings;
  final List<String> badges;
  final RecommendBreakdown breakdown;
  final double? distanceKm;

  const RecommendedCampaign({
    required this.id,
    required this.tieuDe,
    this.moTa,
    this.diaDiem,
    this.ngayBatDau,
    this.ngayKetThuc,
    this.anhBia,
    this.loaiTen,
    this.mucDoUuTien,
    this.matchLevel,
    this.matchScore = 0,
    this.reasons = const [],
    this.warnings = const [],
    this.badges = const [],
    this.breakdown = const RecommendBreakdown(),
    this.distanceKm,
  });

  factory RecommendedCampaign.fromJson(Map<String, dynamic> json) {
    final br = json['score_breakdown'] as Map<String, dynamic>? ?? {};
    return RecommendedCampaign(
      id: json['id'] ?? 0,
      tieuDe: json['tieu_de'] ?? '—',
      moTa: json['mo_ta'],
      diaDiem: json['dia_diem'],
      ngayBatDau: json['ngay_bat_dau'],
      ngayKetThuc: json['ngay_ket_thuc'],
      anhBia: json['anh_bia'],
      loaiTen: json['loai_chien_dich']?['ten'],
      mucDoUuTien: json['muc_do_uu_tien'],
      matchLevel: json['match_level'],
      matchScore: ((json['final_score'] ?? 0) as num).round(),
      reasons: List<String>.from(json['reasons'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
      badges: List<String>.from(json['badges'] ?? []),
      breakdown: RecommendBreakdown(
        skill: ((br['skill'] ?? 0) as num).round(),
        availability: ((br['availability'] ?? 0) as num).round(),
        distance: ((br['distance'] ?? 0) as num).round(),
        reliability: ((br['reliability'] ?? 0) as num).round(),
        profileStrength: ((br['profile_strength'] ?? 0) as num).round(),
      ),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }

  String get matchLabel => switch (matchLevel) {
        'rat_phu_hop' => 'Rất phù hợp',
        'phu_hop' => 'Phù hợp',
        'can_nhac' => 'Cân nhắc',
        _ => 'Gợi ý',
      };
}

class RecommendBreakdown {
  final int skill;
  final int availability;
  final int distance;
  final int reliability;
  final int profileStrength;

  const RecommendBreakdown({
    this.skill = 0,
    this.availability = 0,
    this.distance = 0,
    this.reliability = 0,
    this.profileStrength = 0,
  });
}
