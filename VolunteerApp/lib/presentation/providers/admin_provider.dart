import 'package:flutter/foundation.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/models/user_model.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _repo = AdminRepository();

  bool _isLoading = false;
  String? _error;
  DashboardData? _dashboardData;
  List<AdminUser> _users = [];
  List<PermissionUser> _permissionUsers = [];
  Map<String, List<CategoryItem>> _categories = {};

  // Pagination
  int _userPage = 1;
  bool _hasMoreUsers = true;
  bool _hasMorePermissionUsers = true;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  DashboardData? get dashboardData => _dashboardData;
  List<AdminUser> get users => _users;
  List<PermissionUser> get permissionUsers => _permissionUsers;
  Map<String, List<CategoryItem>> get categories => _categories;
  bool get hasMoreUsers => _hasMoreUsers;
  bool get hasMorePermissionUsers => _hasMorePermissionUsers;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============ DASHBOARD ============
  Future<void> loadDashboard({String period = 'month'}) async {
    _setLoading(true);
    _setError(null);

    final result = await _repo.getDashboard(period: period);
    if (result.success) {
      _dashboardData = result.data;
    } else {
      _setError(result.message);
    }

    _setLoading(false);
  }

  // ============ USER MANAGEMENT ============
  Future<void> loadUsers({
    bool refresh = false,
    String? search,
    String? vaiTro,
    String? trangThai,
  }) async {
    if (refresh) {
      _userPage = 1;
      _users = [];
      _hasMoreUsers = true;
    }

    if (!_hasMoreUsers || _isLoading) return;

    _setLoading(true);
    final result = await _repo.getUsers(
      page: _userPage,
      search: search,
      vaiTro: vaiTro,
      trangThai: trangThai,
    );

    if (result.success) {
      if (refresh) {
        _users = result.data ?? [];
      } else {
        _users.addAll(result.data ?? []);
      }
      _hasMoreUsers = result.meta?['last_page'] != null &&
          _userPage < (result.meta!['last_page'] as int);
      _userPage++;
    } else {
      _setError(result.message);
    }

    _setLoading(false);
  }

  Future<bool> createUser({
    required String hoTen,
    required String email,
    required String matKhau,
    required String vaiTro,
    String? soDienThoai,
  }) async {
    _setLoading(true);
    final result = await _repo.createUser(
      hoTen: hoTen,
      email: email,
      matKhau: matKhau,
      vaiTro: vaiTro,
      soDienThoai: soDienThoai,
    );

    _setLoading(false);
    if (result.success) {
      _users.insert(0, result.data as AdminUser);
      notifyListeners();
    } else {
      _setError(result.message);
    }
    return result.success;
  }

  Future<bool> updateUser({
    required int id,
    required String hoTen,
    required String email,
    required String vaiTro,
    String? soDienThoai,
  }) async {
    _setLoading(true);
    final result = await _repo.updateUser(
      id: id,
      hoTen: hoTen,
      email: email,
      vaiTro: vaiTro,
      soDienThoai: soDienThoai,
    );

    _setLoading(false);
    if (result.success) {
      final idx = _users.indexWhere((u) => u.id == id);
      if (idx >= 0) {
        _users[idx] = result.data as AdminUser;
        notifyListeners();
      }
    } else {
      _setError(result.message);
    }
    return result.success;
  }

  Future<bool> toggleUserStatus(AdminUser user) async {
    final newStatus = user.isActive ? 'vo_hieu_hoa' : 'kich_hoat';
    final result = await _repo.updateUserStatus(user.id, newStatus);

    if (result.success) {
      final idx = _users.indexWhere((u) => u.id == user.id);
      if (idx >= 0) {
        _users[idx] = AdminUser(
          id: user.id,
          hoTen: user.hoTen,
          email: user.email,
          soDienThoai: user.soDienThoai,
          vaiTro: user.vaiTro,
          trangThai: newStatus,
          anhDaiDien: user.anhDaiDien,
          createdAt: user.createdAt,
        );
        notifyListeners();
      }
    } else {
      _setError(result.message);
    }
    return result.success;
  }

  Future<bool> deleteUser(int id) async {
    _setLoading(true);
    final result = await _repo.deleteUser(id);

    _setLoading(false);
    if (result.success) {
      _users.removeWhere((u) => u.id == id);
      notifyListeners();
    } else {
      _setError(result.message);
    }
    return result.success;
  }

  // ============ PERMISSIONS ============
  Future<void> loadPermissionUsers({bool refresh = false, String? search}) async {
    _setLoading(true);
    final result = await _repo.getPermissionUsers(
      page: refresh ? 1 : 1,
      search: search,
    );

    if (result.success) {
      _permissionUsers = result.data ?? [];
    } else {
      _setError(result.message);
    }

    _setLoading(false);
  }

  Future<bool> updatePermission({
    required int id,
    required List<String> permissions,
    String? phamVi,
    bool suDungMacDinh = false,
  }) async {
    _setLoading(true);
    final result = await _repo.updatePermission(
      id: id,
      permissions: permissions,
      phamVi: phamVi,
      suDungMacDinh: suDungMacDinh,
    );

    _setLoading(false);
    if (!result.success) {
      _setError(result.message);
    }
    return result.success;
  }

  // ============ CATEGORIES ============
  Future<void> loadCategories() async {
    _setLoading(true);
    final result = await _repo.getCategories();

    if (result.success) {
      _categories = result.data ?? {};
    } else {
      _setError(result.message);
    }

    _setLoading(false);
  }

  Future<bool> createCategory({
    required String type,
    required String ten,
    String? moTa,
    String? bieuTuong,
  }) async {
    _setLoading(true);
    final result = await _repo.createCategory(
      type: type,
      ten: ten,
      moTa: moTa,
      bieuTuong: bieuTuong,
    );

    _setLoading(false);
    if (result.success) {
      _categories[type] ??= [];
      _categories[type]!.add(result.data!);
      notifyListeners();
    } else {
      _setError(result.message);
    }
    return result.success;
  }

  Future<bool> updateCategory({
    required String type,
    required int id,
    required String ten,
    String? moTa,
    String? bieuTuong,
  }) async {
    _setLoading(true);
    final result = await _repo.updateCategory(
      type: type,
      id: id,
      ten: ten,
      moTa: moTa,
      bieuTuong: bieuTuong,
    );

    _setLoading(false);
    if (result.success) {
      final idx = _categories[type]?.indexWhere((c) => c.id == id) ?? -1;
      if (idx >= 0) {
        _categories[type]![idx] = result.data!;
        notifyListeners();
      }
    } else {
      _setError(result.message);
    }
    return result.success;
  }

  Future<bool> deleteCategory(String type, int id) async {
    _setLoading(true);
    final result = await _repo.deleteCategory(type, id);

    _setLoading(false);
    if (result.success) {
      _categories[type]?.removeWhere((c) => c.id == id);
      notifyListeners();
    } else {
      _setError(result.message);
    }
    return result.success;
  }
}
