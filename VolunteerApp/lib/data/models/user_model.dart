import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String hoTen;
  final String email;
  final String? soDienThoai;
  final String? anhDaiDien;
  final String? gioiTinh;
  final String? ngaySinh;
  final String? soCccd;
  final String? gioiThieu;
  final String? diaChiDuong;
  final double? viDo;
  final double? kinhDo;
  final int? tinhThanhId;
  final int? phuongXaId;
  final String vaiTro;
  final bool xacThucEmail;
  final bool coMatKhau;
  final List<String> quyenHan;
  final UserStats? thongKe;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.hoTen,
    required this.email,
    this.soDienThoai,
    this.anhDaiDien,
    this.gioiTinh,
    this.ngaySinh,
    this.soCccd,
    this.gioiThieu,
    this.diaChiDuong,
    this.viDo,
    this.kinhDo,
    this.tinhThanhId,
    this.phuongXaId,
    required this.vaiTro,
    required this.xacThucEmail,
    required this.coMatKhau,
    this.quyenHan = const [],
    this.thongKe,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      hoTen: json['ho_ten'] ?? '',
      email: json['email'] ?? '',
      soDienThoai: json['so_dien_thoai'],
      anhDaiDien: json['anh_dai_dien'],
      gioiTinh: json['gioi_tinh'],
      ngaySinh: json['ngay_sinh'],
      soCccd: json['so_cccd'],
      gioiThieu: json['gioi_thieu'],
      diaChiDuong: json['dia_chi_duong'],
      viDo: json['vi_do']?.toDouble(),
      kinhDo: json['kinh_do']?.toDouble(),
      tinhThanhId: json['tinh_thanh_id'],
      phuongXaId: json['phuong_xa_id'],
      vaiTro: json['vai_tro'] ?? 'tinh_nguyen_vien',
      xacThucEmail:
          json['xac_thuc_email'] == true || json['xac_thuc_email'] == 1,
      coMatKhau: json['co_mat_khau'] == true || json['co_mat_khau'] == 1,
      quyenHan:
          List<String>.from(json['quyen_han'] ?? json['permissions'] ?? []),
      thongKe: json['thong_ke'] != null
          ? UserStats.fromJson(json['thong_ke'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  // Backward compatible getter
  UserStats? get stats => thongKe;

  // Competency profile data
  factory User.fromCompetencyProfile(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      hoTen: json['ho_ten'] ?? '',
      email: json['email'] ?? '',
      anhDaiDien: json['anh_dai_dien'],
      vaiTro: json['vai_tro'] ?? 'tinh_nguyen_vien',
      xacThucEmail:
          json['xac_thuc_email'] == true || json['xac_thuc_email'] == 1,
      coMatKhau: true,
      quyenHan: List<String>.from(json['quyen_han'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ho_ten': hoTen,
        'email': email,
        'so_dien_thoai': soDienThoai,
        'anh_dai_dien': anhDaiDien,
        'gioi_tinh': gioiTinh,
        'ngay_sinh': ngaySinh,
        'so_cccd': soCccd,
        'gioi_thieu': gioiThieu,
        'dia_chi_duong': diaChiDuong,
        'vi_do': viDo,
        'kinh_do': kinhDo,
        'tinh_thanh_id': tinhThanhId,
        'phuong_xa_id': phuongXaId,
        'vai_tro': vaiTro,
        'xac_thuc_email': xacThucEmail,
        'co_mat_khau': coMatKhau,
        'quyen_han': quyenHan,
      };

  // Alias getters for compatibility
  String get name => hoTen;
  String? get phone => soDienThoai;
  String? get avatar => anhDaiDien;
  String? get bio => gioiThieu;
  String get role => vaiTro;
  bool get emailVerified => xacThucEmail;

  bool get isAdmin => vaiTro == 'quan_tri_vien';
  bool get isReviewer => vaiTro == 'kiem_duyet_vien';
  bool get isVolunteer => vaiTro == 'tinh_nguyen_vien';
  bool get canManageCampaigns => isAdmin || isReviewer;
  bool get isAdminOrReviewer => isAdmin || isReviewer;

  bool hasPermission(String permission) => quyenHan.contains(permission);

  String get roleDisplayName {
    switch (vaiTro) {
      case 'quan_tri_vien':
        return 'Quản trị viên';
      case 'kiem_duyet_vien':
        return 'Kiểm duyệt viên';
      case 'tinh_nguyen_vien':
        return 'Tình nguyện viên';
      default:
        return vaiTro;
    }
  }

  String get initials {
    final parts = hoTen.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.last[0]}${parts[parts.length > 1 ? parts.length - 2 : 0][0]}'
          .toUpperCase();
    }
    return hoTen.isNotEmpty ? hoTen[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [id, email, vaiTro];
}

// User statistics
class UserStats extends Equatable {
  final int soChienDich;
  final int soDangKy;
  final int soHoanThanh;
  final double diemDanhGiaTb;
  final int soDanhGia;

  const UserStats({
    required this.soChienDich,
    required this.soDangKy,
    required this.soHoanThanh,
    required this.diemDanhGiaTb,
    required this.soDanhGia,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      soChienDich: json['so_chien_dich'] ?? 0,
      soDangKy: json['so_dang_ky'] ?? 0,
      soHoanThanh: json['so_hoan_thanh'] ?? 0,
      diemDanhGiaTb: (json['diem_danh_gia_tb'] ?? 0).toDouble(),
      soDanhGia: json['so_danh_gia'] ?? 0,
    );
  }

  int get campaignCount => soChienDich;
  int get registrationCount => soDangKy;
  int get completedCount => soHoanThanh;
  double get avgRating => diemDanhGiaTb;
  int get ratingCount => soDanhGia;

  @override
  List<Object?> get props => [soChienDich, soDangKy, soHoanThanh];
}

// Competency Profile
class CompetencyProfile extends Equatable {
  final int id;
  final String hoTen;
  final String email;
  final String? anhDaiDien;
  final List<int> kyNangIds;
  final List<int> khuVucIds;
  final List<String> lichRanh;
  final String khungGioUuTien;
  final List<ExperienceItem> kinhNghiems;

  const CompetencyProfile({
    required this.id,
    required this.hoTen,
    required this.email,
    this.anhDaiDien,
    this.kyNangIds = const [],
    this.khuVucIds = const [],
    this.lichRanh = const [],
    this.khungGioUuTien = 'linh_hoat',
    this.kinhNghiems = const [],
  });

  factory CompetencyProfile.fromJson(Map<String, dynamic> json) {
    return CompetencyProfile(
      id: json['id'] ?? 0,
      hoTen: json['ho_ten'] ?? '',
      email: json['email'] ?? '',
      anhDaiDien: json['anh_dai_dien'],
      kyNangIds: List<int>.from(json['ky_nang_ids'] ?? []),
      khuVucIds: List<int>.from(json['khu_vuc_ids'] ?? []),
      lichRanh: List<String>.from(json['lich_ranh'] ?? []),
      khungGioUuTien: json['khung_gio_uu_tien'] ?? 'linh_hoat',
      kinhNghiems: (json['kinh_nghiems'] as List? ?? [])
          .map((e) => ExperienceItem.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'ky_nang_ids': kyNangIds,
        'khu_vuc_ids': khuVucIds,
        'lich_ranh': lichRanh,
        'khung_gio_uu_tien': khungGioUuTien,
      };

  @override
  List<Object?> get props => [id, email];
}

class ExperienceItem extends Equatable {
  final int? id;
  final String tieuDe;
  final String? toChuc;
  final String? thoiGian;
  final String? moTa;

  const ExperienceItem({
    this.id,
    required this.tieuDe,
    this.toChuc,
    this.thoiGian,
    this.moTa,
  });

  factory ExperienceItem.fromJson(Map<String, dynamic> json) {
    return ExperienceItem(
      id: json['id'],
      tieuDe: json['tieu_de'] ?? '',
      toChuc: json['to_chuc'],
      thoiGian: json['thoi_gian'],
      moTa: json['mo_ta'],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'tieu_de': tieuDe,
        'to_chuc': toChuc,
        'thoi_gian': thoiGian,
        'mo_ta': moTa,
      };

  @override
  List<Object?> get props => [id, tieuDe];
}

// Admin User Management
class AdminUser extends Equatable {
  final int id;
  final String hoTen;
  final String email;
  final String? soDienThoai;
  final String vaiTro;
  final String trangThai;
  final String? anhDaiDien;
  final DateTime createdAt;

  const AdminUser({
    required this.id,
    required this.hoTen,
    required this.email,
    this.soDienThoai,
    required this.vaiTro,
    required this.trangThai,
    this.anhDaiDien,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? 0,
      hoTen: json['ho_ten'] ?? '',
      email: json['email'] ?? '',
      soDienThoai: json['so_dien_thoai'],
      vaiTro: json['vai_tro'] ?? 'tinh_nguyen_vien',
      trangThai: json['trang_thai'] ?? 'kich_hoat',
      anhDaiDien: json['anh_dai_dien'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  bool get isActive => trangThai == 'kich_hoat';

  @override
  List<Object?> get props => [id, email, trangThai];
}

// Category item
class CategoryItem extends Equatable {
  final int id;
  final String ten;
  final String? moTa;
  final String? bieuTuong;
  final String? mauSac;
  final double? viDo;
  final double? kinhDo;
  final int nguoiDungCount;
  final int chienDichCount;
  final bool hoatDong;
  final DateTime createdAt;

  const CategoryItem({
    required this.id,
    required this.ten,
    this.moTa,
    this.bieuTuong,
    this.mauSac,
    this.viDo,
    this.kinhDo,
    this.nguoiDungCount = 0,
    this.chienDichCount = 0,
    this.hoatDong = true,
    required this.createdAt,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return CategoryItem(
      id: json['id'] ?? 0,
      ten: json['ten'] ?? '',
      moTa: json['mo_ta'],
      bieuTuong: json['bieu_tuong'],
      mauSac: json['mau_sac'],
      viDo: (json['vi_do'] as num?)?.toDouble(),
      kinhDo: (json['kinh_do'] as num?)?.toDouble(),
      nguoiDungCount: json['nguoi_dung_count'] ?? 0,
      chienDichCount: json['chien_dich_count'] ?? 0,
      hoatDong: json['hoat_dong'] == true || json['hoat_dong'] == 1,
      createdAt: parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'ten': ten,
        if (moTa != null) 'mo_ta': moTa,
        if (bieuTuong != null) 'bieu_tuong': bieuTuong,
        if (mauSac != null) 'mau_sac': mauSac,
        if (viDo != null) 'vi_do': viDo,
        if (kinhDo != null) 'kinh_do': kinhDo,
        'hoat_dong': hoatDong,
      };

  @override
  List<Object?> get props => [id, ten];
}

// Province/Ward
class Province extends Equatable {
  final int code;
  final String ten;
  final double lat;
  final double lng;

  const Province({
    required this.code,
    required this.ten,
    required this.lat,
    required this.lng,
  });

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      code: json['code'] ?? json['id'] ?? 0,
      ten: json['ten'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [code, ten];
}

class Ward extends Equatable {
  final int code;
  final String ten;
  final double lat;
  final double lng;

  const Ward({
    required this.code,
    required this.ten,
    required this.lat,
    required this.lng,
  });

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      code: json['code'] ?? json['id'] ?? 0,
      ten: json['ten'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [code, ten];
}

// Skill
class Skill extends Equatable {
  final int id;
  final String ten;
  final String? moTa;
  final String? bieuTuong;

  const Skill({
    required this.id,
    required this.ten,
    this.moTa,
    this.bieuTuong,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'] ?? 0,
      ten: json['ten'] ?? json['ten_ky_nang'] ?? '',
      moTa: json['mo_ta'],
      bieuTuong: json['bieu_tuong'],
    );
  }

  Map<String, dynamic> toJson() => {
        'ten': ten,
        if (moTa != null) 'mo_ta': moTa,
        if (bieuTuong != null) 'bieu_tuong': bieuTuong,
      };

  @override
  List<Object?> get props => [id, ten];
}
