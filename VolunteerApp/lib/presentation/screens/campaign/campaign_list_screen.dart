import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/campaign_repository.dart';
import '../../providers/campaign_provider.dart';
import '../../widgets/campaign_compare_modal.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/campaign_card.dart';
import '../../widgets/common_widgets.dart';
import '../../../core/theme/app_theme.dart';

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
      final auth = context.read<AuthProvider>();
      provider.loadCampaigns(refresh: true);
      provider.loadFilterMeta();
      // Load AI recommendations only for logged-in volunteers with permission
      final user = auth.currentUser;
      if (user != null && user.isVolunteer && user.hasPermission('ai_recommendation.view')) {
        provider.loadVolunteerRecommendations();
      }
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

            // AI Recommendations Section (for logged in volunteers with breakdown)
            if (isLoggedIn &&
                (campaignProvider.volunteerRecommendations.isNotEmpty ||
                    campaignProvider.loadingRecommendations)) ...[
              SliverToBoxAdapter(
                child: _buildVolunteerRecommendationsSection(campaignProvider),
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
                  buttonText: hasActiveFilters ? 'Xóa bộ lọc' : null,
                  onButtonPressed: hasActiveFilters ? _clearAllFilters : null,
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

  // ignore: unused_element
  Widget _legacyRecommendationsSection(CampaignProvider provider) {
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

  // ============ AI RECOMMENDATIONS WITH BREAKDOWN ============
  Widget _buildVolunteerRecommendationsSection(CampaignProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.successColor, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gợi ý cho bạn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Dựa trên kỹ năng, khu vực, lịch rảnh', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filter chips
          Row(
            children: [
              FilterChip(
                label: const Text('Gần tôi', style: TextStyle(fontSize: 11)),
                selected: provider.recNearbyOnly,
                onSelected: (v) {
                  provider.setRecNearbyOnly(v);
                  provider.loadVolunteerRecommendations();
                },
                avatar: const Icon(Icons.location_on, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: provider.recPriority ?? '',
                  isDense: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Mọi mức ưu tiên', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'khan_cap', child: Text('Khẩn cấp', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'cao', child: Text('Cao', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'trung_binh', child: Text('Trung bình', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'thap', child: Text('Thấp', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (v) {
                    provider.setRecPriority(v == '' ? null : v);
                    provider.loadVolunteerRecommendations();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.loadingRecommendations)
            const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
          else
            SizedBox(
              height: 320,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.volunteerRecommendations.length,
                itemBuilder: (_, i) => _buildRecommendCard(provider.volunteerRecommendations[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendCard(RecommendedCampaign c) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)]),
      child: InkWell(
        onTap: () => context.push('/campaign/${c.id}'),
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: SizedBox(
                    height: 90, width: double.infinity,
                    child: c.anhBia != null && c.anhBia!.isNotEmpty
                        ? Image.network(c.anhBia!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder())
                        : _buildPlaceholder(),
                  ),
                ),
                Positioned(
                  top: 6, left: 6,
                  child: Wrap(spacing: 4, children: [
                    if (c.loaiTen != null)
                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)), child: Text(c.loaiTen!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)), child: Text(c.matchLabel, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600))),
                  ]),
                ),
                Positioned(
                  bottom: 6, right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(4)),
                    child: Text('${c.matchScore}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.tieuDe, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on, size: 11, color: Colors.red),
                      const SizedBox(width: 2),
                      Expanded(child: Text(c.diaDiem ?? '—', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                    ]),
                    if (c.distanceKm != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(children: [
                          const Icon(Icons.route, size: 11, color: Colors.green),
                          const SizedBox(width: 2),
                          Text('${c.distanceKm!.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 11)),
                        ]),
                      ),
                    if (c.badges.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(spacing: 4, runSpacing: 4, children: c.badges.take(3).map((b) => Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)), child: Text(b, style: const TextStyle(fontSize: 9)))).toList()),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                      child: Column(
                        children: [
                          _breakdownRow('Kỹ năng', c.breakdown.skill),
                          _breakdownRow('Thời gian', c.breakdown.availability),
                          _breakdownRow('Khoảng cách', c.breakdown.distance),
                          _breakdownRow('Uy tín', c.breakdown.reliability),
                          _breakdownRow('Hồ sơ', c.breakdown.profileStrength),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openCompareModal(c.id, c.tieuDe, c),
                        icon: const Icon(Icons.compare_arrows, size: 14),
                        label: const Text('So sánh với hồ sơ', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 4), minimumSize: const Size(0, 30)),
                      ),
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

  void _openCompareModal(int campaignId, String title, [RecommendedCampaign? rec]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CampaignCompareModal(
        campaignId: campaignId,
        campaignTitle: title,
        recommendation: rec,
      ),
    );
  }

  Widget _breakdownRow(String label, int percent) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text('$percent%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}
