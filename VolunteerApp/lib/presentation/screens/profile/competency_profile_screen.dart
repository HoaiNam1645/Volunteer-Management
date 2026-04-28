import 'package:flutter/material.dart';

class CompetencyProfileScreen extends StatelessWidget {
  const CompetencyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ năng lực'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skills section
            _SectionHeader(
              title: 'Kỹ năng',
              actionLabel: 'Thêm',
              onAction: () => _showAddSkillDialog(context),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SkillChip(label: 'Giao tiếp', onDelete: () {}),
                _SkillChip(label: 'Tổ chức sự kiện', onDelete: () {}),
                _SkillChip(label: 'First Aid', onDelete: () {}),
              ],
            ),

            const SizedBox(height: 24),

            // Certificates section
            _SectionHeader(
              title: 'Chứng chỉ',
              actionLabel: 'Thêm',
              onAction: () => _showAddCertDialog(context),
            ),
            const SizedBox(height: 12),
            _CertificateCard(
              name: 'Chứng chỉ sơ cấp cứu',
              issuer: 'Hội Chữ thập đỏ',
              expiry: '12/2027',
            ),
            const SizedBox(height: 8),
            _CertificateCard(
              name: 'Chứng chỉ PCCC',
              issuer: 'Công an TP.HCM',
              expiry: '06/2026',
            ),

            const SizedBox(height: 24),

            // Experience section
            _SectionHeader(
              title: 'Kinh nghiệm',
              actionLabel: 'Thêm',
              onAction: () => _showAddExperienceDialog(context),
            ),
            const SizedBox(height: 12),
            _ExperienceCard(
              position: 'Tình nguyện viên',
              organization: 'Hội Chữ thập đỏ TP.HCM',
              period: '2022 - Hiện tại',
              description: 'Tham gia các chiến dịch hiến máu nhân đạo',
            ),
            const SizedBox(height: 8),
            _ExperienceCard(
              position: 'Điều phối viên sự kiện',
              organization: 'CLB Thiện nguyện青年',
              period: '2021 - 2022',
              description: 'Tổ chức và điều phối các hoạt động tình nguyện',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSkillDialog(BuildContext context) {
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
              'Thêm kỹ năng',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Tên kỹ năng',
                hintText: 'VD: Giao tiếp, Nấu ăn...',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Thêm'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddCertDialog(BuildContext context) {
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
              'Thêm chứng chỉ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Tên chứng chỉ'),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Cơ quan cấp'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Thêm'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddExperienceDialog(BuildContext context) {
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
              'Thêm kinh nghiệm',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Vị trí'),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Tổ chức'),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Mô tả'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Thêm'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add, size: 18),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;

  const _SkillChip({required this.label, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onDelete,
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final String name;
  final String issuer;
  final String? expiry;

  const _CertificateCard({
    required this.name,
    required this.issuer,
    this.expiry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.workspace_premium),
        ),
        title: Text(name),
        subtitle: Text('$issuer${expiry != null ? ' • Hết hạn: $expiry' : ''}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () {},
        ),
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  final String position;
  final String organization;
  final String period;
  final String? description;

  const _ExperienceCard({
    required this.position,
    required this.organization,
    required this.period,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        position,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        organization,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        period,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {},
                ),
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(description!),
            ],
          ],
        ),
      ),
    );
  }
}
