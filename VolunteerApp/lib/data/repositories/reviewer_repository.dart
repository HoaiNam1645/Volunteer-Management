import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

double _toDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

class ReviewerRepository {
  final ApiClient _apiClient = ApiClient.instance;

  // ============ CAMPAIGN FILTERS ============
  Future<ReviewerResult<CampaignFilters>> getFilters() async {
    try {
      final response =
          await _apiClient.get(ApiEndpoints.reviewerCampaignFilter);

      if (response.data['status'] == 1) {
        return ReviewerResult.success(
          CampaignFilters.fromJson(response.data['data']),
        );
      }
      return ReviewerResult.failure(
          response.data['message'] ?? 'Không lấy được bộ lọc');
    } on DioException catch (e) {
      return ReviewerResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return ReviewerResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  // ============ CAMPAIGN LIST ============
  Future<ReviewerResult<List<ReviewerCampaign>>> getCampaigns({
    int page = 1,
    String? trangThai,
    String? search,
    String? loaiChienDich,
    String? mucDoUuTien,
    String? tuNgay,
    String? denNgay,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.reviewerCampaigns,
        queryParameters: {
          'page': page,
          if (trangThai != null) 'trang_thai': trangThai,
          if (search != null) 'tu_khoa': search,
          if (loaiChienDich != null) 'loai_chien_dich_id': loaiChienDich,
          if (mucDoUuTien != null) 'muc_do_uu_tien': mucDoUuTien,
          if (tuNgay != null) 'tu_ngay': tuNgay,
          if (denNgay != null) 'den_ngay': denNgay,
        },
      );

      if (response.data['status'] == 1) {
        final data = response.data['data'] as List;
        return ReviewerResult.success(
          data.map((e) => ReviewerCampaign.fromJson(e)).toList(),
          meta: response.data['meta'],
        );
      }
      return ReviewerResult.failure(
          response.data['message'] ?? 'Không lấy được danh sách');
    } on DioException catch (e) {
      return ReviewerResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return ReviewerResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  // ============ CAMPAIGN DETAIL ============
  Future<ReviewerResult<ReviewerCampaignDetail>> getCampaignDetail(
      int id) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.reviewerCampaignDetail(id),
      );

      if (response.data['status'] == 1) {
        return ReviewerResult.success(
          ReviewerCampaignDetail.fromJson(response.data['data']),
        );
      }
      return ReviewerResult.failure(
          response.data['message'] ?? 'Không lấy được chi tiết');
    } on DioException catch (e) {
      return ReviewerResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return ReviewerResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  // ============ APPROVE / REJECT ============
  Future<ReviewerResult<void>> approveCampaign(int id) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.reviewerApprove(id),
      );

      if (response.data['status'] == 1) {
        return ReviewerResult.successVoid(
          message: response.data['message'] ?? 'Duyệt chiến dịch thành công',
        );
      }
      return ReviewerResult.failure(
          response.data['message'] ?? 'Duyệt thất bại');
    } on DioException catch (e) {
      return ReviewerResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return ReviewerResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<ReviewerResult<void>> rejectCampaign(int id, String reason) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.reviewerReject(id),
        data: {'ly_do': reason},
      );

