import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/admin_repository.dart';

class AdminCampaignsScreen extends StatefulWidget {
  const AdminCampaignsScreen({super.key});

  @override
  State<AdminCampaignsScreen> createState() => _AdminCampaignsScreenState();
}

class _AdminCampaignsScreenState extends State<AdminCampaignsScreen>
    with SingleTickerProviderStateMixin {
  final AdminRepository _repo = AdminRepository();

  late TabController _tabController;
  String _activeTab = 'pending';
  String _searchQuery = '';
  String? _filterCategory;
  String? _filterPriority;
  bool _isLoading = false;
  bool _isDetailLoading = false;
  bool _isActionLoading = false;

  List<ReviewerCampaign> _campaigns = [];
  ReviewerCampaignStats _stats = ReviewerCampaignStats(
    total: 0,
    choDuyet: 0,
    daDuyet: 0,
    yeuCauHuy: 0,
    daHuy: 0,
    dangDienRa: 0,
    hoanThanh: 0,
  );
  List<FilterOption> _categories = [];
  List<FilterOption> _priorities = [];

  ReviewerCampaign? _detailTarget;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final result = await _repo.getReviewerCampaigns(
        status: _getStatusParam(),
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoryId: _filterCategory,
        priority: _filterPriority,
      );
      if (mounted) {
        if (result.success && result.data != null) {
          setState(() {
            _campaigns = result.data!.campaigns;
            _stats = result.data!.stats;
            _categories = result.data!.categories;
            _priorities = result.data!.priorities;
          });
        } else {
          _showError(result.message ?? 'Không tải được dữ liệu');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCampaigns() async {
    await _loadAll();
  }

  String? _getStatusParam() {
    if (_activeTab == 'pending') return 'cho_duyet';
    if (_activeTab == 'approved') return 'da_duyet';
    if (_activeTab == 'pendingCancel') return 'yeu_cau_huy';
    if (_activeTab == 'cancelled') return 'da_huy';
    if (_activeTab == 'active') return 'dang_dien_ra';
    return null;
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadCampaigns,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsCards(),
                      const SizedBox(height: 16),
                      _buildTabs(),
                      const SizedBox(height: 12),
                      _buildFilters(),
                      const SizedBox(height: 12),
                      _buildCampaignTable(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF3B6DE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Quản lý chiến dịch',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Kiểm duyệt và quản lý các chiến dịch tình nguyện',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard(
              'Tổng', _stats.total, Icons.flag, const Color(0xFF0D6EFD)),
          const SizedBox(width: 12),
          _buildStatCard('Chờ duyệt', _stats.choDuyet, Icons.hourglass_bottom,
              Colors.orange),
          const SizedBox(width: 12),
          _buildStatCard(
              'Đã duyệt', _stats.daDuyet, Icons.check_circle, Colors.cyan),
          const SizedBox(width: 12),
          _buildStatCard(
              'Chờ hủy', _stats.yeuCauHuy, Icons.cancel, Colors.redAccent),
          const SizedBox(width: 12),
          _buildStatCard('Đang hoạt động', _stats.dangDienRa, Icons.play_circle,
              Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text('$value',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        onTap: (index) {
          final tabs = [
            'pending',
            'approved',
            'pendingCancel',
            'cancelled',
            'active'
          ];
          setState(() => _activeTab = tabs[index]);
          _loadCampaigns();
        },
        tabs: [
          Tab(
              child: Row(children: [
            const Icon(Icons.hourglass_bottom, size: 18),
            const SizedBox(width: 6),
            const Text('Chờ duyệt'),
            const SizedBox(width: 6),
            _buildBadge(_stats.choDuyet, Colors.orange),
          ])),
          Tab(
              child: Row(children: [
            const Icon(Icons.check_circle, size: 18),
            const SizedBox(width: 6),
            const Text('Đã duyệt'),
            const SizedBox(width: 6),
            _buildBadge(_stats.daDuyet, Colors.cyan),
          ])),
          Tab(
              child: Row(children: [
            const Icon(Icons.cancel, size: 18),
            const SizedBox(width: 6),
            const Text('Chờ hủy'),
            const SizedBox(width: 6),
            _buildBadge(_stats.yeuCauHuy, Colors.redAccent),
          ])),
          Tab(
              child: Row(children: [
            Icon(Icons.block, size: 18),
            SizedBox(width: 6),
            Text('Đã hủy'),
          ])),
          Tab(
              child: Row(children: [
            const Icon(Icons.play_circle, size: 18),
            const SizedBox(width: 6),
            const Text('Đang hoạt động'),
            const SizedBox(width: 6),
            _buildBadge(_stats.dangDienRa, Colors.green),
          ])),
        ],
      ),
    );
  }

  Widget _buildBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              onSubmitted: (_) => _loadCampaigns(),
              onChanged: (v) => _searchQuery = v,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm chiến dịch...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filterCategory,
              decoration: InputDecoration(
                labelText: 'Loại',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tất cả')),
                ..._categories.map((c) =>
                    DropdownMenuItem(value: c.value, child: Text(c.label))),
              ],
              onChanged: (v) {
                setState(() => _filterCategory = v);
                _loadCampaigns();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filterPriority,
              decoration: InputDecoration(
                labelText: 'Ưu tiên',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tất cả')),
                ..._priorities.map((p) =>
                    DropdownMenuItem(value: p.value, child: Text(p.label))),
              ],
              onChanged: (v) {
                setState(() => _filterPriority = v);
                _loadCampaigns();
              },
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _filterCategory = null;
                _filterPriority = null;
              });
              _loadCampaigns();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Đặt lại'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()))
          : _campaigns.isEmpty
              ? _buildEmptyState()
              : Column(
                  children:
                      _campaigns.map((c) => _buildCampaignRow(c)).toList(),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Không có chiến dịch nào',
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignRow(ReviewerCampaign campaign) {
    final category = campaign.loaiChienDich;
    final creator = campaign.nguoiTao;
    final startDate = campaign.ngayBatDau;
    final endDate = campaign.ngayKetThuc;

    return InkWell(
      onTap: () => _openDetailModal(campaign),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _parseColor(category?.mauSac).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.flag,
                      color: _parseColor(category?.mauSac), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.tieuDe,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              campaign.diaDiem,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(campaign.trangThai),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                    Icons.calendar_today,
                    startDate != null
                        ? DateFormat('dd/MM/yyyy').format(startDate)
                        : '—'),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.group,
                    '${campaign.soDangKy}/${campaign.soLuongToiDa}'),
                const SizedBox(width: 8),
                if (category != null)
                  _buildInfoChip(Icons.category, category.ten),
                const Spacer(),
                if (creator != null)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: Text(
                          creator.hoTen.isNotEmpty
                              ? creator.hoTen[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(creator.hoTen,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildActionButtons(campaign),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ReviewerCampaign campaign) {
    final isPending = campaign.trangThai == 'cho_duyet';
    final isPendingCancel = campaign.trangThai == 'yeu_cau_huy';

    return Row(
      children: [
        if (isPending) ...[
          OutlinedButton(
            onPressed: _isActionLoading
                ? null
                : () => _showRejectDialog(campaign, 'campaign'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Từ chối'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed:
                _isActionLoading ? null : () => _approveCampaign(campaign),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Duyệt'),
          ),
        ] else if (isPendingCancel) ...[
          OutlinedButton(
            onPressed: _isActionLoading
                ? null
                : () => _showRejectDialog(campaign, 'cancel_request'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Từ chối hủy'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed:
                _isActionLoading ? null : () => _approveCancelRequest(campaign),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Duyệt hủy'),
          ),
        ],
        IconButton(
          icon: const Icon(Icons.visibility),
          onPressed: () => _openDetailModal(campaign),
          color: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String rawStatus) {
    final config = switch (rawStatus) {
      'cho_duyet' => ('Chờ duyệt', Colors.orange),
      'da_duyet' => ('Đã duyệt', Colors.green),
      'dang_dien_ra' => ('Đang diễn ra', Colors.blue),
      'tu_choi' => ('Từ chối', Colors.red),
      'hoan_thanh' => ('Hoàn thành', Colors.purple),
      'yeu_cau_huy' => ('Yêu cầu hủy', Colors.redAccent),
      'da_huy' => ('Đã hủy', Colors.grey),
      _ => ('Không xác định', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (config.$2 as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        config.$1,
        style: TextStyle(
            color: config.$2 as Color,
            fontWeight: FontWeight.w600,
            fontSize: 12),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.blue;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }

  Future<void> _openDetailModal(ReviewerCampaign campaign) async {
    setState(() {
      _detailTarget = campaign;
      _isDetailLoading = true;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) =>
            _buildDetailSheet(scrollController),
      ),
    );
  }

  Widget _buildDetailSheet(ScrollController scrollController) {
    if (_detailTarget == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final campaign = _detailTarget!;
    final category = campaign.loaiChienDich;
    final creator = campaign.nguoiTao;

    return StatefulBuilder(
      builder: (context, setSheetState) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _parseColor(category?.mauSac).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.flag,
                      color: _parseColor(category?.mauSac), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.tieuDe,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusBadge(campaign.trangThai),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailItem(Icons.location_on, 'Địa điểm', campaign.diaDiem),
            if (campaign.ngayBatDau != null)
              _buildDetailItem(Icons.calendar_today, 'Ngày bắt đầu',
                  DateFormat('dd/MM/yyyy').format(campaign.ngayBatDau!)),
            if (campaign.ngayKetThuc != null)
              _buildDetailItem(Icons.calendar_today, 'Ngày kết thúc',
                  DateFormat('dd/MM/yyyy').format(campaign.ngayKetThuc!)),
            _buildDetailItem(Icons.group, 'Số lượng TNV',
                '${campaign.soDangKy}/${campaign.soLuongToiDa} người'),
            if (category != null)
              _buildDetailItem(Icons.category, 'Loại chiến dịch', category.ten),
            if (creator != null)
              _buildDetailItem(Icons.person, 'Người tạo',
                  '${creator.hoTen} (${creator.email})'),
            if (campaign.lyDoHuyYeuCau != null &&
                campaign.lyDoHuyYeuCau!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Lý do hủy:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.red)),
                          const SizedBox(height: 4),
                          Text(campaign.lyDoHuyYeuCau!,
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (campaign.moTa.isNotEmpty) ...[
              const Text('Mô tả',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(campaign.moTa, style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 16),
            ],
            if (campaign.kyNangs.isNotEmpty) ...[
              const Text('Kỹ năng yêu cầu',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: campaign.kyNangs
                    .map((skill) => Chip(
                          label:
                              Text(skill, style: const TextStyle(fontSize: 12)),
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                          side: BorderSide.none,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (_isDetailLoading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else ...[
              if (campaign.danhSachDangKy.isNotEmpty) ...[
                const Text('Danh sách đăng ký',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...campaign.danhSachDangKy
                    .map((reg) => _buildRegistrationItem(reg)),
                const SizedBox(height: 16),
              ],
              if (campaign.feedbacks.isNotEmpty) ...[
                const Text('Phản hồi',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...campaign.feedbacks.map((f) => _buildFeedbackItem(f)),
                const SizedBox(height: 16),
              ],
              if (campaign.lichSuKiemDuyet.isNotEmpty) ...[
                const Text('Lịch sử kiểm duyệt',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...campaign.lichSuKiemDuyet.map((h) => _buildHistoryItem(h)),
                const SizedBox(height: 16),
              ],
            ],
            Row(
              children: [
                if (campaign.trangThai == 'cho_duyet') ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showRejectDialog(campaign, 'campaign');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Từ chối'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _approveCampaign(campaign);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Duyệt'),
                    ),
                  ),
                ] else if (campaign.trangThai == 'yeu_cau_huy') ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showRejectDialog(campaign, 'cancel_request');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Từ chối hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _approveCancelRequest(campaign);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Duyệt hủy'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationItem(RegistrationItem reg) {
    final vol = reg.nguoiDung;
    final skills = (vol?.kyNangs ?? [])
        .map((s) => s is Map ? s['ten'] ?? '' : s.toString())
        .where((s) => s.isNotEmpty)
        .toList();
    final areas = (vol?.khuVucs ?? [])
        .map((s) => s is Map ? s['ten'] ?? '' : s.toString())
        .where((s) => s.isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Text(
              vol?.hoTen.isNotEmpty == true ? vol!.hoTen[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vol?.hoTen ?? '—',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(vol?.email ?? '—',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                if (skills.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: skills
                        .take(3)
                        .map((s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(s,
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.blue)),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
          _buildRegStatusBadge(reg.trangThai),
        ],
      ),
    );
  }

  Widget _buildRegStatusBadge(String status) {
    final config = switch (status) {
      'da_dang_ky' => ('Đã đăng ký', Colors.orange),
      'da_duyet' => ('Đã duyệt', Colors.blue),
      'da_xac_nhan' => ('Đã xác nhận', Colors.green),
      'tu_choi' => ('Từ chối', Colors.red),
      'dang_tham_gia' => ('Đang tham gia', Colors.purple),
      'hoan_thanh' => ('Hoàn thành', Colors.teal),
      'da_huy' => ('Đã hủy', Colors.grey),
      _ => (status, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (config.$2 as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(config.$1,
          style: TextStyle(
              color: config.$2 as Color,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildFeedbackItem(FeedbackItem f) {
    final user = f.nguoiDung;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(user?.hoTen ?? '—',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < f.soSao ? Icons.star : Icons.star_border,
                          size: 14,
                          color: Colors.amber,
                        )),
              ),
            ],
          ),
          if (f.nhanXet != null && f.nhanXet!.isNotEmpty)
            Text(f.nhanXet!,
                style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(HistoryItem h) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
                color: AppTheme.primaryColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.hanhDong,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13)),
                if (h.nguoiThucHien != null)
                  Text(
                    '${h.nguoiThucHien!.hoTen} • ${h.taoLuc != null ? DateFormat('dd/MM HH:mm').format(h.taoLuc!) : '—'}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                if (h.ghiChu != null && h.ghiChu!.isNotEmpty)
                  Text(h.ghiChu!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveCampaign(ReviewerCampaign campaign) async {
    setState(() => _isActionLoading = true);
    try {
      final result = await _repo.approveCampaign(campaign.id);
      if (mounted) {
        if (result.success) {
          _showSuccess(result.message ?? 'Đã duyệt chiến dịch');
          await _loadCampaigns();
        } else {
          _showError(result.message ?? 'Duyệt thất bại');
        }
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _approveCancelRequest(ReviewerCampaign campaign) async {
    setState(() => _isActionLoading = true);
    try {
      final result = await _repo.approveCancelRequest(campaign.id);
      if (mounted) {
        if (result.success) {
          _showSuccess(result.message ?? 'Đã duyệt hủy chiến dịch');
          await _loadCampaigns();
        } else {
          _showError(result.message ?? 'Duyệt hủy thất bại');
        }
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _showRejectDialog(ReviewerCampaign campaign, String mode) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(mode == 'cancel_request'
            ? 'Từ chối yêu cầu hủy'
            : 'Từ chối chiến dịch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc muốn từ chối "${campaign.tieuDe}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _rejectCampaign(campaign, mode, reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectCampaign(
      ReviewerCampaign campaign, String mode, String reason) async {
    if (reason.trim().isEmpty) {
      _showError('Vui lòng nhập lý do từ chối');
      return;
    }
    setState(() => _isActionLoading = true);
    try {
      final result = mode == 'cancel_request'
          ? await _repo.rejectCancelRequest(campaign.id, reason)
          : await _repo.rejectCampaign(campaign.id, reason);
      if (mounted) {
        if (result.success) {
          _showSuccess(result.message ?? 'Đã từ chối');
          await _loadCampaigns();
        } else {
          _showError(result.message ?? 'Từ chối thất bại');
        }
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }
}
