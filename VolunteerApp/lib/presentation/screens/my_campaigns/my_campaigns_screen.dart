import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/campaign_provider.dart';
import '../../widgets/campaign_card.dart';
import '../../widgets/common_widgets.dart';

class MyCampaignsScreen extends StatefulWidget {
  const MyCampaignsScreen({super.key});

  @override
  State<MyCampaignsScreen> createState() => _MyCampaignsScreenState();
}

class _MyCampaignsScreenState extends State<MyCampaignsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CampaignProvider>().loadMyCampaigns(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final campaignProvider = context.watch<CampaignProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chiến dịch của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => campaignProvider.refreshMyCampaigns(),
        child: campaignProvider.isLoadingMyCampaigns &&
                campaignProvider.myCampaigns.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : campaignProvider.myCampaigns.isEmpty
                ? const EmptyState(
                    icon: Icons.folder_open,
                    title: 'Chưa có chiến dịch',
                    subtitle: 'Tạo chiến dịch mới để bắt đầu',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: campaignProvider.myCampaigns.length,
                    itemBuilder: (context, index) {
                      final campaign = campaignProvider.myCampaigns[index];
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
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCampaignSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Tạo chiến dịch'),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lọc theo trạng thái',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Tất cả'),
                  selected: true,
                  onSelected: (_) {
                    context.read<CampaignProvider>().setStatusFilter(null);
                    context.read<CampaignProvider>().loadMyCampaigns(refresh: true);
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Nháp'),
                  selected: false,
                  onSelected: (_) {
                    context.read<CampaignProvider>().setStatusFilter('nhap');
                    context.read<CampaignProvider>().loadMyCampaigns(refresh: true);
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Chờ duyệt'),
                  selected: false,
                  onSelected: (_) {
                    context.read<CampaignProvider>().setStatusFilter('cho_duyet');
                    context.read<CampaignProvider>().loadMyCampaigns(refresh: true);
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Đã duyệt'),
                  selected: false,
                  onSelected: (_) {
                    context.read<CampaignProvider>().setStatusFilter('da_duyet');
                    context.read<CampaignProvider>().loadMyCampaigns(refresh: true);
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Đã kết thúc'),
                  selected: false,
                  onSelected: (_) {
                    context.read<CampaignProvider>().setStatusFilter('da_ket_thuc');
                    context.read<CampaignProvider>().loadMyCampaigns(refresh: true);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
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
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tạo chiến dịch mới',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Tên chiến dịch *',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Mô tả *',
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Địa điểm *',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Ngày bắt đầu',
                              ),
                              readOnly: true,
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Ngày kết thúc',
                              ),
                              readOnly: true,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Số lượng tối thiểu',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Số lượng tối đa',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Tạo chiến dịch'),
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
      ),
    );
  }
}
