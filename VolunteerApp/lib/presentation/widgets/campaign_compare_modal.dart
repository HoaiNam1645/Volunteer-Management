import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/campaign_repository.dart';

/// Modal so sánh chiến dịch với hồ sơ TNV (kỹ năng / khu vực / thời gian / điểm tổng).
/// Match logic FE Danh_Sach_Chien_Dich.vue → openCampaignCompare().
class CampaignCompareModal extends StatefulWidget {
  final RecommendedCampaign? recommendation; // optional: nếu đến từ panel gợi ý
  final int campaignId;
  final String campaignTitle;

  const CampaignCompareModal({
    super.key,
    required this.campaignId,
    required this.campaignTitle,
    this.recommendation,
  });

  @override
  State<CampaignCompareModal> createState() => _CampaignCompareModalState();
}

class _CampaignCompareModalState extends State<CampaignCompareModal> {
  final ApiClient _api = ApiClient.instance;
  bool _loading = true;

  // Campaign info
  Map<String, dynamic> _campaign = {};
  List<String> _campaignSkills = const [];
  // Volunteer profile
  List<int> _volSkillIds = const [];
  List<String> _volSkillNames = const [];
  List<int> _volAreaIds = const [];
  List<String> _volAreaNames = const [];
  List<String> _volAvailability = const [];
  double? _volLat;
  double? _volLng;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.get(ApiEndpoints.campaignDetail(widget.campaignId)),
        _api.get(ApiEndpoints.userProfile),
        _api.get(ApiEndpoints.userInfo),
        _api.get(ApiEndpoints.categorySkills),
        _api.get(ApiEndpoints.categoryAreas),
      ]);
      _campaign = (results[0].data['data'] is Map<String, dynamic>) ? results[0].data['data'] as Map<String, dynamic> : {};
      _campaignSkills = ((_campaign['ky_nangs'] as List?) ?? const [])
          .map((s) => (s is Map ? s['ten'] : s)?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      final profile = (results[1].data['data'] is Map<String, dynamic>) ? results[1].data['data'] as Map<String, dynamic> : {};
      final info = (results[2].data['data'] is Map<String, dynamic>) ? results[2].data['data'] as Map<String, dynamic> : {};
      final skillCatalog = (results[3].data['data'] as List? ?? []);
      final areaCatalog = (results[4].data['data'] as List? ?? []);

      _volSkillIds = List<int>.from(profile['ky_nang_ids'] ?? const []);
      _volAreaIds = List<int>.from(profile['khu_vuc_ids'] ?? const []);
      _volAvailability = List<String>.from(profile['lich_ranh'] ?? const []);

      _volSkillNames = _volSkillIds
          .map((id) {
            final s = skillCatalog.firstWhere((e) => e['id'] == id, orElse: () => null);
            return s?['ten']?.toString() ?? '';
          })
          .where((s) => s.isNotEmpty)
          .toList();
      _volAreaNames = _volAreaIds
          .map((id) {
            final a = areaCatalog.firstWhere((e) => e['id'] == id, orElse: () => null);
            return a?['ten']?.toString() ?? '';
          })
          .where((s) => s.isNotEmpty)
          .toList();
      _volLat = (info['vi_do'] is num)
          ? (info['vi_do'] as num).toDouble()
          : double.tryParse((info['vi_do'] ?? '').toString());
      _volLng = (info['kinh_do'] is num)
          ? (info['kinh_do'] as num).toDouble()
          : double.tryParse((info['kinh_do'] ?? '').toString());
    } catch (_) {/* ignore */}
    if (mounted) setState(() => _loading = false);
  }

  // ===== Helpers (match FE Danh_Sach_Chien_Dich.vue) =====
  static const _dayMap = {
    1: 'thu_hai', 2: 'thu_ba', 3: 'thu_tu', 4: 'thu_nam',
    5: 'thu_sau', 6: 'thu_bay', 7: 'chu_nhat',
  };

  List<String> _campaignWeekdays() {
    final start = DateTime.tryParse(_campaign['ngay_bat_dau']?.toString() ?? '');
    final end = DateTime.tryParse(_campaign['ngay_ket_thuc']?.toString() ?? '');
    if (start == null || end == null || start.isAfter(end)) return const [];
    final seen = <String>{};
    var d = start;
    while (!d.isAfter(end)) {
      final key = _dayMap[d.weekday];
      if (key != null) seen.add(key);
      d = d.add(const Duration(days: 1));
    }
    return seen.toList();
  }

  double? _distanceKm() {
    final cLat = (_campaign['vi_do'] is num)
        ? (_campaign['vi_do'] as num).toDouble()
        : double.tryParse((_campaign['vi_do'] ?? '').toString());
    final cLng = (_campaign['kinh_do'] is num)
        ? (_campaign['kinh_do'] as num).toDouble()
        : double.tryParse((_campaign['kinh_do'] ?? '').toString());
    if (cLat == null || cLng == null || _volLat == null || _volLng == null) return null;
    const earth = 6371.0;
    double rad(double v) => v * pi / 180;
    final dLat = rad(cLat - _volLat!);
    final dLng = rad(cLng - _volLng!);
    final a = sin(dLat / 2) * sin(dLat / 2)
        + cos(rad(_volLat!)) * cos(rad(cLat)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earth * c;
  }

  int _distanceToPercent(double? km) {
    if (km == null) return 0;
    if (km <= 3) return 100;
    if (km <= 10) return (100 - ((km - 3) / 7) * 30).round();
    if (km <= 20) return (70 - ((km - 10) / 10) * 30).round();
    return 10;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final matchedSkills = _volSkillNames.where(_campaignSkills.contains).toList();
    final missingSkills = _campaignSkills.where((s) => !_volSkillNames.contains(s)).toList();
    final skillPct = _campaignSkills.isEmpty
        ? 100
        : ((matchedSkills.length / _campaignSkills.length) * 100).round();

    final campaignDays = _campaignWeekdays();
    final matchedDays = campaignDays.where(_volAvailability.contains).toList();
    final availPct = campaignDays.isEmpty
        ? 100
        : ((matchedDays.length / campaignDays.length) * 100).round();

    final km = _distanceKm();
    final distPct = _distanceToPercent(km);

    final overall = widget.recommendation?.matchScore ??
        ((distPct * 0.4) + (skillPct * 0.3) + (availPct * 0.2) + 5).round();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollCtl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ListView(
          controller: scrollCtl,
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Icon(Icons.compare_arrows, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('So sánh chiến dịch với hồ sơ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Text(widget.campaignTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            // Overall score
            _scoreCard('Mức phù hợp tổng', overall.toDouble(), Colors.purple),
            const SizedBox(height: 16),
            // Skill row
            _compareRow(
              icon: Icons.build,
              color: AppTheme.primaryColor,
              title: 'Kỹ năng',
              campaignText: _campaignSkills.isEmpty ? 'Không yêu cầu kỹ năng cụ thể' : _campaignSkills.join(', '),
              profileText: _volSkillNames.isEmpty ? 'Hồ sơ chưa khai báo kỹ năng' : _volSkillNames.join(', '),
              footer: matchedSkills.isEmpty && missingSkills.isEmpty
                  ? 'Không yêu cầu'
                  : 'Khớp ${matchedSkills.length}/${_campaignSkills.length}'
                      '${missingSkills.isNotEmpty ? ' · Còn thiếu: ${missingSkills.join(", ")}' : ''}',
              percent: skillPct,
            ),
            // Location/distance row
            _compareRow(
              icon: Icons.location_on,
              color: Colors.red,
              title: 'Khoảng cách',
              campaignText: (_campaign['dia_diem']?.toString() ?? '—'),
              profileText: _volAreaNames.isEmpty ? 'Hồ sơ chưa chọn khu vực' : _volAreaNames.join(', '),
              footer: km != null ? 'Cách bạn ${km.toStringAsFixed(2)} km' : 'Chưa có toạ độ để tính',
              percent: distPct,
            ),
            // Availability row
            _compareRow(
              icon: Icons.calendar_month,
              color: Colors.orange,
              title: 'Thời gian',
              campaignText: campaignDays.isEmpty ? '—' : campaignDays.map(_dayLabel).join(', '),
              profileText: _volAvailability.isEmpty
                  ? 'Hồ sơ chưa chọn lịch rảnh'
                  : _volAvailability.map(_dayLabel).join(', '),
              footer: campaignDays.isEmpty
                  ? '—'
                  : 'Khớp ${matchedDays.length}/${campaignDays.length} ngày',
              percent: availPct,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dayLabel(String key) => const {
        'thu_hai': 'T2', 'thu_ba': 'T3', 'thu_tu': 'T4', 'thu_nam': 'T5',
        'thu_sau': 'T6', 'thu_bay': 'T7', 'chu_nhat': 'CN',
      }[key] ?? key;

  Widget _scoreCard(String label, double percent, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color))),
          Text('${percent.toInt()}%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _compareRow({
    required IconData icon,
    required Color color,
    required String title,
    required String campaignText,
    required String profileText,
    required String footer,
    required int percent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _pctColor(percent).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Text('$percent%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _pctColor(percent))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _miniRow('Chiến dịch', campaignText),
          const SizedBox(height: 4),
          _miniRow('Hồ sơ bạn', profileText),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 4,
              backgroundColor: Colors.grey[200],
              color: _pctColor(percent),
            ),
          ),
          const SizedBox(height: 4),
          Text(footer, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Color _pctColor(int p) {
    if (p >= 80) return Colors.green;
    if (p >= 50) return Colors.orange;
    if (p > 0) return Colors.red;
    return Colors.grey;
  }

  Widget _miniRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
      ],
    );
  }
}
