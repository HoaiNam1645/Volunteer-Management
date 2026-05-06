import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/auth_provider.dart';

class CompetencyProfileScreen extends StatefulWidget {
  const CompetencyProfileScreen({super.key});

  @override
  State<CompetencyProfileScreen> createState() => _CompetencyProfileScreenState();
}

class _CompetencyProfileScreenState extends State<CompetencyProfileScreen> {
  final UserRepository _repo = UserRepository();
  final TextEditingController _newSkillController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _creatingSkill = false;
  String? _skillCreateError;

  // Profile data
  String _name = '';
  String _email = '';
  String? _avatar;
  final List<int> _skills = [];
  final List<int> _regions = [];
  final List<String> _availability = [];
  String _timePreference = 'linh_hoat';
  final List<_ExperienceDraft> _experiences = [];
  final List<_CertificateDraft> _certificates = [];

  // Catalogs
  List<Skill> _availableSkills = [];
  List<RegionItem> _availableRegions = [];

  static const _weekDays = [
    {'value': 'thu_hai', 'label': 'Thứ Hai'},
    {'value': 'thu_ba', 'label': 'Thứ Ba'},
    {'value': 'thu_tu', 'label': 'Thứ Tư'},
    {'value': 'thu_nam', 'label': 'Thứ Năm'},
    {'value': 'thu_sau', 'label': 'Thứ Sáu'},
    {'value': 'thu_bay', 'label': 'Thứ Bảy'},
    {'value': 'chu_nhat', 'label': 'Chủ Nhật'},
  ];

  static const _timePrefs = [
    {'value': 'sang', 'label': 'Buổi sáng'},
    {'value': 'chieu', 'label': 'Buổi chiều'},
    {'value': 'toi', 'label': 'Buổi tối'},
    {'value': 'ca_ngay', 'label': 'Cả ngày'},
    {'value': 'linh_hoat', 'label': 'Linh hoạt'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _newSkillController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _repo.getSkills(),
      _repo.getRegions(),
      _repo.getCompetencyProfile(),
    ]);
    final skillsRes = results[0] as SkillListResult;
    final regionsRes = results[1] as RegionListResult;
    final profileRes = results[2] as CompetencyResult;