      if (response.data['status'] == 1) {
        return ReviewerResult.successVoid(
          message: response.data['message'] ?? 'Từ chối chiến dịch thành công',
        );
      }
      return ReviewerResult.failure(
          response.data['message'] ?? 'Từ chối thất bại');
    } on DioException catch (e) {
      return ReviewerResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return ReviewerResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  // ============ CANCEL REQUEST ============
  Future<ReviewerResult<void>> approveCancel(int id) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.reviewerApproveCancel(id),
      );

      if (response.data['status'] == 1) {
        return ReviewerResult.successVoid(
          message: response.data['message'] ?? 'Duyệt yêu cầu hủy thành công',
        );
      }
      return ReviewerResult.failure(
          response.data['message'] ?? 'Duyệt thất bại');
    } on DioException catch (e) {
      return ReviewerResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return ReviewerResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<ReviewerResult<void>> rejectCancel(int id, String reason) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.reviewerRejectCancel(id),
        data: {'ly_do': reason},
      );

      if (response.data['status'] == 1) {
        return ReviewerResult.successVoid(
          message: response.data['message'] ?? 'Từ chối yêu cầu hủy thành công',
        );
      }
      return ReviewerResult.failure(
          response.data['message'] ?? 'Từ chối thất bại');
    } on DioException catch (e) {
      return ReviewerResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return ReviewerResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  Future<ReviewerResult<void>> processReport(int id, String trangThai) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.reviewerReportProcess(id),
        data: {'trang_thai': trangThai},
      );

      if (response.data['status'] == 1) {
        return ReviewerResult.successVoid(
          message: response.data['message'] ?? 'Xu ly bao cao thanh cong',
        );
      }
      return ReviewerResult.failure(
          response.data['message'] ?? 'Xu ly bao cao that bai');
    } on DioException catch (e) {
      return ReviewerResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return ReviewerResult.failure('Da xay ra loi: $e');
    }
  }

  // ============ STATISTICS ============
  Future<ReviewerResult<ReviewerStatistics>> getStatistics(
      String period) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.reviewerStats,
        queryParameters: {'period': period},
      );

      if (response.data['status'] == 1) {
        return ReviewerResult.success(
          ReviewerStatistics.fromJson(response.data['data']),
        );
      }
      return ReviewerResult.failure(
          response.data['message'] ?? 'Không lấy được thống kê');
    } on DioException catch (e) {
      return ReviewerResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return ReviewerResult.failure('Đã xảy ra lỗi: $e');
    }
  }
}

// ============ STATISTICS MODEL ============
class ReviewerStatistics {
  final List<KpiItem> kpis;
  final List<MonthlyData> monthlyData;
  final PeriodSummary periodSummary;
  final List<CampaignStatusItem> campaignStatuses;
  final List<TopRegion> topRegions;
  final List<TopSkill> topSkills;

  ReviewerStatistics({
    required this.kpis,
    required this.monthlyData,
    required this.periodSummary,
    required this.campaignStatuses,
    required this.topRegions,
    required this.topSkills,
  });

  factory ReviewerStatistics.fromJson(Map<String, dynamic> json) {
    return ReviewerStatistics(
      kpis: (json['kpis'] as Map<String, dynamic>?)
              ?.values
              .map((e) => KpiItem.fromJson(e))
              .toList() ??
          [],
      monthlyData: (json['monthly_data'] as List? ?? [])
          .map((e) => MonthlyData.fromJson(e))
          .toList(),
      periodSummary: PeriodSummary.fromJson(json['period_summary'] ?? {}),
      campaignStatuses: (json['campaign_statuses'] as List? ?? [])
          .map((e) => CampaignStatusItem.fromJson(e))
          .toList(),
      topRegions: (json['top_regions'] as List? ?? [])
          .map((e) => TopRegion.fromJson(e))
          .toList(),
      topSkills: (json['top_skills'] as List? ?? [])
          .map((e) => TopSkill.fromJson(e))
          .toList(),
    );
  }
}

class KpiItem {
  final String label;
  final String value;
  final bool trendUp;
  final String trendText;
  final String icon;
  final String bgColor;
  final String color;

  KpiItem({
    required this.label,
    required this.value,
    required this.trendUp,
    required this.trendText,
    required this.icon,
    required this.bgColor,
    required this.color,
  });

  factory KpiItem.fromJson(Map<String, dynamic> json) {
    return KpiItem(
      label: json['label'] ?? '',
      value: json['value']?.toString() ?? '0',
      trendUp: json['trend']?['positive'] ?? true,
      trendText: json['trend']?['text'] ?? 'Không đổi',
      icon: json['icon'] ?? 'fa-solid fa-chart',
      bgColor: json['bg_color'] ?? '#e3f2fd',
      color: json['color'] ?? '#2196f3',
    );
  }
}

class MonthlyData {
  final String label;
  final int campaigns;
  final int volunteers;

  MonthlyData({
    required this.label,
    required this.campaigns,
    required this.volunteers,
  });

  factory MonthlyData.fromJson(Map<String, dynamic> json) {
    return MonthlyData(
      label: json['label'] ?? '',
      campaigns: json['campaigns'] ?? 0,
      volunteers: json['volunteers'] ?? 0,
    );
  }
}

