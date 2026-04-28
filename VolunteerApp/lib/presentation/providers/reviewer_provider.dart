import 'package:flutter/foundation.dart';
import '../../data/repositories/reviewer_repository.dart';

class ReviewerProvider extends ChangeNotifier {
  final ReviewerRepository _repo = ReviewerRepository();

  bool _isLoading = false;
  String? _error;
  List<ReviewerCampaign> _campaigns = [];
  ReviewerCampaignDetail? _selectedCampaign;
  CampaignFilters? _filters;

  // Pagination
  int _page = 1;
  bool _hasMore = true;

  // Filters
  String? _statusFilter;
  String? _searchQuery;
  String? _campaignTypeFilter;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ReviewerCampaign> get campaigns => _campaigns;
  ReviewerCampaignDetail? get selectedCampaign => _selectedCampaign;
  CampaignFilters? get filters => _filters;
  bool get hasMore => _hasMore;

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

  void setStatusFilter(String? value) {
    _statusFilter = value;
    loadCampaigns(refresh: true);
  }

  void setSearchQuery(String? value) {
    _searchQuery = value;
  }

  void setCampaignTypeFilter(String? value) {
    _campaignTypeFilter = value;
    loadCampaigns(refresh: true);
  }

  // ============ FILTERS ============
  Future<void> loadFilters() async {
    final result = await _repo.getFilters();
    if (result.success) {
      _filters = result.data;
      notifyListeners();
    }
  }

  // ============ CAMPAIGNS ============
  Future<void> loadCampaigns({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _campaigns = [];
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _setLoading(true);
    _setError(null);

    final result = await _repo.getCampaigns(
      page: _page,
      trangThai: _statusFilter,
      search: _searchQuery,
      loaiChienDich: _campaignTypeFilter,
    );

    if (result.success) {
      if (refresh) {
        _campaigns = result.data ?? [];
      } else {
        _campaigns.addAll(result.data ?? []);
      }
      _hasMore = result.meta?['last_page'] != null &&
          _page < (result.meta!['last_page'] as int);
      _page++;
    } else {
      _setError(result.message);
    }

    _setLoading(false);
  }

  Future<void> loadCampaignDetail(int id) async {
    _setLoading(true);
    _setError(null);

    final result = await _repo.getCampaignDetail(id);
    if (result.success) {
      _selectedCampaign = result.data;
    } else {
      _setError(result.message);
    }

    _setLoading(false);
  }

  // ============ APPROVE / REJECT ============
  Future<bool> approveCampaign(int id) async {
    _setLoading(true);
    final result = await _repo.approveCampaign(id);
    _setLoading(false);

    if (result.success) {
      // Update local data
      final idx = _campaigns.indexWhere((c) => c.id == id);
      if (idx >= 0) {
        // Reload list
        await loadCampaigns(refresh: true);
        await loadCampaignDetail(id);
      }
      return true;
    }

    _setError(result.message);
    return false;
  }

  Future<bool> rejectCampaign(int id, String reason) async {
    _setLoading(true);
    final result = await _repo.rejectCampaign(id, reason);
    _setLoading(false);

    if (result.success) {
      await loadCampaigns(refresh: true);
      await loadCampaignDetail(id);
      return true;
    }

    _setError(result.message);
    return false;
  }

  // ============ CANCEL REQUEST ============
  Future<bool> approveCancel(int id) async {
    _setLoading(true);
    final result = await _repo.approveCancel(id);
    _setLoading(false);

    if (result.success) {
      await loadCampaigns(refresh: true);
      await loadCampaignDetail(id);
      return true;
    }

    _setError(result.message);
    return false;
  }

  Future<bool> rejectCancel(int id, String reason) async {
    _setLoading(true);
    final result = await _repo.rejectCancel(id, reason);
    _setLoading(false);

    if (result.success) {
      await loadCampaignDetail(id);
      return true;
    }

    _setError(result.message);
    return false;
  }

  // ============ REPORTS ============
  Future<bool> processReport(int id, String trangThai) async {
    _setLoading(true);
    final result = await _repo.processReport(id, trangThai);
    _setLoading(false);

    if (!result.success) {
      _setError(result.message);
    }
    return result.success;
  }
}
