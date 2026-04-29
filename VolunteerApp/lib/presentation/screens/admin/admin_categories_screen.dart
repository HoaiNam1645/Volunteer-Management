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
  final Map<String, String> _searchByType = {
    'ky_nang': '',
    'khu_vuc': '',
    'loai_chien_dich': '',
  };

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
    setState(() {
      _isLoading = true;
      _error = null;
    });
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
        return 'Ky nang';
      case 'khu_vuc':
        return 'Khu vuc';
      case 'loai_chien_dich':
        return 'Loai chien dich';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quan ly danh muc'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _categoryTypes.map((t) => Tab(text: _typeLabel(t))).toList(),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _loadCategories),
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
                          child: const Text('Thu lai')),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: _categoryTypes
                      .map(
                        (type) => _CategoryList(
                          type: type,
                          items: _categories[type] ?? [],
                          searchText: _searchByType[type] ?? '',
                          onSearchChanged: (v) =>
                              setState(() => _searchByType[type] = v),
                          onRefresh: _loadCategories,
                          onEdit: (item) => _showEditDialog(type, item),
                          onDelete: (id) => _deleteCategory(type, id),
                        ),
                      )
                      .toList(),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
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
        onSave: (form) async {
          final result = await _repository.createCategory(
            type: currentType,
            ten: form.ten,
            moTa: form.moTa,
            bieuTuong: form.bieuTuong,
            mauSac: form.mauSac,
            viDo: form.viDo,
            kinhDo: form.kinhDo,
            hoatDong: form.hoatDong,
          );
          if (!mounted) return;
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ??
                  (result.success ? 'Tao thanh cong' : 'Tao that bai')),
              backgroundColor: result.success ? null : Colors.red,
            ),
          );
          if (result.success) _loadCategories();
        },
      ),
    );
  }

  void _showEditDialog(String type, CategoryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => _CategoryFormDialog(
        type: type,
        initialData: _CategoryFormData(
          ten: item.ten,
          moTa: item.moTa,
          bieuTuong: item.bieuTuong,
          mauSac: item.mauSac ?? '#f59f00',
          viDo: item.viDo,
          kinhDo: item.kinhDo,
          hoatDong: item.hoatDong,
        ),
        onSave: (form) async {
          final result = await _repository.updateCategory(
            type: type,
            id: item.id,
            ten: form.ten,
            moTa: form.moTa,
            bieuTuong: form.bieuTuong,
            mauSac: form.mauSac,
            viDo: form.viDo,
            kinhDo: form.kinhDo,
            hoatDong: form.hoatDong,
          );
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
          if (result.success) _loadCategories();
        },
      ),
    );
  }

  Future<void> _deleteCategory(String type, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoa danh muc'),
        content: const Text('Ban co chac muon xoa danh muc nay?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _repository.deleteCategory(type, id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(result.message ?? '')));
    if (result.success) _loadCategories();
  }
}

class _CategoryList extends StatelessWidget {
  final String type;
  final List<CategoryItem> items;
  final String searchText;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRefresh;
  final ValueChanged<CategoryItem> onEdit;
  final void Function(int id) onDelete;