class PeriodSummary {
  final int campaigns;
  final int volunteers;

  PeriodSummary({required this.campaigns, required this.volunteers});

  factory PeriodSummary.fromJson(Map<String, dynamic> json) {
    return PeriodSummary(
      campaigns: json['campaigns'] ?? 0,
      volunteers: json['volunteers'] ?? 0,
    );
  }
}

class CampaignStatusItem {
  final String label;
  final int count;
  final double percent;
  final String icon;
  final String color;
  final String bgColor;

  CampaignStatusItem({
    required this.label,
    required this.count,
    required this.percent,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  factory CampaignStatusItem.fromJson(Map<String, dynamic> json) {
    return CampaignStatusItem(
      label: json['label'] ?? '',
      count: json['count'] ?? 0,
      percent: _toDouble(json['percent']),
      icon: json['icon'] ?? 'fa-solid fa-circle',
      color: json['color'] ?? '#6c757d',
      bgColor: json['bg_color'] ?? '#e9ecef',
    );
  }
}

class TopRegion {
  final String name;
  final int volunteers;
  final double percent;

  TopRegion({
    required this.name,
    required this.volunteers,
    required this.percent,
  });

  factory TopRegion.fromJson(Map<String, dynamic> json) {
    return TopRegion(
      name: json['name'] ?? '',
      volunteers: json['volunteers'] ?? 0,
      percent: _toDouble(json['percent']),
    );
  }
}

class TopSkill {
  final String name;
  final int count;
  final double percent;
  final String icon;
  final String color;

  TopSkill({
    required this.name,
    required this.count,
    required this.percent,
    required this.icon,
    required this.color,
  });

  factory TopSkill.fromJson(Map<String, dynamic> json) {
    return TopSkill(
      name: json['name'] ?? '',
      count: json['count'] ?? 0,
      percent: _toDouble(json['percent']),
      icon: json['icon'] ?? 'fa-solid fa-star',
      color: json['color'] ?? '#6c757d',
    );
  }
}

// ============ DATA MODELS ============
class CampaignFilters {
  final List<StatusFilter> trangThaiOptions;
  final List<CampaignTypeFilter> loaiChienDichOptions;

  CampaignFilters({
    required this.trangThaiOptions,
    required this.loaiChienDichOptions,
  });

  factory CampaignFilters.fromJson(Map<String, dynamic> json) {
    final tabs = (json['tabs'] as List? ?? []);
    final statusSource = (json['trang_thai'] as List? ?? tabs);
    final categories =
        (json['loai_chien_dich'] as List? ?? json['categories'] as List? ?? []);
    return CampaignFilters(
      trangThaiOptions:
          statusSource.map((e) => StatusFilter.fromJson(e)).toList(),
      loaiChienDichOptions:
          categories.map((e) => CampaignTypeFilter.fromJson(e)).toList(),
    );
  }
}

class StatusFilter {
  final String value;
  final String label;
  final int count;

  StatusFilter({
    required this.value,
    required this.label,
    required this.count,
  });

  factory StatusFilter.fromJson(Map<String, dynamic> json) {
    final rawCount = json['so_luong'] ?? json['count'] ?? 0;
    return StatusFilter(
      value: (json['gia_tri'] ?? json['api_value'] ?? json['value'] ?? '')
          .toString(),
      label: (json['nhan'] ?? json['label'] ?? json['value'] ?? '').toString(),
      count:
          rawCount is int ? rawCount : int.tryParse(rawCount.toString()) ?? 0,
    );
  }
}

class CampaignTypeFilter {
  final int id;
  final String ten;

  CampaignTypeFilter({
    required this.id,
    required this.ten,
  });

  factory CampaignTypeFilter.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['value'] ?? 0;
    return CampaignTypeFilter(
      id: rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0,
      ten: (json['ten'] ?? json['label'] ?? '').toString(),
    );
  }
}

class ReviewerCampaign {
  final int id;
  final String tenChienDich;
  final String? anhBia;
  final String diaDiem;
  final DateTime ngayBatDau;
  final DateTime ngayKetThuc;
  final DateTime? hanDangKy;
  final String trangThai;
  final String? loaiChienDich;
  final int soLuongToiDa;
  final int soLuongHienTai;
  final String nguoiTaoTen;
  final String? lyDoTuChoi;
  final DateTime createdAt;
  final bool coYeuCauHuy;
  final bool coBaoCao;

