import 'package:flutter/material.dart';
import '../../core/network/auth_service.dart';
import '../../config/tnv_menu_spec.dart';
import '../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isReviewer => _currentUser?.isReviewer ?? false;
  bool get isAdminOrReviewer => isAdmin || isReviewer;
  bool get canManageCampaigns => _currentUser?.canManageCampaigns ?? false;
  bool get isVolunteer => _currentUser?.isVolunteer ?? false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final hasToken = await _authService.isLoggedIn().timeout(
      const Duration(seconds: 3),
      onTimeout: () => false,
    );

    if (hasToken) {
      // Try to get cached user from storage first (populated during login)
      final cachedUser = await UserStorage.getUser();
      if (cachedUser != null) {
        _currentUser = cachedUser;
      } else {
        // Fallback: try /me endpoint (may fail if route doesn't exist)
        final result = await _authService.getCurrentUser().timeout(
          const Duration(seconds: 5),
          onTimeout: () => UserResult.failure('timeout'),
        );
        if (result.success) {
          _currentUser = result.user;
          // Cache for next app start
          if (result.user != null) {
            await UserStorage.saveUser(result.user!);
          }
        }
        // Note: Don't logout if /me fails - user might still have valid token
        // The token will be validated on next API call
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.login(email: email, password: password);
    if (result.success) {
      // Use user from login response directly (avoids /me which may fail)
      _currentUser = result.user;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _error = result.message;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> loginWithGoogle({required String code}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.signInWithGoogle(code: code);
    if (result.success) {
      // Use user from login response directly (avoids /me which may fail)
      _currentUser = result.user;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _error = result.message;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    List<int>? skillIds,
    List<int>? areaIds,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      skillIds: skillIds,
      areaIds: areaIds,
    );

    _isLoading = false;
    if (!result.success) {
      _error = result.message;
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  Future<bool> forgotPassword({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.forgotPassword(email: email);

    _isLoading = false;
    if (!result.success) {
      _error = result.message;
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  Future<bool> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.resetPassword(
      token: token,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );

    _isLoading = false;
    if (!result.success) {
      _error = result.message;
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
    try {
      await _authService.logout().timeout(const Duration(seconds: 3));
    } catch (_) {
      // Ignore logout API errors - tokens are cleared locally
    }
    // Clear cached user data
    await UserStorage.clearUser();
  }

  Future<void> _loadCurrentUser() async {
    final result = await _authService.getCurrentUser();
    if (result.success) {
      _currentUser = result.user;
    }
  }

  Future<void> refreshCurrentUser() async {
    final result = await _authService.getCurrentUser();
    if (result.success && result.user != null) {
      _currentUser = result.user;
      await UserStorage.saveUser(result.user!);
      notifyListeners();
    }
  }

  bool canAccessRoute(String path) {
    if (TnvMenuSpec.publicGuestRoutes.contains(path) ||
        path.startsWith('/campaign/')) {
      return true;
    }

    if (!isLoggedIn) return false;
    if (!isVolunteer) return true;

    if (!TnvMenuSpec.protectedRoutes.contains(path)) return true;

    final user = _currentUser;
    if (user == null) return false;
    final required = _requiredPermissionsForRoute(path);
    if (required.isEmpty) return true;
    return required.any(user.hasPermission);
  }

  String firstAccessibleTnvRoute() {
    if (!isVolunteer || _currentUser == null) return '/';
    for (final item in visibleTnvMenuTree()) {
      if (item.path != '/') return item.path;
    }
    return '/';
  }

  List<TnvMenuItem> visibleTnvMenuTree() {
    final user = _currentUser;
    return TnvMenuSpec.topLevel
        .map((item) => _filterVisibleNode(item, user))
        .whereType<TnvMenuItem>()
        .toList();
  }

  List<String> _requiredPermissionsForRoute(String path) {
    for (final item in TnvMenuSpec.topLevel) {
      final match = _findRoute(item, path);
      if (match != null) return match.requiredPermissions;
    }
    return const [];
  }

  TnvMenuItem? _findRoute(TnvMenuItem item, String path) {
    if (item.path == path) return item;
    for (final child in item.children) {
      final found = _findRoute(child, path);
      if (found != null) return found;
    }
    return null;
  }

  TnvMenuItem? _filterVisibleNode(TnvMenuItem item, User? user) {
    final visibleChildren = item.children
        .map((c) => _filterVisibleNode(c, user))
        .whereType<TnvMenuItem>()
        .toList();

    final selfVisible = _isMenuItemVisible(item, user);
    if (visibleChildren.isEmpty) {
      return selfVisible
          ? TnvMenuItem(
              key: item.key,
              path: item.path,
              label: item.label,
              requiredPermissions: item.requiredPermissions,
              isGuestAllowed: item.isGuestAllowed,
            )
          : null;
    }

    return TnvMenuItem(
      key: item.key,
      path: visibleChildren.first.path,
      label: item.label,
      requiredPermissions: item.requiredPermissions,
      isGuestAllowed: item.isGuestAllowed,
      children: visibleChildren,
    );
  }

  bool _isMenuItemVisible(TnvMenuItem item, User? user) {
    if (item.isGuestAllowed) return true;
    if (user == null) return false;
    if (item.requiredPermissions.isEmpty) return true;
    return item.requiredPermissions.any(user.hasPermission);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
