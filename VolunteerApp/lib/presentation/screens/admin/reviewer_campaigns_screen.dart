import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/repositories/reviewer_repository.dart';

class ReviewerCampaignsScreen extends StatefulWidget {
  const ReviewerCampaignsScreen({super.key});

  @override
  State<ReviewerCampaignsScreen> createState() =>
      _ReviewerCampaignsScreenState();
}

class _ReviewerCampaignsScreenState extends State<ReviewerCampaignsScreen>
    with SingleTickerProviderStateMixin {
  final ReviewerRepository _repository = ReviewerRepository();

  bool _isLoading = true;
  String? _error;

  // Filters
  String _activeTab = 'pending';
  String _searchQuery = '';
  int? _filterCategoryId;
  String? _filterPriority; // khan_cap, cao, trung_binh, thap

  // Data
  List<ReviewerCampaign> _campaigns = [];
  CampaignFilters? _filters;
  ReviewerCampaignDetail? _selectedCampaign;
  Timer? _searchDebounce;

  // Stats
  int _totalCount = 0;
  int _pendingCount = 0;
  int _approvedCount = 0;
  int _pendingCancelCount = 0;
  int _cancelledCount = 0;
  int _activeCount = 0;

  late TabController _tabController;

  // Tab config
  static const List<_TabConfig> _tabs = [
    _TabConfig(value: 'pending', label: 'Chờ duyệt', backendKey: 'cho_duyet'),
    _TabConfig(value: 'approved', label: 'Đã duyệt', backendKey: 'da_duyet'),
    _TabConfig(
        value: 'pending_cancel', label: 'Hủy', backendKey: 'yeu_cau_huy'),
    _TabConfig(value: 'cancelled', label: 'Đã hủy', backendKey: 'da_huy'),
    _TabConfig(
        value: 'active', label: 'Đang diễn ra', backendKey: 'dang_dien_ra'),
    _TabConfig(
        value: 'completed', label: 'Hoàn thành', backendKey: 'hoan_thanh'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final tab = _tabs[_tabController.index];
    setState(() => _activeTab = tab.value);
    _loadCampaigns();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final filtersResult = await _repository.getFilters();
      if (!mounted) return;

      if (filtersResult.success && filtersResult.data != null) {
        _filters = filtersResult.data;
      }

      await _loadCampaigns();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Không thể tải dữ liệu');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCampaigns() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String? trangThai;
      for (final tab in _tabs) {
        if (tab.value == _activeTab) {
          trangThai = tab.backendKey;
          break;
        }
      }

      final result = await _repository.getCampaigns(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        trangThai: trangThai,
        loaiChienDich: _filterCategoryId?.toString(),
        mucDoUuTien: _filterPriority,
      );

      if (!mounted) return;

      if (result.success) {
        _campaigns = result.data ?? [];
        _updateStats();
      } else {
        _error = result.message;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Lỗi kết nối');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateStats() {
    final statusMap = <String, int>{};
    for (final s in _filters?.trangThaiOptions ?? const <StatusFilter>[]) {
      statusMap[s.value] = s.count;
    }
    _pendingCount = statusMap['cho_duyet'] ?? 0;
    _approvedCount = statusMap['da_duyet'] ?? 0;
    _pendingCancelCount = statusMap['yeu_cau_huy'] ?? 0;
    _cancelledCount = statusMap['da_huy'] ?? 0;
    _activeCount = statusMap['dang_dien_ra'] ?? 0;
    _totalCount = _pendingCount +
        _approvedCount +
        _pendingCancelCount +
        _cancelledCount +
        _activeCount;

    if (_totalCount == 0) {
      _totalCount = _campaigns.length;
      _pendingCount =
          _campaigns.where((c) => c.trangThai == 'cho_duyet').length;
      _approvedCount =
          _campaigns.where((c) => c.trangThai == 'da_duyet').length;
      _pendingCancelCount =
          _campaigns.where((c) => c.trangThai == 'yeu_cau_huy').length;
      _cancelledCount = _campaigns.where((c) => c.trangThai == 'da_huy').length;
      _activeCount =
          _campaigns.where((c) => c.trangThai == 'dang_dien_ra').length;
    }
  }

  Future<void> _loadCampaignDetail(int id) async {
    try {
      final result = await _repository.getCampaignDetail(id);
      if (!mounted) return;

      if (result.success) {
        _selectedCampaign = result.data;
      } else {
        _showSnackBar(result.message ?? 'Không thể tải chi tiết',
            isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi kết nối', isError: true);
      }
    } finally {
      // no-op
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _approveCampaign(ReviewerCampaign campaign) async {
    final confirmed = await _showConfirmDialog(
      title: 'Duyệt chiến dịch',
      message: 'Bạn có chắc muốn duyệt chiến dịch "${campaign.tenChienDich}"?',
      confirmText: 'Duyệt',
      confirmColor: Colors.green,
    );

    if (confirmed != true) return;

    try {
      final result = await _repository.approveCampaign(campaign.id);
      if (!mounted) return;

      if (result.success) {
        _showSnackBar(result.message ?? 'Duyệt thành công');
        await _loadCampaigns();
      } else {
        _showSnackBar(result.message ?? 'Duyệt thất bại', isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi kết nối', isError: true);
      }
    }
  }

  Future<void> _rejectCampaign(ReviewerCampaign campaign) async {
    final reason = await _showReasonDialog(
      title: 'Từ chối chiến dịch',
      campaignName: campaign.tenChienDich,
    );

    if (reason == null || reason.isEmpty) return;

    try {
      final result = await _repository.rejectCampaign(campaign.id, reason);
      if (!mounted) return;

      if (result.success) {
        _showSnackBar(result.message ?? 'Từ chối thành công');
        await _loadCampaigns();
      } else {
        _showSnackBar(result.message ?? 'Từ chối thất bại', isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi kết nối', isError: true);
      }
    }
  }

  Future<void> _approveCancel(ReviewerCampaign campaign) async {
    final confirmed = await _showConfirmDialog(
      title: 'Duyệt yêu cầu hủy',
      message:
          'Bạn có chắc muốn duyệt yêu cầu hủy chiến dịch "${campaign.tenChienDich}"?',
      confirmText: 'Duyệt hủy',
      confirmColor: Colors.red,
    );

    if (confirmed != true) return;

    try {
      final result = await _repository.approveCancel(campaign.id);
      if (!mounted) return;

      if (result.success) {
        _showSnackBar(result.message ?? 'Duyệt hủy thành công');
        await _loadCampaigns();
      } else {
        _showSnackBar(result.message ?? 'Duyệt hủy thất bại', isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi kết nối', isError: true);
      }
    }
  }

  Future<void> _rejectCancel(ReviewerCampaign campaign) async {
    final reason = await _showReasonDialog(
      title: 'Từ chối yêu cầu hủy',
      campaignName: campaign.tenChienDich,
    );

    if (reason == null || reason.isEmpty) return;

    try {
      final result = await _repository.rejectCancel(campaign.id, reason);
      if (!mounted) return;

      if (result.success) {
        _showSnackBar(result.message ?? 'Từ chối thành công');
        await _loadCampaigns();
      } else {
        _showSnackBar(result.message ?? 'Từ chối thất bại', isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi kết nối', isError: true);
      }
    }
  }

  Future<void> _processReport(CampaignReport report, String trangThai) async {
    final confirmed = await _showConfirmDialog(
      title: trangThai == 'da_xu_ly' ? 'Danh dau da xu ly' : 'Tu choi bao cao',
      message: 'Xu ly bao cao #${report.id} voi trang thai "$trangThai"?',
      confirmText: 'Xac nhan',
      confirmColor: trangThai == 'da_xu_ly' ? Colors.green : Colors.orange,
    );
    if (confirmed != true) return;

    final result = await _repository.processReport(report.id, trangThai);
    if (!mounted) return;

    if (result.success) {
      _showSnackBar(result.message ?? 'Xu ly bao cao thanh cong');
      if (_selectedCampaign != null) {
        await _loadCampaignDetail(_selectedCampaign!.id);
      }
      await _loadCampaigns();
    } else {
      _showSnackBar(result.message ?? 'Xu ly bao cao that bai', isError: true);
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  Future<String?> _showReasonDialog({
    required String title,
    required String campaignName,
  }) {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              campaignName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Lý do *',
                hintText: 'Nhập lý do từ chối...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCampaignDetail(ReviewerCampaign campaign) async {
    _selectedCampaign = null;
    await _loadCampaignDetail(campaign.id);
    if (!mounted || _selectedCampaign == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _buildDetailContent(scrollController, _selectedCampaign!),
        ),
      ),
    );
  }

  Widget _buildDetailContent(
      ScrollController scrollController, ReviewerCampaignDetail campaign) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.7)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      campaign.tenChienDich,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              if (campaign.loaiChienDich != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    campaign.loaiChienDich!,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Content
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Info cards
              _buildInfoCards(campaign),
              const SizedBox(height: 20),

              if (campaign.nguoiTao != null || campaign.lyDoTuChoi != null) ...[
                _buildSectionTitle('Thong tin bo sung'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (campaign.nguoiTao != null) ...[
                        Text(
                          'Nguoi tao: ${campaign.nguoiTao!.hoTen}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (campaign.hanDangKy != null) ...[
                        Text(
                            'Han dang ky: ${_formatDate(campaign.hanDangKy!)}'),
                        const SizedBox(height: 4),
                      ],
                      Text('Muc do khan cap: ${campaign.mucDoKhanCap}'),
                      if (campaign.lyDoTuChoi != null &&
                          campaign.lyDoTuChoi!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Ly do xu ly: ${campaign.lyDoTuChoi}',
                          style: TextStyle(color: Colors.orange.shade800),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Description
              if (campaign.moTa.isNotEmpty) ...[
                _buildSectionTitle('Mô tả'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(campaign.moTa),
                ),
                const SizedBox(height: 20),
              ],

              // Skills
              if (campaign.kyNangs != null && campaign.kyNangs!.isNotEmpty) ...[
                _buildSectionTitle('Kỹ năng yêu cầu'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: campaign.kyNangs!
                      .map((skill) => Chip(
                            label: Text(skill,
                                style: const TextStyle(fontSize: 12)),
                            backgroundColor: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.1),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Volunteers
              if (campaign.volunteers.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildSectionTitle(
                          'Tinh nguyen vien (${campaign.volunteers.length})'),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _showVolunteerListModal(campaign.volunteers),
                      icon: const Icon(Icons.list, size: 16),
                      label: const Text('Xem danh sach'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...campaign.volunteers.map((v) => _buildVolunteerItem(v)),
                const SizedBox(height: 20),
              ],

              _buildSectionTitle('Ban do'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lat: ${campaign.viDo.toStringAsFixed(6)} | Lng: ${campaign.kinhDo.toStringAsFixed(6)}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Feedbacks
              if (campaign.feedbacks.isNotEmpty) ...[
                _buildSectionTitle('Phản hồi (${campaign.feedbacks.length})'),
                const SizedBox(height: 8),
                ...campaign.feedbacks.map((f) => _buildFeedbackItem(f)),
                const SizedBox(height: 20),
              ],

              // Reports
              if (campaign.baoCaos.isNotEmpty) ...[
                _buildSectionTitle('Báo cáo (${campaign.baoCaos.length})'),
                const SizedBox(height: 8),
                ...campaign.baoCaos.map((r) => _buildReportItem(r)),
                const SizedBox(height: 20),
              ],

              // Review history
              if (campaign.lichSu.isNotEmpty) ...[
                _buildSectionTitle(
                    'L?ch s? ki?m duy?t (${campaign.lichSu.length})'),
                const SizedBox(height: 8),
                ...campaign.lichSu.map(_buildHistoryItem),
                const SizedBox(height: 20),
              ],

              // Trust Eval
              if (campaign.trustEval != null &&
                  campaign.trustEval!.isNotEmpty) ...[
                _buildSectionTitle('Danh gia tin cay (AI)'),
                const SizedBox(height: 8),
                ...campaign.trustEval!.map((t) => _buildTrustEvalItem(t)),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards(ReviewerCampaignDetail campaign) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.location_on,
                  iconColor: Colors.red,
                  label: 'Địa điểm',
                  value: campaign.diaDiem,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.calendar_today,
                  iconColor: Colors.blue,
                  label: 'Bắt đầu',
                  value: _formatDate(campaign.ngayBatDau),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.event,
                  iconColor: Colors.orange,
                  label: 'Kết thúc',
                  value: _formatDate(campaign.ngayKetThuc),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.people,
                  iconColor: Colors.green,
                  label: 'TNV',
                  value: '${campaign.soLuongHienTai}/${campaign.soLuongToiDa}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.flag,
                  iconColor: _getStatusColor(campaign.trangThai),
                  label: 'Trạng thái',
                  value: campaign.trangThaiDisplay,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildVolunteerItem(VolunteerRegistration volunteer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              volunteer.hoTen.isNotEmpty
                  ? volunteer.hoTen[0].toUpperCase()
                  : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  volunteer.hoTen,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (volunteer.email != null) ...[
                  Text(
                    volunteer.email!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
                if (volunteer.kyNangs.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: volunteer.kyNangs
                        .take(3)
                        .map((skill) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(skill,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue.shade700)),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(volunteer.trangThai)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getRegistrationStatusLabel(volunteer.trangThai),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(volunteer.trangThai),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(volunteer.trustScore * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackItem(CampaignFeedback feedback) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                feedback.hoTen,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < feedback.diem ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          if (feedback.noiDung != null && feedback.noiDung!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(feedback.noiDung!,
                style: TextStyle(color: Colors.grey.shade700)),
          ],
          const SizedBox(height: 4),
          Text(
            _formatDateTime(feedback.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(CampaignReport report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.noiDung,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getReportStatusColor(report.trangThai)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getReportStatusLabel(report.trangThai),
                  style: TextStyle(
                    fontSize: 11,
                    color: _getReportStatusColor(report.trangThai),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${report.nguoiGuiTen} - ${_formatDateTime(report.createdAt)}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          if (report.trangThai != 'da_xu_ly' && report.trangThai != 'tu_choi')
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _processReport(report, 'tu_choi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                  ),
                  child: const Text('Tu choi'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _processReport(report, 'da_xu_ly'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Da xu ly'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTrustEvalItem(TrustEvalSummary eval) {
    final scoreColor = eval.diem >= 0.7
        ? Colors.green
        : eval.diem >= 0.4
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  eval.tieuDe,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(eval.diem * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          if (eval.giaiThich != null) ...[
            const SizedBox(height: 8),
            Text(eval.giaiThich!,
                style: TextStyle(color: Colors.grey.shade700)),
          ],
          if (eval.ruiRo.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: eval.ruiRo
                  .map((r) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          r,
                          style:
                              const TextStyle(fontSize: 11, color: Colors.red),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showVolunteerListModal(List<VolunteerRegistration> volunteers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Danh sach tinh nguyen vien',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: volunteers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final v = volunteers[index];
                    return ListTile(
                      title: Text(v.hoTen),
                      subtitle: Text('\n'),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _getRegistrationStatusLabel(v.trangThai),
                            style: TextStyle(
                              fontSize: 11,
                              color: _getStatusColor(v.trangThai),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text('%', style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(ReviewHistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _getHistoryLabel(item.hanhDong),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (item.taoLuc != null)
                Text(
                  _formatDateTime(item.taoLuc!),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
            ],
          ),
          if (item.nguoiThucHien != null) ...[
            const SizedBox(height: 4),
            Text(item.nguoiThucHien!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ],
          if (item.tuTrangThai != null || item.denTrangThai != null) ...[
            const SizedBox(height: 4),
            Text(
              ' -> ',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
          if (item.ghiChu?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(item.ghiChu!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ],
        ],
      ),
    );
  }

  String _getHistoryLabel(String hanhDong) {
    switch (hanhDong) {
      case 'duyet':
        return 'Duyet chien dich';
      case 'tu_choi':
        return 'Tu choi chien dich';
      case 'duyet_huy':
        return 'Duyet yeu cau huy';
      case 'tu_choi_huy':
        return 'Tu choi yeu cau huy';
      default:
        return hanhDong;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'cho_duyet':
        return Colors.orange;
      case 'da_duyet':
        return Colors.blue;
      case 'tu_choi':
        return Colors.red;
      case 'dang_dien_ra':
        return Colors.green;
      case 'hoan_thanh':
        return Colors.grey;
      case 'da_huy':
        return Colors.red;
      case 'yeu_cau_huy':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  Color _getReportStatusColor(String status) {
    switch (status) {
      case 'moi':
        return Colors.orange;
      case 'dang_xu_ly':
        return Colors.blue;
      case 'da_xu_ly':
        return Colors.green;
      case 'tu_choi':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getReportStatusLabel(String status) {
    switch (status) {
      case 'moi':
        return 'Mới';
      case 'dang_xu_ly':
        return 'Đang xử lý';
      case 'da_xu_ly':
        return 'Đã xử lý';
      case 'tu_choi':
        return 'Từ chối';
      default:
        return status;
    }
  }

  String _getRegistrationStatusLabel(String status) {
    switch (status) {
      case 'cho_xac_nhan':
        return 'Cho xac nhan';
      case 'da_dang_ky':
        return 'Đã đăng ký';
      case 'da_duyet':
        return 'Đã duyệt';
      case 'da_xac_nhan':
        return 'Đã xác nhận';
      case 'tu_choi':
        return 'Từ chối';
      case 'dang_tham_gia':
        return 'Đang tham gia';
      case 'hoan_thanh':
        return 'Hoàn thành';
      case 'da_huy':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Quản lý chiến dịch'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Stats cards
          _buildStatsCards(),
          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: _tabs
                  .map((tab) => Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tab.label),
                            const SizedBox(width: 4),
                            _buildTabBadge(tab.value),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          // Search bar & filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm chiến dịch...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _searchDebounce?.cancel();
                _searchDebounce =
                    Timer(const Duration(milliseconds: 350), _loadCampaigns);
              },
            ),
          ),
          // Filter row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Category filter
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterCategoryId?.toString(),
                        hint: const Text('Loại chiến dịch',
                            style: TextStyle(fontSize: 13)),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(
                              value: '',
                              child: Text('Tất cả loại',
                                  style: TextStyle(fontSize: 13))),
                          if (_filters != null)
                            ..._filters!.loaiChienDichOptions
                                .map((c) => DropdownMenuItem(
                                      value: c.id.toString(),
                                      child: Text(c.ten,
                                          style: const TextStyle(fontSize: 13)),
                                    )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterCategoryId =
                                value != null && value.isNotEmpty
                                    ? int.tryParse(value)
                                    : null;
                          });
                          _loadCampaigns();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Priority filter
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterPriority,
                        hint: const Text('Mức độ ưu tiên',
                            style: TextStyle(fontSize: 13)),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem<String>(
                              value: '',
                              child: Text('Tất cả mức độ',
                                  style: TextStyle(fontSize: 13))),
                          DropdownMenuItem<String>(
                              value: 'khan_cap',
                              child: Text('Khẩn cấp',
                                  style: TextStyle(fontSize: 13))),
                          DropdownMenuItem<String>(
                              value: 'cao',
                              child:
                                  Text('Cao', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem<String>(
                              value: 'trung_binh',
                              child: Text('Trung bình',
                                  style: TextStyle(fontSize: 13))),
                          DropdownMenuItem<String>(
                              value: 'thap',
                              child:
                                  Text('Thấp', style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterPriority = value != null && value.isNotEmpty
                                ? value
                                : null;
                          });
                          _loadCampaigns();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(_error!,
                                style: TextStyle(color: Colors.grey.shade600)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _campaigns.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.flag_outlined,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'Không có chiến dịch nào',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadCampaigns,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _campaigns.length,
                              itemBuilder: (context, index) {
                                return _buildCampaignCard(_campaigns[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBadge(String tabValue) {
    final count = _tabCount(tabValue);

    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tabValue == 'pending' || tabValue == 'pending_cancel'
            ? Colors.red
            : Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }

  int _tabCount(String tabValue) {
    switch (tabValue) {
      case 'pending':
        return _pendingCount;
      case 'approved':
        return _approvedCount;
      case 'pending_cancel':
        return _pendingCancelCount;
      case 'cancelled':
        return _cancelledCount;
      case 'active':
        return _activeCount;
      case 'completed':
        for (final s in _filters?.trangThaiOptions ?? const <StatusFilter>[]) {
          if (s.value == 'hoan_thanh') return s.count;
        }
        return 0;
      default:
        return 0;
    }
  }

  Widget _buildStatsCards() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              label: 'Tổng',
              value: _totalCount.toString(),
              color: Colors.blue,
              icon: Icons.flag,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              label: 'Chờ duyệt',
              value: _pendingCount.toString(),
              color: Colors.orange,
              icon: Icons.hourglass_empty,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              label: 'Đã duyệt',
              value: _approvedCount.toString(),
              color: Colors.green,
              icon: Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(ReviewerCampaign campaign) {
    final isPending = campaign.trangThai == 'cho_duyet';
    final hasCancelRequest = campaign.trangThai == 'yeu_cau_huy';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showCampaignDetail(campaign),
        borderRadius: BorderRadius.circular(16),
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
                      color: _getStatusColor(campaign.trangThai)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.flag,
                      color: _getStatusColor(campaign.trangThai),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campaign.tenChienDich,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                campaign.diaDiem,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.calendar_today,
                    text:
                        '${_formatDate(campaign.ngayBatDau)} - ${_formatDate(campaign.ngayKetThuc)}',
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.people,
                    text: '${campaign.soLuongHienTai}/${campaign.soLuongToiDa}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(campaign.trangThai)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      campaign.trangThaiDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(campaign.trangThai),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (campaign.coYeuCauHuy)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cancel,
                              size: 12, color: Colors.red.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Yêu cầu hủy',
                            style: TextStyle(
                                fontSize: 11, color: Colors.red.shade700),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              // Action buttons
              if (isPending || hasCancelRequest) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isPending) ...[
                      OutlinedButton.icon(
                        onPressed: () => _rejectCampaign(campaign),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Từ chối'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _approveCampaign(campaign),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Duyệt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                    if (hasCancelRequest) ...[
                      OutlinedButton.icon(
                        onPressed: () => _rejectCancel(campaign),
                        icon: const Icon(Icons.undo, size: 18),
                        label: const Text('Từ chối hủy'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _approveCancel(campaign),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Duyệt hủy'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

class _TabConfig {
  final String value;
  final String label;
  final String backendKey;

  const _TabConfig({
    required this.value,
    required this.label,
    required this.backendKey,
  });
}