  ReviewerCampaign({
    required this.id,
    required this.tenChienDich,
    this.anhBia,
    required this.diaDiem,
    required this.ngayBatDau,
    required this.ngayKetThuc,
    this.hanDangKy,
    required this.trangThai,
    this.loaiChienDich,
    required this.soLuongToiDa,
    required this.soLuongHienTai,
    required this.nguoiTaoTen,
    this.lyDoTuChoi,
    required this.createdAt,
    required this.coYeuCauHuy,
    required this.coBaoCao,
  });

  factory ReviewerCampaign.fromJson(Map<String, dynamic> json) {
    final loaiChienDichRaw = json['loai_chien_dich'];
    final loaiChienDichText = loaiChienDichRaw is Map<String, dynamic>
        ? (loaiChienDichRaw['ten']?.toString() ??
            loaiChienDichRaw['name']?.toString())
        : loaiChienDichRaw?.toString();

    return ReviewerCampaign(
      id: json['id'] ?? 0,
      tenChienDich:
          (json['ten_chien_dich'] ?? json['tieu_de'] ?? '').toString(),
      anhBia: json['anh_bia'],
      diaDiem: json['dia_diem'] ?? '',
      ngayBatDau: DateTime.parse(json['ngay_bat_dau']),
      ngayKetThuc: DateTime.parse(json['ngay_ket_thuc']),
      hanDangKy: json['han_dang_ky'] != null
          ? DateTime.parse(json['han_dang_ky'])
          : null,
      trangThai: json['trang_thai'] ?? 'nhap',
      loaiChienDich: loaiChienDichText,
      soLuongToiDa: json['so_luong_toi_da'] ?? 0,
      soLuongHienTai: json['so_luong_hien_tai'] ?? json['so_dang_ky'] ?? 0,
      nguoiTaoTen: json['nguoi_tao']?['ho_ten'] ?? json['nguoi_tao_ten'] ?? '',
      lyDoTuChoi: json['ly_do_tu_choi'],
      createdAt: (json['created_at'] ?? json['tao_luc']) != null
          ? DateTime.parse((json['created_at'] ?? json['tao_luc']).toString())
          : DateTime.now(),
      coYeuCauHuy:
          json['co_yeu_cau_huy'] == true || json['co_yeu_cau_huy'] == 1,
      coBaoCao: json['co_bao_cao'] == true || json['co_bao_cao'] == 1,
    );
  }

  String get trangThaiDisplay {
    switch (trangThai) {
      case 'cho_duyet':
        return 'Chờ duyệt';
      case 'da_duyet':
        return 'Đã duyệt';
      case 'tu_choi':
        return 'Từ chối';
      case 'dang_dien_ra':
        return 'Đang diễn ra';
      case 'da_ket_thuc':
        return 'Đã kết thúc';
      case 'da_huy':
        return 'Đã hủy';
      default:
        return trangThai;
    }
  }

  bool get isPending => trangThai == 'cho_duyet';
  bool get canReview =>
      trangThai == 'cho_duyet' ||
      trangThai == 'da_duyet' ||
      trangThai == 'dang_dien_ra';
}

class ReviewerCampaignDetail extends ReviewerCampaign {
  final String moTa;
  final String? moTaAnToan;
  final int mucDoKhanCap;
  final List<String>? kyNangs;
  final List<VolunteerRegistration> volunteers;
  final List<CampaignFeedback> feedbacks;
  final List<CampaignReport> baoCaos;
  final List<ReviewHistoryItem> lichSu;
  final double viDo;
  final double kinhDo;
  final List<TrustEvalSummary>? trustEval;
  final NguoiTaoInfo? nguoiTao;

