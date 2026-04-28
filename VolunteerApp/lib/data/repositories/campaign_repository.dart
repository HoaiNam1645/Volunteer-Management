import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/campaign_model.dart';

class CampaignRepository {
  final ApiClient _apiClient = ApiClient.instance;

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

      final data = response.data['data'];
      final campaigns = (data is List)
          ? (data).map((e) => Campaign.fromJson(e)).toList()
          : (data['data'] as List)
              .map((e) => Campaign.fromJson(e))
              .toList();

      return CampaignListResult.success(
        campaigns: campaigns,
        currentPage: data['current_page'] ?? page,
        lastPage: data['last_page'] ?? 1,
        total: data['total'] ?? 0,
      );
    } catch (e) {
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

      final data = response.data['data'];
      final campaigns = (data is List)
          ? (data).map((e) => Campaign.fromJson(e)).toList()
          : (data['data'] as List)
              .map((e) => Campaign.fromJson(e))
              .toList();

      return CampaignListResult.success(
        campaigns: campaigns,
        currentPage: data['current_page'] ?? page,
        lastPage: data['last_page'] ?? 1,
        total: data['total'] ?? 0,
      );
    } catch (e) {
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

      final data = response.data['data'];
      final campaigns = (data is List)
          ? (data).map((e) => Campaign.fromJson(e)).toList()
          : (data['data'] as List)
              .map((e) => Campaign.fromJson(e))
              .toList();

      return CampaignListResult.success(
        campaigns: campaigns,
        currentPage: data['current_page'] ?? page,
        lastPage: data['last_page'] ?? 1,
        total: data['total'] ?? 0,
      );
    } catch (e) {
      return CampaignListResult.failure('Không thể tải chiến dịch của bạn');
    }
  }

  // ============ CREATE CAMPAIGN ============
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

  // ============ UPDATE CAMPAIGN ============
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
    } catch (e) {
      return OperationResult.failure('Không thể hủy chiến dịch');
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
      final response = await _apiClient.get(
        ApiEndpoints.volunteerCampaigns,
        queryParameters: {
          'per_page': 100,
          'trang_thai': 'da_duyet',
          'for_coordination': 1,
        },
      );

      final data = response.data['data'];
      final campaigns = (data is List)
          ? (data).map((e) => Campaign.fromJson(e)).toList()
          : (data['data'] as List)
              .map((e) => Campaign.fromJson(e))
              .toList();

      return CampaignListResult.success(
        campaigns: campaigns,
        currentPage: data['current_page'] ?? 1,
        lastPage: data['last_page'] ?? 1,
        total: data['total'] ?? 0,
      );
    } catch (e) {
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

  OperationResult({required this.success, this.message});

  factory OperationResult.success(String message) {
    return OperationResult(success: true, message: message);
  }

  factory OperationResult.failure(String message) {
    return OperationResult(success: false, message: message);
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
