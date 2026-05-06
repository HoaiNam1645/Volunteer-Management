import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/coordinator_provider.dart';
import '../../../core/theme/app_theme.dart';

class DieuPhoiNhanSuScreen extends StatefulWidget {
  const DieuPhoiNhanSuScreen({super.key});

  @override
  State<DieuPhoiNhanSuScreen> createState() => _DieuPhoiNhanSuScreenState();
}

class _DieuPhoiNhanSuScreenState extends State<DieuPhoiNhanSuScreen> {
  String? _selectedCampaignId;
  String _activeTab = 'allocation';
  String _tableFilterArea = 'all';
  String _tableFilterProfile = 'all';
  String _tableFilterDistance = 'all';
  String _tableFilterScore = 'all';
  Set<int> _selectedInviteIds = {};
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<CoordinatorProvider>();
      await provider.loadCampaignsForCoordination();
      // Auto-load coordination data for the first auto-selected campaign
      if (provider.activeCampaign != null && _selectedCampaignId == null && mounted) {
        final id = provider.activeCampaign!.id.toString();
        setState(() => _selectedCampaignId = id);
        await provider.loadCoordinationData(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final coordinatorProvider = context.watch<CoordinatorProvider>();
    final campaigns = coordinatorProvider.campaigns;

    // Auto-sync local _selectedCampaignId với provider.activeCampaign sau frame đầu
    // Đảm bảo dropdown + body tab hiển thị đúng campaign vừa được auto-select
    if (_selectedCampaignId == null && coordinatorProvider.activeCampaign != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _selectedCampaignId == null &&
            coordinatorProvider.activeCampaign != null) {
          final id = coordinatorProvider.activeCampaign!.id.toString();
          setState(() => _selectedCampaignId = id);
          coordinatorProvider.loadCoordinationData(id);
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Điều phối nhân sự'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _showFilters,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_selectedCampaignId != null) {
                coordinatorProvider.loadCoordinationData(_selectedCampaignId!);
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: _selectedInviteIds.isNotEmpty
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Đã chọn ${_selectedInviteIds.length} TNV', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    OutlinedButton(
                      onPressed: () => setState(() => _selectedInviteIds.clear()),
                      child: const Text('Xoá chọn'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: coordinatorProvider.isInviting
                          ? null
                          : () => _inviteVolunteers(_selectedInviteIds.toList(), coordinatorProvider),
                      icon: coordinatorProvider.isInviting
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send, size: 16),
                      label: const Text('Mời tham gia'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          if (_selectedCampaignId != null) {
            await coordinatorProvider.loadCoordinationData(_selectedCampaignId!);
          }
        },
        child: CustomScrollView(
          slivers: [
            // Campaign Selector
            SliverToBoxAdapter(
              child: _buildCampaignSelector(campaigns, coordinatorProvider),
            ),

            // Active Campaign Summary
            if (coordinatorProvider.activeCampaign != null)
              SliverToBoxAdapter(
                child: _buildCampaignSummary(coordinatorProvider),
              ),

            // Stats Cards
            SliverToBoxAdapter(
              child: _buildStatsCards(coordinatorProvider),
            ),

            // Filters Section
            if (_showFilters)
              SliverToBoxAdapter(
                child: _buildFiltersSection(),
              ),

            // Tabs
            SliverToBoxAdapter(
              child: _buildTabs(),
            ),

            // Content based on active tab
            if (coordinatorProvider.isLoadingRecommendations)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_selectedCampaignId == null)
              SliverFillRemaining(
                child: _buildEmptyState(
                  icon: Icons.people_outline,
                  title: 'Chọn chiến dịch',
                  subtitle: 'Vui lòng chọn chiến dịch để xem danh sách tình nguyện viên',
                ),
              )
            else if (_activeTab == 'allocation')
              _buildAllocationTab(coordinatorProvider)
            else if (_activeTab == 'risks')
              _buildRisksTab(coordinatorProvider)
            else if (_activeTab == 'detail')
              _buildDetailTab(coordinatorProvider),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignSelector(
    List<dynamic> campaigns,
    CoordinatorProvider provider,
  ) {
    return Container(
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
          const Text(
            'Chọn chiến dịch',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                // Dùng `value:` (controlled) thay vì `initialValue:` để dropdown
                // tự cập nhật khi state đổi (vd auto-select sau khi load xong).
                // ignore: deprecated_member_use
                child: DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _selectedCampaignId != null &&
                          campaigns.any((c) => c.id.toString() == _selectedCampaignId)
                      ? _selectedCampaignId
                      : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  hint: Text(
                    provider.isLoadingCampaigns
                        ? 'Đang tải...'
                        : (campaigns.isEmpty ? 'Chưa có chiến dịch để điều phối' : 'Chọn chiến dịch'),
                    overflow: TextOverflow.ellipsis,
                  ),
                  items: campaigns.map((campaign) {
                    return DropdownMenuItem(
                      value: campaign.id.toString(),
                      child: Text(campaign.tenChienDich, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedCampaignId = value);
                    provider.loadCoordinationData(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _selectedCampaignId != null
                    ? () => _showAISuggestionSheet(provider)
                    : null,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Gợi ý AI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignSummary(CoordinatorProvider provider) {
    final campaign = provider.activeCampaign!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.successColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem('Chiến dịch', campaign.tenChienDich),
          ),
          Expanded(
            child: _buildSummaryItem('Địa điểm', campaign.diaDiem),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Đã đăng ký',
              '${campaign.soLuongHienTai}/${campaign.soLuongToiDa}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatsCards(CoordinatorProvider provider) {
    final total = provider.volunteerRows.length;
    final primary = provider.allocationPrimary.length;
    final recommended = provider.recommendedVolunteers.length;
    final risks = provider.allocationRisks.length;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Tổng gợi ý',
              total.toString(),
              Icons.people,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Đạt chuẩn',
              primary.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Khuyến nghị',
              recommended.toString(),
              Icons.star,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Cảnh báo',
              risks.toString(),
              Icons.warning,
              Colors.red,
            ),
          ),
        ],
      ),
    );
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
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
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

  Widget _buildFiltersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bộ lọc',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _tableFilterArea = 'all';
                    _tableFilterProfile = 'all';
                    _tableFilterDistance = 'all';
                    _tableFilterScore = 'all';
                  });
                },
                child: const Text('Xóa lọc'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFilterDropdown(
            'Khu vực',
            _tableFilterArea,
            [
              {'value': 'all', 'label': 'Tất cả'},
              {'value': 'same_area', 'label': 'Trùng khu vực'},
              {'value': 'remote_area', 'label': 'Ở xa nhưng đúng khu vực'},
              {'value': 'other_area', 'label': 'Khác khu vực'},
            ],
            (value) => setState(() => _tableFilterArea = value!),
          ),
          const SizedBox(height: 8),
          _buildFilterDropdown(
            'Hồ sơ',
            _tableFilterProfile,
            [
              {'value': 'all', 'label': 'Tất cả'},
              {'value': 'outstanding', 'label': 'Nổi bật'},
              {'value': 'not_outstanding', 'label': 'Không nổi bật'},
            ],
            (value) => setState(() => _tableFilterProfile = value!),
          ),
          const SizedBox(height: 8),
          _buildFilterDropdown(
            'Khoảng cách',
            _tableFilterDistance,
            [
              {'value': 'all', 'label': 'Tất cả'},
              {'value': 'lte_5', 'label': '≤ 5km'},
              {'value': 'lte_10', 'label': '≤ 10km'},
              {'value': 'lte_20', 'label': '≤ 20km'},
              {'value': 'gt_25', 'label': '> 25km'},
            ],
            (value) => setState(() => _tableFilterDistance = value!),
          ),
          const SizedBox(height: 8),
          _buildFilterDropdown(
            'Điểm',
            _tableFilterScore,
            [
              {'value': 'all', 'label': 'Tất cả'},
              {'value': 'eq_100', 'label': '100%'},
              {'value': 'gte_80', 'label': '≥ 80%'},
              {'value': 'gte_60', 'label': '≥ 60%'},
              {'value': 'lte_50', 'label': '≤ 50%'},
            ],
            (value) => setState(() => _tableFilterScore = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<Map<String, String>> options,
    ValueChanged<String?> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
            items: options.map((opt) {
              return DropdownMenuItem(
                value: opt['value'],
                child: Text(opt['label']!, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTabButton('allocation', 'Danh sách', Icons.list_alt),
          const SizedBox(width: 6),
          _buildTabButton('risks', 'Cảnh báo', Icons.warning_amber),
          const SizedBox(width: 6),
          _buildTabButton('detail', 'Chi tiết', Icons.analytics),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String label, IconData icon) {
    final isActive = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllocationTab(CoordinatorProvider provider) {
    final filteredRows = _getFilteredVolunteerRows(provider);

    if (filteredRows.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(
          icon: Icons.person_search,
          title: 'Không có tình nguyện viên',
          subtitle: 'Không tìm thấy tình nguyện viên phù hợp với bộ lọc',
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final volunteer = filteredRows[index];
          final isSelected = _selectedInviteIds.contains(volunteer.id);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () => _showVolunteerDetail(volunteer, provider),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedInviteIds.add(volunteer.id);
                              } else {
                                _selectedInviteIds.remove(volunteer.id);
                              }
                            });
                          },
                        ),
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                          child: Text(
                            volunteer.name.isNotEmpty
                                ? volunteer.name[0].toUpperCase()
                                : '?',
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
                                volunteer.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                volunteer.areaText ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getScoreColor(volunteer.finalScore),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${volunteer.finalScore}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Skills
                    if (volunteer.skills.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: (volunteer.skills as List).take(3).map<Widget>((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              skill,
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 12),
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showVolunteerDetail(volunteer, provider),
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('Xem chi tiết'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _inviteVolunteers([volunteer.id], provider),
                            icon: const Icon(Icons.send, size: 16),
                            label: const Text('Mời'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: filteredRows.length,
      ),
    );
  }

  Widget _buildDetailTab(CoordinatorProvider provider) {
    final summary = provider.allocationSummary;

    return SliverToBoxAdapter(
      child: Container(
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
            const Text(
              'Tổng quan phân bổ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Số lượng tối thiểu',
              '${summary['so_luong_toi_thieu'] ?? 0}',
            ),
            _buildDetailRow(
              'Số lượng tối đa',
              '${summary['so_luong_toi_da'] ?? 0}',
            ),
            _buildDetailRow(
              'Đã xác nhận',
              '${summary['so_xac_nhan_hien_tai'] ?? 0}',
            ),
            _buildDetailRow(
              'Đạt chuẩn',
              '${summary['so_tnv_du_chuan'] ?? 0}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRisksTab(CoordinatorProvider provider) {
    final risks = provider.allocationRisks;
    if (risks.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(
          icon: Icons.check_circle_outline,
          title: 'Không có cảnh báo',
          subtitle: 'Phân bổ nhân sự đang ở trạng thái tốt',
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final risk = risks[index];
          final code = (risk['code'] ?? risk['risk_code'] ?? '').toString();
          final message = (risk['message'] ?? risk['ly_do'] ?? code).toString();
          final severity = (risk['severity'] ?? risk['muc_do'] ?? 'medium').toString();
          final color = severity == 'high'
              ? Colors.red
              : severity == 'low'
                  ? Colors.amber
                  : Colors.orange;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(Icons.warning_amber, color: color, size: 20),
              ),
              title: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: code.isEmpty ? null : Text('Mã: $code', style: const TextStyle(fontSize: 11)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  severity.toUpperCase(),
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
        childCount: risks.length,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<dynamic> _getFilteredVolunteerRows(CoordinatorProvider provider) {
    var rows = provider.volunteerRows;

    // Apply filters
    if (_tableFilterArea != 'all') {
      rows = rows.where((v) {
        if (_tableFilterArea == 'same_area') {
          return v.groupCode == 'primary';
        } else if (_tableFilterArea == 'remote_area') {
          return v.groupCode == 'remote_area';
        }
        return true;
      }).toList();
    }

    if (_tableFilterScore != 'all') {
      rows = rows.where((v) {
        final score = v.finalScore ?? 0;
        switch (_tableFilterScore) {
          case 'eq_100':
            return score == 100;
          case 'gte_80':
            return score >= 80;
          case 'gte_60':
            return score >= 60;
          case 'lte_50':
            return score <= 50;
          default:
            return true;
        }
      }).toList();
    }

    return rows;
  }

  Color _getScoreColor(int? score) {
    if (score == null) return Colors.grey;
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.amber;
    return Colors.red;
  }

  void _showVolunteerDetail(dynamic volunteer, CoordinatorProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _VolunteerDetailSheet(
          scrollController: scrollController,
          volunteer: volunteer,
          provider: provider,
          onInvite: () => _inviteVolunteers([volunteer.id], provider),
        ),
      ),
    );
  }

  void _showAISuggestionSheet(CoordinatorProvider provider) {
    if (provider.volunteerRows.isEmpty) return;
    _showVolunteerDetail(provider.volunteerRows.first, provider);
  }

  Future<void> _inviteVolunteers(List<int> ids, CoordinatorProvider provider) async {
    if (_selectedCampaignId == null) return;

    final success = await provider.inviteVolunteers(_selectedCampaignId!, ids);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi lời mời thành công!')),
      );
    }
  }
}

// ============ Volunteer Detail Sheet ============
class _VolunteerDetailSheet extends StatelessWidget {
  final dynamic volunteer;
  final CoordinatorProvider provider;
  final VoidCallback onInvite;
  final ScrollController scrollController;

  const _VolunteerDetailSheet({
    required this.scrollController,
    required this.volunteer,
    required this.provider,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final breakdown = volunteer.breakdown ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Text(
                  volunteer.name.isNotEmpty ? volunteer.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      volunteer.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      volunteer.email ?? '',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${volunteer.finalScore ?? 0}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),

          // Score Breakdown
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Điểm phân tích',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _buildScoreRow('Kỹ năng', breakdown['skill'] ?? 0),
                  _buildScoreRow('Lịch trình', breakdown['availability'] ?? 0),
                  _buildScoreRow('Khoảng cách', breakdown['distance'] ?? 0),
                  _buildScoreRow('Độ tin cậy', breakdown['reliability'] ?? 0),
                  _buildScoreRow('Hồ sơ', breakdown['profileStrength'] ?? 0),
                  const SizedBox(height: 24),

                  // Skills
                  if (volunteer.skills.isNotEmpty) ...[
                    const Text(
                      'Kỹ năng',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (volunteer.skills as List).map<Widget>((skill) {
                        return Chip(
                          label: Text(skill, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Reasons
                  if (volunteer.reasons.isNotEmpty) ...[
                    const Text(
                      'Lý do phù hợp',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ...(volunteer.reasons as List).map<Widget>((reason) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(reason)),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                  ],

                  // Warnings
                  if (volunteer.warnings.isNotEmpty) ...[
                    const Text(
                      'Cảnh báo',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ...(volunteer.warnings as List).map<Widget>((warning) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.warning,
                                color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(warning)),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ),

          // Actions
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Đóng'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onInvite();
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Mời tham gia'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, dynamic score) {
    final scoreValue = (score is int || score is double) ? score.toInt() : 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey[700])),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: scoreValue / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(_getColorForScore(scoreValue)),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text(
              '$scoreValue%',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForScore(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