  ReviewerCampaignDetail({
    required super.id,
    required super.tenChienDich,
    super.anhBia,
    required super.diaDiem,
    required super.ngayBatDau,
    required super.ngayKetThuc,
    super.hanDangKy,
    required super.trangThai,
    super.loaiChienDich,
    required super.soLuongToiDa,
    required super.soLuongHienTai,
    required super.nguoiTaoTen,
    super.lyDoTuChoi,
    required super.createdAt,
    required super.coYeuCauHuy,
    required super.coBaoCao,
    required this.moTa,
    this.moTaAnToan,
    required this.mucDoKhanCap,
    this.kyNangs,
    required this.volunteers,
    required this.feedbacks,
    required this.baoCaos,
    required this.lichSu,
    required this.viDo,
    required this.kinhDo,
    this.trustEval,
    this.nguoiTao,
  });

  factory ReviewerCampaignDetail.fromJson(Map<String, dynamic> json) {
    final loaiChienDichRaw = json['loai_chien_dich'];
    final loaiChienDichText = loaiChienDichRaw is Map<String, dynamic>
        ? (loaiChienDichRaw['ten']?.toString() ??
            loaiChienDichRaw['name']?.toString())
        : loaiChienDichRaw?.toString();
    final kyNangRaw = json['ky_nangs'] as List? ?? const [];
    final kyNangValues = kyNangRaw
        .map((e) => e is Map<String, dynamic> ? e['ten'] : e)
        .where((e) => e != null)
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();

    return ReviewerCampaignDetail(
      id: json['id'] ?? 0,
      tenChienDich:
          (json['ten_chien_dich'] ?? json['tieu_de'] ?? '').toString(),
      anhBia: json['anh_bia'],
      diaDiem: json['dia_diem'] ?? '',
      ngayBatDau: DateTime.parse(json['ngay_bat_dau']),
      ngayKetThuc: DateTime.parse(json['ngay_ket_thuc']),
      hanDangKy: json['han_dang_ky'] != null
          ? DateTime.parse(json['han_dang_ky'])
          : null,
      trangThai: json['trang_thai'] ?? 'nhap',
      loaiChienDich: loaiChienDichText,
      soLuongToiDa: json['so_luong_toi_da'] ?? 0,
      soLuongHienTai: json['so_luong_hien_tai'] ?? json['so_dang_ky'] ?? 0,
      nguoiTaoTen: json['nguoi_tao']?['ho_ten'] ?? json['nguoi_tao_ten'] ?? '',
      lyDoTuChoi:
          (json['ly_do_tu_choi'] ?? json['ly_do_huy_yeu_cau'])?.toString(),
      createdAt: (json['created_at'] ?? json['tao_luc']) != null
          ? DateTime.parse((json['created_at'] ?? json['tao_luc']).toString())
          : DateTime.now(),
      coYeuCauHuy:
          json['co_yeu_cau_huy'] == true || json['co_yeu_cau_huy'] == 1,
      coBaoCao: json['co_bao_cao'] == true || json['co_bao_cao'] == 1,
      moTa: json['mo_ta'] ?? '',
      moTaAnToan: json['mo_ta_an_toan'],
      mucDoKhanCap: json['muc_do_khan_cap'] ?? 0,
      kyNangs: kyNangValues,
      viDo: _toDouble(json['vi_do']),
      kinhDo: _toDouble(json['kinh_do']),
      volunteers: (json['tinh_nguyen_viens'] as List? ??
              json['danh_sach_dang_ky'] as List? ??
              const [])
          .map((e) => VolunteerRegistration.fromJson(e))
          .toList(),
      feedbacks:
          (json['phan_hois'] as List? ?? json['feedbacks'] as List? ?? const [])
              .map((e) => CampaignFeedback.fromJson(e))
              .toList(),
      baoCaos: (json['bao_caos'] as List? ?? [])
          .map((e) => CampaignReport.fromJson(e))
          .toList(),
      lichSu: (json['lich_su_kiem_duyet'] as List? ?? [])
          .map((e) => ReviewHistoryItem.fromJson(e))
          .toList(),
      trustEval: (json['trust_eval'] as List? ?? [])
          .map((e) => TrustEvalSummary.fromJson(e))
          .toList(),
      nguoiTao: json['nguoi_tao'] != null
          ? NguoiTaoInfo.fromJson(json['nguoi_tao'])
          : null,
    );
  }
}

class NguoiTaoInfo {
  final int id;
  final String hoTen;
  final String? anhDaiDien;
  final int soChienDich;
  final double diemDanhGia;

