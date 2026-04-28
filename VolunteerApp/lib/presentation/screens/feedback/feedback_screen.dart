import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/registration_model.dart';
import '../../providers/registration_provider.dart';
import '../../widgets/common_widgets.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RegistrationProvider>().loadRegistrations(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final regProvider = context.watch<RegistrationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => regProvider.refreshRegistrations(),
        child: regProvider.isLoading && regProvider.registrations.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : regProvider.registrations.isEmpty
                ? const EmptyState(
                    icon: Icons.history,
                    title: 'Chưa có đăng ký nào',
                    subtitle: 'Đăng ký tham gia chiến dịch để bắt đầu',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: regProvider.registrations.length,
                    itemBuilder: (context, index) {
                      final reg = regProvider.registrations[index];
                      return _RegistrationCard(
                        registration: reg,
                        onCancel: reg.canCancel
                            ? () => _handleCancel(reg)
                            : null,
                        onFeedback: reg.canFeedback
                            ? () => _showFeedbackDialog(reg)
                            : null,
                      );
                    },
                  ),
      ),
    );
  }

  Future<void> _handleCancel(Registration reg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(
        title: 'Hủy đăng ký',
        content: 'Bạn có chắc muốn hủy đăng ký này?',
        confirmText: 'Hủy đăng ký',
        isDestructive: true,
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<RegistrationProvider>().cancelRegistration(reg.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Đã hủy đăng ký' : 'Hủy đăng ký thất bại'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _showFeedbackDialog(Registration reg) {
    final ratingController = ValueNotifier<int?>(null);
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đánh giá chiến dịch',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<int?>(
              valueListenable: ratingController,
              builder: (context, rating, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < (rating ?? 0) ? Icons.star : Icons.star_border,
                        size: 36,
                        color: Colors.amber,
                      ),
                      onPressed: () => ratingController.value = index + 1,
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Nhận xét (tùy chọn)',
                hintText: 'Chia sẻ trải nghiệm của bạn...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (ratingController.value == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng chọn số sao')),
                    );
                    return;
                  }
                  final success = await context.read<RegistrationProvider>().submitFeedback(
                    chienDichId: reg.chienDichId,
                    diem: ratingController.value ?? 5,
                    noiDung: commentController.text.isNotEmpty
                        ? commentController.text
                        : null,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Cảm ơn bạn đã đánh giá!' : 'Gửi đánh giá thất bại'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Gửi đánh giá'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
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
                    context.read<RegistrationProvider>().setStatusFilter(null);
                    context.read<RegistrationProvider>().loadRegistrations(refresh: true);
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Chờ xác nhận'),
                  selected: false,
                  onSelected: (_) {
                    context.read<RegistrationProvider>().setStatusFilter('cho_xac_nhan');
                    context.read<RegistrationProvider>().loadRegistrations(refresh: true);
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Đã xác nhận'),
                  selected: false,
                  onSelected: (_) {
                    context.read<RegistrationProvider>().setStatusFilter('da_xac_nhan');
                    context.read<RegistrationProvider>().loadRegistrations(refresh: true);
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Đã tham gia'),
                  selected: false,
                  onSelected: (_) {
                    context.read<RegistrationProvider>().setStatusFilter('da_tham_gia');
                    context.read<RegistrationProvider>().loadRegistrations(refresh: true);
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
}

class _RegistrationCard extends StatelessWidget {
  final Registration registration;
  final VoidCallback? onCancel;
  final VoidCallback? onFeedback;

  const _RegistrationCard({
    required this.registration,
    this.onCancel,
    this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    registration.tenChienDich ?? 'Chiến dịch #${registration.chienDichId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _StatusBadge(status: registration.trangThai),
              ],
            ),
            const SizedBox(height: 8),
            if (registration.ngayDangKy != null)
              Text(
                'Đăng ký: ${DateTimeUtils.formatDateTime(registration.ngayDangKy!)}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (onCancel != null)
                  OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Hủy'),
                  ),
                if (onCancel != null && onFeedback != null)
                  const SizedBox(width: 8),
                if (onFeedback != null)
                  ElevatedButton(
                    onPressed: onFeedback,
                    child: const Text('Đánh giá'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'cho_xac_nhan':
        color = Colors.orange;
        label = 'Chờ xác nhận';
        break;
      case 'da_xac_nhan':
        color = Colors.blue;
        label = 'Đã xác nhận';
        break;
      case 'da_tham_gia':
        color = Colors.green;
        label = 'Đã tham gia';
        break;
      case 'vo_hieu_hoa':
        color = Colors.grey;
        label = 'Đã hủy';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
