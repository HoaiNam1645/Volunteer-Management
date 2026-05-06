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
import '../../widgets/osm_map_widget.dart';

class CampaignDetailScreen extends StatefulWidget {
  final int campaignId;

  const CampaignDetailScreen({super.key, required this.campaignId});

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  int _activeImageIndex = 0;

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

  Future<void> _refresh() => context.read<CampaignProvider>().loadCampaignDetail(widget.campaignId);

  Future<void> _doRegister() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmDialog(
        title: 'Đăng ký tham gia',
        content: 'Bạn có chắc muốn đăng ký tham gia chiến dịch này?',
        confirmText: 'Đăng ký',
      ),
    );
    if (ok != true || !mounted) return;
    final regProvider = context.read<RegistrationProvider>();
    final success = await regProvider.register(campaignId: widget.campaignId);
    _showResult(success, success ? 'Đăng ký thành công!' : (regProvider.error ?? 'Đăng ký thất bại'));
    if (success) await _refresh();
  }

  Future<void> _doConfirm() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmDialog(
        title: 'Xác nhận tham gia',
        content: 'Bạn xác nhận sẽ tham gia chiến dịch này?',
        confirmText: 'Xác nhận',
      ),
    );
    if (ok != true || !mounted) return;
    final regProvider = context.read<RegistrationProvider>();
    final success = await regProvider.confirmParticipation(widget.campaignId);
    _showResult(success, success ? 'Đã xác nhận tham gia!' : (regProvider.error ?? 'Xác nhận thất bại'));
    if (success) await _refresh();
  }

  Future<void> _doCancel() async {
    final reasonCtl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đăng ký'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng cho biết lý do hủy:', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtl,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Lý do hủy...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          ElevatedButton(
            onPressed: () {
              if (reasonCtl.text.trim().isEmpty) return;
              Navigator.pop(ctx, reasonCtl.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hủy đăng ký', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    final regProvider = context.read<RegistrationProvider>();
    final success = await regProvider.cancelRegistration(widget.campaignId, lyDoHuy: reason);
    _showResult(success, success ? 'Đã hủy đăng ký' : (regProvider.error ?? 'Hủy thất bại'));
    if (success) await _refresh();
  }

  void _showResult(bool success, String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: success ? Colors.green : Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final campaignProvider = context.watch<CampaignProvider>();
    final campaign = campaignProvider.selectedCampaign;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: campaignProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : campaign == null
              ? ErrorDisplay(
                  message: campaignProvider.error ?? 'Không tìm thấy chiến dịch',
                  onRetry: _refresh,
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    slivers: [
                      _buildAppBar(campaign),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildStatusBadge(campaign),
                                  const SizedBox(width: 8),
                                  if (campaign.loaiChienDich != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                                      child: Text(campaign.loaiChienDich!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(campaign.tenChienDich, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              if (campaign.lyDoHuy != null && campaign.lyDoHuy!.isNotEmpty) _buildCancelReasonBanner(campaign.lyDoHuy!),
                              if (campaign.dangKyHienTai != null) _buildRegistrationStatusBanner(campaign.dangKyHienTai!),
                              _buildInfoCard(campaign),
                              const SizedBox(height: 16),
                              _buildSection('Mô tả', Icons.description, [
                                Text(campaign.moTa, style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5)),
                              ]),
                              if (campaign.kyNangs != null && campaign.kyNangs!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildSection('Kỹ năng cần thiết', Icons.build, [
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: campaign.kyNangs!
                                        .map((s) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                              child: Text(s, style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                                            ))
                                        .toList(),
                                  ),
                                ]),
                              ],
                              if (campaign.viDo != null && campaign.kinhDo != null) ...[
                                const SizedBox(height: 16),
                                _buildSection('Vị trí trên bản đồ', Icons.map, [
                                  OsmMapWidget(
                                    latitude: campaign.viDo,
                                    longitude: campaign.kinhDo,
                                    height: 200,
                                    draggable: false,
                                  ),
                                ]),
                              ],
                              if (campaign.moTaAnToan != null && campaign.moTaAnToan!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildSafetyCard(campaign.moTaAnToan!),
                              ],
                              if (campaign.feedbacks.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildReviewsSection(campaign.feedbacks),
                              ],
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: campaign != null ? _buildActionBar(campaign) : null,
    );
  }

  Widget _buildAppBar(Campaign campaign) {
    final imgs = campaign.images;
    final hasImages = imgs.isNotEmpty;
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: Colors.black,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: hasImages
            ? Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: imgs.length,
                    onPageChanged: (i) => setState(() => _activeImageIndex = i),
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: imgs[i],
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey[200]),
                      errorWidget: (_, __, ___) => _buildPlaceholder(),
                    ),
                  ),
                  if (imgs.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          imgs.length,
                          (i) => Container(
                            width: i == _activeImageIndex ? 20 : 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3)),
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() => Container(
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.volunteer_activism, size: 64, color: Colors.grey)),
      );

  Widget _buildStatusBadge(Campaign campaign) {
    final color = switch (campaign.trangThai) {
      'da_duyet' => AppTheme.successColor,
      'cho_duyet' => AppTheme.warningColor,
      'dang_dien_ra' => AppTheme.primaryColor,
      'hoan_thanh' => Colors.grey,
      'da_huy' => AppTheme.errorColor,
      'tu_choi' => AppTheme.errorColor,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(campaign.statusDisplayName, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }

  Widget _buildCancelReasonBanner(String reason) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red[200]!)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cancel_outlined, color: Colors.red[700], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lý do hủy', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700], fontSize: 12)),
                const SizedBox(height: 4),
                Text(reason, style: TextStyle(color: Colors.red[800], fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationStatusBanner(Map<String, dynamic> reg) {
    final status = reg['trang_thai']?.toString() ?? '';
    final label = switch (status) {
      'da_dang_ky' => 'Bạn đã đăng ký',
      'da_xac_nhan' => 'Bạn đã xác nhận tham gia',
      'da_duyet' => 'Đăng ký của bạn đã được duyệt',
      'dang_tham_gia' => 'Bạn đang tham gia',
      'hoan_thanh' => 'Bạn đã hoàn thành chiến dịch',
      'tu_choi' => 'Đăng ký của bạn bị từ chối',
      'da_huy' => 'Bạn đã hủy đăng ký',
      _ => 'Trạng thái: $status',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3))),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Campaign campaign) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          _infoRow(Icons.location_on, 'Địa điểm', campaign.diaDiem, Colors.red),
          const Divider(height: 16),
          _infoRow(Icons.calendar_today, 'Thời gian', DateTimeUtils.formatCampaignDate(campaign.ngayBatDau, campaign.ngayKetThuc), AppTheme.primaryColor),
          if (campaign.hanDangKy != null) ...[
            const Divider(height: 16),
            _infoRow(Icons.schedule, 'Hạn đăng ký', DateTimeUtils.formatDeadline(campaign.hanDangKy), Colors.orange),
          ],
          const Divider(height: 16),
          _infoRow(
            Icons.people,
            'Số lượng',
            '${campaign.soLuongHienTai}/${campaign.soLuongToiDa} (xác nhận: ${campaign.soXacNhan})',
            Colors.green,
          ),
          if (campaign.nguoiTao != null) ...[
            const Divider(height: 16),
            _infoRow(Icons.person, 'Người điều phối', campaign.nguoiTao!.hoTen, Colors.blueGrey),
          ],
          if (campaign.viDo != null && campaign.kinhDo != null) ...[
            const Divider(height: 16),
            _infoRow(Icons.map, 'Toạ độ', '${campaign.viDo!.toStringAsFixed(5)}, ${campaign.kinhDo!.toStringAsFixed(5)}', Colors.indigo),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        SizedBox(
          width: 100,
          child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 18, color: AppTheme.primaryColor), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))]),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSafetyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green[200]!)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.health_and_safety, color: Colors.green[700], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phương án an toàn', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
                const SizedBox(height: 4),
                Text(text, style: TextStyle(fontSize: 13, color: Colors.green[900])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(List<Map<String, dynamic>> feedbacks) {
    final avgRating = feedbacks.isEmpty
        ? 0.0
        : feedbacks
                .map((f) => (f['so_sao'] is num ? (f['so_sao'] as num).toDouble() : 0.0))
                .fold<double>(0, (a, b) => a + b) /
            feedbacks.length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text('Đánh giá từ TNV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              Text('${avgRating.toStringAsFixed(1)} ★', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
              Text(' (${feedbacks.length})', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const Divider(),
          ...feedbacks.take(5).map((f) {
            final user = f['nguoi_dung'] as Map<String, dynamic>? ?? {};
            final stars = (f['so_sao'] is num ? (f['so_sao'] as num).toInt() : 0);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                        backgroundImage: user['anh_dai_dien'] != null && user['anh_dai_dien'].toString().isNotEmpty
                            ? NetworkImage(user['anh_dai_dien'].toString())
                            : null,
                        child: user['anh_dai_dien'] == null
                            ? const Icon(Icons.person, size: 14, color: AppTheme.primaryColor)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user['ho_ten']?.toString() ?? 'Ẩn danh',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(i < stars ? Icons.star : Icons.star_border, size: 12, color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                  if ((f['nhan_xet'] ?? '').toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 36),
                      child: Text(f['nhan_xet'].toString(), style: TextStyle(fontSize: 12, color: Colors.grey[800])),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget? _buildActionBar(Campaign campaign) {
    final actions = <Widget>[];
    if (campaign.coTheDangKy) {
      actions.add(_actionButton('Đăng ký tham gia', Icons.how_to_reg, AppTheme.primaryColor, _doRegister));
    }
    if (campaign.coTheXacNhan) {
      actions.add(_actionButton('Xác nhận tham gia', Icons.check_circle, Colors.green, _doConfirm));
    }
    if (campaign.coTheHuyDangKy) {
      actions.add(_actionButton('Hủy đăng ký', Icons.cancel, Colors.red, _doCancel));
    }
    if (actions.isEmpty) return null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2))]),
      child: SafeArea(
        top: false,
        child: Row(children: actions.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: w))).toList()),
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
