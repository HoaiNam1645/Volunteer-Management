import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/admin_repository.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminRepository _repository = AdminRepository();
  List<AdminUser> _users = [];
  bool _isLoading = true;
  String? _error;
  String _search = '';
  String? _selectedRole;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({int page = 1}) async {
    setState(() => _isLoading = true);
    final result = await _repository.getUsers(
      page: page,
      search: _search.isNotEmpty ? _search : null,
      vaiTro: _selectedRole,
      trangThai: _selectedStatus,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _users = result.data ?? [];
        } else {
          _error = result.message;
        }
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm người dùng...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              onChanged: (v) => _search = v,
              onSubmitted: (_) => _loadUsers(),
            ),
          ),
          // User list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                            TextButton(
                              onPressed: () => _loadUsers(),
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _users.isEmpty
                        ? const Center(child: Text('Không có người dùng nào'))
                        : RefreshIndicator(
                            onRefresh: () => _loadUsers(),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: _users.length,
                              itemBuilder: (ctx, i) => _UserCard(
                                user: _users[i],
                                onStatusToggle: () => _loadUsers(),
                              ),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _UserFormDialog(
        onSave: (hoTen, email, matKhau, vaiTro, soDienThoai) async {
          final result = await _repository.createUser(
            hoTen: hoTen,
            email: email,
            matKhau: matKhau,
            vaiTro: vaiTro,
            soDienThoai: soDienThoai,
          );
          if (mounted) {
            Navigator.pop(ctx);
            if (result.success) {
              _loadUsers();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result.message ?? 'Tạo thành công')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result.message ?? 'Tạo thất bại'), backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUser user;
  final VoidCallback onStatusToggle;

  const _UserCard({required this.user, required this.onStatusToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          backgroundImage: user.anhDaiDien != null ? NetworkImage(user.anhDaiDien!) : null,
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
            if (action == 'toggle_status') {
              final repo = AdminRepository();
              final newStatus = user.trangThai == 'hoat_dong' ? 'bi_khoa' : 'hoat_dong';
              final result = await repo.updateUserStatus(user.id, newStatus);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.message ?? '')),
                );
                onStatusToggle();
              }
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'toggle_status',
              child: Text(user.trangThai == 'hoat_dong' ? 'Khóa tài khoản' : 'Mở khóa'),
            ),
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
        label = 'Kiểm duyệt';
        break;
      default:
        color = Colors.green;
        label = 'TNV';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String trangThai;

  const _StatusChip({required this.trangThai});

  @override
  Widget build(BuildContext context) {
    final isActive = trangThai == 'hoat_dong';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.grey).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'Hoạt động' : 'Bị khóa',
        style: TextStyle(color: isActive ? Colors.green : Colors.grey, fontSize: 11),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final String? selectedRole;
  final String? selectedStatus;
  final void Function(String?, String?) onApply;

  const _FilterSheet({
    this.selectedRole,
    this.selectedStatus,
    required this.onApply,
  });

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
          const Text('Lọc người dùng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Vai trò'),
            value: _role,
            items: const [
              DropdownMenuItem(value: null, child: Text('Tất cả')),
              DropdownMenuItem(value: 'tinh_nguyen_vien', child: Text('Tình nguyện viên')),
              DropdownMenuItem(value: 'kiem_duyet_vien', child: Text('Kiểm duyệt viên')),
              DropdownMenuItem(value: 'quan_tri_vien', child: Text('Quản trị viên')),
            ],
            onChanged: (v) => setState(() => _role = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Trạng thái'),
            value: _status,
            items: const [
              DropdownMenuItem(value: null, child: Text('Tất cả')),
              DropdownMenuItem(value: 'hoat_dong', child: Text('Hoạt động')),
              DropdownMenuItem(value: 'bi_khoa', child: Text('Bị khóa')),
            ],
            onChanged: (v) => setState(() => _status = v),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              widget.onApply(_role, _status);
              Navigator.pop(context);
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  final void Function(String hoTen, String email, String matKhau, String vaiTro, String? soDienThoai) onSave;

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
      title: const Text('Tạo người dùng'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _hoTenController,
                decoration: const InputDecoration(labelText: 'Họ tên *'),
                validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email *'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _matKhauController,
                decoration: const InputDecoration(labelText: 'Mật khẩu *'),
                obscureText: true,
                validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _soDtController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Vai trò *'),
                value: _vaiTro,
                items: const [
                  DropdownMenuItem(value: 'tinh_nguyen_vien', child: Text('Tình nguyện viên')),
                  DropdownMenuItem(value: 'kiem_duyet_vien', child: Text('Kiểm duyệt viên')),
                  DropdownMenuItem(value: 'quan_tri_vien', child: Text('Quản trị viên')),
                ],
                onChanged: (v) => setState(() => _vaiTro = v ?? 'tinh_nguyen_vien'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                _hoTenController.text,
                _emailController.text,
                _matKhauController.text,
                _vaiTro,
                _soDtController.text.isNotEmpty ? _soDtController.text : null,
              );
            }
          },
          child: const Text('Tạo'),
        ),
      ],
    );
  }
}
