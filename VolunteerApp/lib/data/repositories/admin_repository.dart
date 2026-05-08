import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

/// Backend đôi khi trả số dạng String (vd "10.5", "0.95"). Parse an toàn để
/// tránh `NoSuchMethodError: Class 'String' has no instance method 'toDouble'`.
double _safeDouble(dynamic v, {double fallback = 0.0}) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

double? _safeDoubleNullable(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int _safeInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

/// Cast về `List<String>` an toàn, kể cả khi list chứa Map hoặc number.
List<String> _safeStringList(dynamic v) {
  if (v is! List) return const [];
  final out = <String>[];
  for (final e in v) {
    if (e == null) continue;
    if (e is String) {
      if (e.isNotEmpty) out.add(e);
    } else if (e is Map) {
      final s = (e['message'] ??
              e['text'] ??
              e['ten'] ??
              e['name'] ??
              e['label'] ??
              e['value'] ??
              '')
          .toString();
      if (s.isNotEmpty) out.add(s);
    } else {
      out.add(e.toString());
    }
  }
  return out;
}

class AdminRepository {
  final ApiClient _apiClient = ApiClient.instance;

  String _normalizeCategoryType(String type) {
    switch (type) {
      case 'ky_nang':
        return 'ky-nang';
      case 'khu_vuc':
        return 'khu-vuc';
      case 'loai_chien_dich':
        return 'loai-chien-dich';
      default:
        return type;
    }
  }

  // ============ ADMIN DASHBOARD ============
  Future<AdminResult<DashboardData>> getDashboard(
      {String period = 'month'}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.adminDashboard,
        queryParameters: {'period': period},
      );

      if (response.data['status'] == 1) {
        return AdminResult.success(
          DashboardData.fromJson(response.data['data']),
        );
      }
      return AdminResult.failure(
          response.data['message'] ?? 'Không lấy được dữ liệu');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  // ============ REVIEWER STATS ============
  Future<AdminResult<ReviewerStats>> getReviewerStats(
      {String period = 'month'}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.reviewerStats,
        queryParameters: {'period': period},
      );

      if (response.data['status'] == 1) {
        return AdminResult.success(
          ReviewerStats.fromJson(response.data['data']),
        );
      }
      return AdminResult.failure(
          response.data['message'] ?? 'Không lấy được dữ liệu');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  // ============ USER MANAGEMENT ============
  Future<AdminResult<List<AdminUser>>> getUsers({
    int page = 1,
    String? search,
    String? vaiTro,
    String? trangThai,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.adminUsers,
        queryParameters: {
          'page': page,
          if (search != null) 'search': search,
          if (vaiTro != null) 'vai_tro': vaiTro,
          if (trangThai != null) 'trang_thai': trangThai,
        },
      );

      if (response.data['status'] == 1) {
        final data = response.data['data'] as List;
        return AdminResult.success(
          data.map((e) => AdminUser.fromJson(e)).toList(),
          meta: response.data['meta'],
        );
      }
      return AdminResult.failure(
          response.data['message'] ?? 'Không lấy được danh sách');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<AdminResult<AdminUser>> createUser({
    required String hoTen,
    required String email,
    required String matKhau,
    required String vaiTro,
    String? soDienThoai,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.adminUsers,
        data: {
          'ho_ten': hoTen,
          'email': email,
          'mat_khau': matKhau,
          'vai_tro': vaiTro,
          if (soDienThoai != null) 'so_dien_thoai': soDienThoai,
        },
      );

      if (response.data['status'] == 1) {
        return AdminResult.success(
          AdminUser.fromJson(response.data['data']),
          message: response.data['message'],
        );
      }
      return AdminResult.failure(
          response.data['message'] ?? 'Tạo người dùng thất bại');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<AdminResult<AdminUser>> updateUser({
    required int id,
    required String hoTen,
    required String email,
    required String vaiTro,
    required String trangThai,
    String? soDienThoai,
  }) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.adminUserDetail(id),
        data: {
          'ho_ten': hoTen,
          'email': email,
          'vai_tro': vaiTro,
          'trang_thai': trangThai,
          if (soDienThoai != null) 'so_dien_thoai': soDienThoai,
        },
      );

      if (response.data['status'] == 1) {
        return AdminResult.success(
          AdminUser.fromJson(response.data['data']),
          message: response.data['message'],
        );
      }
      return AdminResult.failure(
          response.data['message'] ?? 'Cập nhật thất bại');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<AdminResult<void>> updateUserStatus(int id, String trangThai) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.adminUserStatus(id),
        data: {'trang_thai': trangThai},
      );

      if (response.data['status'] == 1) {
        return AdminResult.successVoid(
          message: response.data['message'] ?? 'Cập nhật trạng thái thành công',
        );
      }
      return AdminResult.failure(
          response.data['message'] ?? 'Cập nhật thất bại');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<AdminResult<void>> deleteUser(int id) async {
    try {
      final response =
          await _apiClient.delete(ApiEndpoints.adminUserDelete(id));

      if (response.data['status'] == 1) {
        return AdminResult.successVoid(
          message: response.data['message'] ?? 'Xóa người dùng thành công',
        );
      }
      return AdminResult.failure(response.data['message'] ?? 'Xóa thất bại');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  // ============ PERMISSIONS MANAGEMENT ============
  Future<AdminResult<List<PermissionUser>>> getPermissionUsers({
    int page = 1,
    String? search,
    String? vaiTro,
    String? cheDoQuyen, // 'mac_dinh' or 'tuy_chinh'
    String? phamVi, // 'admin' or 'user'
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.adminPermissions,
        queryParameters: {
          'page': page,
          if (search != null) 'tu_khoa': search, // Backend expects 'tu_khoa'
          if (vaiTro != null) 'vai_tro': vaiTro,
          if (cheDoQuyen != null) 'che_do_quyen': cheDoQuyen,
          if (phamVi != null) 'pham_vi': phamVi,
        },
      );

      if (response.data['status'] == 1) {
        final data = response.data['data'] as List;
        return AdminResult.success(
          data.map((e) => PermissionUser.fromJson(e)).toList(),
          meta: response.data['meta'],
        );
      }
      return AdminResult.failure(
          response.data['message'] ?? 'Không lấy được dữ liệu');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<AdminResult<void>> updatePermission({
    required int id,
    required List<String> permissions,
    String? phamVi,
    bool suDungMacDinh = false,
  }) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.adminPermissionDetail(id),
        data: {
          'quyen_han': permissions,
          if (phamVi != null) 'pham_vi': phamVi,
          'su_dung_mac_dinh': suDungMacDinh,
        },
      );

      if (response.data['status'] == 1) {
        return AdminResult.successVoid(
          message: response.data['message'] ?? 'Cập nhật quyền thành công',
        );
      }
      return AdminResult.failure(
          response.data['message'] ?? 'Cập nhật thất bại');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  // ============ CATEGORY MANAGEMENT ============
  Future<AdminResult<Map<String, List<CategoryItem>>>> getCategories() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.adminCategories);

      if (response.data['status'] == 1) {
        final data = response.data['data'] as Map<String, dynamic>;
        // Map backend keys to frontend keys
        final result = <String, List<CategoryItem>>{};
        // Backend: ky_nangs -> Frontend: ky_nang
        if (data['ky_nangs'] != null) {
          result['ky_nang'] = (data['ky_nangs'] as List)
              .map((e) => CategoryItem.fromJson(e))
              .toList();
        }
        // Backend: khu_vucs -> Frontend: khu_vuc
        if (data['khu_vucs'] != null) {
          result['khu_vuc'] = (data['khu_vucs'] as List)
              .map((e) => CategoryItem.fromJson(e))
              .toList();
        }
        // Backend: loai_chien_dichs -> Frontend: tinh_thanh (using loai_chien_dich)
        if (data['loai_chien_dichs'] != null) {
          result['loai_chien_dich'] = (data['loai_chien_dichs'] as List)
              .map((e) => CategoryItem.fromJson(e))
              .toList();
        }
        return AdminResult.success(result);
      }
      return AdminResult.failure(
          response.data['message'] ?? 'Không lấy được dữ liệu');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<AdminResult<CategoryItem>> createCategory({
    required String type,
    required String ten,
    String? moTa,
    String? bieuTuong,
    String? mauSac,
    double? viDo,
    double? kinhDo,
    bool? hoatDong,
  }) async {
    try {
      final normalizedType = _normalizeCategoryType(type);
      final response = await _apiClient.post(
        ApiEndpoints.adminCategoryCreate(normalizedType),
        data: {
          'ten': ten,
          if (moTa != null) 'mo_ta': moTa,
          if (bieuTuong != null) 'bieu_tuong': bieuTuong,
          if (mauSac != null) 'mau_sac': mauSac,
          if (viDo != null) 'vi_do': viDo,
          if (kinhDo != null) 'kinh_do': kinhDo,
          if (hoatDong != null) 'hoat_dong': hoatDong,
        },
      );

      if (response.data['status'] == 1) {
        return AdminResult.success(
          CategoryItem.fromJson(response.data['data']),
          message: response.data['message'],
        );
      }
      return AdminResult.failure(response.data['message'] ?? 'Tạo thất bại');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<AdminResult<CategoryItem>> updateCategory({
    required String type,
    required int id,
    required String ten,
    String? moTa,
    String? bieuTuong,
    String? mauSac,
    double? viDo,
    double? kinhDo,
    bool? hoatDong,
  }) async {
    try {
      final normalizedType = _normalizeCategoryType(type);
      final response = await _apiClient.put(
        ApiEndpoints.adminCategoryUpdate(normalizedType, id),
        data: {
          'ten': ten,
          if (moTa != null) 'mo_ta': moTa,
          if (bieuTuong != null) 'bieu_tuong': bieuTuong,
          if (mauSac != null) 'mau_sac': mauSac,
          if (viDo != null) 'vi_do': viDo,
          if (kinhDo != null) 'kinh_do': kinhDo,
          if (hoatDong != null) 'hoat_dong': hoatDong,
        },
      );

      if (response.data['status'] == 1) {
        return AdminResult.success(
          CategoryItem.fromJson(response.data['data']),
          message: response.data['message'],
        );
      }
      return AdminResult.failure(
          response.data['message'] ?? 'Cập nhật thất bại');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<AdminResult<void>> deleteCategory(String type, int id) async {
    try {
      final normalizedType = _normalizeCategoryType(type);
      final response = await _apiClient.delete(
        ApiEndpoints.adminCategoryDelete(normalizedType, id),
      );

      if (response.data['status'] == 1) {
        return AdminResult.successVoid(
          message: response.data['message'] ?? 'Xóa thành công',
        );
      }
      return AdminResult.failure(response.data['message'] ?? 'Xóa thất bại');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  // ============ REVIEWER CAMPAIGN MANAGEMENT ============
  Future<AdminResult<ReviewerCampaignList>> getReviewerCampaigns({
    int page = 1,
    String? search,
    String? status,
    String? categoryId,
    String? priority,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.reviewerCampaigns,
        queryParameters: {
          'page': page,
          if (search != null && search.isNotEmpty) 'tu_khoa': search,
          if (status != null && status.isNotEmpty) 'trang_thai': status,
          if (categoryId != null && categoryId.isNotEmpty)
            'loai_chien_dich_id': categoryId,
          if (priority != null && priority.isNotEmpty)
            'muc_do_uu_tien': priority,
        },
      );

      if (response.data['status'] == 1) {
        return AdminResult.success(
          ReviewerCampaignList.fromJson(response.data),
        );
      }
      return AdminResult.failure(
          response.data['message'] ?? 'Không lấy được dữ liệu');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<AdminResult<ReviewerCampaignList>>
      getReviewerCampaignFilterMeta() async {
    try {
      final response =
          await _apiClient.get(ApiEndpoints.reviewerCampaignFilter);

      if (response.data['status'] == 1) {
        return AdminResult.success(
          ReviewerCampaignList.fromJson(response.data),
        );
      }
      return AdminResult.failure(
          response.data['message'] ?? 'Không lấy được bộ lọc');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<AdminResult<ReviewerCampaign>> getReviewerCampaignDetail(
      int id) async {
    try {
      final response =
          await _apiClient.get(ApiEndpoints.reviewerCampaignDetail(id));

      if (response.data['status'] == 1) {
        return AdminResult.success(
          ReviewerCampaign.fromJson(response.data['data']),
        );
      }
      return AdminResult.failure(
          response.data['message'] ?? 'Không lấy được chi tiết');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<AdminResult<void>> approveCampaign(int id) async {
    try {
      final response = await _apiClient.put(ApiEndpoints.reviewerApprove(id));

      if (response.data['status'] == 1) {
        return AdminResult.successVoid(message: response.data['message']);
      }
      return AdminResult.failure(response.data['message'] ?? 'Duyệt thất bại');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<AdminResult<void>> rejectCampaign(int id, String reason) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.reviewerReject(id),
        data: {'ly_do': reason},
      );

      if (response.data['status'] == 1) {
        return AdminResult.successVoid(message: response.data['message']);
      }
      return AdminResult.failure(
          response.data['message'] ?? 'Từ chối thất bại');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<AdminResult<void>> approveCancelRequest(int id) async {
    try {
      final response =
          await _apiClient.put(ApiEndpoints.reviewerApproveCancel(id));

      if (response.data['status'] == 1) {
        return AdminResult.successVoid(message: response.data['message']);
      }
      return AdminResult.failure(
          response.data['message'] ?? 'Duyệt hủy thất bại');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<AdminResult<void>> rejectCancelRequest(int id, String reason) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.reviewerRejectCancel(id),
        data: {'ly_do': reason},
      );

      if (response.data['status'] == 1) {
        return AdminResult.successVoid(message: response.data['message']);
      }
      return AdminResult.failure(
          response.data['message'] ?? 'Từ chối hủy thất bại');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<AdminResult<void>> processReport(
      int id, String status, String? response) async {
    try {
      final responseData = await _apiClient.put(
        ApiEndpoints.reviewerReportProcess(id),
        data: {
          'trang_thai': status,
          if (response != null) 'phan_hoi_xu_ly': response,
        },
      );

      if (responseData.data['status'] == 1) {
        return AdminResult.successVoid(message: responseData.data['message']);
      }
      return AdminResult.failure(
          responseData.data['message'] ?? 'Xử lý báo cáo thất bại');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  // ============ TRUST EVAL ============
  Future<AdminResult<TrustEvalStats>> getTrustEvalStats() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.trustEvalStats);

      if (response.data['status'] == 1) {
        return AdminResult.success(
          TrustEvalStats.fromJson(response.data['data']),
        );
      }
      return AdminResult.failure(
          response.data['message'] ?? 'Không lấy được thống kê');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<AdminResult<TrustEvalHealth>> getTrustEvalHealth() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.trustEvalHealth);

      if (response.data['status'] == 1) {
        return AdminResult.success(
          TrustEvalHealth.fromJson(response.data['data']),
        );
      }
      return AdminResult.failure(
          response.data['message'] ?? 'Không kiểm tra được trạng thái ML');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<AdminResult<CampaignTrustEval>> getCampaignTrustEval(
      int campaignId) async {
    try {
      final response =
          await _apiClient.get(ApiEndpoints.trustEvalCampaign(campaignId));

      if (response.data['status'] == 1) {
        final raw = response.data['data'];
        if (raw is! Map) {
          return AdminResult.failure('Dữ liệu đánh giá không hợp lệ');
        }
        try {
          return AdminResult.success(
            CampaignTrustEval.fromJson(Map<String, dynamic>.from(raw)),
          );
        } catch (e) {
          // ignore: avoid_print
          print('[TrustEval parse error] $e\nRaw: $raw');
          return AdminResult.failure('Lỗi phân tích đánh giá: $e');
        }
      }
      return AdminResult.failure(
          response.data['message'] ?? 'Không lấy được đánh giá');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<AdminResult<CampaignTrustEval>> refreshCampaignTrustEval(
      int campaignId) async {
    try {
      final response =
          await _apiClient.post(ApiEndpoints.trustEvalRefresh(campaignId));

      if (response.data['status'] == 1) {
        final raw = response.data['data'];
        if (raw is! Map) {
          return AdminResult.failure('Dữ liệu đánh giá không hợp lệ');
        }
        try {
          return AdminResult.success(
            CampaignTrustEval.fromJson(Map<String, dynamic>.from(raw)),
          );
        } catch (e) {
          // ignore: avoid_print
          print('[TrustEval parse error] $e\nRaw: $raw');
          return AdminResult.failure('Lỗi phân tích đánh giá: $e');
        }
      }
      return AdminResult.failure(
          response.data['message'] ?? 'Làm mới đánh giá thất bại');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<AdminResult<VolunteerTrustEval>> getVolunteerTrustEval(
      int volunteerId) async {
    try {
      final response =
          await _apiClient.get(ApiEndpoints.trustEvalVolunteer(volunteerId));

      if (response.data['status'] == 1) {
        return AdminResult.success(
          VolunteerTrustEval.fromJson(response.data['data']),
        );
      }
      return AdminResult.failure(
          response.data['message'] ?? 'Không lấy được đánh giá');
    } on DioException catch (e) {
      return AdminResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AdminResult.failure('Đã xảy ra lỗi: $e');
    }
  }
}

// ============ DATA MODELS ============
class DashboardData {
  final int totalUsers;
  final int activeCampaigns;
  final int pendingApprovals;
  final int totalFeedback;
  final List<SummaryItem> summary;
  final List<ActivityChartItem> activityChart;
  final List<RoleDistribution> roleDistribution;
  final List<RecentUser> recentUsers;
  final List<RecentCampaign> recentCampaigns;

  DashboardData({
    required this.totalUsers,
    required this.activeCampaigns,
    required this.pendingApprovals,
    required this.totalFeedback,
    required this.summary,
    required this.activityChart,
    required this.roleDistribution,
    required this.recentUsers,
    required this.recentCampaigns,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final summaryData = data['summary'] as Map<String, dynamic>? ?? {};

    return DashboardData(
      totalUsers: summaryData['total_users']?['value'] ?? 0,
      activeCampaigns: summaryData['active_campaigns']?['value'] ?? 0,
      pendingApprovals: summaryData['pending_approvals']?['value'] ?? 0,
      totalFeedback: summaryData['total_feedback']?['value'] ?? 0,
      summary: (summaryData.entries
          .map((e) => SummaryItem.fromJson(e.key, e.value))
          .toList()),
      activityChart: (data['activity_chart'] as List? ?? [])
          .map((e) => ActivityChartItem.fromJson(e))
          .toList(),
      roleDistribution: (data['role_distribution'] as List? ?? [])
          .map((e) => RoleDistribution.fromJson(e))
          .toList(),
      recentUsers: (data['recent_users'] as List? ?? [])
          .map((e) => RecentUser.fromJson(e))
          .toList(),
      recentCampaigns: (data['recent_campaigns'] as List? ?? [])
          .map((e) => RecentCampaign.fromJson(e))
          .toList(),
    );
  }
}

class SummaryItem {
  final String key;
  final String label;
  final int value;
  final String icon;
  final String bgClass;
  final String? badgeLabel;
  final TrendData? trend;

  SummaryItem({
    required this.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.bgClass,
    this.badgeLabel,
    this.trend,
  });

  factory SummaryItem.fromJson(String key, Map<String, dynamic> json) {
    return SummaryItem(
      key: json['key'] ?? key,
      label: json['label'] ?? '',
      value: json['value'] ?? 0,
      icon: json['icon'] ?? '',
      bgClass: json['bg_class'] ?? json['bg_color'] ?? '',
      badgeLabel: json['badge_label'],
      trend: json['trend'] != null ? TrendData.fromJson(json['trend']) : null,
    );
  }
}

class TrendData {
  final String text;
  final bool positive;
  final double? percentChange;

  TrendData({
    required this.text,
    required this.positive,
    this.percentChange,
  });

  factory TrendData.fromJson(Map<String, dynamic> json) {
    return TrendData(
      text: json['text'] ?? '',
      positive: json['positive'] ?? false,
      percentChange: _safeDoubleNullable(json['percent_change']),
    );
  }
}

class ActivityChartItem {
  final String label;
  final int registrations;
  final int campaigns;

  ActivityChartItem({
    required this.label,
    required this.registrations,
    required this.campaigns,
  });

  factory ActivityChartItem.fromJson(Map<String, dynamic> json) {
    return ActivityChartItem(
      label: json['label'] ?? json['period'] ?? '',
      registrations: json['registrations'] ?? 0,
      campaigns: json['campaigns'] ?? 0,
    );
  }
}

class RoleDistribution {
  final String key;
  final String label;
  final int count;
  final int percent;
  final String color;

  RoleDistribution({
    required this.key,
    required this.label,
    required this.count,
    required this.percent,
    required this.color,
  });

  factory RoleDistribution.fromJson(Map<String, dynamic> json) {
    return RoleDistribution(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      count: json['count'] ?? 0,
      percent: json['percent'] ?? 0,
      color: json['color'] ?? '#4f8cf7',
    );
  }
}

class RecentUser {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String time;
  final String role;
  final String status;
  final String roleLabel;
  final String statusLabel;

  RecentUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.time,
    required this.role,
    required this.status,
    required this.roleLabel,
    required this.statusLabel,
  });

  factory RecentUser.fromJson(Map<String, dynamic> json) {
    return RecentUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['ho_ten'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      time: json['time'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      roleLabel: json['role_label'] ?? '',
      statusLabel: json['status_label'] ?? '',
    );
  }
}

class RecentCampaign {
  final int id;
  final String title;
  final String? image;
  final String location;
  final int volunteers;
  final int target;
  final String status;
  final String statusLabel;

  RecentCampaign({
    required this.id,
    required this.title,
    this.image,
    required this.location,
    required this.volunteers,
    required this.target,
    required this.status,
    required this.statusLabel,
  });

  factory RecentCampaign.fromJson(Map<String, dynamic> json) {
    return RecentCampaign(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['tieu_de'] ?? '',
      image: json['image'] ?? json['anh_bia'],
      location: json['location'] ?? json['dia_diem'] ?? '',
      volunteers: json['volunteers'] ?? 0,
      target: json['target'] ?? 0,
      status: json['status'] ?? '',
      statusLabel: json['status_label'] ?? '',
    );
  }
}

class TrendItem {
  final String label;
  final int value;
  final double change;
  final String icon;
  final String bgClass;

  TrendItem({
    required this.label,
    required this.value,
    required this.change,
    required this.icon,
    required this.bgClass,
  });

  factory TrendItem.fromJson(Map<String, dynamic> json) {
    return TrendItem(
      label: json['label'] ?? '',
      value: json['value'] ?? 0,
      change: _safeDouble(json['change']),
      icon: json['icon'] ?? 'fa-solid fa-chart-line',
      bgClass: json['bg_class'] ?? 'bg-primary',
    );
  }
}

class ActivityItem {
  final int id;
  final String moTa;
  final String nguoiThucHien;
  final DateTime thoiGian;
  final String? icon;

  ActivityItem({
    required this.id,
    required this.moTa,
    required this.nguoiThucHien,
    required this.thoiGian,
    this.icon,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id'] ?? 0,
      moTa: json['mo_ta'] ?? '',
      nguoiThucHien: json['nguoi_thuc_hien'] ?? '',
      thoiGian: json['thoi_gian'] != null
          ? DateTime.parse(json['thoi_gian'])
          : DateTime.now(),
      icon: json['icon'],
    );
  }
}

class ChartDataPoint {
  final String label;
  final int registrations;
  final int campaigns;

  ChartDataPoint({
    required this.label,
    required this.registrations,
    required this.campaigns,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      label: json['label'] ?? '',
      registrations: json['registrations'] ?? 0,
      campaigns: json['campaigns'] ?? 0,
    );
  }
}

class ReviewerStats {
  final int pendingCampaigns;
  final int approvedThisMonth;
  final int rejectedThisMonth;
  final int totalVolunteers;
  final int activeCampaigns;
  final double avgReviewTime;
  final List<TrendItem> trends;
  final List<ChartDataPoint> chartData;
  final List<TopRegion> topRegions;
  final List<TopSkill> topSkills;
  final Map<String, int> campaignStatusDistribution;

  ReviewerStats({
    required this.pendingCampaigns,
    required this.approvedThisMonth,
    required this.rejectedThisMonth,
    required this.totalVolunteers,
    required this.activeCampaigns,
    required this.avgReviewTime,
    required this.trends,
    required this.chartData,
    this.topRegions = const [],
    this.topSkills = const [],
    this.campaignStatusDistribution = const {},
  });

  factory ReviewerStats.fromJson(Map<String, dynamic> json) {
    return ReviewerStats(
      pendingCampaigns: json['cho_duyet'] ?? 0,
      approvedThisMonth: json['da_duyet_thang_nay'] ?? 0,
      rejectedThisMonth: json['tu_choi_thang_nay'] ?? 0,
      totalVolunteers: json['tong_tinh_nguyen_vien'] ?? 0,
      activeCampaigns: json['chien_dich_dang_hoat_dong'] ?? 0,
      avgReviewTime: _safeDouble(json['thoi_gian_duyet_trung_binh']),
      trends: (json['xu_huong'] as List? ?? [])
          .map((e) => TrendItem.fromJson(e))
          .toList(),
      chartData: (json['bieu_do'] as List? ?? [])
          .map((e) => ChartDataPoint.fromJson(e))
          .toList(),
      topRegions: (json['top_regions'] as List? ?? [])
          .map((e) => TopRegion.fromJson(e))
          .toList(),
      topSkills: (json['top_skills'] as List? ?? [])
          .map((e) => TopSkill.fromJson(e))
          .toList(),
      campaignStatusDistribution:
          Map<String, int>.from(json['campaign_status_distribution'] ?? {}),
    );
  }
}

class TopRegion {
  final String name;
  final int count;
  final double percent;

  TopRegion({required this.name, required this.count, required this.percent});

  factory TopRegion.fromJson(Map<String, dynamic> json) {
    return TopRegion(
      name: json['name'] ?? json['ten'] ?? '',
      count: json['count'] ?? json['so_luong'] ?? 0,
      percent: _safeDouble(json['percent']),
    );
  }
}

class TopSkill {
  final String name;
  final int count;
  final double percent;

  TopSkill({required this.name, required this.count, required this.percent});

  factory TopSkill.fromJson(Map<String, dynamic> json) {
    return TopSkill(
      name: json['name'] ?? json['ten'] ?? '',
      count: json['count'] ?? json['so_luong'] ?? 0,
      percent: _safeDouble(json['percent']),
    );
  }
}

class PermissionUser {
  final int id;
  final String hoTen;
  final String email;
  final String vaiTro;
  final String? phamVi;
  final List<String> quyenHan;
  final bool suDungMacDinh;
  final DateTime createdAt;

  PermissionUser({
    required this.id,
    required this.hoTen,
    required this.email,
    required this.vaiTro,
    this.phamVi,
    required this.quyenHan,
    required this.suDungMacDinh,
    required this.createdAt,
  });

  factory PermissionUser.fromJson(Map<String, dynamic> json) {
    // Backend uses 'su_dung_mac_dinh_pham_vi' instead of 'su_dung_mac_dinh'
    final suDungMacDinh =
        json['su_dung_mac_dinh'] ?? json['su_dung_mac_dinh_pham_vi'];
    return PermissionUser(
      id: json['id'] ?? 0,
      hoTen: json['ho_ten'] ?? '',
      email: json['email'] ?? '',
      vaiTro: json['vai_tro'] ?? 'tinh_nguyen_vien',
      phamVi: json['pham_vi'] ?? json['scope'],
      quyenHan:
          List<String>.from(json['quyen_han'] ?? json['permissions'] ?? []),
      suDungMacDinh: suDungMacDinh == true || suDungMacDinh == 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

// ============ REVIEWER CAMPAIGN MODELS ============
class ReviewerCampaignList {
  final List<ReviewerCampaign> campaigns;
  final ReviewerCampaignStats stats;
  final List<FilterOption> tabs;
  final List<FilterOption> categories;
  final List<FilterOption> priorities;

  ReviewerCampaignList({
    required this.campaigns,
    required this.stats,
    required this.tabs,
    required this.categories,
    required this.priorities,
  });

  factory ReviewerCampaignList.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List? ?? [];
    final thongKe = json['thong_ke'] as Map<String, dynamic>? ?? {};
    final boLoc = json['bo_loc'] as Map<String, dynamic>? ?? {};

    return ReviewerCampaignList(
      campaigns: data.map((e) => ReviewerCampaign.fromJson(e)).toList(),
      stats: ReviewerCampaignStats.fromJson(thongKe),
      tabs: (boLoc['tabs'] as List? ?? [])
          .map((e) => FilterOption.fromJson(e))
          .toList(),
      categories: (boLoc['categories'] as List? ?? [])
          .map((e) => FilterOption.fromJson(e))
          .toList(),
      priorities: (boLoc['priorities'] as List? ?? [])
          .map((e) => FilterOption.fromJson(e))
          .toList(),
    );
  }
}

class ReviewerCampaign {
  final int id;
  final String tieuDe;
  final String moTa;
  final String diaDiem;
  final double? viDo;
  final double? kinhDo;
  final DateTime? ngayBatDau;
  final DateTime? ngayKetThuc;
  final int soLuongToiDa;
  final int soDangKy;
  final String trangThai;
  final String? lyDoTuChoi;
  final String? lyDoHuyYeuCau;
  final CampaignCategory? loaiChienDich;
  final int? loaiChienDichId;
  final CampaignCreator? nguoiTao;
  final List<String> kyNangs;
  final List<RegistrationItem> danhSachDangKy;
  final List<FeedbackItem> feedbacks;
  final List<ReportItem> baoCaos;
  final List<HistoryItem> lichSuKiemDuyet;

  ReviewerCampaign({
    required this.id,
    required this.tieuDe,
    required this.moTa,
    required this.diaDiem,
    this.viDo,
    this.kinhDo,
    this.ngayBatDau,
    this.ngayKetThuc,
    required this.soLuongToiDa,
    required this.soDangKy,
    required this.trangThai,
    this.lyDoTuChoi,
    this.lyDoHuyYeuCau,
    this.loaiChienDich,
    this.loaiChienDichId,
    this.nguoiTao,
    this.kyNangs = const [],
    this.danhSachDangKy = const [],
    this.feedbacks = const [],
    this.baoCaos = const [],
    this.lichSuKiemDuyet = const [],
  });

  factory ReviewerCampaign.fromJson(Map<String, dynamic> json) {
    return ReviewerCampaign(
      id: json['id'] ?? 0,
      tieuDe: json['tieu_de'] ?? '',
      moTa: json['mo_ta'] ?? '',
      diaDiem: json['dia_diem'] ?? '',
      viDo: _safeDoubleNullable(json['vi_do']),
      kinhDo: _safeDoubleNullable(json['kinh_do']),
      ngayBatDau: json['ngay_bat_dau'] != null
          ? DateTime.parse(json['ngay_bat_dau'])
          : null,
      ngayKetThuc: json['ngay_ket_thuc'] != null
          ? DateTime.parse(json['ngay_ket_thuc'])
          : null,
      soLuongToiDa: json['so_luong_toi_da'] ?? 0,
      soDangKy: json['so_dang_ky'] ?? 0,
      trangThai: json['trang_thai'] ?? '',
      lyDoTuChoi: json['ly_do_tu_choi'],
      lyDoHuyYeuCau: json['ly_do_huy_yeu_cau'],
      loaiChienDich: json['loai_chien_dich'] != null
          ? CampaignCategory.fromJson(json['loai_chien_dich'])
          : null,
      loaiChienDichId: json['loai_chien_dich_id'],
      nguoiTao: json['nguoi_tao'] != null
          ? CampaignCreator.fromJson(json['nguoi_tao'])
          : null,
      kyNangs: (json['ky_nangs'] as List? ?? [])
          .map((e) => e is String ? e : e['ten'] ?? '')
          .toList()
          .cast<String>(),
      danhSachDangKy: (json['danh_sach_dang_ky'] as List? ?? [])
          .map((e) => RegistrationItem.fromJson(e))
          .toList(),
      feedbacks: (json['feedbacks'] as List? ?? [])
          .map((e) => FeedbackItem.fromJson(e))
          .toList(),
      baoCaos: (json['bao_caos'] as List? ?? [])
          .map((e) => ReportItem.fromJson(e))
          .toList(),
      lichSuKiemDuyet: (json['lich_su_kiem_duyet'] as List? ?? [])
          .map((e) => HistoryItem.fromJson(e))
          .toList(),
    );
  }
}

class ReviewerCampaignStats {
  final int total;
  final int choDuyet;
  final int daDuyet;
  final int yeuCauHuy;
  final int daHuy;
  final int dangDienRa;
  final int hoanThanh;

  ReviewerCampaignStats({
    required this.total,
    required this.choDuyet,
    required this.daDuyet,
    required this.yeuCauHuy,
    required this.daHuy,
    required this.dangDienRa,
    required this.hoanThanh,
  });

  factory ReviewerCampaignStats.fromJson(Map<String, dynamic> json) {
    return ReviewerCampaignStats(
      total: json['tong'] ?? 0,
      choDuyet: json['cho_duyet'] ?? 0,
      daDuyet: json['da_duyet'] ?? 0,
      yeuCauHuy: json['yeu_cau_huy'] ?? 0,
      daHuy: json['da_huy'] ?? 0,
      dangDienRa: json['dang_dien_ra'] ?? 0,
      hoanThanh: json['hoan_thanh'] ?? 0,
    );
  }
}

class FilterOption {
  final String value;
  final String label;
  final int? count;

  FilterOption({required this.value, required this.label, this.count});

  factory FilterOption.fromJson(Map<String, dynamic> json) {
    return FilterOption(
      value: json['value'] ?? json['id']?.toString() ?? '',
      label: json['label'] ?? json['ten'] ?? '',
      count: json['count'],
    );
  }
}

class CampaignCategory {
  final int id;
  final String ten;
  final String? bieuTuong;
  final String? mauSac;
  final String? moTa;

  CampaignCategory({
    required this.id,
    required this.ten,
    this.bieuTuong,
    this.mauSac,
    this.moTa,
  });

  factory CampaignCategory.fromJson(Map<String, dynamic> json) {
    return CampaignCategory(
      id: json['id'] ?? 0,
      ten: json['ten'] ?? '',
      bieuTuong: json['bieu_tuong'],
      mauSac: json['mau_sac'],
      moTa: json['mo_ta'],
    );
  }
}

class CampaignCreator {
  final int id;
  final String hoTen;
  final String email;

  CampaignCreator({
    required this.id,
    required this.hoTen,
    required this.email,
  });

  factory CampaignCreator.fromJson(Map<String, dynamic> json) {
    return CampaignCreator(
      id: json['id'] ?? 0,
      hoTen: json['ho_ten'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class RegistrationItem {
  final int id;
  final RegistrationVolunteer? nguoiDung;
  final String trangThai;
  final DateTime? dangKyLuc;
  final DateTime? xacNhanLuc;
  final DateTime? duyetLuc;
  final DateTime? huyLuc;
  final String? lyDoHuy;
  final String? ghiChu;

  RegistrationItem({
    required this.id,
    this.nguoiDung,
    required this.trangThai,
    this.dangKyLuc,
    this.xacNhanLuc,
    this.duyetLuc,
    this.huyLuc,
    this.lyDoHuy,
    this.ghiChu,
  });

  factory RegistrationItem.fromJson(Map<String, dynamic> json) {
    return RegistrationItem(
      id: json['id'] ?? 0,
      nguoiDung: json['nguoi_dung'] != null
          ? RegistrationVolunteer.fromJson(json['nguoi_dung'])
          : null,
      trangThai: json['trang_thai'] ?? '',
      dangKyLuc: json['dang_ky_luc'] != null
          ? DateTime.parse(json['dang_ky_luc'])
          : null,
      xacNhanLuc: json['xac_nhan_luc'] != null
          ? DateTime.parse(json['xac_nhan_luc'])
          : null,
      duyetLuc:
          json['duyet_luc'] != null ? DateTime.parse(json['duyet_luc']) : null,
      huyLuc: json['huy_luc'] != null ? DateTime.parse(json['huy_luc']) : null,
      lyDoHuy: json['ly_do_huy'],
      ghiChu: json['ghi_chu'],
    );
  }
}

class RegistrationVolunteer {
  final int id;
  final String hoTen;
  final String email;
  final List<dynamic> kyNangs;
  final List<dynamic> khuVucs;

  RegistrationVolunteer({
    required this.id,
    required this.hoTen,
    required this.email,
    this.kyNangs = const [],
    this.khuVucs = const [],
  });

  factory RegistrationVolunteer.fromJson(Map<String, dynamic> json) {
    return RegistrationVolunteer(
      id: json['id'] ?? 0,
      hoTen: json['ho_ten'] ?? '',
      email: json['email'] ?? '',
      kyNangs: json['ky_nangs'] as List? ?? [],
      khuVucs: json['khu_vucs'] as List? ?? [],
    );
  }
}

class FeedbackItem {
  final int id;
  final int soSao;
  final String? nhanXet;
  final List<dynamic> thePhanHoi;
  final FeedbackUser? nguoiDung;

  FeedbackItem({
    required this.id,
    required this.soSao,
    this.nhanXet,
    this.thePhanHoi = const [],
    this.nguoiDung,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      id: json['id'] ?? 0,
      soSao: json['so_sao'] ?? 0,
      nhanXet: json['nhan_xet'],
      thePhanHoi: json['the_phan_hoi'] as List? ?? [],
      nguoiDung: json['nguoi_dung'] != null
          ? FeedbackUser.fromJson(json['nguoi_dung'])
          : null,
    );
  }
}

class FeedbackUser {
  final int id;
  final String hoTen;
  final String email;

  FeedbackUser({required this.id, required this.hoTen, required this.email});

  factory FeedbackUser.fromJson(Map<String, dynamic> json) {
    return FeedbackUser(
      id: json['id'] ?? 0,
      hoTen: json['ho_ten'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class ReportItem {
  final int id;
  final String tieuDe;
  final String noiDung;
  final String trangThai;
  final String? phanHoiXuLy;
  final ReportUser? nguoiGui;
  final DateTime? taoLuc;

  ReportItem({
    required this.id,
    required this.tieuDe,
    required this.noiDung,
    required this.trangThai,
    this.phanHoiXuLy,
    this.nguoiGui,
    this.taoLuc,
  });

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    return ReportItem(
      id: json['id'] ?? 0,
      tieuDe: json['tieu_de'] ?? '',
      noiDung: json['noi_dung'] ?? '',
      trangThai: json['trang_thai'] ?? 'moi',
      phanHoiXuLy: json['phan_hoi_xu_ly'],
      nguoiGui: json['nguoi_gui'] != null
          ? ReportUser.fromJson(json['nguoi_gui'])
          : null,
      taoLuc: json['tao_luc'] != null ? DateTime.parse(json['tao_luc']) : null,
    );
  }
}

class ReportUser {
  final int id;
  final String hoTen;

  ReportUser({required this.id, required this.hoTen});

  factory ReportUser.fromJson(Map<String, dynamic> json) {
    return ReportUser(
      id: json['id'] ?? 0,
      hoTen: json['ho_ten'] ?? '',
    );
  }
}

class HistoryItem {
  final int id;
  final String hanhDong;
  final String? tuTrangThai;
  final String? denTrangThai;
  final String? ghiChu;
  final DateTime? taoLuc;
  final HistoryUser? nguoiThucHien;

  HistoryItem({
    required this.id,
    required this.hanhDong,
    this.tuTrangThai,
    this.denTrangThai,
    this.ghiChu,
    this.taoLuc,
    this.nguoiThucHien,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] ?? 0,
      hanhDong: json['hanh_dong'] ?? '',
      tuTrangThai: json['tu_trang_thai'],
      denTrangThai: json['den_trang_thai'],
      ghiChu: json['ghi_chu'],
      taoLuc: json['tao_luc'] != null ? DateTime.parse(json['tao_luc']) : null,
      nguoiThucHien: json['nguoi_thuc_hien'] != null
          ? HistoryUser.fromJson(json['nguoi_thuc_hien'])
          : null,
    );
  }
}

class HistoryUser {
  final int id;
  final String hoTen;

  HistoryUser({required this.id, required this.hoTen});

  factory HistoryUser.fromJson(Map<String, dynamic> json) {
    return HistoryUser(
      id: json['id'] ?? 0,
      hoTen: json['ho_ten'] ?? '',
    );
  }
}

// ============ TRUST EVAL MODELS ============
class TrustEvalStats {
  final int totalEvaluations;
  final double avgTrustScore;
  final double avgRiskScore;
  final Map<String, int> byRiskLevel;
  final Map<String, int> byTrustLabel;
  final Map<String, int> byRecommendedAction;
  final Map<String, int> byEvaluationSource;
  final List<HighRiskCampaign> recentHighRisk;

  TrustEvalStats({
    required this.totalEvaluations,
    required this.avgTrustScore,
    required this.avgRiskScore,
    required this.byRiskLevel,
    required this.byTrustLabel,
    required this.byRecommendedAction,
    required this.byEvaluationSource,
    required this.recentHighRisk,
  });

  factory TrustEvalStats.fromJson(Map<String, dynamic> json) {
    return TrustEvalStats(
      totalEvaluations: json['total_evaluations'] ?? 0,
      avgTrustScore: _safeDouble(json['avg_trust_score']),
      avgRiskScore: _safeDouble(json['avg_risk_score']),
      byRiskLevel: Map<String, int>.from(json['by_risk_level'] ?? {}),
      byTrustLabel: Map<String, int>.from(json['by_trust_label'] ?? {}),
      byRecommendedAction:
          Map<String, int>.from(json['by_recommended_action'] ?? {}),
      byEvaluationSource:
          Map<String, int>.from(json['by_evaluation_source'] ?? {}),
      recentHighRisk: (json['recent_high_risk'] as List? ?? [])
          .map((e) => HighRiskCampaign.fromJson(e))
          .toList(),
    );
  }
}

class HighRiskCampaign {
  final int campaignId;
  final String? tieuDe;
  final String riskLevel;
  final double? trustScore;
  final bool isAnomaly;
  final DateTime? evaluatedAt;

  HighRiskCampaign({
    required this.campaignId,
    this.tieuDe,
    required this.riskLevel,
    this.trustScore,
    required this.isAnomaly,
    this.evaluatedAt,
  });

  factory HighRiskCampaign.fromJson(Map<String, dynamic> json) {
    return HighRiskCampaign(
      campaignId: json['campaign_id'] ?? 0,
      tieuDe: json['tieu_de'],
      riskLevel: json['risk_level'] ?? 'UNKNOWN',
      trustScore: _safeDoubleNullable(json['trust_score']),
      isAnomaly: json['is_anomaly'] == true,
      evaluatedAt: json['evaluated_at'] != null
          ? DateTime.parse(json['evaluated_at'])
          : null,
    );
  }
}

class TrustEvalHealth {
  final bool healthy;
  final int? modelsLoaded;
  final Map<String, bool>? models;

  TrustEvalHealth({
    required this.healthy,
    this.modelsLoaded,
    this.models,
  });

  factory TrustEvalHealth.fromJson(Map<String, dynamic> json) {
    // Backend returns data directly, not nested under 'data' key
    final data = json['data'] ?? json;
    final modelsLoadedData =
        data['models_loaded'] as Map<String, dynamic>? ?? {};
    return TrustEvalHealth(
      healthy: json['healthy'] == true || data['healthy'] == true,
      modelsLoaded: modelsLoadedData.values.where((v) => v == true).length,
      models: modelsLoadedData.map((k, v) => MapEntry(k, v == true)),
    );
  }
}

class CampaignTrustEval {
  final int campaignId;
  final String tieuDe;
  final double trustScore;
  final double riskScore;
  final String riskLevel;
  final String trustLabel;
  final String recommendedAction;
  final bool isAnomaly;
  final double? confidence;
  final ValidationResult? validation;
  final ContentAnalysis? contentAnalysis;
  final Map<String, double>? shapValues;
  final DateTime? evaluatedAt;

  CampaignTrustEval({
    required this.campaignId,
    required this.tieuDe,
    required this.trustScore,
    required this.riskScore,
    required this.riskLevel,
    required this.trustLabel,
    required this.recommendedAction,
    required this.isAnomaly,
    this.confidence,
    this.validation,
    this.contentAnalysis,
    this.shapValues,
    this.evaluatedAt,
  });

  factory CampaignTrustEval.fromJson(Map<String, dynamic> json) {
    // Backend có thể trả 2 shape:
    // (a) flat:    { trust_score: 0.7, risk_score: 0.2, risk_level: 'LOW', ... }
    // (b) nested:  { trust_score: { calibrated_probability: 0.7, label, confidence },
    //               risk_assessment: { risk_score, overall_risk_level, is_anomaly, anomaly_types, flags },
    //               decision_support: { recommended_action, reason, ... },
    //               shap_explanation: { top_positive_factors, top_negative_factors }, ... }
    final trustObj = json['trust_score'];
    final riskObj = json['risk_assessment'];
    final decisionObj = json['decision_support'];
    final shapObj = json['shap_values'] ?? json['shap_explanation'];

    double trustScore = 0;
    String trustLabel = 'NEUTRAL';
    double? confidence;
    if (trustObj is Map) {
      trustScore = _safeDouble(trustObj['calibrated_probability'] ??
          trustObj['calibrated_score'] ??
          trustObj['raw_score']);
      trustLabel = trustObj['label']?.toString() ?? 'NEUTRAL';
      confidence = _safeDoubleNullable(trustObj['confidence']);
    } else {
      trustScore = _safeDouble(trustObj);
      trustLabel = json['trust_label']?.toString() ?? 'NEUTRAL';
      confidence = _safeDoubleNullable(json['confidence']);
    }

    double riskScore = 0;
    String riskLevel = 'UNKNOWN';
    bool isAnomaly = false;
    if (riskObj is Map) {
      riskScore = _safeDouble(riskObj['risk_score']);
      riskLevel = (riskObj['overall_risk_level'] ?? riskObj['risk_level'])
              ?.toString() ??
          'UNKNOWN';
      isAnomaly = riskObj['is_anomaly'] == true;
    } else {
      riskScore = _safeDouble(json['risk_score']);
      riskLevel = json['risk_level']?.toString() ?? 'UNKNOWN';
      isAnomaly = json['is_anomaly'] == true;
    }

    String recommendedAction = 'APPROVE';
    if (decisionObj is Map) {
      recommendedAction =
          decisionObj['recommended_action']?.toString() ?? 'APPROVE';
    } else {
      recommendedAction = json['recommended_action']?.toString() ?? 'APPROVE';
    }

    Map<String, double>? shapValues;
    if (shapObj is Map) {
      // Nested: top_positive_factors / top_negative_factors
      final positives = shapObj['top_positive_factors'];
      final negatives = shapObj['top_negative_factors'];
      if (positives is List || negatives is List) {
        shapValues = <String, double>{};
        for (final list in [positives, negatives]) {
          if (list is List) {
            for (final f in list) {
              if (f is Map) {
                final feature =
                    (f['feature'] ?? f['display_name'] ?? '').toString();
                if (feature.isEmpty) continue;
                shapValues[feature] = _safeDouble(f['contribution']);
              }
            }
          }
        }
      } else {
        // Flat map<String, num>
        shapValues = <String, double>{};
        shapObj.forEach((k, v) {
          shapValues![k.toString()] = _safeDouble(v);
        });
      }
    }

    final evaluatedRaw =
        json['evaluated_at'] ?? json['evaluation_timestamp'];

    return CampaignTrustEval(
      campaignId: _safeInt(json['campaign_id']),
      tieuDe: json['tieu_de']?.toString() ?? '',
      trustScore: trustScore,
      riskScore: riskScore,
      riskLevel: riskLevel,
      trustLabel: trustLabel,
      recommendedAction: recommendedAction,
      isAnomaly: isAnomaly,
      confidence: confidence,
      validation: json['validation'] is Map
          ? ValidationResult.fromJson(
              Map<String, dynamic>.from(json['validation'] as Map))
          : null,
      contentAnalysis: json['content_analysis'] is Map
          ? ContentAnalysis.fromJson(
              Map<String, dynamic>.from(json['content_analysis'] as Map))
          : null,
      shapValues: shapValues,
      evaluatedAt:
          evaluatedRaw != null ? DateTime.tryParse(evaluatedRaw.toString()) : null,
    );
  }
}

class ValidationResult {
  final bool passed;
  final List<String> criticalErrors;
  final List<String> warnings;

  ValidationResult({
    required this.passed,
    required this.criticalErrors,
    required this.warnings,
  });

  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    return ValidationResult(
      passed: json['passed'] == true,
      criticalErrors: _safeStringList(json['critical_errors']),
      warnings: _safeStringList(json['warnings']),
    );
  }
}

class ContentAnalysis {
  final List<RiskKeyword> riskKeywords;
  final List<String> vaguenessSignals;
  final List<String> safetyDescriptions;

  ContentAnalysis({
    required this.riskKeywords,
    required this.vaguenessSignals,
    required this.safetyDescriptions,
  });

  factory ContentAnalysis.fromJson(Map<String, dynamic> json) {
    final keywords = json['risk_keywords'];
    final keywordList = <RiskKeyword>[];
    if (keywords is List) {
      for (final e in keywords) {
        if (e is Map) {
          keywordList
              .add(RiskKeyword.fromJson(Map<String, dynamic>.from(e)));
        } else if (e is String) {
          keywordList.add(RiskKeyword(keyword: e));
        }
      }
    }
    return ContentAnalysis(
      riskKeywords: keywordList,
      vaguenessSignals: _safeStringList(json['vagueness_signals']),
      safetyDescriptions: _safeStringList(json['safety_descriptions']),
    );
  }
}

class RiskKeyword {
  final String keyword;
  final double? score;
  final String? context;

  RiskKeyword({required this.keyword, this.score, this.context});

  factory RiskKeyword.fromJson(Map<String, dynamic> json) {
    return RiskKeyword(
      keyword:
          (json['keyword'] ?? json['ten'] ?? json['text'] ?? '').toString(),
      score: _safeDoubleNullable(json['score']),
      context: json['context']?.toString(),
    );
  }
}

// ============ RESULT CLASS ============
class AdminResult<T> {
  final bool success;
  final T? data;
  final String? message;
  final Map<String, dynamic>? meta;

  AdminResult({
    required this.success,
    this.data,
    this.message,
    this.meta,
  });

  factory AdminResult.success(
    T data, {
    String? message,
    Map<String, dynamic>? meta,
  }) {
    return AdminResult(
      success: true,
      data: data,
      message: message,
      meta: meta,
    );
  }

  factory AdminResult.successVoid({String? message}) {
    return AdminResult(
      success: true,
      data: null,
      message: message,
    );
  }

  factory AdminResult.failure(String message) {
    return AdminResult(success: false, message: message);
  }
}

class VolunteerTrustEval {
  final int volunteerId;
  final String hoTen;
  final String email;
  final double trustScore;
  final double riskScore;
  final String riskLevel;
  final String trustLabel;
  final String recommendedAction;
  final bool isAnomaly;
  final double? confidence;
  final int totalCampaigns;
  final int completedCampaigns;
  final int cancelledCampaigns;
  final double avgFeedbackScore;
  final int totalReports;
  final List<CampaignEvalSummary> recentCampaignEvals;
  final Map<String, double>? shapValues;
  final DateTime? evaluatedAt;

  VolunteerTrustEval({
    required this.volunteerId,
    required this.hoTen,
    required this.email,
    required this.trustScore,
    required this.riskScore,
    required this.riskLevel,
    required this.trustLabel,
    required this.recommendedAction,
    required this.isAnomaly,
    this.confidence,
    required this.totalCampaigns,
    required this.completedCampaigns,
    required this.cancelledCampaigns,
    required this.avgFeedbackScore,
    required this.totalReports,
    required this.recentCampaignEvals,
    this.shapValues,
    this.evaluatedAt,
  });

  factory VolunteerTrustEval.fromJson(Map<String, dynamic> json) {
    return VolunteerTrustEval(
      volunteerId: json['volunteer_id'] ?? json['id'] ?? 0,
      hoTen: json['ho_ten'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      trustScore: _safeDouble(json['trust_score']),
      riskScore: _safeDouble(json['risk_score']),
      riskLevel: json['risk_level'] ?? 'UNKNOWN',
      trustLabel: json['trust_label'] ?? 'NEUTRAL',
      recommendedAction: json['recommended_action'] ?? 'APPROVE',
      isAnomaly: json['is_anomaly'] == true,
      confidence: _safeDoubleNullable(json['confidence']),
      totalCampaigns: json['total_campaigns'] ?? 0,
      completedCampaigns: json['completed_campaigns'] ?? 0,
      cancelledCampaigns: json['cancelled_campaigns'] ?? 0,
      avgFeedbackScore: _safeDouble(json['avg_feedback_score']),
      totalReports: json['total_reports'] ?? 0,
      recentCampaignEvals: (json['recent_campaign_evals'] as List? ?? [])
          .map((e) => CampaignEvalSummary.fromJson(e))
          .toList(),
      shapValues: (json['shap_values'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, _safeDouble(v))),
      evaluatedAt: json['evaluated_at'] != null
          ? DateTime.parse(json['evaluated_at'])
          : null,
    );
  }
}

class CampaignEvalSummary {
  final int campaignId;
  final String? tieuDe;
  final double trustScore;
  final String riskLevel;
  final DateTime? evaluatedAt;

  CampaignEvalSummary({
    required this.campaignId,
    this.tieuDe,
    required this.trustScore,
    required this.riskLevel,
    this.evaluatedAt,
  });

  factory CampaignEvalSummary.fromJson(Map<String, dynamic> json) {
    return CampaignEvalSummary(
      campaignId: json['campaign_id'] ?? 0,
      tieuDe: json['tieu_de'] ?? json['title'],
      trustScore: _safeDouble(json['trust_score']),
      riskLevel: json['risk_level'] ?? 'UNKNOWN',
      evaluatedAt: json['evaluated_at'] != null
          ? DateTime.parse(json['evaluated_at'])
          : null,
    );
  }
}
