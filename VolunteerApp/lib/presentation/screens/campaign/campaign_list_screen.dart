import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/campaign_card.dart';
import '../../widgets/common_widgets.dart';
import '../../core/theme/app_theme.dart';

class CampaignListScreen extends StatefulWidget {
  const CampaignListScreen({super.key});

  @override
  State<CampaignListScreen> createState() => _CampaignListScreenState();
}

class _CampaignListScreenState extends State<CampaignListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _locationController = TextEditingController();

  // Filter states
  String? _selectedSort;
  String? _selectedLocation;
  bool _showFilters = false;

  // Static data for filters (can be loaded from API)
  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'newest', 'label': 'Mới nhất', 'icon': Icons.schedule},
    {'value': 'urgent', 'label': 'Khẩn cấp', 'icon': Icons.priority_high},
    {'value': 'soonest', 'label': 'Sắp diễn ra', 'icon': Icons.event},
  ];

  final List<Map<String, dynamic>> _locations = [
    {'value': '', 'label': 'Tất cả khu vực'},
    {'value': 'hcm', 'label': 'TP. Hồ Chí Minh'},
    {'value': 'hn', 'label': 'Hà Nội'},
    {'value': 'dn', 'label': 'Đà Nẵng'},
    {'value': 'ct', 'label': 'Cần Thơ'},
  ];

  final List<Map<String, dynamic>> _categories = [
    {'value': '', 'label': 'Tất cả'},
    {'value': 'giao-duc', 'label': 'Giáo dục'},
    {'value': 'y-te', 'label': 'Y tế'},
    {'value': 'moi-truong', 'label': 'Môi trường'},
    {'value': 'xa-hoi', 'label': 'Xã hội'},
    {'value': 'van-hoa', 'label': 'Văn hóa'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CampaignProvider>();
      provider.loadCampaigns(refresh: true);
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<CampaignProvider>().loadCampaigns();
    }
  }

  void _onSearch(String query) {
    context.read<CampaignProvider>().setSearchQuery(query);
    context.read<CampaignProvider>().loadCampaigns(refresh: true);
  }

  void _onSortChanged(String? sort) {
    setState(() => _selectedSort = sort);
    context.read<CampaignProvider>().setSortOption(sort);
    context.read<CampaignProvider>().loadCampaigns(refresh: true);
  }

  void _onLocationChanged(String? location) {
    setState(() => _selectedLocation = location);
    context.read<CampaignProvider>().setLocationFilter(location);
    context.read<CampaignProvider>().loadCampaigns(refresh: true);
  }

  void _onCategoryChanged(String? category) {
    context.read<CampaignProvider>().setCategoryFilter(category?.isEmpty == true ? null : category);
    context.read<CampaignProvider>().loadCampaigns(refresh: true);
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _selectedSort = null;
      _selectedLocation = null;
      _selectedCategory = null;
    });
    final provider = context.read<CampaignProvider>();
    provider.setSearchQuery(null);
    provider.setSortOption(null);
    provider.setLocationFilter(null);
    provider.setCategoryFilter(null);
    provider.loadCampaigns(refresh: true);
  }

  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final campaignProvider = context.watch<CampaignProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;

    // Check if any filters are active
    final hasActiveFilters = _searchController.text.isNotEmpty ||
        _selectedSort != null ||
        _selectedLocation != null ||
        _selectedCategory != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chiến dịch'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: hasActiveFilters,
              child: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: 'Bộ lọc',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                          _onSearch('');
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
              onSubmitted: _onSearch,
              onChanged: (value) => setState(() {}),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => campaignProvider.refreshCampaigns(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Expandable Filters Section
            if (_showFilters)
              SliverToBoxAdapter(
                child: _buildFiltersSection(),
              ),

            // AI Recommendations Section (for logged in users)
            if (isLoggedIn && campaignProvider.recommendedCampaigns.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _buildRecommendationsSection(campaignProvider),
              ),
            ],

            // Search Result Banner
            if (campaignProvider.searchQuery != null &&
                campaignProvider.searchQuery!.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildSearchResultBanner(campaignProvider),
              ),

            // Sort & Results Bar
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hiển thị ${campaignProvider.campaigns.length} chiến dịch',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (hasActiveFilters)
                      TextButton.icon(
                        onPressed: _clearAllFilters,
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Xóa lọc'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      initialValue: _selectedSort,
                      onSelected: _onSortChanged,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _sortOptions.firstWhere(
                                (s) => s['value'] == _selectedSort,
                                orElse: () => _sortOptions[0],
                              )['icon'] as IconData,
                              size: 16,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _sortOptions.firstWhere(
                                (s) => s['value'] == _selectedSort,
                                orElse: () => _sortOptions[0],
                              )['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey[700]),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => _sortOptions.map((sort) {
                        return PopupMenuItem<String>(
                          value: sort['value'] as String,
                          child: Row(
                            children: [
                              Icon(
                                sort['icon'] as IconData,
                                size: 18,
                                color: _selectedSort == sort['value']
                                    ? AppTheme.primaryColor
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                sort['label'] as String,
                                style: TextStyle(
                                  fontWeight: _selectedSort == sort['value']
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _selectedSort == sort['value']
                                      ? AppTheme.primaryColor
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Filter chips (horizontal)
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'Tất cả',
                      isSelected: campaignProvider.statusFilter == null,
                      onSelected: () {
                        campaignProvider.setStatusFilter(null);
                        campaignProvider.loadCampaigns(refresh: true);
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Đang tuyển',
                      isSelected: campaignProvider.statusFilter == 'da_duyet',
                      onSelected: () {
                        campaignProvider.setStatusFilter('da_duyet');
                        campaignProvider.loadCampaigns(refresh: true);
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Đang diễn ra',
                      isSelected: campaignProvider.statusFilter == 'dang_dien_ra',
                      onSelected: () {
                        campaignProvider.setStatusFilter('dang_dien_ra');
                        campaignProvider.loadCampaigns(refresh: true);
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Sắp tới',
                      isSelected: campaignProvider.statusFilter == 'sap_toi',
                      onSelected: () {
                        campaignProvider.setStatusFilter('sap_toi');
                        campaignProvider.loadCampaigns(refresh: true);
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Đã kết thúc',
                      isSelected: campaignProvider.statusFilter == 'da_ket_thuc',
                      onSelected: () {
                        campaignProvider.setStatusFilter('da_ket_thuc');
                        campaignProvider.loadCampaigns(refresh: true);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Category Filter Chips
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat['value'] ||
                        (_selectedCategory == null && cat['value'] == '');
                    return Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 8),
                      child: ChoiceChip(
                        label: Text(cat['label'] as String),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _selectedCategory = cat['value'] as String);
                          _onCategoryChanged(cat['value'] as String);
                        },
                        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Campaign list
            if (campaignProvider.isLoading && campaignProvider.campaigns.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (campaignProvider.error != null &&
                campaignProvider.campaigns.isEmpty)
              SliverFillRemaining(
                child: ErrorDisplay(
                  message: campaignProvider.error!,
                  onRetry: () => campaignProvider.refreshCampaigns(),
                ),
              )
            else if (campaignProvider.campaigns.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.search_off,
                  title: 'Không tìm thấy chiến dịch',
                  subtitle: 'Thử thay đổi từ khóa tìm kiếm hoặc bộ lọc',
                  action: hasActiveFilters
                      ? TextButton.icon(
                          onPressed: _clearAllFilters,
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Xóa bộ lọc'),
                        )
                      : null,
                ),
              )
            else ...[
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= campaignProvider.campaigns.length) {
                      return campaignProvider.hasMore
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : const SizedBox.shrink();
                    }

                    final campaign = campaignProvider.campaigns[index];
                    return CampaignCard(
                      imageUrl: campaign.anhBia,
                      title: campaign.tenChienDich,
                      location: campaign.diaDiem,
                      startDate: campaign.ngayBatDau,
                      endDate: campaign.ngayKetThuc,
                      currentParticipants: campaign.soLuongHienTai,
                      maxParticipants: campaign.soLuongToiDa,
                      status: campaign.trangThai,
                      onTap: () => context.push('/campaign/${campaign.id}'),
                    );
                  },
                  childCount: campaignProvider.campaigns.length +
                      (campaignProvider.hasMore ? 1 : 0),
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bộ lọc nâng cao',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _showFilters = false),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Location Filter
          Text(
            'Khu vực',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _locations.map((loc) {
              final isSelected = _selectedLocation == loc['value'] ||
                  (_selectedLocation == null && loc['value'] == '');
              return ChoiceChip(
                label: Text(loc['label'] as String),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedLocation = loc['value'] as String);
                  _onLocationChanged(loc['value'] as String);
                },
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Category Filter
          Text(
            'Lĩnh vực',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
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
                  _onCategoryChanged(cat['value'] as String);
                },
                selectedColor: AppTheme.successColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.successColor : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Sort Options
          Text(
            'Sắp xếp theo',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sortOptions.map((sort) {
              final isSelected = _selectedSort == sort['value'];
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      sort['icon'] as IconData,
                      size: 16,
                      color: isSelected ? AppTheme.warningColor : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(sort['label'] as String),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedSort = sort['value'] as String);
                  _onSortChanged(sort['value'] as String);
                },
                selectedColor: AppTheme.warningColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.warningColor : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildSearchResultBanner(CampaignProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.search,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kết quả tìm kiếm',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  '"${provider.searchQuery}"',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _searchController.clear();
              _onSearch('');
            },
            tooltip: 'Xóa tìm kiếm',
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(CampaignProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.successColor.withValues(alpha: 0.1),
            AppTheme.successColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.successColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.successColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gợi ý cho bạn',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Dựa trên kỹ năng và vị trí của bạn',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: provider.recommendedCampaigns.length,
              itemBuilder: (context, index) {
                final campaign = provider.recommendedCampaigns[index];
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 12),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.push('/campaign/${campaign.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 100,
                            width: double.infinity,
                            child: campaign.anhBia != null
                                ? Image.network(
                                    campaign.anhBia!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _buildPlaceholder(),
                                  )
                                : _buildPlaceholder(),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    campaign.tenChienDich,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          campaign.diaDiem,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
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
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.volunteer_activism,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }
}