  NguoiTaoInfo({
    required this.id,
    required this.hoTen,
    this.anhDaiDien,
    required this.soChienDich,
    required this.diemDanhGia,
  });

  factory NguoiTaoInfo.fromJson(Map<String, dynamic> json) {
    return NguoiTaoInfo(
      id: json['id'] ?? 0,
      hoTen: json['ho_ten'] ?? '',
      anhDaiDien: json['anh_dai_dien'],
      soChienDich: json['so_chien_dich'] ?? 0,
      diemDanhGia: _toDouble(json['diem_danh_gia']),
    );
  }
}

class VolunteerRegistration {
  final int registrationId;
  final int userId;
  final String hoTen;
  final String? anhDaiDien;
  final String? email;
  final List<String> kyNangs;
  final String? khuVuc;
  final String trangThai;
  final DateTime? ngayXacNhan;
  final String? lyDo;
  final double trustScore;
  final DateTime? dangKyLuc;

  VolunteerRegistration({
    required this.registrationId,
    required this.userId,
    required this.hoTen,
    this.anhDaiDien,
    this.email,
    this.kyNangs = const [],
    this.khuVuc,
    required this.trangThai,
    this.ngayXacNhan,
    this.lyDo,
    required this.trustScore,
    this.dangKyLuc,
  });

