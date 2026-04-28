import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/api_endpoints.dart';
import 'api_client.dart';
import '../../data/models/user_model.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // ============ LOGIN ============
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.data['status'] == 1) {
        final fullData = response.data;
        final userData = response.data['data'] ?? {};
        await _saveAuthData(fullData);
        // Parse and cache user from login response instead of calling /me
        final user = userData['vai_tro'] != null ? User.fromJson(userData) : null;
        if (user != null) {
          await UserStorage.saveUser(user);
        }
        return AuthResult.success(
          message: response.data['message'] ?? 'Đăng nhập thành công',
          user: user,
        );
      }
      return AuthResult.failure(response.data['message'] ?? 'Đăng nhập thất bại');
    } on DioException catch (e) {
      return AuthResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AuthResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  // ============ REGISTER ============
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    List<int>? skillIds,
    List<int>? areaIds,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: {
          'ho_ten': name,
          'email': email,
          'mat_khau': password,
          'mat_khau_xac_nhan': passwordConfirmation,
          if (skillIds != null) 'ky_nang_ids': skillIds,
          if (areaIds != null) 'khu_vuc_ids': areaIds,
        },
      );

      if (response.data['status'] == 1) {
        return AuthResult.success(
          message: response.data['message'] ?? 'Đăng ký thành công. Vui lòng xác thực email.',
        );
      }
      return AuthResult.failure(response.data['message'] ?? 'Đăng ký thất bại');
    } on DioException catch (e) {
      return AuthResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AuthResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  // ============ GOOGLE SIGN IN ============
  Future<AuthResult> signInWithGoogle({required String code}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.googleAuth,
        data: {'code': code},
      );

      if (response.data['status'] == 1) {
        final fullData = response.data;
        final userData = response.data['data'] ?? {};
        await _saveAuthData(fullData);
        // Parse and cache user from login response instead of calling /me
        final user = userData['vai_tro'] != null ? User.fromJson(userData) : null;
        if (user != null) {
          await UserStorage.saveUser(user);
        }
        return AuthResult.success(
          message: response.data['message'] ?? 'Đăng nhập thành công',
          user: user,
        );
      }
      return AuthResult.failure(response.data['message'] ?? 'Đăng nhập thất bại');
    } on DioException catch (e) {
      return AuthResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AuthResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  // ============ FORGOT PASSWORD ============
  Future<AuthResult> forgotPassword({required String email}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );

      if (response.data['status'] == 1) {
        return AuthResult.success(
          message: response.data['message'] ?? 'Đã gửi email đặt lại mật khẩu',
        );
      }
      return AuthResult.failure(response.data['message'] ?? 'Gửi yêu cầu thất bại');
    } on DioException catch (e) {
      return AuthResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AuthResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  // ============ RESET PASSWORD ============
  Future<AuthResult> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.resetPassword,
        data: {
          'ma_xac_thuc': token,
          'email': email,
          'mat_khau': password,
          'mat_khau_xac_nhan': passwordConfirmation,
        },
      );

      if (response.data['status'] == 1) {
        return AuthResult.success(
          message: response.data['message'] ?? 'Đặt lại mật khẩu thành công',
        );
      }
      return AuthResult.failure(response.data['message'] ?? 'Đặt lại mật khẩu thất bại');
    } on DioException catch (e) {
      return AuthResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AuthResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  // ============ VERIFY EMAIL ============
  Future<AuthResult> verifyEmail({required String token}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.emailVerify,
        data: {'ma_xac_thuc': token},
      );

      if (response.data['status'] == 1) {
        return AuthResult.success(
          message: response.data['message'] ?? 'Xác thực email thành công',
        );
      }
      return AuthResult.failure(response.data['message'] ?? 'Xác thực thất bại');
    } on DioException catch (e) {
      return AuthResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return AuthResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  // ============ GET CURRENT USER ============
  Future<UserResult> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.me);

      if (response.data['status'] == 1) {
        final user = User.fromJson(response.data['data']);
        return UserResult.success(user);
      }
      return UserResult.failure(response.data['message'] ?? 'Không lấy được thông tin');
    } on DioException catch (e) {
      return UserResult.failure(_apiClient.handleError(e).fullMessage);
    } catch (e) {
      return UserResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  // ============ LOGOUT ============
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {}
    await _apiClient.clearTokens();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  // ============ CHECK AUTH STATUS ============
  Future<bool> isLoggedIn() async {
    return await _apiClient.hasToken();
  }

  // ============ PRIVATE HELPERS ============
  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    // Token might be in data or at top level of response
    final accessToken = data['access_token'] ?? data['token'];
    if (accessToken != null) {
      await _apiClient.saveToken(accessToken.toString());
    }
    if (data['refresh_token'] != null) {
      await _apiClient.saveRefreshToken(data['refresh_token'].toString());
    }
  }
}

// ============ RESULT CLASSES ============
class AuthResult {
  final bool success;
  final String message;
  final User? user;

  AuthResult({required this.success, required this.message, this.user});

  factory AuthResult.success({required String message, User? user}) {
    return AuthResult(success: true, message: message, user: user);
  }

  factory AuthResult.failure(String message) {
    return AuthResult(success: false, message: message);
  }
}

class UserResult {
  final bool success;
  final User? user;
  final String? message;

  UserResult({required this.success, this.user, this.message});

  factory UserResult.success(User user) {
    return UserResult(success: true, user: user);
  }

  factory UserResult.failure(String message) {
    return UserResult(success: false, message: message);
  }
}

// ============ STORAGE HELPERS ============
class UserStorage {
  static const _userKey = 'cached_user';

  static Future<void> saveUser(User user) async {
    final storage = const FlutterSecureStorage();
    await storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  static Future<User?> getUser() async {
    try {
      final storage = const FlutterSecureStorage();
      final data = await storage.read(key: _userKey);
      if (data != null) {
        return User.fromJson(jsonDecode(data));
      }
    } catch (_) {}
    return null;
  }

  static Future<void> clearUser() async {
    final storage = const FlutterSecureStorage();
    await storage.delete(key: _userKey);
  }
}
