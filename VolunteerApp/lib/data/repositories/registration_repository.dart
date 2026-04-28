import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/registration_model.dart';

class RegistrationRepository {
  final ApiClient _apiClient = ApiClient.instance;

  // ============ REGISTER FOR CAMPAIGN ============
  Future<RegistrationResult> register({
    required int campaignId,
    String? ghiChu,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.campaignRegister(campaignId),
        data: {
          if (ghiChu != null) 'ghi_chu': ghiChu,
        },
      );
      if (response.data['status'] == 1) {
        return RegistrationResult.success(
          null,
          message: response.data['message'] ?? 'Đăng ký thành công',
        );
      }
      return RegistrationResult.failure(response.data['message'] ?? 'Đăng ký thất bại');
    } catch (e) {
      return RegistrationResult.failure('Không thể đăng ký tham gia');
    }
  }

  // ============ GET MY REGISTRATIONS ============
  // Backend: volunteer xem chiến dịch của mình qua /tinh-nguyen-vien/chien-dich
  // Mỗi campaign trong danh sách đó chứa thông tin đăng ký của volunteer
  Future<RegistrationListResult> getMyRegistrations({
    int page = 1,
    String? trangThai,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        if (trangThai != null) 'trang_thai': trangThai,
      };

      final response = await _apiClient.get(
        ApiEndpoints.volunteerCampaigns,
        queryParameters: queryParams,
      );

      final data = response.data['data'];
      final campaigns = (data is List)
          ? data
          : (data['data'] as List? ?? []);

      // Map campaigns -> registrations (reuse Registration model)
      final registrations = campaigns
          .map((e) => Registration.fromJson(e))
          .toList();

      return RegistrationListResult.success(
        registrations: registrations,
        currentPage: data['current_page'] ?? page,
        lastPage: data['last_page'] ?? 1,
        total: data['total'] ?? 0,
      );
    } catch (e) {
      return RegistrationListResult.failure('Không thể tải danh sách đăng ký');
    }
  }

  // ============ CANCEL REGISTRATION ============
  Future<OperationResult> cancelRegistration(int campaignId, {String? lyDoHuy}) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.campaignCancel(campaignId),
        data: {
          if (lyDoHuy != null) 'ly_do_huy': lyDoHuy,
        },
      );
      if (response.data['status'] == 1) {
        return OperationResult.success(response.data['message'] ?? 'Đã hủy đăng ký thành công');
      }
      return OperationResult.failure(response.data['message'] ?? 'Hủy thất bại');
    } catch (e) {
      return OperationResult.failure('Không thể hủy đăng ký');
    }
  }

  // ============ SUBMIT FEEDBACK ============
  Future<OperationResult> submitFeedback({
    required int chienDichId,
    required int diem,
    String? noiDung,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.feedbackCampaign,
        data: {
          'chien_dich_id': chienDichId,
          'diem': diem,
          if (noiDung != null) 'noi_dung': noiDung,
        },
      );
      if (response.data['status'] == 1) {
        return OperationResult.success(response.data['message'] ?? 'Cảm ơn bạn đã gửi đánh giá!');
      }
      return OperationResult.failure(response.data['message'] ?? 'Gửi thất bại');
    } catch (e) {
      return OperationResult.failure('Không thể gửi đánh giá');
    }
  }

  // ============ SUBMIT REPORT ============
  Future<OperationResult> submitReport({
    required int chienDichId,
    required String noiDung,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.feedbackReport,
        data: {
          'chien_dich_id': chienDichId,
          'noi_dung': noiDung,
        },
      );
      if (response.data['status'] == 1) {
        return OperationResult.success(response.data['message'] ?? 'Đã gửi báo cáo!');
      }
      return OperationResult.failure(response.data['message'] ?? 'Gửi thất bại');
    } catch (e) {
      return OperationResult.failure('Không thể gửi báo cáo');
    }
  }

  // ============ GET REGISTRATION DETAIL ============
  Future<RegistrationResult> getRegistrationDetail(int campaignId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.volunteerCampaignDetail(campaignId),
      );
      if (response.data['status'] == 1) {
        final registration = Registration.fromJson(response.data['data']);
        return RegistrationResult.success(registration);
      }
      return RegistrationResult.failure(response.data['message'] ?? 'Lỗi');
    } catch (e) {
      return RegistrationResult.failure('Không thể tải chi tiết đăng ký');
    }
  }
}

// ============ RESULT CLASSES ============
class RegistrationListResult {
  final bool success;
  final List<Registration> registrations;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? message;

  RegistrationListResult({
    required this.success,
    this.registrations = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.message,
  });

  factory RegistrationListResult.success({
    required List<Registration> registrations,
    required int currentPage,
    required int lastPage,
    required int total,
  }) {
    return RegistrationListResult(
      success: true,
      registrations: registrations,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
    );
  }

  factory RegistrationListResult.failure(String message) {
    return RegistrationListResult(success: false, message: message);
  }
}

class RegistrationResult {
  final bool success;
  final Registration? registration;
  final String? message;

  RegistrationResult({
    required this.success,
    this.registration,
    this.message,
  });

  factory RegistrationResult.success(Registration? registration, {String? message}) {
    return RegistrationResult(
      success: true,
      registration: registration,
      message: message,
    );
  }

  factory RegistrationResult.failure(String message) {
    return RegistrationResult(success: false, message: message);
  }
}

class OperationResult {
  final bool success;
  final String? message;

  OperationResult({required this.success, this.message});

  factory OperationResult.success(String message) {
    return OperationResult(success: true, message: message);
  }

  factory OperationResult.failure(String message) {
    return OperationResult(success: false, message: message);
  }
}
