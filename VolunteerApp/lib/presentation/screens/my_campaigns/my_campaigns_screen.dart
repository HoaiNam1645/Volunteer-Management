import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/campaign_provider.dart';
import '../../widgets/campaign_card.dart';
import '../../widgets/common_widgets.dart';
import '../../core/theme/app_theme.dart';

class MyCampaignsScreen extends StatefulWidget {
  const MyCampaignsScreen({super.key});

  @override
  State<MyCampaignsScreen> createState() => _MyCampaignsScreenState();
}

class _MyCampaignsScreenState extends State<MyCampaignsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isGridView = true;
  bool _showFilters = false;

  // Filter states
  String? _selectedCategory;
  String? _selectedPriority;

  // Status tabs matching Frontend
  final List<Map<String, dynamic>> _statusTabs = [
    {'value': null, 'label': 'Tất cả'},
    {'value': 'cho_duyet', 'label': 'Chờ duyệt'},
    {'value': 'da_duyet', 'label': 'Đã duyệt'},
    {'value': 'dang_dien_ra', 'label': 'Đang diễn ra'},
    {'value': 'da_ket_thuc', 'label': 'Đã kết thúc'},
    {'value': 'tu_choi', 'label': 'Từ chối'},
  ];

  // Categories
  final List<Map<String, dynamic>> _categories = [
    {'value': '', 'label': 'Tất cả loại'},
    {'value': 'giao-duc', 'label': 'Giáo dục'},
    {'value': 'y-te', 'label': 'Y tế'},
    {'value': 'moi-truong', 'label': 'Môi trường'},
    {'value': 'xa-hoi', 'label': 'Xã hội'},
    {'value': 'van-hoa', 'label': 'Văn hóa'},
  ];

  // Priorities
  final List<Map<String, dynamic>> _priorities = [
    {'value': '', 'label': 'Tất cả mức'},
    {'value': 'urgent', 'label': 'Khẩn cấp', 'color': Colors.red},
    {'value': 'high', 'label': 'Cao', 'color': Colors.orange},
    {'value': 'medium', 'label': 'Trung bình', 'color': Colors.yellow.shade700},
    {'value': 'low', 'label': 'Thấp', 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _statusTabs.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CampaignProvider>().loadMyCampaigns(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final selectedStatus = _statusTabs[_tabController.index]['value'];
      context.read<CampaignProvider>().setStatusFilter(selectedStatus);
      context.read<CampaignProvider>().loadMyCampaigns(refresh: true);
    }
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = '';
      _selectedPriority = '';
    });
    _tabController.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final campaignProvider = context.watch<CampaignProvider>();

    // Check if any filters are active
    final hasActiveFilters = _searchController.text.isNotEmpty ||
        _selectedCategory != null && _selectedCategory!.isNotEmpty ||
        _selectedPriority != null && _selectedPriority!.isNotEmpty ||
        _tabController.index != 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Chiến dịch của tôi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: hasActiveFilters,
              child: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: 'Bộ lọc',
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'Dạng danh sách' : 'Dạng lưới',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabAlignment: TabAlignment.start,
          tabs: _statusTabs.map((tab) {
            final count = _getCountByStatus(tab['value'], campaignProvider);
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tab['label']),
                  if (count > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _tabController.index == _statusTabs.indexOf(tab)
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _tabController.index == _statusTabs.indexOf(tab)
                              ? AppTheme.primaryColor
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => campaignProvider.refreshMyCampaigns(),
        child: CustomScrollView(
          slivers: [
            // Expandable Filters Section
            if (_showFilters)
              SliverToBoxAdapter(
                child: _buildFiltersSection(),
              ),

            // Stats Cards
            SliverToBoxAdapter(
              child: _buildStatsCards(campaignProvider),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm chiến dịch...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    if (hasActiveFilters) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear_all, color: Colors.red),
                        onPressed: _clearAllFilters,
                        tooltip: 'Xóa lọc',
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Category & Priority Filter Chips
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Category dropdown
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        setState(() => _selectedCategory = value);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedCategory != null && _selectedCategory!.isNotEmpty
                              ? AppTheme.primaryColor.withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedCategory != null && _selectedCategory!.isNotEmpty
                                ? AppTheme.primaryColor
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 16,
                              color: _selectedCategory != null && _selectedCategory!.isNotEmpty
                                  ? AppTheme.primaryColor
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _categories.firstWhere(
                                (c) => c['value'] == _selectedCategory,
                                orElse: () => _categories[0],
                              )['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: _selectedCategory != null && _selectedCategory!.isNotEmpty
                                    ? AppTheme.primaryColor
                                    : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => _categories.map((cat) {
                        return PopupMenuItem<String>(
                          value: cat['value'] as String,
                          child: Text(cat['label'] as String),
                        );
                      }).toList(),
                    ),
                    const SizedBox(width: 8),
                    // Priority dropdown
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        setState(() => _selectedPriority = value);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedPriority != null && _selectedPriority!.isNotEmpty
                              ? AppTheme.warningColor.withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedPriority != null && _selectedPriority!.isNotEmpty
                                ? AppTheme.warningColor
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.priority_high,
                              size: 16,
                              color: _selectedPriority != null && _selectedPriority!.isNotEmpty
                                  ? AppTheme.warningColor
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _priorities.firstWhere(
                                (p) => p['value'] == _selectedPriority,
                                orElse: () => _priorities[0],
                              )['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: _selectedPriority != null && _selectedPriority!.isNotEmpty
                                    ? AppTheme.warningColor
                                    : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => _priorities.map((p) {
                        return PopupMenuItem<String>(
                          value: p['value'] as String,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: p['color'] as Color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(p['label'] as String),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Campaign list
            if (campaignProvider.isLoadingMyCampaigns &&
                campaignProvider.myCampaigns.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (campaignProvider.myCampaigns.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.folder_open,
                  title: 'Chưa có chiến dịch',
                  subtitle: 'Tạo chiến dịch mới để bắt đầu',
                  action: TextButton.icon(
                    onPressed: () => _showCreateCampaignSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo chiến dịch'),
                  ),
                ),
              )
            else ...[
              if (_isGridView)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final campaign = campaignProvider.myCampaigns[index];
                        return _buildCampaignGridItem(campaign);
                      },
                      childCount: campaignProvider.myCampaigns.length,
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final campaign = campaignProvider.myCampaigns[index];
                      return _buildCampaignListItem(campaign);
                    },
                    childCount: campaignProvider.myCampaigns.length,
                  ),
                ),
            ],

            // Bottom padding for nav bar
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCampaignSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Tạo chiến dịch'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildFiltersSection() {
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
            offset: const Offset(0, 2),
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
                'Bộ lọc nâng cao',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _showFilters = false),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category Filter
          const Text('Loại chiến dịch', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat['value'] ||
                  (_selectedCategory == null && cat['value'] == '');
              return ChoiceChip(
                label: Text(cat['label'] as String),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedCategory = cat['value'] as String);
                },
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Priority Filter
          const Text('Mức độ ưu tiên', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _priorities.map((p) {
              final isSelected = _selectedPriority == p['value'] ||
                  (_selectedPriority == null && p['value'] == '');
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: p['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(p['label'] as String),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedPriority = p['value'] as String);
                },
                selectedColor: (p['color'] as Color).withValues(alpha: 0.2),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(CampaignProvider provider) {
    final total = provider.myCampaigns.length;
    final pending = provider.myCampaigns.where((c) => c.trangThai == 'cho_duyet').length;
    final approved = provider.myCampaigns.where((c) => c.trangThai == 'da_duyet').length;
    final active = provider.myCampaigns.where((c) => c.trangThai == 'dang_dien_ra').length;
    final completed = provider.myCampaigns.where((c) => c.trangThai == 'da_ket_thuc').length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Tổng', total.toString(), Icons.folder_outlined, Colors.blue),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard('Chờ duyệt', pending.toString(), Icons.hourglass_empty, Colors.orange),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard('Đã duyệt', approved.toString(), Icons.check_circle_outline, Colors.green),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard('Đang diễn ra', active.toString(), Icons.play_circle_outline, Colors.purple),
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignGridItem(dynamic campaign) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/campaign/${campaign.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image with actions
            Stack(
              children: [
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: campaign.anhBia != null
                      ? Image.network(campaign.anhBia!, fit: BoxFit.cover)
                      : _buildPlaceholder(),
                ),
                // Priority badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: _buildPriorityBadge(campaign.mucDoKhanCap),
                ),
                // Status badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildStatusBadge(campaign.trangThai),
                ),
                // Action buttons
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _buildActionButtons(campaign),
                ),
              ],
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.tenChienDich,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            campaign.diaDiem,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: campaign.soLuongToiDa > 0
                                  ? campaign.soLuongHienTai / campaign.soLuongToiDa
                                  : 0,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${campaign.soLuongHienTai}/${campaign.soLuongToiDa}',
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignListItem(dynamic campaign) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/campaign/${campaign.id}'),
        child: Column(
          children: [
            ListTile(
              leading: SizedBox(
                width: 60,
                height: 60,
                child: campaign.anhBia != null
                    ? Image.network(campaign.anhBia!, fit: BoxFit.cover)
                    : _buildPlaceholder(),
              ),
              title: Text(
                campaign.tenChienDich,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          campaign.diaDiem,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStatusBadge(campaign.trangThai),
                      const SizedBox(width: 8),
                      _buildPriorityBadge(campaign.mucDoKhanCap),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _handleCampaignAction(value, campaign),
                itemBuilder: (context) => _buildCampaignMenuItems(campaign),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: campaign.soLuongToiDa > 0
                            ? campaign.soLuongHienTai / campaign.soLuongToiDa
                            : 0,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${campaign.soLuongHienTai}/${campaign.soLuongToiDa} người',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildCampaignMenuItems(dynamic campaign) {
    final items = <PopupMenuEntry<String>>[];

    items.add(const PopupMenuItem(
      value: 'view',
      child: Row(
        children: [
          Icon(Icons.visibility_outlined, size: 20),
          SizedBox(width: 8),
          Text('Xem chi tiết'),
        ],
      ),
    ));

    if (campaign.trangThai == 'cho_duyet') {
      items.add(const PopupMenuItem(
        value: 'edit',
        child: Row(
          children: [
            Icon(Icons.edit_outlined, size: 20),
            SizedBox(width: 8),
            Text('Chỉnh sửa'),
          ],
        ),
      ));
    }

    if (campaign.trangThai == 'da_duyet') {
      items.add(const PopupMenuItem(
        value: 'start',
        child: Row(
          children: [
            Icon(Icons.play_arrow, size: 20, color: Colors.green),
            SizedBox(width: 8),
            Text('Bắt đầu chiến dịch'),
          ],
        ),
      ));
    }

    if (campaign.trangThai == 'dang_dien_ra') {
      items.add(const PopupMenuItem(
        value: 'complete',
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text('Hoàn thành'),
          ],
        ),
      ));
    }

    if (campaign.trangThai == 'cho_duyet' || campaign.trangThai == 'da_duyet') {
      items.add(const PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete_outline, size: 20, color: Colors.red),
            SizedBox(width: 8),
            Text('Xóa', style: TextStyle(color: Colors.red)),
          ],
        ),
      ));
    }

    return items;
  }

  Widget _buildActionButtons(dynamic campaign) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (campaign.trangThai == 'da_duyet')
          _buildActionButton(
            Icons.play_arrow,
            Colors.green,
            () => _handleCampaignAction('start', campaign),
          ),
        if (campaign.trangThai == 'cho_duyet')
          _buildActionButton(
            Icons.edit,
            Colors.blue,
            () => _handleCampaignAction('edit', campaign),
          ),
        PopupMenuButton<String>(
          iconSize: 20,
          padding: EdgeInsets.zero,
          onSelected: (value) => _handleCampaignAction(value, campaign),
          itemBuilder: (context) => _buildCampaignMenuItems(campaign),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onPressed) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  void _handleCampaignAction(String action, dynamic campaign) async {
    switch (action) {
      case 'view':
        context.push('/campaign/${campaign.id}');
        break;
      case 'edit':
        _showEditCampaignSheet(context, campaign);
        break;
      case 'start':
        await _confirmStartCampaign(campaign);
        break;
      case 'complete':
        await _confirmCompleteCampaign(campaign);
        break;
      case 'delete':
        await _confirmDeleteCampaign(campaign);
        break;
    }
  }

  Future<void> _confirmStartCampaign(dynamic campaign) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bắt đầu chiến dịch'),
        content: Text('Bạn có chắc muốn bắt đầu chiến dịch "${campaign.tenChienDich}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Bắt đầu'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<CampaignProvider>();
      final success = await provider.updateCampaignStatus(campaign.id, 'dang_dien_ra');
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chiến dịch đã bắt đầu!')),
        );
        provider.loadMyCampaigns(refresh: true);
      }
    }
  }

  Future<void> _confirmCompleteCampaign(dynamic campaign) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hoàn thành chiến dịch'),
        content: Text('Bạn có chắc muốn đánh dấu hoàn thành chiến dịch "${campaign.tenChienDich}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<CampaignProvider>();
      final success = await provider.updateCampaignStatus(campaign.id, 'da_ket_thuc');
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chiến dịch đã hoàn thành!')),
        );
        provider.loadMyCampaigns(refresh: true);
      }
    }
  }

  Future<void> _confirmDeleteCampaign(dynamic campaign) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa chiến dịch'),
        content: Text('Bạn có chắc muốn xóa chiến dịch "${campaign.tenChienDich}"? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<CampaignProvider>();
      final success = await provider.deleteCampaign(campaign.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chiến dịch đã được xóa!')),
        );
      }
    }
  }

  void _showEditCampaignSheet(BuildContext context, dynamic campaign) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _CreateCampaignSheet(
          scrollController: scrollController,
          editCampaign: campaign,
        ),
      ),
    );
  }

  void _showCreateCampaignSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _CreateCampaignSheet(
          scrollController: scrollController,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'da_duyet':
        color = AppTheme.successColor;
        label = 'Đã duyệt';
        break;
      case 'cho_duyet':
        color = AppTheme.warningColor;
        label = 'Chờ duyệt';
        break;
      case 'dang_dien_ra':
        color = AppTheme.primaryColor;
        label = 'Đang diễn ra';
        break;
      case 'da_ket_thuc':
        color = Colors.grey;
        label = 'Đã kết thúc';
        break;
      case 'tu_choi':
        color = AppTheme.errorColor;
        label = 'Từ chối';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildPriorityBadge(int? priority) {
    if (priority == null) return const SizedBox.shrink();
    
    Color color;
    String label;
    
    switch (priority) {
      case 1:
        color = Colors.red;
        label = 'Khẩn cấp';
        break;
      case 2:
        color = Colors.orange;
        label = 'Cao';
        break;
      case 3:
        color = Colors.yellow.shade700;
        label = 'Trung bình';
        break;
      default:
        color = Colors.green;
        label = 'Thấp';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.volunteer_activism, size: 40, color: Colors.grey),
      ),
    );
  }

  int _getCountByStatus(String? status, CampaignProvider provider) {
    if (status == null) return provider.myCampaigns.length;
    return provider.myCampaigns.where((c) => c.trangThai == status).length;
  }
}

