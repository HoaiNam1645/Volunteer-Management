import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/admin_repository.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminRepository _repository = AdminRepository();
  final TextEditingController _searchController = TextEditingController();

  List<AdminUser> _users = [];
  bool _isLoading = true;
  String? _error;
  String _activeTab = 'all';
  String _search = '';
  String? _selectedRole;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final tabStatus = switch (_activeTab) {
      'pending' => 'cho_duyet',
      'locked' => 'bi_khoa',
      _ => null,
    };

    final result = await _repository.getUsers(
      page: page,
      search: _search.isNotEmpty ? _search : null,
      vaiTro: _selectedRole,
      trangThai: _selectedStatus ?? tabStatus,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.success) {
        _users = result.data ?? [];
      } else {
        _error = result.message;
      }
    });
  }

  Future<void> _loadStatsTabs() async {
    final result = await _repository.getUsers(page: 1);
    if (!mounted || !result.success) return;
    setState(() {
      _users = result.data ?? [];
    });
  }

  int get _pendingCount =>
      _users.where((u) => u.trangThai == 'cho_duyet').length;
  int get _lockedCount => _users.where((u) => u.trangThai == 'bi_khoa').length;

  bool _isSelf(AdminUser user) {
    final myId = context.read<AuthProvider>().currentUser?.id;
    return myId != null && myId == user.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTabs(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tim kiem nguoi dung...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                      onSubmitted: (v) {
                        _search = v.trim();
                        _loadUsers();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                      onPressed: _showFilterDialog,
                      icon: const Icon(Icons.tune)),
                ],
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _tabChip('all', 'Tat ca (${_users.length})'),
          _tabChip('pending', 'Cho duyet ($_pendingCount)'),
          _tabChip('locked', 'Bi khoa ($_lockedCount)'),
        ],
      ),
    );
  }

  Widget _tabChip(String value, String label) {
    final selected = _activeTab == value;
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) {
        setState(() => _activeTab = value);
        _selectedStatus = null;
        _loadUsers();
      },
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            TextButton(onPressed: _loadUsers, child: const Text('Thu lai')),
          ],
        ),
      );
    }
    if (_users.isEmpty)
      return const Center(child: Text('Khong co nguoi dung nao'));

    return RefreshIndicator(
      onRefresh: () async {
        await _loadUsers();
        await _loadStatsTabs();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _users.length,
        itemBuilder: (ctx, i) => _UserCard(
          user: _users[i],
          isSelf: _isSelf(_users[i]),
          onStatusToggle: _loadUsers,
          onEdit: _showEditDialog,
          onDelete: _confirmDelete,
          onView: _showViewDialog,
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _FilterSheet(
        selectedRole: _selectedRole,
        selectedStatus: _selectedStatus,
        onApply: (role, status) {
          setState(() {
            _selectedRole = role;
            _selectedStatus = status;
          });
          _loadUsers();
        },
      ),
    );
  }

  void _showViewDialog(AdminUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thong tin nguoi dung'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ho ten: ${user.hoTen}'),
            Text('Email: ${user.email}'),
            Text('Vai tro: ${user.vaiTro}'),
            Text('Trang thai: ${user.trangThai}'),
            Text('So dien thoai: ${user.soDienThoai ?? '-'}'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Dong')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showEditDialog(user);
            },
            child: const Text('Chinh sua'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(AdminUser user) {
    showDialog(
      context: context,
      builder: (ctx) => _UserEditDialog(
        user: user,
        onSave: (hoTen, email, vaiTro, trangThai, soDienThoai) async {
          final result = await _repository.updateUser(
            id: user.id,
            hoTen: hoTen,
            email: email,
            vaiTro: vaiTro,
            soDienThoai: soDienThoai,
          );

          if (result.success && user.trangThai != trangThai) {
            await _repository.updateUserStatus(user.id, trangThai);
          }

          if (!mounted) return;
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ??
                  (result.success
                      ? 'Cap nhat thanh cong'
                      : 'Cap nhat that bai')),
              backgroundColor: result.success ? null : Colors.red,
            ),
          );
          if (result.success) _loadUsers();
        },
      ),
    );
  }

  void _confirmDelete(AdminUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xac nhan xoa'),
        content: Text('Ban co chac muon xoa nguoi dung "${user.hoTen}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Huy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _repository.deleteUser(user.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.message ??
                      (result.success ? 'Xoa thanh cong' : 'Xoa that bai')),
                  backgroundColor: result.success ? null : Colors.red,
                ),
              );
              if (result.success) _loadUsers();
            },
            child: const Text('Xoa'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _UserFormDialog(
        onSave: (hoTen, email, matKhau, vaiTro, trangThai, soDienThoai) async {
          final result = await _repository.createUser(
            hoTen: hoTen,
            email: email,
            matKhau: matKhau,
            vaiTro: vaiTro,
            soDienThoai: soDienThoai,
          );
          if (result.success &&
              result.data != null &&
              trangThai != 'hoat_dong') {
            await _repository.updateUserStatus(result.data!.id, trangThai);
          }
          if (!mounted) return;
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ??
                  (result.success ? 'Tao thanh cong' : 'Tao that bai')),
              backgroundColor: result.success ? null : Colors.red,
            ),
          );
          if (result.success) _loadUsers();
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUser user;
  final bool isSelf;
  final VoidCallback onStatusToggle;
  final void Function(AdminUser user) onEdit;
  final void Function(AdminUser user) onDelete;
  final void Function(AdminUser user) onView;

  const _UserCard({
    required this.user,
    required this.isSelf,
    required this.onStatusToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
          backgroundImage:
              user.anhDaiDien != null ? NetworkImage(user.anhDaiDien!) : null,
          child: user.anhDaiDien == null
              ? Text(user.hoTen[0].toUpperCase())
              : null,
        ),
        title: Text(user.hoTen),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 2),
            Row(
              children: [
                _RoleChip(vaiTro: user.vaiTro),
                const SizedBox(width: 8),
                _StatusChip(trangThai: user.trangThai),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
            if (action == 'view') {
              onView(user);
              return;
            }
            if (action == 'toggle_status') {
              final repo = AdminRepository();
              String newStatus = 'hoat_dong';
              if (user.trangThai == 'hoat_dong') newStatus = 'bi_khoa';
              if (user.trangThai == 'cho_duyet') newStatus = 'hoat_dong';
              final result = await repo.updateUserStatus(user.id, newStatus);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.message ?? '')));
                onStatusToggle();
              }
            } else if (action == 'edit') {
              onEdit(user);
            } else if (action == 'delete') {
              onDelete(user);
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'view', child: Text('Xem chi tiet')),
            PopupMenuItem(
              value: 'toggle_status',
              enabled: !isSelf,
              child: Text(
                user.trangThai == 'cho_duyet'
                    ? 'Duyet tai khoan'
                    : (user.trangThai == 'hoat_dong'
                        ? 'Khoa tai khoan'
                        : 'Mo khoa'),
              ),
            ),
            const PopupMenuItem(value: 'edit', child: Text('Chinh sua')),
            PopupMenuItem(
                value: 'delete', enabled: !isSelf, child: const Text('Xoa')),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String vaiTro;

  const _RoleChip({required this.vaiTro});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (vaiTro) {
      case 'quan_tri_vien':
        color = Colors.red;
        label = 'Admin';
        break;
      case 'kiem_duyet_vien':
        color = Colors.orange;
        label = 'Kiem duyet';
        break;
      default:
        color = Colors.green;
        label = 'TNV';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String trangThai;

  const _StatusChip({required this.trangThai});

  @override
  Widget build(BuildContext context) {
    final color = switch (trangThai) {
      'hoat_dong' => Colors.green,
      'cho_duyet' => Colors.orange,
      'bi_khoa' => Colors.red,
      _ => Colors.grey,
    };

    final label = switch (trangThai) {
      'hoat_dong' => 'Hoat dong',
      'cho_duyet' => 'Cho duyet',
      'bi_khoa' => 'Bi khoa',
      _ => trangThai,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final String? selectedRole;
  final String? selectedStatus;
  final void Function(String?, String?) onApply;

  const _FilterSheet(
      {this.selectedRole, this.selectedStatus, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _role;
  String? _status;

  @override
  void initState() {
    super.initState();
    _role = widget.selectedRole;
    _status = widget.selectedStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Loc nguoi dung',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Vai tro'),
            value: _role,
            items: const [
              DropdownMenuItem(value: null, child: Text('Tat ca')),
              DropdownMenuItem(
                  value: 'tinh_nguyen_vien', child: Text('Tinh nguyen vien')),
              DropdownMenuItem(
                  value: 'kiem_duyet_vien', child: Text('Kiem duyet vien')),
              DropdownMenuItem(
                  value: 'quan_tri_vien', child: Text('Quan tri vien')),
            ],
            onChanged: (v) => setState(() => _role = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Trang thai'),
            value: _status,
            items: const [
              DropdownMenuItem(value: null, child: Text('Tat ca')),
              DropdownMenuItem(value: 'hoat_dong', child: Text('Hoat dong')),
              DropdownMenuItem(value: 'cho_duyet', child: Text('Cho duyet')),
              DropdownMenuItem(value: 'bi_khoa', child: Text('Bi khoa')),
            ],
            onChanged: (v) => setState(() => _status = v),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              widget.onApply(_role, _status);
              Navigator.pop(context);
            },
            child: const Text('Ap dung'),
          ),
        ],
      ),
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  final void Function(String hoTen, String email, String matKhau, String vaiTro,
      String trangThai, String? soDienThoai) onSave;

  const _UserFormDialog({required this.onSave});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hoTenController = TextEditingController();
  final _emailController = TextEditingController();
  final _matKhauController = TextEditingController();
  final _soDtController = TextEditingController();
  String _vaiTro = 'tinh_nguyen_vien';
  String _trangThai = 'hoat_dong';

  @override
  void dispose() {
    _hoTenController.dispose();
    _emailController.dispose();
    _matKhauController.dispose();
    _soDtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tao nguoi dung'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                  controller: _hoTenController,
                  decoration: const InputDecoration(labelText: 'Ho ten *'),
                  validator: (v) => v?.isEmpty == true ? 'Bat buoc' : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v?.isEmpty == true ? 'Bat buoc' : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _matKhauController,
                  decoration: const InputDecoration(labelText: 'Mat khau *'),
                  obscureText: true,
                  validator: (v) => v?.isEmpty == true ? 'Bat buoc' : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _soDtController,
                  decoration: const InputDecoration(labelText: 'So dien thoai'),
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Vai tro *'),
                value: _vaiTro,
                items: const [
                  DropdownMenuItem(
                      value: 'tinh_nguyen_vien',
                      child: Text('Tinh nguyen vien')),
                  DropdownMenuItem(
                      value: 'kiem_duyet_vien', child: Text('Kiem duyet vien')),
                  DropdownMenuItem(
                      value: 'quan_tri_vien', child: Text('Quan tri vien')),
                ],
                onChanged: (v) =>
                    setState(() => _vaiTro = v ?? 'tinh_nguyen_vien'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Trang thai *'),
                value: _trangThai,
                items: const [
                  DropdownMenuItem(
                      value: 'hoat_dong', child: Text('Hoat dong')),
                  DropdownMenuItem(
                      value: 'cho_duyet', child: Text('Cho duyet')),
                  DropdownMenuItem(value: 'bi_khoa', child: Text('Bi khoa')),
                ],
                onChanged: (v) => setState(() => _trangThai = v ?? 'hoat_dong'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Huy')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                _hoTenController.text,
                _emailController.text,
                _matKhauController.text,
                _vaiTro,
                _trangThai,
                _soDtController.text.isNotEmpty ? _soDtController.text : null,
              );
            }
          },
          child: const Text('Tao'),
        ),
      ],
    );
  }
}