  const _CategoryList({
    required this.type,
    required this.items,
    required this.searchText,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final q = searchText.trim().toLowerCase();
    final filtered = q.isEmpty
        ? items
        : items.where((e) => e.ten.toLowerCase().contains(q)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tim theo ten...',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Chua co danh muc nao'))
              : RefreshIndicator(
                  onRefresh: () async => onRefresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _leadingColor(item, context),
                            child: Text(
                                item.bieuTuong ?? item.ten[0].toUpperCase()),
                          ),
                          title: Text(item.ten),
                          subtitle: Text(_subtitle(item)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: Colors.blue),
                                onPressed: () => onEdit(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () => onDelete(item.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Color _leadingColor(CategoryItem item, BuildContext context) {
    if (type == 'loai_chien_dich' && item.mauSac != null) {
      final hex = item.mauSac!.replaceAll('#', '');
      if (hex.length == 6) {
        final value = int.tryParse('FF$hex', radix: 16);
        if (value != null) return Color(value).withValues(alpha: 0.2);
      }
    }
    return Theme.of(context).primaryColor.withValues(alpha: 0.1);
  }

  String _subtitle(CategoryItem item) {
    final lines = <String>[];
    if (item.moTa?.isNotEmpty == true) lines.add(item.moTa!);
    if (type == 'khu_vuc' && item.viDo != null && item.kinhDo != null) {
      lines.add('${item.viDo}, ${item.kinhDo}');
    }
    lines.add(
        'Users: ${item.nguoiDungCount} | Campaigns: ${item.chienDichCount}');
    return lines.join('\n');
  }
}

class _CategoryFormData {
  final String ten;
  final String? moTa;
  final String? bieuTuong;
  final String? mauSac;
  final double? viDo;
  final double? kinhDo;
  final bool hoatDong;

  const _CategoryFormData({
    required this.ten,
    this.moTa,
    this.bieuTuong,
    this.mauSac,
    this.viDo,
    this.kinhDo,
    required this.hoatDong,
  });
}

class _CategoryFormDialog extends StatefulWidget {
  final String type;
  final _CategoryFormData? initialData;
  final void Function(_CategoryFormData data) onSave;

  const _CategoryFormDialog(
      {required this.type, this.initialData, required this.onSave});

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tenController = TextEditingController();
  final _moTaController = TextEditingController();
  final _iconController = TextEditingController();
  final _mauSacController = TextEditingController(text: '#f59f00');
  final _viDoController = TextEditingController();
  final _kinhDoController = TextEditingController();
  bool _hoatDong = true;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data != null) {
      _tenController.text = data.ten;
      _moTaController.text = data.moTa ?? '';
      _iconController.text = data.bieuTuong ?? '';
      _mauSacController.text = data.mauSac ?? '#f59f00';
      _viDoController.text = data.viDo?.toString() ?? '';
      _kinhDoController.text = data.kinhDo?.toString() ?? '';
      _hoatDong = data.hoatDong;
    }
  }

  @override
  void dispose() {
    _tenController.dispose();
    _moTaController.dispose();
    _iconController.dispose();
    _mauSacController.dispose();
    _viDoController.dispose();
    _kinhDoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialData == null
          ? 'Them ${_typeLabel(widget.type)}'
          : 'Sua ${_typeLabel(widget.type)}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _tenController,
                decoration: const InputDecoration(labelText: 'Ten *'),
                validator: (v) => v?.isEmpty == true ? 'Bat buoc' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _moTaController,
                decoration: const InputDecoration(labelText: 'Mo ta'),
                maxLines: 2,
              ),
              if (widget.type == 'ky_nang' ||
                  widget.type == 'loai_chien_dich') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _iconController,
                  decoration: const InputDecoration(labelText: 'Bieu tuong'),
                ),
              ],
              if (widget.type == 'khu_vuc') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _viDoController,
                        decoration: const InputDecoration(labelText: 'Vi do'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _kinhDoController,
                        decoration: const InputDecoration(labelText: 'Kinh do'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                  ],
                ),
              ],
              if (widget.type == 'loai_chien_dich') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mauSacController,
                  decoration: const InputDecoration(labelText: 'Mau sac HEX'),
                ),
              ],
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hoat dong'),
                value: _hoatDong,
                onChanged: (v) => setState(() => _hoatDong = v),
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
                _CategoryFormData(
                  ten: _tenController.text,
                  moTa: _moTaController.text.isNotEmpty
                      ? _moTaController.text
                      : null,
                  bieuTuong: _iconController.text.isNotEmpty
                      ? _iconController.text
                      : null,
                  mauSac: _mauSacController.text.isNotEmpty
                      ? _mauSacController.text
                      : null,
                  viDo: _viDoController.text.isNotEmpty
                      ? double.tryParse(_viDoController.text)
                      : null,
                  kinhDo: _kinhDoController.text.isNotEmpty
                      ? double.tryParse(_kinhDoController.text)
                      : null,
                  hoatDong: _hoatDong,
                ),
              );
            }
          },
          child: Text(widget.initialData == null ? 'Tao' : 'Luu'),
        ),
      ],
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'ky_nang':
        return 'ky nang';
      case 'khu_vuc':
        return 'khu vuc';
      case 'loai_chien_dich':
        return 'loai chien dich';
      default:
        return type;
    }
  }
}
