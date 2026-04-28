import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/auth_service.dart';
import '../../../core/theme/app_theme.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String token;

  const EmailVerificationScreen({super.key, required this.token});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  String? _error;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _verifyEmail();
  }

  Future<void> _verifyEmail() async {
    if (widget.token.isEmpty) {
      setState(() => _error = 'Token không hợp lệ');
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.verifyEmail(token: widget.token);

    setState(() {
      _isLoading = false;
      if (result.success) {
        _isVerified = true;
      } else {
        _error = result.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIcon(),
                const SizedBox(height: 32),
                _buildTitle(),
                const SizedBox(height: 16),
                _buildMessage(),
                const SizedBox(height: 32),
                _buildAction(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (_isLoading) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (_isVerified) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.successColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle,
          size: 60,
          color: AppTheme.successColor,
        ),
      );
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.error,
        size: 60,
        color: AppTheme.errorColor,
      ),
    );
  }

  Widget _buildTitle() {
    if (_isLoading) {
      return const Text(
        'Đang xác thực...',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF212121),
        ),
        textAlign: TextAlign.center,
      );
    }

    if (_isVerified) {
      return const Text(
        'Xác thực thành công!',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.successColor,
        ),
        textAlign: TextAlign.center,
      );
    }

    return const Text(
      'Xác thực thất bại',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppTheme.errorColor,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage() {
    if (_isLoading) {
      return Text(
        'Vui lòng chờ trong giây lát...',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      );
    }

    if (_isVerified) {
      return Text(
        'Email của bạn đã được xác thực thành công.\nBây giờ bạn có thể đăng nhập và sử dụng ứng dụng.',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      );
    }

    return Column(
      children: [
        Text(
          _error ?? 'Đã xảy ra lỗi khi xác thực email.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Vui lòng thử lại hoặc liên hệ hỗ trợ.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAction() {
    if (_isLoading) return const SizedBox.shrink();

    if (_isVerified) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => context.go('/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Đăng nhập ngay',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Quay về đăng nhập',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go('/register'),
          child: const Text('Đăng ký tài khoản mới'),
        ),
      ],
    );
  }
}
