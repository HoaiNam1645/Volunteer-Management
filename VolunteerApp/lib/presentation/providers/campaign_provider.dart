import 'package:flutter/material.dart';
import '../../data/models/campaign_model.dart';
import '../../data/repositories/campaign_repository.dart';

class CampaignProvider extends ChangeNotifier {
  final CampaignRepository _repository = CampaignRepository();

  List<Campaign> _campaigns = [];
  Campaign? _selectedCampaign;
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  String? _searchQuery;

  // Filter states
  String? _statusFilter;
  String? _categoryFilter;

  List<Campaign> get campaigns => _campaigns;
  Campaign? get selectedCampaign => _selectedCampaign;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  // ============ GET CAMPAIGNS ============
  Future<void> loadCampaigns({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _campaigns = [];
      _hasMore = true;
    }

    if (!_hasMore && !refresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.getCampaigns(
      page: _currentPage,
      search: _searchQuery,
      trangThai: _statusFilter,
      loaiChienDich: _categoryFilter,
    );

    if (result.success) {
      if (refresh) {
        _campaigns = result.campaigns;
      } else {
        _campaigns.addAll(result.campaigns);
      }
      _hasMore = result.currentPage < result.lastPage;
      _currentPage = result.currentPage + 1;
    } else {
      _error = result.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshCampaigns() => loadCampaigns(refresh: true);

  void setSearchQuery(String? query) {
    _searchQuery = query;
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
  }

  // ============ GET CAMPAIGN DETAIL ============
  Future<void> loadCampaignDetail(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.getCampaignDetail(id);

    if (result.success) {
      _selectedCampaign = result.campaign;
    } else {
      _error = result.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearSelectedCampaign() {
    _selectedCampaign = null;
    notifyListeners();
  }

  // ============ MY CAMPAIGNS ============
  List<Campaign> _myCampaigns = [];
  bool _isLoadingMyCampaigns = false;
  bool _hasMoreMyCampaigns = true;
  int _myCampaignsPage = 1;

  List<Campaign> get myCampaigns => _myCampaigns;
  bool get isLoadingMyCampaigns => _isLoadingMyCampaigns;
  bool get hasMoreMyCampaigns => _hasMoreMyCampaigns;

  Future<void> loadMyCampaigns({bool refresh = false}) async {
    if (_isLoadingMyCampaigns) return;

    if (refresh) {
      _myCampaignsPage = 1;
      _myCampaigns = [];
      _hasMoreMyCampaigns = true;
    }

    if (!_hasMoreMyCampaigns && !refresh) return;

    _isLoadingMyCampaigns = true;
    notifyListeners();

    final result = await _repository.getMyCampaigns(
      page: _myCampaignsPage,
      trangThai: _statusFilter,
    );

    if (result.success) {
      if (refresh) {
        _myCampaigns = result.campaigns;
      } else {
        _myCampaigns.addAll(result.campaigns);
      }
      _hasMoreMyCampaigns = result.currentPage < result.lastPage;
      _myCampaignsPage = result.currentPage + 1;
    }

    _isLoadingMyCampaigns = false;
    notifyListeners();
  }

  Future<void> refreshMyCampaigns() => loadMyCampaigns(refresh: true);

  // ============ CREATE CAMPAIGN ============
  Future<Campaign?> createCampaign(Campaign campaign) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.createCampaign(campaign);

    _isLoading = false;
    if (result.success) {
      final newCampaign = result.campaign!;
      _myCampaigns.insert(0, newCampaign);
      notifyListeners();
      return newCampaign;
    }

    _error = result.message;
    notifyListeners();
    return null;
  }

  // ============ UPDATE CAMPAIGN ============
  Future<bool> updateCampaign(int id, Campaign campaign) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.updateCampaign(id, campaign);

    _isLoading = false;
    if (result.success) {
      final index = _myCampaigns.indexWhere((c) => c.id == id);
      if (index != -1) {
        _myCampaigns[index] = result.campaign!;
      }
      if (_selectedCampaign?.id == id) {
        _selectedCampaign = result.campaign;
      }
    } else {
      _error = result.message;
    }
    notifyListeners();
    return result.success;
  }

  // ============ DELETE CAMPAIGN ============
  Future<bool> deleteCampaign(int id) async {
    _isLoading = true;
    notifyListeners();

    final result = await _repository.deleteCampaign(id);

    _isLoading = false;
    if (result.success) {
      _myCampaigns.removeWhere((c) => c.id == id);
    } else {
      _error = result.message;
    }
    notifyListeners();
    return result.success;
  }

  // ============ AI SUGGESTIONS ============
  AISuggestion? _aiSuggestions;
  bool _isLoadingSuggestions = false;

  AISuggestion? get aiSuggestions => _aiSuggestions;
  bool get isLoadingSuggestions => _isLoadingSuggestions;

  Future<void> loadAISuggestions(int campaignId) async {
    _isLoadingSuggestions = true;
    notifyListeners();

    final result = await _repository.getAISuggestions(campaignId);

    _isLoadingSuggestions = false;
    if (result.success) {
      _aiSuggestions = result.suggestions;
    }
    notifyListeners();
  }

  void clearSuggestions() {
    _aiSuggestions = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
