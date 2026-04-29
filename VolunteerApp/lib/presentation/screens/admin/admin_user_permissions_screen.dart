import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/admin_repository.dart';

class AdminUserPermissionsScreen extends StatefulWidget {
  const AdminUserPermissionsScreen({super.key});

  @override
  State<AdminUserPermissionsScreen> createState() =>
      _AdminUserPermissionsScreenState();
}

class _AdminUserPermissionsScreenState
    extends State<AdminUserPermissionsScreen> {
  final AdminRepository _repo = AdminRepository();

  bool _isLoading = false;
  int? _savingUserId;
  Timer? _searchDebounce;

  List<PermissionUser> _allUsers = [];
  List<PermissionUser> _users = [];
  static const int _pageSize = 20;
  int _currentPage = 1;
  int _lastPage = 1;

  String _searchQuery = '';
  String _filterMode = '';

  final Map<String, List<String>> _permissionGroups = {
    'Account Center': ['account_center.view', 'account_center.manage'],
    'Competency Profile': [
      'competency_profile.view',
      'competency_profile.manage',
    ],
    'Volunteer Campaigns': [
      'volunteer_campaigns.view',
      'volunteer_campaigns.manage',
    ],
    'Campaign Coordination': [
      'campaign_coordination.view',
      'campaign_coordination.manage',
    ],
    'Campaign Report Monitoring': [
      'campaign_report_monitoring.view',
      'campaign_report_monitoring.manage',
    ],
    'Feedback Tracking': ['feedback_tracking.view', 'feedback_tracking.manage'],
    'Campaign Participation': [
      'campaign_participation.view',
      'campaign_participation.manage',
    ],
    'AI Recommendation': ['ai_recommendation.view', 'ai_recommendation.manage'],
  };

  final Map<String, List<String>> _draftPermissions = {};
  final Map<String, List<String>> _originalPermissions = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadUsers({int page = 1}) async {
    setState(() => _isLoading = true);
    final result = await _repo.getPermissionUsers(
      search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
      vaiTro: 'tinh_nguyen_vien',
      cheDoQuyen: _filterMode.isNotEmpty ? _filterMode : null,
      phamVi: 'user',
    );

    if (!mounted) return;

    if (result.success) {
      _allUsers = result.data ?? [];
      _lastPage = (_allUsers.length / _pageSize).ceil();
      if (_lastPage < 1) _lastPage = 1;
      _currentPage = page.clamp(1, _lastPage);
      _users = _sliceCurrentPage();

      _draftPermissions.clear();
      _originalPermissions.clear();
      for (final user in _users) {
        final cloned = List<String>.from(user.quyenHan);
        _draftPermissions[user.id.toString()] = cloned;
        _originalPermissions[user.id.toString()] = List<String>.from(cloned);
      }
    } else {
      _allUsers = [];
      _users = [];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Khong tai duoc du lieu'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  List<PermissionUser> _sliceCurrentPage() {
    final start = (_currentPage - 1) * _pageSize;
    if (start >= _allUsers.length) return const [];
    final end = (start + _pageSize).clamp(0, _allUsers.length);
    return _allUsers.sublist(start, end);
  }

  bool _isDirty(PermissionUser user) {
    final key = user.id.toString();
    final draft = (_draftPermissions[key] ?? const <String>[]).toSet();
    final original = (_originalPermissions[key] ?? const <String>[]).toSet();
    return draft.length != original.length || !draft.containsAll(original);
  }

  void _togglePermission(String userKey, String permission, bool enabled) {
    final draft =
        List<String>.from(_draftPermissions[userKey] ?? const <String>[]);
    if (enabled) {
      if (!draft.contains(permission)) draft.add(permission);
    } else {
      draft.remove(permission);
    }
    setState(() => _draftPermissions[userKey] = draft);
  }

  void _togglePermissionGroup(
    String userKey,
    List<String> permissions,
    bool enabled,
  ) {
    final draft =
        List<String>.from(_draftPermissions[userKey] ?? const <String>[]);
    for (final p in permissions) {
      if (enabled) {
        if (!draft.contains(p)) draft.add(p);
      } else {
        draft.remove(p);
      }
    }
    setState(() => _draftPermissions[userKey] = draft);
  }

  void _resetToDefault(PermissionUser user) {
    setState(() => _draftPermissions[user.id.toString()] = <String>[]);
  }

  Future<void> _savePermissions(PermissionUser user) async {
    setState(() => _savingUserId = user.id);
    final draft = _draftPermissions[user.id.toString()] ?? const <String>[];
    final result = await _repo.updatePermission(
      id: user.id,
      permissions: draft,
      phamVi: 'user',
      suDungMacDinh: draft.isEmpty,
    );

    if (!mounted) return;

    if (result.success) {
      _originalPermissions[user.id.toString()] = List<String>.from(draft);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Da luu quyen'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Luu that bai'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _savingUserId = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadUsers,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildFilters()),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_users.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('Khong co du lieu')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                  sliver: SliverList.builder(
                    itemCount: _users.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _users.length) return _buildPagination();
                      return _buildUserCard(_users[index]);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final total = _allUsers.length;
    final defaultCount = _allUsers.where((u) => u.suDungMacDinh).length;
    final customCount = _allUsers.where((u) => !u.suDungMacDinh).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF3B6DE7)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phan quyen tinh nguyen vien',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tong: $total | Mac dinh: $defaultCount | Tuy chinh: $customCount',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Tim theo ten/email',
                ),
                onChanged: (v) {
                  _searchQuery = v;
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(
                    const Duration(milliseconds: 350),
                    () => _loadUsers(page: 1),
                  );
                },
                onSubmitted: (_) => _loadUsers(page: 1),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _filterMode.isEmpty ? null : _filterMode,
                decoration: const InputDecoration(labelText: 'Che do'),
                items: const [
                  DropdownMenuItem(value: 'mac_dinh', child: Text('Mac dinh')),
                  DropdownMenuItem(
                      value: 'tuy_chinh', child: Text('Tuy chinh')),
                ],
                onChanged: (v) => _filterMode = v ?? '',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _loadUsers(page: 1),
                      child: const Text('Ap dung'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _filterMode = '';
                        });
                        _loadUsers(page: 1);
                      },
                      child: const Text('Dat lai'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(PermissionUser user) {
    final userKey = user.id.toString();
    final draft = _draftPermissions[userKey] ?? const <String>[];
    final dirty = _isDirty(user);
    final saving = _savingUserId == user.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(user.hoTen),
        subtitle: Text(
          '${user.email}\n${user.suDungMacDinh ? 'mac dinh' : 'tuy chinh'}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          for (final entry in _permissionGroups.entries)
            _buildPermissionGroup(entry.key, entry.value, user, draft),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      user.suDungMacDinh ? null : () => _resetToDefault(user),
                  child: const Text('Reset mac dinh'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: (!dirty || saving || user.suDungMacDinh)
                      ? null
                      : () => _savePermissions(user),
                  child: saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Luu thay doi'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionGroup(
    String group,
    List<String> permissions,
    PermissionUser user,
    List<String> draft,
  ) {
    final hasAll = permissions.every(draft.contains);
    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    group,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Checkbox(
                  value: hasAll,
                  onChanged: user.suDungMacDinh
                      ? null
                      : (v) => _togglePermissionGroup(
                            user.id.toString(),
                            permissions,
                            v == true,
                          ),
                ),
              ],
            ),
            for (final permission in permissions)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(permission, style: const TextStyle(fontSize: 12)),
                value: draft.contains(permission),
                onChanged: user.suDungMacDinh
                    ? null
                    : (v) => _togglePermission(
                        user.id.toString(), permission, v == true),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (_lastPage <= 1) return const SizedBox(height: 12);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _currentPage > 1
                  ? () => _loadUsers(page: _currentPage - 1)
                  : null,
              child: const Text('Trang truoc'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('$_currentPage/$_lastPage'),
          ),
          Expanded(
            child: OutlinedButton(
              onPressed: _currentPage < _lastPage
                  ? () => _loadUsers(page: _currentPage + 1)
                  : null,
              child: const Text('Trang sau'),
            ),
          ),
        ],
      ),
    );
  }
}
