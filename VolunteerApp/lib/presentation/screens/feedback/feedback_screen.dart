import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/registration_provider.dart';
import '../../widgets/common_widgets.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _historySearch = '';
  String? _historyFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RegistrationProvider>().loadTrackingData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final regProvider = context.watch<RegistrationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Theo dõi phản hồi'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history, size: 18),
                  const SizedBox(width: 6),
                  const Text('Lịch sử'),
                  if (regProvider.trackingHistory.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _buildCountBadge(regProvider.trackingHistory.length),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 18),
                  const SizedBox(width: 6),
                  const Text('Đánh giá'),
                  if (regProvider.trackingRatings.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _buildCountBadge(regProvider.trackingRatings.length),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flag, size: 18),
                  const SizedBox(width: 6),
                  const Text('Báo cáo'),
                  if (regProvider.trackingReports.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _buildCountBadge(regProvider.trackingReports.length),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: History
          _buildHistoryTab(regProvider),
          // Tab 2: Scores
          _buildScoresTab(regProvider),
          // Tab 3: Reports
          _buildReportsTab(regProvider),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _tabController.indexIsChanging ? Colors.grey[200] : AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _tabController.indexIsChanging ? Colors.grey[600] : AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildStatsCards(RegistrationProvider provider) {
    final stats = provider.trackingStats;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Hoàn thành',
              (stats['so_chien_dich_hoan_thanh'] ?? 0).toString(),
              Icons.check_circle_outline,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Đang tham gia',
              (stats['so_chien_dich_dang_tham_gia'] ?? 0).toString(),
              Icons.play_circle_outline,
              AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Điểm TB',
              _formatRating(stats['diem_danh_gia_trung_binh'] ?? 0),
              Icons.star_outline,
              Colors.amber,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Báo cáo',
              '${stats['bao_cao_dang_xu_ly'] ?? 0}/${stats['tong_bao_cao'] ?? 0}',
              Icons.flag_outlined,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRating(dynamic value) {
    if (value == null) return '0.0';
    final numericValue =
        (value is num) ? value.toDouble() : double.tryParse(value.toString()) ?? 0;
    return numericValue.toStringAsFixed(1);
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============ HISTORY TAB ============
  Widget _buildHistoryTab(RegistrationProvider provider) {
    if (provider.isLoading && provider.trackingHistory.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredHistory = provider.trackingHistory.where((h) {
      final campaignTitle = (h['chien_dich']?['tieu_de'] ?? '').toString().toLowerCase();
      final matchesSearch = _historySearch.isEmpty || campaignTitle.contains(_historySearch.toLowerCase());
      final matchesFilter = _historyFilter == null || _historyFilter!.isEmpty || h['trang_thai_dang_ky'] == _historyFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    return RefreshIndicator(
      onRefresh: () => provider.loadTrackingData(),
      child: CustomScrollView(
        slivers: [
          // Stats
          SliverToBoxAdapter(child: _buildStatsCards(provider)),

          // Search & Filter
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm chiến dịch...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) => setState(() => _historySearch = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) => setState(() => _historyFilter = value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_list, size: 20),
                          const SizedBox(width: 4),
                          Text(_historyFilter ?? 'Tất cả', style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: '', child: Text('Tất cả')),
                      PopupMenuItem(value: 'da_dang_ky', child: Text('Đã đăng ký')),
                      PopupMenuItem(value: 'da_xac_nhan', child: Text('Đã xác nhận')),
                      PopupMenuItem(value: 'da_duyet', child: Text('Đã duyệt')),
                      PopupMenuItem(value: 'dang_tham_gia', child: Text('Đang tham gia')),
                      PopupMenuItem(value: 'hoan_thanh', child: Text('Hoàn thành')),
                      PopupMenuItem(value: 'da_huy', child: Text('Đã hủy')),
                      PopupMenuItem(value: 'tu_choi', child: Text('Từ chối')),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // List
          if (filteredHistory.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                icon: Icons.history,
                title: 'Chưa có lịch sử',
                subtitle: 'Đăng ký tham gia chiến dịch để xem lịch sử',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = filteredHistory[index];
                  return _buildHistoryItem(item);
                },
                childCount: filteredHistory.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final campaign = item['chien_dich'] ?? {};
    final status = item['trang_thai_dang_ky'] ?? '';
    final rating = item['danh_gia_tnv'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showActionSheet(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.handshake, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campaign['tieu_de'] ?? 'Không xác định',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          campaign['nguoi_tao']?['ho_ten'] ?? '-',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      campaign['dia_diem'] ?? '-',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (rating != null && rating['so_sao'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...List.generate(5, (i) {
                      return Icon(
                        i < (rating['so_sao'] ?? 0) ? Icons.star : Icons.star_border,
                        size: 14,
                        color: Colors.amber,
                      );
                    }),
                    const SizedBox(width: 4),
                    Text(
                      '${rating['so_sao']}/5',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'da_dang_ky':
        color = Colors.blue;
        label = 'Đã đăng ký';
        icon = Icons.check;
        break;
      case 'da_xac_nhan':
        color = AppTheme.primaryColor;
        label = 'Đã xác nhận';
        icon = Icons.verified;
        break;
      case 'da_duyet':
        color = Colors.green;
        label = 'Đã duyệt';
        icon = Icons.task_alt;
        break;
      case 'dang_tham_gia':
        color = Colors.orange;
        label = 'Đang tham gia';
        icon = Icons.play_arrow;
        break;
      case 'hoan_thanh':
        color = Colors.green;
        label = 'Hoàn thành';
        icon = Icons.check_circle;
        break;
      case 'da_huy':
        color = Colors.grey;
        label = 'Đã hủy';
        icon = Icons.cancel;
        break;
      case 'tu_choi':
        color = Colors.red;
        label = 'Từ chối';
        icon = Icons.close;
        break;
      default:
        color = Colors.grey;
        label = status;
        icon = Icons.circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  void _showActionSheet(Map<String, dynamic> item) {
    final campaign = item['chien_dich'] ?? {};
    final canFeedback = item['co_the_danh_gia_chien_dich'] == true;
    final canReport = item['co_the_report'] == true;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              campaign['tieu_de'] ?? 'Chiến dịch',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Xem chi tiết'),
              onTap: () {
                Navigator.pop(context);
                final cid = item['chien_dich_id'] ?? campaign['id'];
                if (cid != null) {
                  context.push('/campaign/$cid');
                }
              },
            ),
            if (canFeedback)
              ListTile(
                leading: const Icon(Icons.comment_outlined, color: Colors.green),
                title: const Text('Gửi đánh giá'),
                onTap: () {
                  Navigator.pop(context);
                  _showFeedbackDialog(item);
                },
              ),
            if (canReport)
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.red),
                title: const Text('Báo cáo chiến dịch'),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog(item);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog(Map<String, dynamic> item) {
    final campaign = item['chien_dich'] ?? {};
    final existing = item['phan_hoi_chien_dich'];
    int selectedRating = (existing?['so_sao'] is num) ? (existing['so_sao'] as num).toInt() : 0;
    final commentController = TextEditingController(
      text: (existing?['nhan_xet'] ?? '').toString(),
    );
    final selectedTags = <int>{
      ...((existing?['the_ids'] as List?) ?? const []).map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).where((e) => e != 0),
    };
    final regProvider = context.read<RegistrationProvider>();
    final tags = regProvider.feedbackTags;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gửi đánh giá',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign['tieu_de'] ?? 'Chiến dịch',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Ngày: ${_formatDateRange(campaign)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Center(child: Text('Đánh giá trải nghiệm của bạn', style: TextStyle(fontWeight: FontWeight.w600))),
                const SizedBox(height: 8),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return IconButton(
                        icon: Icon(
                          i < selectedRating ? Icons.star : Icons.star_border,
                          size: 36,
                          color: Colors.amber,
                        ),
                        onPressed: () => setModalState(() => selectedRating = i + 1),
                      );
                    }),
                  ),
                ),
                Center(
                  child: Text(
                    _getRatingLabel(selectedRating),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: 'Nhận xét của bạn',
                    hintText: 'Chia sẻ trải nghiệm của bạn...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Bạn muốn cải thiện điều gì?',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) {
                      final id = tag['id'] is int ? tag['id'] as int : int.tryParse('${tag['id']}') ?? 0;
                      final selected = selectedTags.contains(id);
                      return FilterChip(
                        label: Text(tag['ten']?.toString() ?? '-'),
                        selected: selected,
                        onSelected: (_) => setModalState(() {
                          if (selected) {
                            selectedTags.remove(id);
                          } else {
                            selectedTags.add(id);
                          }
                        }),
                        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                        checkmarkColor: AppTheme.primaryColor,
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedRating > 0
                        ? () async {
                            final cid = item['chien_dich_id'] ?? campaign['id'] ?? 0;
                            final provider = context.read<RegistrationProvider>();
                            final success = await provider.submitFeedback(
                              chienDichId: cid is int ? cid : int.tryParse(cid.toString()) ?? 0,
                              soSao: selectedRating,
                              nhanXet: commentController.text.isNotEmpty ? commentController.text : null,
                              theIds: selectedTags.toList(),
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success ? 'Cảm ơn bạn đã đánh giá!' : (provider.error ?? 'Gửi đánh giá thất bại')),
                                  backgroundColor: success ? Colors.green : Colors.red,
                                ),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Gửi đánh giá'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReportDialog(Map<String, dynamic> item) {
    final campaign = item['chien_dich'] ?? {};
    final categoryController = TextEditingController();
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Báo cáo chiến dịch',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign['tieu_de'] ?? 'Chiến dịch',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    campaign['dia_diem'] ?? '-',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Phân loại báo cáo',
                hintText: 'Ví dụ: Vi phạm nội quy, Lỗi thông tin...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                hintText: 'Nhập tiêu đề báo cáo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'Nội dung',
                hintText: 'Mô tả chi tiết vấn đề...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (categoryController.text.isEmpty ||
                      titleController.text.isEmpty ||
                      contentController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
                    );
                    return;
                  }

                  final cid = item['chien_dich_id'] ?? campaign['id'] ?? 0;
                  final provider = context.read<RegistrationProvider>();
                  final success = await provider.submitReport(
                    chienDichId: cid is int ? cid : int.tryParse(cid.toString()) ?? 0,
                    phanLoai: categoryController.text,
                    tieuDe: titleController.text,
                    noiDung: contentController.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Báo cáo đã được gửi!' : (provider.error ?? 'Gửi báo cáo thất bại')),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                    // Switch to reports tab after successful submission
                    if (success) {
                      _tabController.animateTo(2);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.red,
                ),
                child: const Text('Gửi báo cáo'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Rất không hài lòng';
      case 2:
        return 'Không hài lòng';
      case 3:
        return 'Bình thường';
      case 4:
        return 'Hài lòng';
      case 5:
        return 'Rất hài lòng';
      default:
        return '';
    }
  }

  String _formatDateRange(Map<String, dynamic> campaign) {
    final start = campaign['ngay_bat_dau'] ?? '';
    final end = campaign['ngay_ket_thuc'] ?? '';
    if (start.isEmpty && end.isEmpty) return '-';
    return '$start - $end';
  }

  // ============ SCORES TAB ============
  Widget _buildScoresTab(RegistrationProvider provider) {
    if (provider.isLoading && provider.trackingRatings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final ratings = provider.trackingRatings;
    final avgRating = _formatRating(provider.trackingStats['diem_danh_gia_trung_binh'] ?? 0);

    return RefreshIndicator(
      onRefresh: () => provider.loadTrackingData(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Rating circle
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.amber, width: 4),
                            ),
                            child: Center(
                              child: Text(
                                avgRating,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (i) {
                              return Icon(
                                i < (double.tryParse(avgRating)?.round() ?? 0)
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 18,
                                color: Colors.amber,
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Dựa trên ${ratings.length} đánh giá',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Rating list
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber),
                        SizedBox(width: 8),
                        Text('Chi tiết đánh giá', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    if (ratings.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('Chưa có đánh giá nào')),
                      )
                    else
                      ...ratings.map((rating) => _buildRatingItem(rating)),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildRatingItem(Map<String, dynamic> rating) {
    final stars = rating['so_sao'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.star, color: AppTheme.primaryColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rating['ten_chien_dich'] ?? 'Không xác định',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatDateTime(rating['tao_luc']),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              return Icon(
                i < stars ? Icons.star : Icons.star_border,
                size: 14,
                color: Colors.amber,
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            '$stars/5',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '-';
    return dateTime.split('T').first;
  }

  // ============ REPORTS TAB ============
  Widget _buildReportsTab(RegistrationProvider provider) {
    if (provider.isLoading && provider.trackingReports.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final reports = provider.trackingReports;

    if (reports.isEmpty) {
      return const EmptyState(
        icon: Icons.flag_outlined,
        title: 'Chưa có báo cáo nào',
        subtitle: 'Các báo cáo của bạn sẽ hiển thị ở đây',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadTrackingData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return _buildReportCard(report);
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final status = report['trang_thai'] ?? '';
    final response = report['phan_hoi_xu_ly'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['tieu_de'] ?? 'Báo cáo',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${report['ten_chien_dich'] ?? '-'} - ${_formatDateTime(report['tao_luc'])}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildReportStatusBadge(status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.category_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Phân loại: ${report['phan_loai'] ?? '-'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report['noi_dung'] ?? '',
              style: const TextStyle(fontSize: 14),
            ),
            if (response.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phản hồi xử lý',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(response, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'moi':
        color = Colors.blue;
        label = 'Mới';
        break;
      case 'dang_xu_ly':
        color = Colors.orange;
        label = 'Đang xử lý';
        break;
      case 'da_xu_ly':
        color = Colors.green;
        label = 'Đã xử lý';
        break;
      case 'tu_choi':
        color = Colors.red;
        label = 'Từ chối';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