class _UserEditDialog extends StatefulWidget {
  final AdminUser user;
  final void Function(String hoTen, String email, String vaiTro,
      String trangThai, String? soDienThoai) onSave;

  const _UserEditDialog({required this.user, required this.onSave});

  @override
  State<_UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<_UserEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hoTenController;
  late final TextEditingController _emailController;
  late final TextEditingController _soDtController;
  late String _vaiTro;
  late String _trangThai;

  @override
  void initState() {
    super.initState();
    _hoTenController = TextEditingController(text: widget.user.hoTen);
    _emailController = TextEditingController(text: widget.user.email);
    _soDtController =
        TextEditingController(text: widget.user.soDienThoai ?? '');
    _vaiTro = widget.user.vaiTro;
    _trangThai = widget.user.trangThai;
  }

  @override
  void dispose() {
    _hoTenController.dispose();
    _emailController.dispose();
    _soDtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chinh sua nguoi dung'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                  controller: _hoTenController,
                  decoration: const InputDecoration(labelText: 'Ho ten *'),
                  validator: (v) => v?.isEmpty == true ? 'Bat buoc' : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v?.isEmpty == true ? 'Bat buoc' : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _soDtController,
                  decoration: const InputDecoration(labelText: 'So dien thoai'),
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Vai tro *'),
                value: _vaiTro,
                items: const [
                  DropdownMenuItem(
                      value: 'tinh_nguyen_vien',
                      child: Text('Tinh nguyen vien')),
                  DropdownMenuItem(
                      value: 'kiem_duyet_vien', child: Text('Kiem duyet vien')),
                  DropdownMenuItem(
                      value: 'quan_tri_vien', child: Text('Quan tri vien')),
                ],
                onChanged: (v) => setState(() => _vaiTro = v ?? _vaiTro),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Trang thai *'),
                value: _trangThai,
                items: const [
                  DropdownMenuItem(
                      value: 'hoat_dong', child: Text('Hoat dong')),
                  DropdownMenuItem(
                      value: 'cho_duyet', child: Text('Cho duyet')),
                  DropdownMenuItem(value: 'bi_khoa', child: Text('Bi khoa')),
                ],
                onChanged: (v) => setState(() => _trangThai = v ?? _trangThai),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Huy')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                _hoTenController.text,
                _emailController.text,
                _vaiTro,
                _trangThai,
                _soDtController.text.isNotEmpty ? _soDtController.text : null,
              );
            }
          },
          child: const Text('Luu'),
        ),
      ],
    );
  }
}
