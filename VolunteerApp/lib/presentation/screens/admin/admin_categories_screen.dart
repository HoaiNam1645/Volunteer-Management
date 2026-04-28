import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/admin_repository.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen>
    with SingleTickerProviderStateMixin {
  final AdminRepository _repository = AdminRepository();
  late TabController _tabController;
  Map<String, List<CategoryItem>> _categories = {};
  bool _isLoading = true;
  String? _error;

  final _categoryTypes = ['ky_nang', 'khu_vuc', 'loai_chien_dich'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final result = await _repository.getCategories();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _categories = result.data ?? {};
        } else {
          _error = result.message;
        }
      });
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'ky_nang':
        return 'Kỹ năng';
      case 'khu_vuc':
        return 'Khu vực';
      case 'loai_chien_dich':
        return 'Loại chiến dịch';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý danh mục'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _categoryTypes.map((t) => Tab(text: _typeLabel(t))).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      TextButton(
                        onPressed: _loadCategories,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: _categoryTypes.map((type) => _CategoryList(
                    type: type,
                    items: _categories[type] ?? [],
                    onRefresh: _loadCategories,
                    onDelete: (id) => _deleteCategory(type, id),
                  )).toList(),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog() {
    final currentType = _categoryTypes[_tabController.index];
    showDialog(
      context: context,
      builder: (ctx) => _CategoryFormDialog(
        type: currentType,
        onSave: (ten, moTa) async {
          final result = await _repository.createCategory(
            type: currentType,
            ten: ten,
            moTa: moTa,
          );
          if (mounted) {
            Navigator.pop(ctx);
            if (result.success) {
              _loadCategories();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result.message ?? 'Tạo thành công')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.message ?? 'Tạo thất bại'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteCategory(String type, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa danh mục'),
        content: const Text('Bạn có chắc muốn xóa danh mục này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _repository.deleteCategory(type, id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? '')),
        );
        _loadCategories();
      }
    }
  }
}

class _CategoryList extends StatelessWidget {
  final String type;
  final List<CategoryItem> items;
  final VoidCallback onRefresh;
  final void Function(int id) onDelete;

  const _CategoryList({
    required this.type,
    required this.items,
    required this.onRefresh,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Chưa có danh mục nào'));
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final item = items[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Text(item.bieuTuong ?? item.ten[0].toUpperCase()),
              ),
              title: Text(item.ten),
              subtitle: item.moTa != null ? Text(item.moTa!) : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => onDelete(item.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryFormDialog extends StatefulWidget {
  final String type;
  final void Function(String ten, String? moTa) onSave;

  const _CategoryFormDialog({required this.type, required this.onSave});

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tenController = TextEditingController();
  final _moTaController = TextEditingController();

  @override
  void dispose() {
    _tenController.dispose();
    _moTaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Thêm ${_typeLabel(widget.type)}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _tenController,
              decoration: const InputDecoration(labelText: 'Tên *'),
              validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _moTaController,
              decoration: const InputDecoration(labelText: 'Mô tả'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                _tenController.text,
                _moTaController.text.isNotEmpty ? _moTaController.text : null,
              );
            }
          },
          child: const Text('Tạo'),
        ),
      ],
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'ky_nang':
        return 'kỹ năng';
      case 'khu_vuc':
        return 'khu vực';
      case 'tinh_thanh':
        return 'tỉnh thành';
      default:
        return type;
    }
  }
}
