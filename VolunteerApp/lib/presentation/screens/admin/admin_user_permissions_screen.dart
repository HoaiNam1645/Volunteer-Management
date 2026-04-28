import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/admin_repository.dart';

class AdminUserPermissionsScreen extends StatefulWidget {
  const AdminUserPermissionsScreen({super.key});

  @override
  State<AdminUserPermissionsScreen> createState() => _AdminUserPermissionsScreenState();
}

class _AdminUserPermissionsScreenState extends State<AdminUserPermissionsScreen> {
  final AdminRepository _repo = AdminRepository();

  bool _isLoading = false;
  bool _isSaving = false;
  int? _savingUserId;

  List<PermissionUser> _users = [];
  String _searchQuery = '';
  String _filterMode = '';

  final Map<String, List<String>> _permissionGroups = {
    'Account Center': ['account_center.view', 'account_center.manage'],
    'Competency Profile': ['competency_profile.view', 'competency_profile.manage'],
    'Volunteer Campaigns': ['volunteer_campaigns.view', 'volunteer_campaigns.manage'],
    'Campaign Coordination': ['campaign_coordination.view', 'campaign_coordination.manage'],
    'Campaign Report Monitoring': ['campaign_report_monitoring.view', 'campaign_report_monitoring.manage'],
    'Feedback Tracking': ['feedback_tracking.view', 'feedback_tracking.manage'],
    'Campaign Participation': ['campaign_participation.view', 'campaign_participation.manage'],
    'AI Recommendation': ['ai_recommendation.view', 'ai_recommendation.manage'],
  };

  final Map<String, List<String>> _draftPermissions = {};

