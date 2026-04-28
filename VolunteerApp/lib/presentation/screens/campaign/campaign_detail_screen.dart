import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/campaign_model.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/registration_provider.dart';
import '../../widgets/common_widgets.dart';

class CampaignDetailScreen extends StatefulWidget {
  final int campaignId;

  const CampaignDetailScreen({
    super.key,
    required this.campaignId,
  });

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CampaignProvider>().loadCampaignDetail(widget.campaignId);
    });
  }

  @override
  void dispose() {
    context.read<CampaignProvider>().clearSelectedCampaign();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Đăng ký tham gia',
        content: 'Bạn có chắc muốn đăng ký tham gia chiến dịch này?',
        confirmText: 'Đăng ký',
      ),
    );

    if (result == true && mounted) {
      final regProvider = context.read<RegistrationProvider>();
      final success = await regProvider.register(campaignId: widget.campaignId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Đăng ký thành công!'
                  : regProvider.error ?? 'Đăng ký thất bại',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaignProvider = context.watch<CampaignProvider>();
    final campaign = campaignProvider.selectedCampaign;

    return Scaffold(
      body: campaignProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : campaign == null
              ? ErrorDisplay(
                  message: campaignProvider.error ?? 'Không tìm thấy chiến dịch',
                  onRetry: () =>
                      campaignProvider.loadCampaignDetail(widget.campaignId),
                )
              : CustomScrollView(
                  slivers: [
                    _buildAppBar(campaign),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusBadge(campaign),
                            const SizedBox(height: 12),
                            Text(
                              campaign.tenChienDich,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              Icons.location_on,
                              campaign.diaDiem,
                            ),
                            if (campaign.viDo != null && campaign.kinhDo != null)
                              _buildInfoRow(
                                Icons.map,
                                'Lat: ${campaign.viDo}, Lng: ${campaign.kinhDo}',
                              ),
                            _buildInfoRow(
                              Icons.calendar_today,
                              DateTimeUtils.formatCampaignDate(
                                campaign.ngayBatDau,
                                campaign.ngayKetThuc,
                              ),
                            ),
                            _buildInfoRow(
                              Icons.people,
                              '${campaign.soLuongHienTai}/${campaign.soLuongToiDa} người',
                            ),
                            if (campaign.hanDangKy != null)
                              _buildInfoRow(
                                Icons.schedule,
                                'Hạn đăng ký: ${DateTimeUtils.formatDeadline(campaign.hanDangKy)}',
                              ),
                            const SizedBox(height: 24),
                            const Text(
                              'Mô tả',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              campaign.moTa,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[800],
                                height: 1.5,
                              ),
                            ),
                            if (campaign.moTaAnToan != null) ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.health_and_safety,
                                        color: Colors.green[700]),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Phương án an toàn',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(campaign.moTaAnToan!),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: campaign != null && _canRegister(campaign)
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _handleRegister,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Đăng ký tham gia'),
              ),
            )
          : null,
    );
  }

  Widget _buildAppBar(Campaign campaign) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      leading: IconButton(
        icon: const CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.arrow_back, color: Colors.black),
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: campaign.anhBia != null
            ? CachedNetworkImage(
                imageUrl: campaign.anhBia!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[200]),
                errorWidget: (_, __, ___) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.volunteer_activism,
          size: 64,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Campaign campaign) {
    Color color;
    switch (campaign.trangThai) {
      case 'da_duyet':
        color = AppTheme.successColor;
        break;
      case 'cho_duyet':
        color = AppTheme.warningColor;
        break;
      case 'dang_dien_ra':
        color = AppTheme.primaryColor;
        break;
      case 'tu_choi':
        color = AppTheme.errorColor;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        campaign.statusDisplayName,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canRegister(Campaign campaign) {
    return campaign.trangThai == 'da_duyet' &&
        !campaign.isFull &&
        campaign.isRegistrationOpen;
  }
}
