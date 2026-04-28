import 'package:equatable/equatable.dart';

class Registration extends Equatable {
  final int id;
  final int chienDichId;
  final String? tenChienDich;
  final int nguoiDungId;
  final String? tenNguoiDung;
  final String trangThai;
  final DateTime? ngayDangKy;
  final DateTime? ngayXacNhan;
  final String? ghiChu;
  final Feedback? phanHoi;

  const Registration({
    required this.id,
    required this.chienDichId,
    this.tenChienDich,
    required this.nguoiDungId,
    this.tenNguoiDung,
    required this.trangThai,
    this.ngayDangKy,
    this.ngayXacNhan,
    this.ghiChu,
    this.phanHoi,
  });

  factory Registration.fromJson(Map<String, dynamic> json) {
    return Registration(
      id: json['id'] ?? 0,
      chienDichId: json['chien_dich_id'] ?? 0,
      tenChienDich: json['ten_chien_dich'],
      nguoiDungId: json['nguoi_dung_id'] ?? 0,
      tenNguoiDung: json['ten_nguoi_dung'],
      trangThai: json['trang_thai'] ?? 'cho_xac_nhan',
      ngayDangKy: json['ngay_dang_ky'] != null
          ? DateTime.parse(json['ngay_dang_ky'])
          : null,
      ngayXacNhan: json['ngay_xac_nhan'] != null
          ? DateTime.parse(json['ngay_xac_nhan'])
          : null,
      ghiChu: json['ghi_chu'],
      phanHoi: json['phan_hoi'] != null
          ? Feedback.fromJson(json['phan_hoi'])
          : null,
    );
  }

  String get statusDisplayName {
    switch (trangThai) {
      case 'cho_xac_nhan':
        return 'Chờ xác nhận';
      case 'da_xac_nhan':
        return 'Đã xác nhận';
      case 'da_tham_gia':
        return 'Đã tham gia';
      case 'vo_hieu_hoa':
        return 'Vô hiệu hóa';
      default:
        return trangThai;
    }
  }

  bool get canCancel =>
      trangThai == 'cho_xac_nhan' || trangThai == 'da_xac_nhan';

  bool get canFeedback =>
      trangThai == 'da_tham_gia' || trangThai == 'da_xac_nhan';

  @override
  List<Object?> get props => [id, chienDichId, trangThai, ngayDangKy];
}

class Feedback extends Equatable {
  final int id;
  final int? diemDanhGia;
  final String? nhanXet;
  final String? goiY;
  final DateTime createdAt;

  const Feedback({
    required this.id,
    this.diemDanhGia,
    this.nhanXet,
    this.goiY,
    required this.createdAt,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'] ?? 0,
      diemDanhGia: json['diem_danh_gia'],
      nhanXet: json['nhan_xet'],
      goiY: json['goi_y'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'diem_danh_gia': diemDanhGia,
    'nhan_xet': nhanXet,
    'goi_y': goiY,
  };

  @override
  List<Object?> get props => [id, diemDanhGia, nhanXet];
}

class CreateFeedbackRequest {
  final int registrationId;
  final int? rating;
  final String? comment;
  final String? suggestion;

  CreateFeedbackRequest({
    required this.registrationId,
    this.rating,
    this.comment,
    this.suggestion,
  });

  Map<String, dynamic> toJson() => {
    'diem_danh_gia': rating,
    'nhan_xet': comment,
    'goi_y': suggestion,
  };
}