  int get _totalUsers => _users.length;
  int get _volunteerCount => _users.where((u) => u.vaiTro == 'tinh_nguyen_vien').length;
  int get _defaultCount => _users.where((u) => u.suDungMacDinh).length;
  int get _customCount => _users.where((u) => !u.suDungMacDinh).length;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final result = await _repo.getPermissionUsers(search: _searchQuery.isNotEmpty ? _searchQuery : null);
      if (mounted) {
        if (result.success && result.data != null) {
          setState(() {
            _users = result.data!.where((u) => u.vaiTro == 'tinh_nguyen_vien').toList();
            _draftPermissions.clear();
            for (final user in _users) {
              _draftPermissions[user.id.toString()] = List.from(user.quyenHan);
            }
          });
        } else {
          _showError(result.message ?? 'Không tải được dữ liệu');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccess(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green),
      );
    }
  }

  List<PermissionUser> get _filteredUsers {
    return _users.where((u) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!u.hoTen.toLowerCase().contains(q) && !u.email.toLowerCase().contains(q)) return false;
      }
      if (_filterMode == 'mac_dinh' && !u.suDungMacDinh) return false;
      if (_filterMode == 'tuy_chinh' && u.suDungMacDinh) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsGrid(isWide),
                    const SizedBox(height: 16),
                    _buildLegend(),
                    const SizedBox(height: 12),
                    _buildFilters(isWide),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filteredUsers.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volunteer_activism, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('Không tìm thấy tình nguyện viên nào',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildUserCard(_filteredUsers[index]),
                    childCount: _filteredUsers.length,
                  ),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF3B6DE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_pin, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Phân quyền TNV',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Quản lý quyền hạn tình nguyện viên',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(bool isWide) {
    final stats = [
      ('Tổng TNV', _totalUsers.toString(), Icons.people, Colors.blue),
      ('Mặc định', _defaultCount.toString(), Icons.settings, Colors.grey),
      ('Tùy chỉnh', _customCount.toString(), Icons.tune, Colors.orange),
    ];

    if (isWide) {
      return Row(
        children: stats
            .map((s) => Expanded(child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildStatCard(s.$1, s.$2, s.$3, s.$4),
                )))
            .toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: stats.map((s) => _buildStatCard(s.$1, s.$2, s.$3, s.$4)).toList(),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem('Mặc định', Colors.grey[400]!),
          _buildLegendItem('Tùy chỉnh', Colors.green),
          _buildLegendItem('Đã lưu', AppTheme.primaryColor),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
    );
  }

  Widget _buildFilters(bool isWide) {
    if (isWide) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildSearchField(),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildModeFilter()),
            const SizedBox(width: 12),
            _buildResetButton(),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchField(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildModeFilter()),
              const SizedBox(width: 12),
              _buildResetButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (v) => setState(() => _searchQuery = v),
      decoration: InputDecoration(
        hintText: 'Tìm kiếm...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildModeFilter() {
    return DropdownButtonFormField<String>(
      value: _filterMode.isEmpty ? null : _filterMode,
      decoration: InputDecoration(
        labelText: 'Chế độ',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: const [
        DropdownMenuItem(value: '', child: Text('Tất cả')),
        DropdownMenuItem(value: 'mac_dinh', child: Text('Mặc định')),
        DropdownMenuItem(value: 'tuy_chinh', child: Text('Tùy chỉnh')),
      ],
      onChanged: (v) => setState(() => _filterMode = v ?? ''),
    );
  }

  Widget _buildResetButton() {
    return OutlinedButton.icon(
      onPressed: () => setState(() {
        _searchQuery = '';
        _filterMode = '';
      }),
      icon: const Icon(Icons.refresh, size: 18),
      label: const Text('Đặt lại'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey[600],
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildUserCard(PermissionUser user) {
    final userKey = user.id.toString();
    final draft = _draftPermissions[userKey] ?? List.from(user.quyenHan);
    final isDefault = user.suDungMacDinh;
    final isDirty = !_isListEqual(List.from(user.quyenHan), draft);
    final isSavingThis = _savingUserId == user.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDirty ? Border.all(color: Colors.orange.shade300, width: 2) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.green.withValues(alpha: 0.1),
            child: Text(
              user.hoTen.isNotEmpty ? user.hoTen[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            user.hoTen,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.email,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const SizedBox(height: 4),
              _buildModeBadge(isDefault, isDirty),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDirty && !isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${draft.length} quyền',
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              const SizedBox(width: 8),
              if (isSavingThis)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              else
                const Icon(Icons.keyboard_arrow_down),
            ],
          ),
          children: [
            const Divider(),
            const SizedBox(height: 8),
            ..._permissionGroups.entries.map((entry) => _buildPermissionGroup(entry.key, entry.value, user, draft)),
            const SizedBox(height: 16),
            if (!isDefault)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isDirty) ...[
                    OutlinedButton(
                      onPressed: () => _resetToDefault(user),
                      child: const Text('Đặt lại'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  ElevatedButton(
                    onPressed: isDirty ? () => _savePermissions(user, draft) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDirty ? Colors.green : Colors.grey[300],
                    ),
                    child: Text('Lưu thay đổi', style: TextStyle(color: isDirty ? Colors.white : Colors.grey[600])),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionGroup(String label, List<String> permissions, PermissionUser user, List<String> draft) {
    final hasAll = permissions.every((p) => draft.contains(p));
    final hasAny = permissions.any((p) => draft.contains(p));
    final color = user.suDungMacDinh ? Colors.grey[400]! : (hasAny ? Colors.green : Colors.grey[300]);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            hasAll ? Icons.check_box : (hasAny ? Icons.indeterminate_check_box : Icons.check_box_outline_blank),
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: hasAny ? Colors.black87 : Colors.grey[500],
                fontWeight: hasAny ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (user.suDungMacDinh)
            Text('(mặc định)', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildModeBadge(bool isDefault, bool isDirty) {
    final label = isDefault ? 'Mặc định' : (isDirty ? 'Có thay đổi' : 'Tùy chỉnh');
    final color = isDefault ? Colors.grey[400]! : (isDirty ? Colors.orange : Colors.green);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }

  bool _isListEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sa = a.toSet();
    for (final e in b) if (!sa.contains(e)) return false;
    return true;
  }

  void _resetToDefault(PermissionUser user) {
    setState(() {
      _draftPermissions[user.id.toString()] = [];
    });
  }

  Future<void> _savePermissions(PermissionUser user, List<String> draft) async {
    setState(() => _savingUserId = user.id);
    try {
      final result = await _repo.updatePermission(
        id: user.id,
        permissions: draft,
        phamVi: 'user',
      );
      if (mounted) {
        if (result.success) {
          _showSuccess(result.message ?? 'Đã lưu quyền');
          await _loadUsers();
        } else {
          _showError(result.message ?? 'Lưu thất bại');
        }
      }
    } finally {
      if (mounted) setState(() => _savingUserId = null);
    }
  }
}
