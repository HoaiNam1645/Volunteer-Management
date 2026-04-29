import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/report_monitoring_provider.dart';
import '../../../core/theme/app_theme.dart';

class GiamSatBaoCaoScreen extends StatefulWidget {
  const GiamSatBaoCaoScreen({super.key});

  @override
  State<GiamSatBaoCaoScreen> createState() => _GiamSatBaoCaoScreenState();
}

class _GiamSatBaoCaoScreenState extends State<GiamSatBaoCaoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCampaignId;
  String _participantSearch = '';
  String _participantStatusFilter = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportMonitoringProvider>().loadCampaigns();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportMonitoringProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Giám sát báo cáo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_selectedCampaignId != null) {
                provider.loadMonitoringData(_selectedCampaignId!);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Campaign Selector
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Chọn chiến dịch cần theo dõi',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const Spacer(),
                    if (provider.isLoadingDetail)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCampaignId,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  hint: const Text('Chọn chiến dịch'),
                  items: provider.campaigns.map((campaign) {
                    return DropdownMenuItem(
                      value: campaign.id.toString(),
                      child: Text(
                        campaign.tenChienDich,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCampaignId = value);
                    if (value != null) {
                      provider.loadMonitoringData(value);
                    }
                  },
                ),
                // Campaign Summary Strip
                if (provider.activeCampaign != null) ...[
                  const SizedBox(height: 12),
                  _buildCampaignSummary(provider),
                ],
              ],
            ),
          ),

          // Stats Cards
          if (provider.activeCampaign != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Đăng ký hợp lệ',
                      provider.stats.totalValidRegistrations.toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Đã duyệt',
                      provider.stats.totalApproved.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Phản hồi',
                      provider.stats.totalFeedbacks.toString(),
                      Icons.star,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Báo cáo chờ',
                      provider.stats.pendingReports.toString(),
                      Icons.warning,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ),

          // Tabs
          if (provider.activeCampaign != null) ...[
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.primaryColor,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people, size: 18),
                        const SizedBox(width: 8),
                        Text('Tham gia (${provider.participants.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.comment, size: 18),
                        const SizedBox(width: 8),
                        Text('Phản hồi (${provider.feedbacks.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder_open, size: 18),
                        const SizedBox(width: 8),
                        Text('Báo cáo (${provider.reports.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildParticipantsTab(provider),
                  _buildFeedbackTab(provider),
                  _buildReportsTab(provider),
                ],
              ),
            ),
          ] else
            Expanded(
              child: _buildEmptyState(),
            ),
        ],
      ),
    );
  }

  Widget _buildCampaignSummary(ReportMonitoringProvider provider) {
    final campaign = provider.activeCampaign!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trạng thái',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCampaignStatusBgColor(campaign.trangThai),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getCampaignStatusLabel(campaign.trangThai),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getCampaignStatusTextColor(campaign.trangThai),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thời gian',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  campaign.thoiGianText ?? '—',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Địa điểm',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  campaign.diaDiem,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============ PARTICIPANTS TAB ============
  Widget _buildParticipantsTab(ReportMonitoringProvider provider) {
    final filtered = provider.participants.where((p) {
      final matchesStatus = _participantStatusFilter.isEmpty ||
          p.status == _participantStatusFilter;

      final matchesSearch = _participantSearch.isEmpty ||
          p.tenNguoiDung.toLowerCase().contains(_participantSearch.toLowerCase()) ||
          (p.email?.toLowerCase().contains(_participantSearch.toLowerCase()) ?? false);

      return matchesStatus && matchesSearch;
    }).toList();

    return Column(
      children: [
        // Search and Filter
        Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên hoặc email TNV',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) => setState(() => _participantSearch = value),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _participantStatusFilter,
                hint: const Text('Trạng thái'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Tất cả')),
                  DropdownMenuItem(value: 'da_dang_ky', child: Text('Chờ xác nhận')),
                  DropdownMenuItem(value: 'da_xac_nhan', child: Text('Đã xác nhận')),
                  DropdownMenuItem(value: 'da_duyet', child: Text('Đã duyệt')),
                  DropdownMenuItem(value: 'dang_tham_gia', child: Text('Đang tham gia')),
                  DropdownMenuItem(value: 'hoan_thanh', child: Text('Hoàn thành')),
                ],
                onChanged: (value) =>
                    setState(() => _participantStatusFilter = value ?? ''),
              ),
            ],
          ),
        ),
        Text(
          'Hiển thị ${filtered.length}/${provider.participants.length} bản ghi',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        // List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có dữ liệu tình nguyện viên',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final participant = filtered[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
                              child: Text(
                                _getInitials(participant.tenNguoiDung),
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    participant.tenNguoiDung,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    participant.email ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Đăng ký: ${_formatDateTime(participant.dangKyLuc)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getParticipationStatusBgColor(
                                    participant.status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getParticipationStatusLabel(participant.status),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _getParticipationStatusTextColor(
                                      participant.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ============ FEEDBACK TAB ============
  Widget _buildFeedbackTab(ReportMonitoringProvider provider) {
    if (provider.feedbacks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.comment_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Chưa có phản hồi nào từ tình nguyện viên',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.feedbacks.length,
      itemBuilder: (context, index) {
        final feedback = provider.feedbacks[index];
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
                            feedback.tenNguoiDung,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            feedback.email ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              Icons.star,
                              size: 16,
                              color: i < feedback.soSao
                                  ? Colors.amber
                                  : Colors.grey[300],
                            );
                          }),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(feedback.taoLuc),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (feedback.nhanXet?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  Text(feedback.nhanXet!),
                ],
                if (feedback.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: feedback.tags.map<Widget>((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          tag.ten,
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ============ REPORTS TAB ============
  Widget _buildReportsTab(ReportMonitoringProvider provider) {
    if (provider.reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Chưa có báo cáo nào trong chiến dịch này',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.reports.length,
      itemBuilder: (context, index) {
        final report = provider.reports[index];
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
                      child: Text(
                        report.tieuDe,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getReportStatusBgColor(report.trangThai),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getReportStatusLabel(report.trangThai),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getReportStatusTextColor(report.trangThai),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${report.tenNguoiGui ?? 'Không xác định'} · ${report.phanLoai ?? 'Khác'} · ${_formatDateTime(report.taoLuc)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Text(report.noiDung),
                // Response
                if (report.phanHoiXuLy?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PHẢN HỒI XỬ LÝ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(report.phanHoiXuLy!),
                        if (report.tenNguoiXuLy?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${report.tenNguoiXuLy} · ${_formatDateTime(report.xuLyLuc)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ============ EMPTY STATE ============
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.query_stats,
              size: 36,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chọn chiến dịch để bắt đầu theo dõi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Màn này sẽ hiển thị danh sách tham gia,\nphản hồi và báo cáo của chiến dịch bạn chọn.',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============ HELPERS ============
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatDateTime(String? value) {
    if (value == null || value.isEmpty) return '—';
    try {
      final date = DateTime.parse(value);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value;
    }
  }

  String _getCampaignStatusLabel(String status) {
    return {
      'cho_duyet': 'Chờ duyệt',
      'da_duyet': 'Đã duyệt',
      'dang_dien_ra': 'Đang diễn ra',
      'hoan_thanh': 'Hoàn thành',
      'yeu_cau_huy': 'Yêu cầu hủy',
      'da_huy': 'Đã hủy',
      'tu_choi': 'Từ chối',
      'nhap': 'Nháp',
    }[status] ?? status;
  }

  Color _getCampaignStatusBgColor(String status) {
    return {
      'cho_duyet': Colors.orange.shade100,
      'da_duyet': Colors.blue.shade100,
      'dang_dien_ra': Colors.green.shade100,
      'hoan_thanh': Colors.green.shade100,
      'yeu_cau_huy': Colors.orange.shade100,
      'da_huy': Colors.red.shade100,
      'tu_choi': Colors.red.shade100,
      'nhap': Colors.grey.shade200,
    }[status] ?? Colors.grey.shade100;
  }

  Color _getCampaignStatusTextColor(String status) {
    return {
      'cho_duyet': Colors.orange.shade800,
      'da_duyet': Colors.blue.shade800,
      'dang_dien_ra': Colors.green.shade800,
      'hoan_thanh': Colors.green.shade800,
      'yeu_cau_huy': Colors.orange.shade800,
      'da_huy': Colors.red.shade800,
      'tu_choi': Colors.red.shade800,
      'nhap': Colors.grey.shade700,
    }[status] ?? Colors.grey.shade700;
  }

  String _getParticipationStatusLabel(String status) {
    return {
      'da_dang_ky': 'Chờ xác nhận',
      'da_xac_nhan': 'Đã xác nhận',
      'da_duyet': 'Đã duyệt',
      'dang_tham_gia': 'Đang tham gia',
      'hoan_thanh': 'Hoàn thành',
      'tu_choi': 'Từ chối',
      'da_huy': 'Đã hủy',
    }[status] ?? status;
  }

  Color _getParticipationStatusBgColor(String status) {
    return {
      'da_dang_ky': Colors.orange.shade100,
      'da_xac_nhan': Colors.orange.shade100,
      'da_duyet': Colors.blue.shade100,
      'dang_tham_gia': Colors.green.shade100,
      'hoan_thanh': Colors.green.shade100,
      'tu_choi': Colors.red.shade100,
      'da_huy': Colors.red.shade100,
    }[status] ?? Colors.grey.shade100;
  }

  Color _getParticipationStatusTextColor(String status) {
    return {
      'da_dang_ky': Colors.orange.shade800,
      'da_xac_nhan': Colors.orange.shade800,
      'da_duyet': Colors.blue.shade800,
      'dang_tham_gia': Colors.green.shade800,
      'hoan_thanh': Colors.green.shade800,
      'tu_choi': Colors.red.shade800,
      'da_huy': Colors.red.shade800,
    }[status] ?? Colors.grey.shade700;
  }

  String _getReportStatusLabel(String status) {
    return {
      'moi': 'Mới',
      'dang_xu_ly': 'Đang xử lý',
      'da_xu_ly': 'Đã xử lý',
      'tu_choi': 'Từ chối',
    }[status] ?? status;
  }

  Color _getReportStatusBgColor(String status) {
    return {
      'moi': Colors.orange.shade100,
      'dang_xu_ly': Colors.orange.shade100,
      'da_xu_ly': Colors.green.shade100,
      'tu_choi': Colors.red.shade100,
    }[status] ?? Colors.grey.shade100;
  }

  Color _getReportStatusTextColor(String status) {
    return {
      'moi': Colors.orange.shade800,
      'dang_xu_ly': Colors.orange.shade800,
      'da_xu_ly': Colors.green.shade800,
      'tu_choi': Colors.red.shade800,
    }[status] ?? Colors.grey.shade700;
  }
}