  factory VolunteerRegistration.fromJson(Map<String, dynamic> json) {
    // Parse nested nguoi_dung if present
    final nguoiDung = json['nguoi_dung'] as Map<String, dynamic>?;

    // Parse ky_nangs from nested nguoi_dung
    List<String> kyNangs = [];
    if (nguoiDung != null && nguoiDung['ky_nangs'] != null) {
      kyNangs = (nguoiDung['ky_nangs'] as List)
          .map((skill) => (skill is Map)
              ? (skill['ten'] ?? '').toString()
              : skill.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Parse khu_vucs from nested nguoi_dung
    String? khuVuc;
    if (nguoiDung != null && nguoiDung['khu_vucs'] != null) {
      khuVuc = (nguoiDung['khu_vucs'] as List)
          .map((area) =>
              (area is Map) ? (area['ten'] ?? '').toString() : area.toString())
          .where((s) => s.isNotEmpty)
          .join(', ');
      if (khuVuc.isEmpty) khuVuc = null;
    }

    return VolunteerRegistration(
      registrationId: json['dang_ky_id'] ?? json['id'] ?? 0,
      userId: json['nguoi_dung_id'] ?? json['id'] ?? 0,
      hoTen: nguoiDung?['ho_ten'] ?? json['ho_ten'] ?? '',
      anhDaiDien: nguoiDung?['anh_dai_dien'] ?? json['anh_dai_dien'],
      email: nguoiDung?['email'],
      kyNangs: kyNangs,
      khuVuc: khuVuc,
      trangThai: json['trang_thai'] ?? 'cho_xac_nhan',
      ngayXacNhan: json['ngay_xac_nhan'] != null
          ? DateTime.tryParse(json['ngay_xac_nhan'])
          : null,
      lyDo: json['ly_do'],
      trustScore: _toDouble(json['diem_tin_cay']),
      dangKyLuc: json['dang_ky_luc'] != null
          ? DateTime.tryParse(json['dang_ky_luc'])
          : null,
    );
  }
}

class CampaignFeedback {
  final int id;
  final String hoTen;
  final String? anhDaiDien;
  final int diem;
  final String? noiDung;
  final DateTime createdAt;

  CampaignFeedback({
    required this.id,
    required this.hoTen,
    this.anhDaiDien,
    required this.diem,
    this.noiDung,
    required this.createdAt,
  });

  factory CampaignFeedback.fromJson(Map<String, dynamic> json) {
    final nguoiDung = json['nguoi_dung'] as Map<String, dynamic>?;
    return CampaignFeedback(
      id: json['id'] ?? 0,
      hoTen: (json['ho_ten'] ?? nguoiDung?['ho_ten'] ?? '').toString(),
      anhDaiDien: json['anh_dai_dien'] ?? nguoiDung?['anh_dai_dien'],
      diem: json['diem'] ?? json['so_sao'] ?? 0,
      noiDung: json['noi_dung'] ?? json['nhan_xet'],
      createdAt: (json['created_at'] ?? json['tao_luc']) != null
          ? DateTime.parse((json['created_at'] ?? json['tao_luc']).toString())
          : DateTime.now(),
    );
  }
}

class CampaignReport {
  final int id;
  final int nguoiGuiId;
  final String nguoiGuiTen;
  final String noiDung;
  final String trangThai;
  final DateTime createdAt;

  CampaignReport({
    required this.id,
    required this.nguoiGuiId,
    required this.nguoiGuiTen,
    required this.noiDung,
    required this.trangThai,
    required this.createdAt,
  });

  factory CampaignReport.fromJson(Map<String, dynamic> json) {
    final nguoiGui = json['nguoi_gui'] as Map<String, dynamic>?;
    final title = (json['tieu_de'] ?? '').toString();
    final body = (json['noi_dung'] ?? '').toString();
    return CampaignReport(
      id: json['id'] ?? 0,
      nguoiGuiId: json['nguoi_gui_id'] ?? nguoiGui?['id'] ?? 0,
      nguoiGuiTen:
          (json['nguoi_gui_ten'] ?? nguoiGui?['ho_ten'] ?? '').toString(),
      noiDung: title.isNotEmpty && body.isNotEmpty ? '$title: $body' : body,
      trangThai: json['trang_thai'] ?? 'cho_xu_ly',
      createdAt: (json['created_at'] ?? json['tao_luc']) != null
          ? DateTime.parse((json['created_at'] ?? json['tao_luc']).toString())
          : DateTime.now(),
    );
  }
}

class ReviewHistoryItem {
  final int id;
  final String hanhDong;
  final String? tuTrangThai;
  final String? denTrangThai;
  final String? ghiChu;
  final DateTime? taoLuc;
  final String? nguoiThucHien;

  ReviewHistoryItem({
    required this.id,
    required this.hanhDong,
    this.tuTrangThai,
    this.denTrangThai,
    this.ghiChu,
    this.taoLuc,
    this.nguoiThucHien,
  });

  factory ReviewHistoryItem.fromJson(Map<String, dynamic> json) {
    return ReviewHistoryItem(
      id: json['id'] ?? 0,
      hanhDong: json['hanh_dong'] ?? '',
      tuTrangThai: json['tu_trang_thai'],
      denTrangThai: json['den_trang_thai'],
      ghiChu: json['ghi_chu'],
      taoLuc:
          json['tao_luc'] != null ? DateTime.tryParse(json['tao_luc']) : null,
      nguoiThucHien: json['nguoi_thuc_hien']?['ho_ten'],
    );
  }
}

class TrustEvalSummary {
  final int id;
  final String tieuDe;
  final double diem;
  final String mucDo;
  final List<String> ruiRo;
  final String? giaiThich;

  TrustEvalSummary({
    required this.id,
    required this.tieuDe,
    required this.diem,
    required this.mucDo,
    required this.ruiRo,
    this.giaiThich,
  });

  factory TrustEvalSummary.fromJson(Map<String, dynamic> json) {
    return TrustEvalSummary(
      id: json['id'] ?? 0,
      tieuDe: json['tieu_de'] ?? '',
      diem: _toDouble(json['diem']),
      mucDo: json['muc_do'] ?? 'trung_binh',
      ruiRo: List<String>.from(json['rui_ro'] ?? []),
      giaiThich: json['giai_thich'],
    );
  }
}

// ============ RESULT CLASS ============
class ReviewerResult<T> {
  final bool success;
  final T? data;
  final String? message;
  final Map<String, dynamic>? meta;

  ReviewerResult({
    required this.success,
    this.data,
    this.message,
    this.meta,
  });

  factory ReviewerResult.success(
    T data, {
    String? message,
    Map<String, dynamic>? meta,
  }) {
    return ReviewerResult(
      success: true,
      data: data,
      message: message,
      meta: meta,
    );
  }

  factory ReviewerResult.successVoid({String? message}) {
    return ReviewerResult(
      success: true,
      data: null,
      message: message,
    );
  }

  factory ReviewerResult.failure(String message) {
    return ReviewerResult(success: false, message: message);
  }
}
