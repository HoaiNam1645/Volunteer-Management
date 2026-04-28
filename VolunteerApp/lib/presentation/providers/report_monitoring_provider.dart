import 'package:flutter/material.dart';
import '../../data/models/campaign_model.dart';
import '../../data/repositories/campaign_repository.dart';

class ReportMonitoringProvider extends ChangeNotifier {
  final CampaignRepository _repository = CampaignRepository();

  // Campaigns for selection
  List<Campaign> _campaigns = [];
  List<Campaign> get campaigns => _campaigns;

  // Active campaign
  MonitoringCampaign? _activeCampaign;
  MonitoringCampaign? get activeCampaign => _activeCampaign;

  // Data lists
  List<ParticipantItem> _participants = [];
  List<FeedbackItem> _feedbacks = [];
  List<ReportItem> _reports = [];
  List<ParticipantItem> get participants => _participants;
  List<FeedbackItem> get feedbacks => _feedbacks;
  List<ReportItem> get reports => _reports;

  // Stats
  MonitoringStats _stats = MonitoringStats();
  MonitoringStats get stats => _stats;

  // Loading states
  bool _isLoadingList = false;
  bool _isLoadingDetail = false;
  bool get isLoadingList => _isLoadingList;
  bool get isLoadingDetail => _isLoadingDetail;

  // Error
  String? _error;
  String? get error => _error;

  // ============ LOAD CAMPAIGNS ============
  Future<void> loadCampaigns() async {
    _isLoadingList = true;
    _error = null;
    notifyListeners();

    final result = await _repository.getMyCampaigns();

    if (result.success) {
      _campaigns = result.campaigns;
      
      // Auto-select first campaign
      if (_campaigns.isNotEmpty && _activeCampaign == null) {
        await loadMonitoringData(_campaigns.first.id.toString());
      }
    } else {
      _error = result.message;
    }

    _isLoadingList = false;
    notifyListeners();
  }

  // ============ LOAD MONITORING DATA ============
  Future<void> loadMonitoringData(String campaignId) async {
    _isLoadingDetail = true;
    _error = null;
    notifyListeners();

    final result = await _repository.getCampaignMonitoring(
      int.tryParse(campaignId) ?? 0,
    );

    if (result.success) {
      final data = result.data;
      final campaign = data['chien_dich'] ?? {};
      final thongKe = data['thong_ke'] ?? {};

      _activeCampaign = MonitoringCampaign.fromJson(campaign);

      _stats = MonitoringStats(
        totalValidRegistrations: thongKe['tong_dang_ky_hop_le'] ?? 0,
        totalApproved: thongKe['tong_da_duyet'] ?? 0,
        totalInProgress: thongKe['tong_dang_tham_gia'] ?? 0,
        totalFeedbacks: thongKe['tong_phan_hoi'] ?? 0,
        totalReports: thongKe['tong_bao_cao'] ?? 0,
        pendingReports: thongKe['bao_cao_chua_xu_ly'] ?? 0,
      );

      // Parse participants
      final danhSachThamGia = data['danh_sach_tham_gia'] as List? ?? [];
      _participants = danhSachThamGia.map((e) => ParticipantItem.fromJson(e)).toList();

      // Parse feedbacks
      final phanHoi = data['phan_hoi'] as List? ?? [];
      _feedbacks = phanHoi.map((e) => FeedbackItem.fromJson(e)).toList();

      // Parse reports
      final baoCao = data['bao_cao'] as List? ?? [];
      _reports = baoCao.map((e) => ReportItem.fromJson(e)).toList();
    } else {
      _error = result.message;
    }

    _isLoadingDetail = false;
    notifyListeners();
  }

  // ============ REFRESH ============
  Future<void> refresh() async {
    if (_activeCampaign?.id != null) {
      await loadMonitoringData(_activeCampaign!.id.toString());
    }
  }

  // ============ CLEAR STATE ============
  void clearState() {
    _campaigns = [];
    _activeCampaign = null;
    _participants = [];
    _feedbacks = [];
    _reports = [];
    _stats = MonitoringStats();
    _error = null;
    notifyListeners();
  }
}

// ============ MONITORING CAMPAIGN ============
class MonitoringCampaign {
  final int id;
  final String tenChienDich;
  final String trangThai;
  final String diaDiem;
  final String? thoiGianText;

  MonitoringCampaign({
    required this.id,
    required this.tenChienDich,
    required this.trangThai,
    required this.diaDiem,
    this.thoiGianText,
  });

  factory MonitoringCampaign.fromJson(Map<String, dynamic> json) {
    return MonitoringCampaign(
      id: json['id'] ?? 0,
      tenChienDich: json['tieu_de'] ?? '—',
      trangThai: json['trang_thai'] ?? 'nhap',
      diaDiem: json['dia_diem'] ?? '—',
      thoiGianText: _buildTimeRange(json),
    );
  }

