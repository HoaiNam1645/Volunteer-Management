import 'package:equatable/equatable.dart';

/// Base class for form validation
abstract class ValidationResult extends Equatable {
  const ValidationResult();
}

class ValidationSuccess extends ValidationResult {
  const ValidationSuccess();

  @override
  List<Object?> get props => [];
}

class ValidationFailure extends ValidationResult {
  final String message;

  const ValidationFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Common validation helpers
class Validators {
  Validators._();

  static ValidationResult validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return ValidationFailure('$fieldName không được để trống');
    }
    return const ValidationSuccess();
  }

  static ValidationResult validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationFailure('Email không được để trống');
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return const ValidationFailure('Email không hợp lệ');
    }
    return const ValidationSuccess();
  }

  static ValidationResult validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationFailure('Mật khẩu không được để trống');
    }
    if (value.length < 8) {
      return const ValidationFailure('Mật khẩu phải có ít nhất 8 ký tự');
    }
    return const ValidationSuccess();
  }

  static ValidationResult validatePasswordMatch(
    String? password,
    String? confirmPassword,
  ) {
    if (password != confirmPassword) {
      return const ValidationFailure('Mật khẩu xác nhận không khớp');
    }
    return const ValidationSuccess();
  }

  static ValidationResult validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationSuccess(); // Phone is optional
    }
    final phoneRegex = RegExp(r'^0[0-9]{9,10}$');
    if (!phoneRegex.hasMatch(value)) {
      return const ValidationFailure('Số điện thoại không hợp lệ');
    }
    return const ValidationSuccess();
  }

  static ValidationResult validateMinLength(
    String? value,
    int minLength,
    String fieldName,
  ) {
    if (value == null || value.length < minLength) {
      return ValidationFailure('$fieldName phải có ít nhất $minLength ký tự');
    }
    return const ValidationSuccess();
  }

  static ValidationResult validateMaxLength(
    String? value,
    int maxLength,
    String fieldName,
  ) {
    if (value != null && value.length > maxLength) {
      return ValidationFailure('$fieldName không được vượt quá $maxLength ký tự');
    }
    return const ValidationSuccess();
  }
}
