import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/reviewer_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/reviewer_repository.dart';

class CoordinatorScreen extends StatefulWidget {
  const CoordinatorScreen({super.key});

  @override
  State<CoordinatorScreen> createState() => _CoordinatorScreenState();
}

class _CoordinatorScreenState extends State<CoordinatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ReviewerProvider>();
      provider.loadFilters();
      provider.loadCampaigns(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReviewerProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Kiểm duyệt chiến dịch'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Chờ duyệt'),
            Tab(text: 'Đã duyệt'),
            Tab(text: 'Từ chối'),
            Tab(text: 'Đang hoạt động'),
          ],
          onTap: (index) {
            final status = ['cho_duyet', 'da_duyet', 'tu_choi', 'dang_dien_ra'][index];
            provider.setStatusFilter(status);
          },
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(provider),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCampaignList(provider, 'cho_duyet'),
                _buildCampaignList(provider, 'da_duyet'),
                _buildCampaignList(provider, 'tu_choi'),
                _buildCampaignList(provider, 'dang_dien_ra'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ReviewerProvider provider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm chiến dịch...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (value) {
                provider.setSearchQuery(value);
                provider.loadCampaigns(refresh: true);
              },
            ),
          ),
          const SizedBox(width: 12),
          _buildFilterButton(),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.tune, color: AppTheme.primaryColor),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'all', child: Text('Tất cả loại')),
        const PopupMenuItem(value: '1', child: Text('Nhân đạo')),
        const PopupMenuItem(value: '2', child: Text('Môi trường')),
        const PopupMenuItem(value: '3', child: Text('Giáo dục')),
      ],
      onSelected: (value) {
        final provider = context.read<ReviewerProvider>();
        provider.setCampaignTypeFilter(value == 'all' ? null : value);
      },
    );
  }

  Widget _buildCampaignList(ReviewerProvider provider, String status) {
    if (provider.isLoading && provider.campaigns.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.campaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(provider.error!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadCampaigns(refresh: true),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final filtered = provider.campaigns.where((c) => c.trangThai == status).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _getEmptyText(status),
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadCampaigns(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filtered.length) {
            provider.loadCampaigns();
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _buildCampaignCard(filtered[index]);
        },
      ),
    );
  }

  String _getEmptyText(String status) {
    switch (status) {
      case 'cho_duyet':
        return 'Không có chiến dịch chờ duyệt';
      case 'da_duyet':
        return 'Không có chiến dịch đã duyệt';
      case 'tu_choi':
        return 'Không có chiến dịch bị từ chối';
      case 'dang_dien_ra':
        return 'Không có chiến dịch đang hoạt động';
      default:
        return 'Không có chiến dịch';
    }
  }

  Widget _buildCampaignCard(ReviewerCampaign campaign) {
    Color statusColor;
    IconData statusIcon;

    switch (campaign.trangThai) {
      case 'cho_duyet':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'da_duyet':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'tu_choi':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'dang_dien_ra':
        statusColor = Colors.blue;
        statusIcon = Icons.play_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
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
                            Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                campaign.nguoiTaoTen,
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          campaign.trangThaiDisplay,
                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.location_on, campaign.diaDiem),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.calendar_today,
                    DateFormat('dd/MM/yyyy').format(campaign.ngayBatDau),
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.group,
                    '${campaign.soLuongHienTai}/${campaign.soLuongToiDa}',
                  ),
                ],
              ),
              if (campaign.coYeuCauHuy || campaign.coBaoCao) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (campaign.coYeuCauHuy)
                      _buildAlertChip('Yêu cầu hủy', Colors.orange),
                    if (campaign.coBaoCao) ...[
                      const SizedBox(width: 8),
                      _buildAlertChip('Có báo cáo', Colors.red),
                    ],
                  ],
                ),
              ],
              if (campaign.lyDoTuChoi != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lý do từ chối: ${campaign.lyDoTuChoi}',
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (campaign.trangThai == 'cho_duyet') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showRejectDialog(campaign),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Từ chối'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _approveCampaign(campaign),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Duyệt'),
                      ),
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
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showCampaignDetail(ReviewerCampaign campaign) {
    context.push('/coordinator/campaign/${campaign.id}');
  }

  Future<void> _approveCampaign(ReviewerCampaign campaign) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận duyệt'),
        content: Text('Bạn có chắc muốn duyệt chiến dịch "${campaign.tenChienDich}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<ReviewerProvider>();
      final success = await provider.approveCampaign(campaign.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Duyệt thành công!' : 'Duyệt thất bại!'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showRejectDialog(ReviewerCampaign campaign) async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối chiến dịch'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Lý do từ chối',
            hintText: 'Nhập lý do từ chối...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(context, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (reason != null && mounted) {
      final provider = context.read<ReviewerProvider>();
      final success = await provider.rejectCampaign(campaign.id, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Từ chối thành công!' : 'Từ chối thất bại!'),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }
}
