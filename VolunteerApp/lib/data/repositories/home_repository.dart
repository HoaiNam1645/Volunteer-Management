import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class HomeRepository {
  final ApiClient _apiClient = ApiClient.instance;

  Future<HomeData> getHome() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.home);
      final data = response.data?['data'] ?? {};
      return HomeData.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return HomeData.empty();
    }
  }
}

class HomeData {
  final HeroStats hero;
  final List<HomeCampaign> featured;
  final List<HomeCampaign> upcoming;
  final List<HomeCampaign> completed;
  final List<RecentVolunteer> recentVolunteers;

  const HomeData({
    required this.hero,
    required this.featured,
    required this.upcoming,
    required this.completed,
    required this.recentVolunteers,
  });

  factory HomeData.empty() => const HomeData(
        hero: HeroStats(volunteerCount: 0, campaignCount: 0, provinceCount: 0),
        featured: [],
        upcoming: [],
        completed: [],
        recentVolunteers: [],
      );

  factory HomeData.fromJson(Map<String, dynamic> json) {
    final hero = json['hero'] as Map<String, dynamic>? ?? {};
    return HomeData(
      hero: HeroStats(
        volunteerCount: (hero['volunteer_count'] ?? 0) is num ? (hero['volunteer_count'] as num).toInt() : 0,
        campaignCount: (hero['campaign_count'] ?? 0) is num ? (hero['campaign_count'] as num).toInt() : 0,
        provinceCount: (hero['province_count'] ?? 0) is num ? (hero['province_count'] as num).toInt() : 0,
      ),
      featured: (json['featured_campaigns'] as List? ?? []).map((e) => HomeCampaign.fromJson(e)).toList(),
      upcoming: (json['upcoming_campaigns'] as List? ?? []).map((e) => HomeCampaign.fromJson(e)).toList(),
      completed: (json['completed_campaigns'] as List? ?? []).map((e) => HomeCampaign.fromJson(e)).toList(),
      recentVolunteers: (json['recent_volunteers'] as List? ?? []).map((e) => RecentVolunteer.fromJson(e)).toList(),
    );
  }
}

class HeroStats {
  final int volunteerCount;
  final int campaignCount;
  final int provinceCount;
  const HeroStats({required this.volunteerCount, required this.campaignCount, required this.provinceCount});
}

class HomeCampaign {
  final int id;
  final String tieuDe;
  final String? moTa;
  final String? diaDiem;
  final String? ngayBatDau;
  final String? anhBia;
  final int soDangKy;
  final int soXacNhan;
  final int soLuongToiDa;
  final String? mucDoUuTien;
  final String? loaiTen;

  const HomeCampaign({
    required this.id,
    required this.tieuDe,
    this.moTa,
    this.diaDiem,
    this.ngayBatDau,
    this.anhBia,
    this.soDangKy = 0,
    this.soXacNhan = 0,
    this.soLuongToiDa = 0,
    this.mucDoUuTien,
    this.loaiTen,
  });

  factory HomeCampaign.fromJson(Map<String, dynamic> json) {
    return HomeCampaign(
      id: json['id'] ?? 0,
      tieuDe: json['tieu_de'] ?? '',
      moTa: json['mo_ta'],
      diaDiem: json['dia_diem'],
      ngayBatDau: json['ngay_bat_dau'],
      anhBia: json['anh_bia'],
      soDangKy: (json['so_dang_ky'] ?? 0) is num ? (json['so_dang_ky'] as num).toInt() : 0,
      soXacNhan: (json['so_xac_nhan'] ?? 0) is num ? (json['so_xac_nhan'] as num).toInt() : 0,
      soLuongToiDa: (json['so_luong_toi_da'] ?? 0) is num ? (json['so_luong_toi_da'] as num).toInt() : 0,
      mucDoUuTien: json['muc_do_uu_tien'],
      loaiTen: json['loai_chien_dich']?['ten'],
    );
  }

  int get total => soLuongToiDa > 0 ? soLuongToiDa : (soDangKy > soXacNhan ? soDangKy : soXacNhan).clamp(1, 1 << 31);
  double get progress => total > 0 ? (soDangKy / total).clamp(0, 1).toDouble() : 0;
}

class RecentVolunteer {
  final int? id;
  final String name;
  final String? avatar;
  final String? campaignTitle;
  final String? location;
  final String? status;
  final String? dangKyLuc;

  const RecentVolunteer({
    this.id,
    required this.name,
    this.avatar,
    this.campaignTitle,
    this.location,
    this.status,
    this.dangKyLuc,
  });

  factory RecentVolunteer.fromJson(Map<String, dynamic> json) {
    final user = json['nguoi_dung'] as Map<String, dynamic>?;
    final campaign = json['chien_dich'] as Map<String, dynamic>?;
    return RecentVolunteer(
      id: json['id'],
      name: user?['ho_ten'] ?? 'Tình nguyện viên',
      avatar: user?['anh_dai_dien'],
      campaignTitle: campaign?['tieu_de'],
      location: campaign?['dia_diem'],
      status: json['trang_thai'],
      dangKyLuc: json['dang_ky_luc'],
    );
  }
}
