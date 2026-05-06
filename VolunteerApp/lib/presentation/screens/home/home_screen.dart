import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/home_repository.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeRepository _repo = HomeRepository();
  bool _loading = true;
  HomeData _data = HomeData.empty();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _repo.getHome();
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  // ===== Computed: impactStats =====
  Map<String, num> get _impactStats {
    final all = [..._data.featured, ..._data.upcoming, ..._data.completed];
    final featuredAndUpcoming = [..._data.featured, ..._data.upcoming];
    final totalCapacity = all.fold<int>(0, (s, e) => s + e.total);
    final totalRegistrations = all.fold<int>(0, (s, e) => s + e.soDangKy);
    final activeCampaigns = featuredAndUpcoming.length;
    final totalCampaigns = all.isEmpty ? 1 : all.length;
    final fillRate = totalCapacity > 0 ? ((totalRegistrations / totalCapacity) * 100).round() : 0;
    final completedRate = ((_data.completed.length / totalCampaigns) * 100).round();
    final activeRate = ((activeCampaigns / totalCampaigns) * 100).round();
    return {
      'totalRegistrations': totalRegistrations,
      'fillRate': fillRate.clamp(0, 100),
      'completedRate': completedRate.clamp(0, 100),
      'activeCampaigns': activeCampaigns,
      'activeRate': activeRate.clamp(0, 100),
    };
  }

  String _fmt(num n) => n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _timeLabel(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final d = DateTime.tryParse(raw);
    if (d == null) return _formatDate(raw);
    final diff = d.difference(DateTime.now()).inDays;
    if (diff <= 0) return 'Sắp bắt đầu';
    if (diff == 1) return 'Bắt đầu sau 1 ngày';
    return 'Bắt đầu sau $diff ngày';
  }

  String _relativeTime(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final d = DateTime.tryParse(raw.replaceAll(' ', 'T'));
    if (d == null) return raw;
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 30) return '${diff.inDays} ngày trước';
    return _formatDate(raw);
  }

  String _statusLabel(String? s) => switch (s) {
        'da_dang_ky' => 'Đã đăng ký',
        'da_duyet' => 'Đã duyệt',
        'da_xac_nhan' => 'Đã xác nhận',
        'dang_tham_gia' => 'Đang tham gia',
        'hoan_thanh' => 'Hoàn thành',
        _ => 'Cập nhật mới',
      };

  Color _priorityColor(String? p) => switch (p) {
        'khan_cap' => Colors.red,
        'cao' => AppTheme.primaryColor,
        'thap' => Colors.green,
        _ => Colors.cyan,
      };

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final stats = _impactStats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VMS-AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/campaigns'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _data.featured.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildHero(user?.name, stats),
                  _sectionTitle('Trung tâm thông tin nhanh', 'Nhìn nhanh các chỉ số quan trọng'),
                  _buildOverviewCards(stats),
                  if (_data.featured.isNotEmpty) ...[
                    _sectionTitle('🔥 Chiến dịch nổi bật', 'Tâm điểm tuần này', actionText: 'Xem tất cả', onAction: () => context.go('/campaigns')),
                    _buildSpotlight(),
                  ],
                  if (_data.upcoming.isNotEmpty) ...[
                    _sectionTitle('📅 Chiến dịch sắp tới', 'Đăng ký sớm để có chỗ'),
                    _buildHorizontalList(_data.upcoming, false),
                  ],
                  if (_data.completed.isNotEmpty) ...[
                    _sectionTitle('✅ Chiến dịch đã hoàn thành', 'Đã khép lại với báo cáo'),
                    _buildHorizontalList(_data.completed, true),
                  ],
                  _sectionTitle('📈 Bản đồ tác động', 'Đo lường hiệu quả triển khai'),
                  _buildImpactCards(stats),
                  if (_data.recentVolunteers.isNotEmpty) ...[
                    _sectionTitle('👥 TNV tham gia gần đây', 'Lượt đăng ký mới nhất'),
                    _buildRecentVolunteers(),
                  ],
                  _sectionTitle('🤖 AI hỗ trợ vận hành', 'Hỗ trợ điều phối & duyệt chiến dịch'),
                  _buildAiCards(),
                  _sectionTitle('🚀 Cách tham gia', 'Bốn bước đơn giản'),
                  _buildSteps(),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  Widget _buildHero(String? name, Map<String, num> stats) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF12375B), Color(0xFF0F4C81), Color(0xFF114677)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text('Mạng lưới thiện nguyện minh bạch', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name != null ? 'Xin chào, $name!' : 'Lan tỏa yêu thương,',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Cùng kết nối — Cùng hành động',
            style: TextStyle(color: Color(0xFFFFD46B), fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/campaigns'),
                  icon: const Icon(Icons.explore),
                  label: const Text('Khám phá'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/my-campaigns'),
                  icon: const Icon(Icons.folder_open, color: Colors.white),
                  label: const Text('Của tôi', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Hero mini stats grid
          Row(
            children: [
              Expanded(child: _heroMini(Icons.people, 'TNV', '${_fmt(_data.hero.volunteerCount)}+')),
              const SizedBox(width: 8),
              Expanded(child: _heroMini(Icons.people_alt, 'Lượt tham gia', '${_fmt(stats['totalRegistrations']!)}+')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _heroMini(Icons.location_on, 'Tỉnh thành', '${_fmt(_data.hero.provinceCount)}+')),
              const SizedBox(width: 8),
              Expanded(child: _heroMini(Icons.star, 'Tỉ lệ lấp đầy', '${stats['fillRate']}%')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMini(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle, {String? actionText, VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          if (actionText != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionText)),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(Map<String, num> stats) {
    final cards = [
      ('Tình nguyện viên', '${_fmt(_data.hero.volunteerCount)}+', 'Đã xác thực', Icons.group, Colors.blue),
      ('Đang mở', '${stats['activeCampaigns']}', '${stats['activeRate']}% tổng', Icons.campaign, Colors.orange),
      ('Lượt đăng ký', '${_fmt(stats['totalRegistrations']!)}', 'Đã tiếp nhận', Icons.fact_check, Colors.green),
      ('Lấp đầy', '${stats['fillRate']}%', 'Đáp ứng nhân sự', Icons.pie_chart, Colors.purple),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.5,
        children: cards
            .map((c) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: c.$5.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                        child: Icon(c.$4, size: 16, color: c.$5),
                      ),
                      Text(c.$1, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(c.$2, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(c.$3, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSpotlight() {
    final spotlight = _data.featured.first;
    final secondary = _data.featured.skip(1).take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          InkWell(
            onTap: () => context.push('/campaign/${spotlight.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Stack(
                      children: [
                        Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _priorityColor(spotlight.mucDoUuTien),
                            image: spotlight.anhBia != null && spotlight.anhBia!.isNotEmpty
                                ? DecorationImage(image: NetworkImage(spotlight.anhBia!), fit: BoxFit.cover)
                                : null,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)),
                            child: const Text('Tâm điểm', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(spotlight.tieuDe, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        if (spotlight.moTa != null && spotlight.moTa!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(spotlight.moTa!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _meta(Icons.location_on, spotlight.diaDiem ?? '—'),
                            _meta(Icons.calendar_today, _formatDate(spotlight.ngayBatDau)),
                            _meta(Icons.people, '${spotlight.soDangKy}/${spotlight.total}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: spotlight.progress,
                            backgroundColor: Colors.grey[200],
                            color: _priorityColor(spotlight.mucDoUuTien),
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (secondary.isNotEmpty) const SizedBox(height: 8),
          ...secondary.map((c) => _compactCampaignTile(c)),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      );

  Widget _compactCampaignTile(HomeCampaign c) {
    return InkWell(
      onTap: () => context.push('/campaign/${c.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 60, height: 60,
                color: _priorityColor(c.mucDoUuTien),
                child: c.anhBia != null && c.anhBia!.isNotEmpty
                    ? Image.network(c.anhBia!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox())
                    : const Icon(Icons.campaign, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.tieuDe, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('${c.diaDiem ?? '—'} • ${_formatDate(c.ngayBatDau)}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text('${c.soDangKy}/${c.total} đăng ký', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalList(List<HomeCampaign> list, bool completed) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final c = list[i];
          return Container(
            width: 240,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
            child: InkWell(
              onTap: () => context.push('/campaign/${c.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: Container(
                      height: 90,
                      width: double.infinity,
                      color: completed ? Colors.grey : _priorityColor(c.mucDoUuTien),
                      child: c.anhBia != null && c.anhBia!.isNotEmpty
                          ? ColorFiltered(
                              colorFilter: completed
                                  ? const ColorFilter.matrix([
                                      0.5, 0.5, 0.5, 0, 0,
                                      0.5, 0.5, 0.5, 0, 0,
                                      0.5, 0.5, 0.5, 0, 0,
                                      0,   0,   0,   1, 0,
                                    ])
                                  : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                              child: Image.network(c.anhBia!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
                            )
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.tieuDe, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        _meta(Icons.location_on, c.diaDiem ?? '—'),
                        const SizedBox(height: 2),
                        _meta(completed ? Icons.check_circle : Icons.access_time, completed ? 'Hoàn thành' : _timeLabel(c.ngayBatDau)),
                        const SizedBox(height: 4),
                        if (!completed)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: c.progress,
                              backgroundColor: Colors.grey[200],
                              color: _priorityColor(c.mucDoUuTien),
                              minHeight: 3,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImpactCards(Map<String, num> stats) {
    final items = [
      ('Năng lực phủ', '${stats['activeCampaigns']}', 'Chiến dịch đang vận hành', stats['activeRate']!.toDouble()),
      ('Lượt phục vụ', _fmt(stats['totalRegistrations']!), 'Lượt phân bổ nhân sự', stats['fillRate']!.toDouble()),
      ('Đã hoàn tất', '${_data.completed.length}', 'Đã có báo cáo tổng kết', stats['completedRate']!.toDouble()),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: items
            .map((it) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it.$1, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(it.$2, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(it.$3, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: it.$4 / 100,
                          backgroundColor: Colors.grey[200],
                          color: Colors.green,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildRecentVolunteers() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: _data.recentVolunteers
            .take(5)
            .map((v) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                        backgroundImage: (v.avatar != null && v.avatar!.isNotEmpty) ? NetworkImage(v.avatar!) : null,
                        child: (v.avatar == null || v.avatar!.isEmpty) ? const Icon(Icons.person, color: AppTheme.primaryColor) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                  child: Text(_statusLabel(v.status), style: const TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            Text(_relativeTime(v.dangKyLuc), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            const SizedBox(height: 4),
                            Text(v.campaignTitle ?? '—', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            if (v.location != null && v.location!.isNotEmpty)
                              Text(v.location!, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildAiCards() {
    final cards = [
      ('Điều phối (Recommend)', 'AI hỗ trợ điều phối nhân sự',
          'Gợi ý TNV phù hợp cho từng chiến dịch dựa trên kỹ năng, khu vực, mức độ phù hợp.',
          ['Ưu tiên đúng khu vực và kỹ năng', 'Giảm thời gian lọc thủ công', 'Mời TNV ngay tại màn điều phối'],
          Icons.people_alt, Colors.blue),
      ('Duyệt chiến dịch (AI)', 'AI hỗ trợ ra quyết định duyệt',
          'Phân tích độ tin cậy chiến dịch mới, cảnh báo rủi ro và đề xuất hành động.',
          ['Phân tích nội dung & điểm tin cậy', 'Gợi ý duyệt/từ chối/bổ sung', 'Chỉ dấu rủi ro từ trust-eval'],
          Icons.shield, Colors.green),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: cards
            .map((c) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
                            child: Text(c.$1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          Icon(c.$5, color: c.$6),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(c.$2, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(c.$3, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      const SizedBox(height: 6),
                      ...c.$4.map((p) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(child: Text(p, style: const TextStyle(fontSize: 12))),
                              ],
                            ),
                          )),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSteps() {
    final steps = [
      ('Đăng ký tài khoản', 'Tạo hồ sơ và xác minh email', Icons.person_add),
      ('Tìm chiến dịch', 'Lọc theo khu vực, kỹ năng', Icons.search),
      ('Đăng ký tham gia', 'Chọn chiến dịch phù hợp', Icons.fact_check),
      ('Nhận đánh giá', 'Hoàn thành và nhận chứng nhận', Icons.emoji_events),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: List.generate(steps.length, (i) {
          final s = steps[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  alignment: Alignment.center,
                  child: Text('${i + 1}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Icon(s.$3, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(s.$2, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
