import 'package:flutter/material.dart';
import '../../data/models/registration_model.dart';
import '../../data/repositories/registration_repository.dart';

class RegistrationProvider extends ChangeNotifier {
  final RegistrationRepository _repository = RegistrationRepository();

  List<Registration> _registrations = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  String? _statusFilter;

  // ============ TRACKING DATA ============
  List<Map<String, dynamic>> _trackingHistory = [];
  List<Map<String, dynamic>> _trackingRatings = [];
  List<Map<String, dynamic>> _trackingReports = [];
  List<Map<String, dynamic>> _feedbackTags = [];
  Map<String, dynamic> _trackingStats = {};

  List<Map<String, dynamic>> get trackingHistory => _trackingHistory;
  List<Map<String, dynamic>> get trackingRatings => _trackingRatings;
  List<Map<String, dynamic>> get trackingReports => _trackingReports;
  List<Map<String, dynamic>> get feedbackTags => _feedbackTags;
  Map<String, dynamic> get trackingStats => _trackingStats;

  List<Registration> get registrations => _registrations;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  // ============ LOAD TRACKING DATA ============
  Future<void> loadTrackingData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.getTrackingData();

    if (result.success) {
      final data = result.data;

      _trackingStats = Map<String, dynamic>.from(data['thong_ke'] ?? {});
      _trackingHistory = List<Map<String, dynamic>>.from(data['lich_su_hoat_dong'] ?? []);
      _trackingRatings = List<Map<String, dynamic>>.from(data['diem_danh_gia'] ?? []);
      _trackingReports = List<Map<String, dynamic>>.from(data['bao_cao_chien_dich'] ?? []);
      _feedbackTags = List<Map<String, dynamic>>.from(data['the_phan_hoi'] ?? []);
    } else {
      _error = result.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  // ============ LOAD REGISTRATIONS ============
  Future<void> loadRegistrations({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _registrations = [];
      _hasMore = true;
    }

    if (!_hasMore && !refresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.getMyRegistrations(
      page: _currentPage,
      trangThai: _statusFilter,
    );

    if (result.success) {
      if (refresh) {
        _registrations = result.registrations;
      } else {
        _registrations.addAll(result.registrations);
      }
      _hasMore = result.currentPage < result.lastPage;
      _currentPage = result.currentPage + 1;
    } else {
      _error = result.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshRegistrations() => loadRegistrations(refresh: true);

  void setStatusFilter(String? status) {
    _statusFilter = status;
  }

  // ============ REGISTER FOR CAMPAIGN ============
  Future<bool> register({
    required int campaignId,
    String? ghiChu,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.register(
      campaignId: campaignId,
      ghiChu: ghiChu,
    );

    _isLoading = false;
    if (!result.success) {
      _error = result.message;
    }
    notifyListeners();
    return result.success;
  }

  // ============ CONFIRM PARTICIPATION ============
  Future<bool> confirmParticipation(int campaignId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final result = await _repository.confirmParticipation(campaignId);
    _isLoading = false;
    if (!result.success) _error = result.message;
    notifyListeners();
    return result.success;
  }

  // ============ CANCEL REGISTRATION ============
  Future<bool> cancelRegistration(int campaignId, {String? lyDoHuy}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.cancelRegistration(campaignId, lyDoHuy: lyDoHuy);

    _isLoading = false;
    if (!result.success) {
      _error = result.message;
    }
    notifyListeners();
    return result.success;
  }

  // ============ SUBMIT FEEDBACK ============
  Future<bool> submitFeedback({
    required int chienDichId,
    required int soSao,
    String? nhanXet,
    List<int> theIds = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.submitFeedback(
      chienDichId: chienDichId,
      soSao: soSao,
      nhanXet: nhanXet,
      theIds: theIds,
    );

    if (result.success) {
      await loadTrackingData();
    } else {
      _error = result.message;
      _isLoading = false;
      notifyListeners();
    }
    return result.success;
  }

  // ============ SUBMIT REPORT ============
  Future<bool> submitReport({
    required int chienDichId,
    String? phanLoai,
    String? tieuDe,
    String? noiDung,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.submitReport(
      chienDichId: chienDichId,
      phanLoai: phanLoai,
      tieuDe: tieuDe,
      noiDung: noiDung,
    );

    if (result.success) {
      // Reload tracking data
      await loadTrackingData();
    } else {
      _error = result.message;
      _isLoading = false;
      notifyListeners();
    }

    return result.success;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
