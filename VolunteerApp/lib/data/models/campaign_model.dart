import 'package:equatable/equatable.dart';
import 'user_model.dart';

/// Backend đôi khi trả số dưới dạng chuỗi (vd "10.7936000") — parse an toàn.
double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

DateTime? _asDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}

/// `loai_chien_dich` có thể là:
/// - String (legacy)
/// - Map `{id, ten}` (từ relation Eloquent)
/// - null (chỉ có loai_chien_dich_id)
/// Trả về tên hiển thị; fallback sang id nếu cần.
String? _extractLoaiChienDich(dynamic obj, dynamic idFallback) {
  if (obj is String) return obj;
  if (obj is Map) {
    final ten = obj['ten'];
    if (ten is String && ten.isNotEmpty) return ten;
    final id = obj['id'];
    if (id != null) return id.toString();
  }
  if (idFallback != null) return idFallback.toString();
  return null;
}

class Campaign extends Equatable {
  final int id;
  final String tenChienDich;
  final String moTa;
  final String? moTaNgan;
  final String? anhBia;
  final List<String>? hinhAnh;
  final String diaDiem;
  final double? viDo;
  final double? kinhDo;
  final DateTime ngayBatDau;
  final DateTime ngayKetThuc;
  final DateTime? hanDangKy;
  final int soLuongToiThieu;
  final int soLuongToiDa;
  final int soLuongHienTai;
  final String trangThai;
  final String? loaiChienDich;
  final User? nguoiTao;
  final List<String>? kyNangs;
  final String? moTaAnToan;
  final int? mucDoKhanCap;
  final DateTime createdAt;
  // Detail-specific fields (chỉ có trong response detail)
  final List<String> images;
  final String? lyDoHuy;
  final bool coTheDangKy;
  final bool coTheXacNhan;
  final bool coTheHuyDangKy;
  final Map<String, dynamic>? dangKyHienTai;
  final List<Map<String, dynamic>> feedbacks;
  final int soXacNhan;