// =============== CREATE/EDIT CAMPAIGN SHEET ===============
class _CreateCampaignSheet extends StatefulWidget {
  final ScrollController scrollController;
  final dynamic editCampaign;

  const _CreateCampaignSheet({
    required this.scrollController,
    this.editCampaign,
  });

  @override
  State<_CreateCampaignSheet> createState() => _CreateCampaignSheetState();
}

class _CreateCampaignSheetState extends State<_CreateCampaignSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  String? _selectedCategory;
  String? _selectedPriority;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'value': 'giao-duc', 'label': 'Giáo dục'},
    {'value': 'y-te', 'label': 'Y tế'},
    {'value': 'moi-truong', 'label': 'Môi trường'},
    {'value': 'xa-hoi', 'label': 'Xã hội'},
    {'value': 'van-hoa', 'label': 'Văn hóa'},
  ];

  final List<Map<String, dynamic>> _priorities = [
    {'value': '1', 'label': 'Khẩn cấp', 'color': Colors.red},
    {'value': '2', 'label': 'Cao', 'color': Colors.orange},
    {'value': '3', 'label': 'Trung bình', 'color': Colors.yellow.shade700},
    {'value': '4', 'label': 'Thấp', 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editCampaign != null) {
      _titleController.text = widget.editCampaign.tenChienDich;
      _descriptionController.text = widget.editCampaign.moTa;
      _locationController.text = widget.editCampaign.diaDiem;
      _minController.text = widget.editCampaign.soLuongToiThieu.toString();
      _maxController.text = widget.editCampaign.soLuongToiDa.toString();
      _startDate = widget.editCampaign.ngayBatDau;
      _endDate = widget.editCampaign.ngayKetThuc;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now().add(const Duration(days: 7))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<CampaignProvider>();
      bool success;

      if (widget.editCampaign != null) {
        success = await provider.updateCampaign(
          widget.editCampaign.id,
          _buildCampaign(),
        );
      } else {
        final result = await provider.createCampaign(_buildCampaign());
        success = result != null;
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editCampaign != null
                ? 'Cập nhật chiến dịch thành công!'
                : 'Tạo chiến dịch thành công!'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Campaign _buildCampaign() {
    return Campaign(
      id: widget.editCampaign?.id ?? 0,
      tenChienDich: _titleController.text,
      moTa: _descriptionController.text,
      diaDiem: _locationController.text,
      ngayBatDau: _startDate ?? DateTime.now(),
      ngayKetThuc: _endDate ?? DateTime.now().add(const Duration(days: 7)),
      soLuongToiThieu: int.tryParse(_minController.text) ?? 10,
      soLuongToiDa: int.tryParse(_maxController.text) ?? 100,
      soLuongHienTai: widget.editCampaign?.soLuongHienTai ?? 0,
      trangThai: 'cho_duyet',
      createdAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editCampaign != null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Chỉnh sửa chiến dịch' : 'Tạo chiến dịch mới',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            // Form content
            Expanded(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tên chiến dịch *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Vui lòng nhập tên chiến dịch' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả *',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      validator: (value) =>
                          value?.isEmpty == true ? 'Vui lòng nhập mô tả' : null,
                    ),
                    const SizedBox(height: 16),

                    // Location
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Địa điểm *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Vui lòng nhập địa điểm' : null,
                    ),
                    const SizedBox(height: 16),

                    // Category & Priority
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Loại chiến dịch *',
                              border: OutlineInputBorder(),
                            ),
                            items: _categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat['value'] as String,
                                child: Text(cat['label'] as String),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedCategory = value),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedPriority,
                            decoration: const InputDecoration(
                              labelText: 'Mức ưu tiên *',
                              border: OutlineInputBorder(),
                            ),
                            items: _priorities.map((p) {
                              return DropdownMenuItem(
                                value: p['value'] as String,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: p['color'] as Color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(p['label'] as String),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedPriority = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Date range
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Ngày bắt đầu *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _startDate != null
                                    ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                    : 'Chọn ngày',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Ngày kết thúc *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _endDate != null
                                    ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                    : 'Chọn ngày',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quantity
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minController,
                            decoration: const InputDecoration(
                              labelText: 'Số lượng tối thiểu *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value?.isEmpty == true ? 'Vui lòng nhập' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _maxController,
                            decoration: const InputDecoration(
                              labelText: 'Số lượng tối đa *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value?.isEmpty == true ? 'Vui lòng nhập' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(isEditing ? 'Cập nhật' : 'Tạo chiến dịch'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
