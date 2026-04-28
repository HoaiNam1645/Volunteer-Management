import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/campaign_provider.dart';
import '../../widgets/campaign_card.dart';
import '../../widgets/common_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CampaignProvider>().loadCampaigns(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final campaignProvider = context.watch<CampaignProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer App'),
        actions: [
          if (authProvider.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => context.push('/admin'),
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/campaigns'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => campaignProvider.refreshCampaigns(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào, ${user?.name ?? 'Tình nguyện viên'}! 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Hãy cùng nhau lan tỏa yêu thương',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.search,
                            label: 'Tìm kiếm',
                            onTap: () => context.go('/campaigns'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.add_circle_outline,
                            label: 'Tạo chiến dịch',
                            onTap: () => context.push('/my-campaigns'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.history,
                            label: 'Lịch sử',
                            onTap: () => context.go('/feedback'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stats section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        icon: Icons.campaign,
                        title: 'Chiến dịch',
                        value: '${campaignProvider.campaigns.length}+',
                        onTap: () => context.go('/campaigns'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        icon: Icons.people,
                        title: 'Người tham gia',
                        value: '1K+',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Campaigns section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chiến dịch nổi bật',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/campaigns'),
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),
              ),

              if (campaignProvider.isLoading && campaignProvider.campaigns.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (campaignProvider.error != null && campaignProvider.campaigns.isEmpty)
                ErrorDisplay(
                  message: campaignProvider.error!,
                  onRetry: () => campaignProvider.refreshCampaigns(),
                )
              else if (campaignProvider.campaigns.isEmpty)
                const EmptyState(
                  icon: Icons.volunteer_activism,
                  title: 'Chưa có chiến dịch nào',
                  subtitle: 'Hãy là người đầu tiên tạo chiến dịch!',
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: campaignProvider.campaigns.take(5).length,
                  itemBuilder: (context, index) {
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
                ),

              const SizedBox(height: 24),

              // Admin quick actions
              if (authProvider.canManageCampaigns) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text(
                    'Quản lý',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.dashboard, size: 18),
                        label: const Text('Dashboard'),
                        onPressed: () => context.push('/admin'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.manage_accounts, size: 18),
                        label: const Text('Điều phối'),
                        onPressed: () => context.push('/coordinator'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.assessment, size: 18),
                        label: const Text('Báo cáo'),
                        onPressed: () => context.push('/report'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