  const Campaign({
    required this.id,
    required this.tenChienDich,
    required this.moTa,
    this.moTaNgan,
    this.anhBia,
    this.hinhAnh,
    required this.diaDiem,
    this.viDo,
    this.kinhDo,
    required this.ngayBatDau,
    required this.ngayKetThuc,
    this.hanDangKy,
    required this.soLuongToiThieu,
    required this.soLuongToiDa,
    this.soLuongHienTai = 0,
    required this.trangThai,
    this.loaiChienDich,
    this.nguoiTao,
    this.kyNangs,
    this.moTaAnToan,
    this.mucDoKhanCap,
    required this.createdAt,
    this.images = const [],
    this.lyDoHuy,
    this.coTheDangKy = false,
    this.coTheXacNhan = false,
    this.coTheHuyDangKy = false,
    this.dangKyHienTai,
    this.feedbacks = const [],
    this.soXacNhan = 0,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] ?? 0,
      tenChienDich: json['ten_chien_dich'] ?? json['tieu_de'] ?? '',
      moTa: json['mo_ta'] ?? '',
      moTaNgan: json['mo_ta_ngan'],
      anhBia: json['anh_bia'],
      hinhAnh: json['hinh_anh'] != null
          ? List<String>.from(json['hinh_anh'])
          : null,
      diaDiem: (json['dia_diem'] ?? '').toString(),
      viDo: _asDouble(json['vi_do']),
      kinhDo: _asDouble(json['kinh_do']),
      ngayBatDau: _asDate(json['ngay_bat_dau']) ?? DateTime.now(),
      ngayKetThuc: _asDate(json['ngay_ket_thuc']) ?? DateTime.now(),
      hanDangKy: _asDate(json['han_dang_ky']),
      soLuongToiThieu: _asInt(json['so_luong_toi_thieu']) ?? 1,
      soLuongToiDa: _asInt(json['so_luong_toi_da']) ?? 10,
      // Support both so_luong_hien_tai and so_dang_ky from FE
      soLuongHienTai: _asInt(json['so_luong_hien_tai']) ?? _asInt(json['so_dang_ky']) ?? 0,
      trangThai: (json['trang_thai'] ?? 'nhap').toString(),
      loaiChienDich: _extractLoaiChienDich(json['loai_chien_dich'], json['loai_chien_dich_id']),
      nguoiTao: json['nguoi_tao'] is Map<String, dynamic>
          ? User.fromJson(json['nguoi_tao'] as Map<String, dynamic>)
          : null,
      // Support both List<String> and List<{ten: String}> for ky_nangs
      kyNangs: _parseSkills(json['ky_nangs']),
      moTaAnToan: json['mo_ta_an_toan'],
      mucDoKhanCap: _asInt(json['muc_do_khan_cap']),
      createdAt: _asDate(json['created_at']) ?? DateTime.now(),
      images: _parseImages(json),
      lyDoHuy: json['ly_do_huy'],
      coTheDangKy: json['co_the_dang_ky'] == true,
      coTheXacNhan: json['co_the_xac_nhan'] == true,
      coTheHuyDangKy: json['co_the_huy_dang_ky'] == true,
      dangKyHienTai: json['dang_ky_hien_tai'] is Map<String, dynamic>
          ? json['dang_ky_hien_tai'] as Map<String, dynamic>
          : null,
      feedbacks: (json['feedbacks'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      soXacNhan: _asInt(json['so_xac_nhan']) ?? 0,
    );
  }

  static List<String> _parseImages(Map<String, dynamic> json) {
    final list = json['danh_sach_anh'] ?? json['images'];
    if (list is List && list.isNotEmpty) {
      return list.map((e) => e.toString()).toList();
    }
    if (json['anh_bia'] != null) return [json['anh_bia'].toString()];
    return const [];
  }

  static List<String>? _parseSkills(dynamic kyNangs) {
    if (kyNangs == null) return null;
    if (kyNangs is List) {
      if (kyNangs.isEmpty) return null;
      // Check if first element is a string or object
      if (kyNangs.first is String) {
        return List<String>.from(kyNangs);
      } else {
        // Object with 'ten' property
        return kyNangs.map((s) => s['ten']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'tieu_de': tenChienDich,
    'mo_ta': moTa,
    if (moTaNgan != null) 'mo_ta_ngan': moTaNgan,
    if (anhBia != null) 'anh_bia': anhBia,
    'dia_diem': diaDiem,
    if (viDo != null) 'vi_do': viDo,
    if (kinhDo != null) 'kinh_do': kinhDo,
    'ngay_bat_dau': ngayBatDau.toIso8601String().split('T').first,
    'ngay_ket_thuc': ngayKetThuc.toIso8601String().split('T').first,
    if (hanDangKy != null) 'han_dang_ky': hanDangKy!.toIso8601String().split('T').first,
    'so_luong_toi_thieu': soLuongToiThieu,
    'so_luong_toi_da': soLuongToiDa,
    if (loaiChienDich != null) 'loai_chien_dich_id': int.tryParse(loaiChienDich!) ?? loaiChienDich,
    if (mucDoKhanCap != null)
      'muc_do_uu_tien': const {1: 'khan_cap', 2: 'cao', 3: 'trung_binh', 4: 'thap'}[mucDoKhanCap] ?? 'trung_binh',
    if (kyNangs != null) 'ky_nang_ids': kyNangs,
    if (moTaAnToan != null) 'mo_ta_an_toan': moTaAnToan,
  };

  bool get isFull => soLuongHienTai >= soLuongToiDa;
  bool get isRegistrationOpen =>
      hanDangKy == null || hanDangKy!.isAfter(DateTime.now());
  bool get isOngoing =>
      DateTime.now().isAfter(ngayBatDau) &&
      DateTime.now().isBefore(ngayKetThuc);
  bool get isUpcoming => DateTime.now().isBefore(ngayBatDau);
  bool get isPast => DateTime.now().isAfter(ngayKetThuc);

  int get availableSlots => soLuongToiDa - soLuongHienTai;

  String get statusDisplayName {
    switch (trangThai) {
      case 'nhap':
        return 'Nháp';
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

  @override
  List<Object?> get props => [id, tenChienDich, trangThai, ngayBatDau];
}

class CampaignListResponse {
  final List<Campaign> campaigns;
  final int currentPage;
  final int lastPage;
  final int total;

  CampaignListResponse({
    required this.campaigns,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory CampaignListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is List ? json['data'] : [];
    return CampaignListResponse(
      campaigns: (data as List).map((e) => Campaign.fromJson(e)).toList(),
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      total: json['total'] ?? 0,
    );
  }
}
