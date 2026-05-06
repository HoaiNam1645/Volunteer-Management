/// API response wrapper - matches Laravel backend structure
/// Standard Laravel API response format:
/// {
///   "status": 1,
///   "message": "Operation successful",
///   "data": { ... },
///   "meta": { "pagination": { ... } }
/// }
/// Error format:
/// {
///   "status": 0,
///   "message": "Error message",
///   "errors": { "field": ["error1", "error2"] }
/// }

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final PaginationMeta? meta;
  final Map<String, List<String>>? errors;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.meta,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    final success = json['status'] == 1 || json['success'] == true;
    return ApiResponse(
      success: success,
      message: json['message'],
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      meta: json['meta'] != null
          ? PaginationMeta.fromJson(json['meta'])
          : null,
      errors: json['errors'] != null
          ? (json['errors'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, List<String>.from(v)),
            )
          : null,
    );
  }

  String get errorMessage {
    if (errors != null) {
      return errors!.entries.expand((e) => e.value).join('\n');
    }
    return message ?? 'Đã xảy ra lỗi';
  }
}

class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] ?? json;
    return PaginationMeta(
      currentPage: pagination['current_page'] ?? 1,
      lastPage: pagination['last_page'] ?? 1,
      perPage: pagination['per_page'] ?? 20,
      total: pagination['total'] ?? 0,
    );
  }

  bool get hasMorePages => currentPage < lastPage;
}

/// Error response from backend
class ApiError {
  final String message;
  final Map<String, List<String>>? errors;
  final int? statusCode;

  ApiError({
    required this.message,
    this.errors,
    this.statusCode,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['message'] ?? 'An error occurred',
      errors: json['errors'] != null
          ? (json['errors'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, List<String>.from(v)),
            )
          : null,
    );
  }

  bool get isForbidden => statusCode == 403;

  String get fullMessage {
    if (errors == null) return message;
    final errorList = errors!.entries.expand((e) => e.value).toList();
    return errorList.isNotEmpty ? errorList.join('\n') : message;
  }
}