    if (skillsRes.success) _availableSkills = skillsRes.skills;
    if (regionsRes.success) _availableRegions = regionsRes.regions;
    if (profileRes.success && profileRes.profile != null) {
      final p = profileRes.profile!;
      _name = p.hoTen;
      _email = p.email;
      _avatar = p.anhDaiDien;
      _skills
        ..clear()
        ..addAll(p.kyNangIds);
      _regions
        ..clear()
        ..addAll(p.khuVucIds);
      _availability
        ..clear()
        ..addAll(p.lichRanh);
      _timePreference = p.khungGioUuTien;
      _experiences
        ..clear()
        ..addAll(p.kinhNghiems.map(_ExperienceDraft.fromItem));
      _certificates
        ..clear()
        ..addAll(p.chungChis.map(_CertificateDraft.fromItem));
    }
    if (mounted) setState(() => _loading = false);
  }

  bool get _canManageProfile {
    final user = context.read<AuthProvider>().currentUser;
    return user?.hasPermission('competency_profile.manage') ?? false;
  }

  int get _profileCompletion {
    int score = 0;
    if (_skills.isNotEmpty) score += 25;
    if (_regions.isNotEmpty) score += 25;
    if (_availability.isNotEmpty) score += 20;
    if (_experiences.isNotEmpty) score += 20;
    if (_certificates.isNotEmpty) score += 10;
    return score;
  }

  List<String> get _incompleteSections {
    final hints = <String>[];
    if (_skills.isEmpty) hints.add('Thêm kỹ năng');
    if (_regions.isEmpty) hints.add('Chọn khu vực hoạt động');
    if (_availability.isEmpty) hints.add('Chọn thời gian rảnh');
    if (_experiences.isEmpty) hints.add('Thêm kinh nghiệm');
    if (_certificates.isEmpty) hints.add('Thêm chứng chỉ');
    return hints;
  }

  void _toggleSkill(int id) {
    setState(() {
      if (_skills.contains(id)) {
        _skills.remove(id);
      } else {
        _skills.add(id);
      }
    });
  }

  void _toggleRegion(int id) {
    setState(() {
      if (_regions.contains(id)) {
        _regions.remove(id);
      } else {
        _regions.add(id);
      }
    });
  }

  void _toggleAvailability(String value) {
    setState(() {
      if (_availability.contains(value)) {
        _availability.remove(value);
      } else {
        _availability.add(value);
      }
    });
  }

  Future<void> _createSkillFromInput() async {
    final name = _newSkillController.text.trim();
    if (name.isEmpty) {
      setState(() => _skillCreateError = 'Vui lòng nhập tên kỹ năng cần thêm.');
      return;
    }
    setState(() {
      _creatingSkill = true;
      _skillCreateError = null;
    });
    final res = await _repo.createSkill(name);
    if (!mounted) return;
    if (res.success && res.skill != null) {
      final newSkill = res.skill!;
      final idx = _availableSkills.indexWhere((s) => s.id == newSkill.id);
      if (idx >= 0) {
        _availableSkills[idx] = newSkill;
      } else {
        _availableSkills.add(newSkill);
      }
      _availableSkills.sort((a, b) => a.ten.compareTo(b.ten));
      if (!_skills.contains(newSkill.id)) _skills.add(newSkill.id);
      _newSkillController.clear();
      setState(() => _creatingSkill = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm kỹ năng mới'), backgroundColor: Colors.green),
      );
    } else {
      setState(() {
        _creatingSkill = false;
        _skillCreateError = res.message ?? 'Không thể thêm kỹ năng mới.';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_canManageProfile) return;
    setState(() => _saving = true);
    final res = await _repo.updateCompetencyProfile(
      kyNangIds: _skills,
      khuVucIds: _regions,
      lichRanh: _availability,
      khungGioUuTien: _timePreference,
      kinhNghiems: _experiences
          .where((e) => e.title.text.trim().isNotEmpty)
          .map((e) => ExperienceItem(
                tieuDe: e.title.text.trim(),
                toChuc: e.org.text.trim(),
                thoiGian: e.period.text.trim(),
                moTa: e.desc.text.trim(),
              ))
          .toList(),
      chungChis: _certificates
          .where((c) => c.name.text.trim().isNotEmpty)
          .map((c) => CertificateItem(
                ten: c.name.text.trim(),
                donViCap: c.issuer.text.trim(),
              ))
          .toList(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.success ? (res.message ?? 'Cập nhật thành công') : (res.message ?? 'Lỗi lưu hồ sơ')),
        backgroundColor: res.success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Hồ sơ năng lực'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton.icon(
              onPressed: (_canManageProfile && !_saving) ? _saveProfile : null,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save, size: 18),
              label: Text(_saving ? 'Đang lưu...' : 'Lưu thay đổi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 16),
                  _buildSkillsCard(),
                  const SizedBox(height: 16),
                  _buildExperienceCard(),
                  const SizedBox(height: 16),
                  _buildCertificateCard(),
                  const SizedBox(height: 16),
                  _buildRegionCard(),
                  const SizedBox(height: 16),
                  _buildAvailabilityCard(),
                  const SizedBox(height: 16),
                  _buildSummaryCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _sectionCard({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: child,
      );

  Widget _buildHeaderCard() {
    return _sectionCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                  backgroundImage: (_avatar != null && _avatar!.isNotEmpty) ? NetworkImage(_avatar!) : null,
                  child: (_avatar == null || _avatar!.isEmpty)
                      ? const Icon(Icons.person, color: AppTheme.primaryColor)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(_email, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Mức độ hoàn thiện', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: LinearProgressIndicator(
                            value: _profileCompletion / 100,
                            backgroundColor: Colors.grey[200],
                            color: _profileCompletion >= 80 ? Colors.green : Colors.orange,
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('$_profileCompletion%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _profileCompletion >= 80 ? Colors.green : Colors.orange,
                            )),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (_incompleteSections.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _incompleteSections
                    .map((h) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 12, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(h, style: const TextStyle(fontSize: 11, color: Colors.orange)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cardHeader(IconData icon, Color color, String title, {Widget? trailing}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
            if (trailing != null) trailing,
          ],
        ),
      );

  Widget _buildSkillsCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.build, AppTheme.primaryColor, 'Kỹ năng'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chọn các kỹ năng bạn có để gợi ý chiến dịch phù hợp.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableSkills.map((s) {
                    final selected = _skills.contains(s.id);
                    return FilterChip(
                      label: Text(s.ten),
                      selected: selected,
                      onSelected: _canManageProfile ? (_) => _toggleSkill(s.id) : null,
                      selectedColor: AppTheme.primaryColor,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kỹ năng khác', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newSkillController,
                              onSubmitted: (_) => _createSkillFromInput(),
                              decoration: InputDecoration(
                                hintText: 'Nhập kỹ năng để thêm mới',
                                isDense: true,
                                border: const OutlineInputBorder(),
                                errorText: _skillCreateError,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: (_canManageProfile && !_creatingSkill) ? _createSkillFromInput : null,
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                            child: _creatingSkill
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.add, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Nhập kỹ năng chưa có rồi bấm thêm để tạo mới và chọn luôn.',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            Icons.work_outline,
            Colors.green,
            'Kinh nghiệm',
            trailing: TextButton.icon(
              onPressed: () => setState(() => _experiences.add(_ExperienceDraft.empty())),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Thêm'),
            ),
          ),
          if (_experiences.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Chưa có kinh nghiệm', style: TextStyle(color: Colors.grey))),
            )
          else
            ..._experiences.asMap().entries.map((entry) => _buildExperienceItem(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildExperienceItem(int idx, _ExperienceDraft exp) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.favorite, color: Colors.green, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: exp.editing
                ? Column(
                    children: [
                      TextField(
                        controller: exp.title,
                        decoration: const InputDecoration(labelText: 'Vị trí / hoạt động', isDense: true, border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: exp.org,
                        decoration: const InputDecoration(labelText: 'Tổ chức', isDense: true, border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: exp.period,
                        decoration: const InputDecoration(labelText: 'Thời gian', isDense: true, border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: exp.desc,
                        decoration: const InputDecoration(labelText: 'Mô tả', isDense: true, border: OutlineInputBorder()),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => exp.editing = false),
                          icon: const Icon(Icons.check, size: 14),
                          label: const Text('Xong'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exp.title.text.isEmpty ? '(chưa đặt tên)' : exp.title.text,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${exp.org.text} · ${exp.period.text}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      if (exp.desc.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(exp.desc.text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                        ),
                    ],
                  ),
          ),
          if (!exp.editing)
            IconButton(
              icon: const Icon(Icons.edit, size: 16),
              onPressed: () => setState(() => exp.editing = true),
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.red),
            onPressed: () => setState(() => _experiences.removeAt(idx)),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            Icons.workspace_premium,
            Colors.orange,
            'Chứng chỉ',
            trailing: TextButton.icon(
              onPressed: () => setState(() => _certificates.add(_CertificateDraft.empty())),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Thêm'),
            ),
          ),
          if (_certificates.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Chưa có chứng chỉ', style: TextStyle(color: Colors.grey))),
            )
          else
            ..._certificates.asMap().entries.map((entry) => _buildCertificateItem(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildCertificateItem(int idx, _CertificateDraft cert) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.emoji_events, color: Colors.orange, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: cert.editing
                ? Column(
                    children: [
                      TextField(
                        controller: cert.name,
                        decoration: const InputDecoration(labelText: 'Tên chứng chỉ', isDense: true, border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: cert.issuer,
                        decoration: const InputDecoration(labelText: 'Đơn vị cấp', isDense: true, border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => cert.editing = false),
                          icon: const Icon(Icons.check, size: 14),
                          label: const Text('Xong'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cert.name.text.isEmpty ? '(chưa đặt tên)' : cert.name.text,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (cert.issuer.text.isNotEmpty)
                        Text(cert.issuer.text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
          ),
          if (!cert.editing)
            IconButton(
              icon: const Icon(Icons.edit, size: 16),
              onPressed: () => setState(() => cert.editing = true),
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.red),
            onPressed: () => setState(() => _certificates.removeAt(idx)),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.location_on, Colors.red, 'Khu vực hoạt động'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chọn khu vực bạn muốn tham gia chiến dịch.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableRegions.map((r) {
                    final selected = _regions.contains(r.id);
                    return FilterChip(
                      label: Text(r.ten),
                      selected: selected,
                      onSelected: _canManageProfile ? (_) => _toggleRegion(r.id) : null,
                      selectedColor: Colors.red,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontSize: 12,
                      ),
                      avatar: Icon(Icons.location_on,
                          size: 14, color: selected ? Colors.white : Colors.red),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.event_available, Colors.blue, 'Thời gian rảnh'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chọn các ngày trong tuần bạn có thể tham gia.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 12),
                ..._weekDays.map((d) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(d['label']!, style: const TextStyle(fontSize: 13)),
                      value: _availability.contains(d['value']),
                      onChanged: _canManageProfile ? (_) => _toggleAvailability(d['value']!) : null,
                      controlAffinity: ListTileControlAffinity.leading,
                    )),
                const Divider(),
                const Text('Khung giờ ưu tiên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _timePreference,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  items: _timePrefs
                      .map((t) => DropdownMenuItem(
                            value: t['value'],
                            child: Text(t['label']!),
                          ))
                      .toList(),
                  onChanged: _canManageProfile
                      ? (v) {
                          if (v != null) setState(() => _timePreference = v);
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final summaryRow = (String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Tổng quan hồ sơ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          summaryRow('Kỹ năng', '${_skills.length} / ${_availableSkills.length}'),
          summaryRow('Kinh nghiệm', '${_experiences.length} hoạt động'),
          summaryRow('Khu vực', '${_regions.length} khu vực'),
          summaryRow('Lịch rảnh', '${_availability.length} ngày/tuần'),
          summaryRow('Chứng chỉ', _certificates.length.toString()),
        ],
      ),
    );
  }
}

class _ExperienceDraft {
  final TextEditingController title;
  final TextEditingController org;
  final TextEditingController period;
  final TextEditingController desc;
  bool editing;

  _ExperienceDraft({
    required this.title,
    required this.org,
    required this.period,
    required this.desc,
    this.editing = false,
  });

  factory _ExperienceDraft.empty() => _ExperienceDraft(
        title: TextEditingController(),
        org: TextEditingController(),
        period: TextEditingController(),
        desc: TextEditingController(),
        editing: true,
      );

  factory _ExperienceDraft.fromItem(ExperienceItem e) => _ExperienceDraft(
        title: TextEditingController(text: e.tieuDe),
        org: TextEditingController(text: e.toChuc ?? ''),
        period: TextEditingController(text: e.thoiGian ?? ''),
        desc: TextEditingController(text: e.moTa ?? ''),
      );
}

class _CertificateDraft {
  final TextEditingController name;
  final TextEditingController issuer;
  bool editing;

  _CertificateDraft({required this.name, required this.issuer, this.editing = false});

  factory _CertificateDraft.empty() => _CertificateDraft(
        name: TextEditingController(),
        issuer: TextEditingController(),
        editing: true,
      );

  factory _CertificateDraft.fromItem(CertificateItem c) => _CertificateDraft(
        name: TextEditingController(text: c.ten),
        issuer: TextEditingController(text: c.donViCap ?? ''),
      );
}