  static String? _buildTimeRange(Map<String, dynamic> json) {
    final start = json['thoi_gian_bat_dau_thuc_te'] ?? json['ngay_bat_dau'];
    final end = json['thoi_gian_ket_thuc_thuc_te'] ?? json['ngay_ket_thuc'];
    
    final startStr = _formatDate(start);
    final endStr = _formatDate(end);
    
    if (startStr == null && endStr == null) return null;
    if (startStr != null && endStr != null) return '$startStr - $endStr';
    return startStr ?? endStr;
  }

  static String? _formatDate(dynamic value) {
    if (value == null) return null;
    try {
      final date = DateTime.parse(value.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return value.toString();
    }
  }
}

// ============ MONITORING STATS ============
class MonitoringStats {
  final int totalValidRegistrations;
  final int totalApproved;
  final int totalInProgress;
  final int totalFeedbacks;
  final int totalReports;
  final int pendingReports;

  MonitoringStats({
    this.totalValidRegistrations = 0,
    this.totalApproved = 0,
    this.totalInProgress = 0,
    this.totalFeedbacks = 0,
    this.totalReports = 0,
    this.pendingReports = 0,
  });
}

// ============ PARTICIPANT ITEM ============
class ParticipantItem {
  final int id;
  final String tenNguoiDung;
  final String? email;
  final String? avatar;
  final String status;
  final String? dangKyLuc;
  final String? xacNhanLuc;
  final String? ghiChu;

  ParticipantItem({
    required this.id,
    required this.tenNguoiDung,
    this.email,
    this.avatar,
    required this.status,
    this.dangKyLuc,
    this.xacNhanLuc,
    this.ghiChu,
  });

  factory ParticipantItem.fromJson(Map<String, dynamic> json) {
    final nguoiDung = json['nguoi_dung'] ?? {};
    return ParticipantItem(
      id: json['id'] ?? 0,
      tenNguoiDung: nguoiDung['ho_ten'] ?? 'Không xác định',
      email: nguoiDung['email'],
      avatar: nguoiDung['anh_dai_dien'],
      status: json['trang_thai'] ?? '',
      dangKyLuc: json['dang_ky_luc'],
      xacNhanLuc: json['xac_nhan_luc'],
      ghiChu: json['ghi_chu'] ?? json['ly_do_huy'],
    );
  }
}

// ============ FEEDBACK ITEM ============
class FeedbackItem {
  final int id;
  final String tenNguoiDung;
  final String? email;
  final int soSao;
  final String? nhanXet;
  final String? taoLuc;
  final List<FeedbackTag> tags;

  FeedbackItem({
    required this.id,
    required this.tenNguoiDung,
    this.email,
    required this.soSao,
    this.nhanXet,
    this.taoLuc,
    this.tags = const [],
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    final nguoiDung = json['nguoi_dung'] ?? {};
    return FeedbackItem(
      id: json['id'] ?? 0,
      tenNguoiDung: nguoiDung['ho_ten'] ?? 'Ẩn danh',
      email: nguoiDung['email'],
      soSao: int.tryParse(json['so_sao']?.toString() ?? '0') ?? 0,
      nhanXet: json['nhan_xet'],
      taoLuc: json['tao_luc'],
      tags: (json['the_phan_hoi'] as List?)
              ?.map((e) => FeedbackTag.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class FeedbackTag {
  final int id;
  final String ten;

  FeedbackTag({required this.id, required this.ten});

  factory FeedbackTag.fromJson(Map<String, dynamic> json) {
    return FeedbackTag(
      id: json['id'] ?? 0,
      ten: json['ten'] ?? '',
    );
  }
}

// ============ REPORT ITEM ============
class ReportItem {
  final int id;
  final String tieuDe;
  final String? phanLoai;
  final String noiDung;
  final String trangThai;
  final String? phanHoiXuLy;
  final String? taoLuc;
  final String? xuLyLuc;
  final String? tenNguoiGui;
  final String? tenNguoiXuLy;

  ReportItem({
    required this.id,
    required this.tieuDe,
    this.phanLoai,
    required this.noiDung,
    required this.trangThai,
    this.phanHoiXuLy,
    this.taoLuc,
    this.xuLyLuc,
    this.tenNguoiGui,
    this.tenNguoiXuLy,
  });

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    final nguoiGui = json['nguoi_gui'] ?? {};
    final nguoiXuLy = json['nguoi_xu_ly'] ?? {};
    return ReportItem(
      id: json['id'] ?? 0,
      tieuDe: json['tieu_de'] ?? '—',
      phanLoai: json['phan_loai'],
      noiDung: json['noi_dung'] ?? '',
      trangThai: json['trang_thai'] ?? 'moi',
      phanHoiXuLy: json['phan_hoi_xu_ly'],
      taoLuc: json['tao_luc'],
      xuLyLuc: json['xu_ly_luc'],
      tenNguoiGui: nguoiGui['ho_ten'],
      tenNguoiXuLy: nguoiXuLy['ho_ten'],
    );
  }
}
