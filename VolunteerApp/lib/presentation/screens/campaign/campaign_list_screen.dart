import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/campaign_provider.dart';
import '../../widgets/campaign_card.dart';
import '../../widgets/common_widgets.dart';

class CampaignListScreen extends StatefulWidget {
  const CampaignListScreen({super.key});

  @override
  State<CampaignListScreen> createState() => _CampaignListScreenState();
}

class _CampaignListScreenState extends State<CampaignListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CampaignProvider>().loadCampaigns(refresh: true);
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final campaignProvider = context.watch<CampaignProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chiến dịch'),
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
            // Filter chips
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tất cả'),
                      selected: campaignProvider.error == null,
                      onSelected: (_) {
                        campaignProvider.setStatusFilter(null);
                        campaignProvider.loadCampaigns(refresh: true);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Đang tuyển'),
                      selected: campaignProvider.error == null,
                      onSelected: (_) {
                        campaignProvider.setStatusFilter('da_duyet');
                        campaignProvider.loadCampaigns(refresh: true);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Đang diễn ra'),
                      selected: campaignProvider.error == null,
                      onSelected: (_) {
                        campaignProvider.setStatusFilter('dang_dien_ra');
                        campaignProvider.loadCampaigns(refresh: true);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Sắp tới'),
                      selected: campaignProvider.error == null,
                      onSelected: (_) {
                        campaignProvider.setStatusFilter('dang_dien_ra');
                        campaignProvider.loadCampaigns(refresh: true);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Campaign list
            if (campaignProvider.isLoading && campaignProvider.campaigns.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (campaignProvider.error != null && campaignProvider.campaigns.isEmpty)
              SliverFillRemaining(
                child: ErrorDisplay(
                  message: campaignProvider.error!,
                  onRetry: () => campaignProvider.refreshCampaigns(),
                ),
              )
            else if (campaignProvider.campaigns.isEmpty)
              const SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.search_off,
                  title: 'Không tìm thấy chiến dịch',
                  subtitle: 'Thử thay đổi từ khóa tìm kiếm',
                ),
              )
            else
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
        ),
      ),
    );
  }
}
