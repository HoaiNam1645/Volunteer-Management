import 'package:equatable/equatable.dart';
import 'user_model.dart';

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
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] ?? 0,
      tenChienDich: json['ten_chien_dich'] ?? '',
      moTa: json['mo_ta'] ?? '',
      moTaNgan: json['mo_ta_ngan'],
      anhBia: json['anh_bia'],
      hinhAnh: json['hinh_anh'] != null
          ? List<String>.from(json['hinh_anh'])
          : null,
      diaDiem: json['dia_diem'] ?? '',
      viDo: json['vi_do']?.toDouble(),
      kinhDo: json['kinh_do']?.toDouble(),
      ngayBatDau: DateTime.parse(json['ngay_bat_dau']),
      ngayKetThuc: DateTime.parse(json['ngay_ket_thuc']),
      hanDangKy: json['han_dang_ky'] != null
          ? DateTime.parse(json['han_dang_ky'])
          : null,
      soLuongToiThieu: json['so_luong_toi_thieu'] ?? 1,
      soLuongToiDa: json['so_luong_toi_da'] ?? 10,
      soLuongHienTai: json['so_luong_hien_tai'] ?? 0,
      trangThai: json['trang_thai'] ?? 'nhap',
      loaiChienDich: json['loai_chien_dich'],
      nguoiTao: json['nguoi_tao'] != null
          ? User.fromJson(json['nguoi_tao'])
          : null,
      kyNangs: json['ky_nangs'] != null
          ? List<String>.from(json['ky_nangs'])
          : null,
      moTaAnToan: json['mo_ta_an_toan'],
      mucDoKhanCap: json['muc_do_khan_cap'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'ten_chien_dich': tenChienDich,
    'mo_ta': moTa,
    'mo_ta_ngan': moTaNgan,
    'anh_bia': anhBia,
    'hinh_anh': hinhAnh,
    'dia_diem': diaDiem,
    'vi_do': viDo,
    'kinh_do': kinhDo,
    'ngay_bat_dau': ngayBatDau.toIso8601String(),
    'ngay_ket_thuc': ngayKetThuc.toIso8601String(),
    'han_dang_ky': hanDangKy?.toIso8601String(),
    'so_luong_toi_thieu': soLuongToiThieu,
    'so_luong_toi_da': soLuongToiDa,
    'mo_ta_an_toan': moTaAnToan,
    'muc_do_khan_cap': mucDoKhanCap,
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
