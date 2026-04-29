import 'package:flutter/material.dart';
import '../../data/models/campaign_model.dart';
import '../../data/repositories/campaign_repository.dart';

class CoordinatorProvider extends ChangeNotifier {
  final CampaignRepository _repository = CampaignRepository();

  // Campaigns for selection
  List<Campaign> _campaigns = [];
  List<Campaign> get campaigns => _campaigns;

  // Active campaign
  Campaign? _activeCampaign;
  Campaign? get activeCampaign => _activeCampaign;

  // Loading states
  bool _isLoadingCampaigns = false;
  bool _isLoadingRecommendations = false;
  bool get isLoadingCampaigns => _isLoadingCampaigns;
  bool get isLoadingRecommendations => _isLoadingRecommendations;

  // Volunteer data
  List<VolunteerRecommendation> _allocationPrimary = [];
  List<VolunteerRecommendation> _recommendedVolunteers = [];
  List<VolunteerRecommendation> _remoteAreaVolunteers = [];
  List<VolunteerRecommendation> _excludedVolunteers = [];
  List<VolunteerRecommendation> get allocationPrimary => _allocationPrimary;
  List<VolunteerRecommendation> get recommendedVolunteers => _recommendedVolunteers;
  List<VolunteerRecommendation> get remoteAreaVolunteers => _remoteAreaVolunteers;
  List<VolunteerRecommendation> get excludedVolunteers => _excludedVolunteers;

  // Combined rows for display
  List<VolunteerRecommendation> get volunteerRows {
    final rows = <VolunteerRecommendation>[];
    rows.addAll(_allocationPrimary);
    rows.addAll(_recommendedVolunteers);
    rows.addAll(_remoteAreaVolunteers);
    rows.addAll(_excludedVolunteers);
    return rows;
  }

  // Allocation summary
  Map<String, dynamic> _allocationSummary = {};
  Map<String, dynamic> get allocationSummary => _allocationSummary;

  // Risk flags
  List<Map<String, dynamic>> _allocationRisks = [];
  List<Map<String, dynamic>> get allocationRisks => _allocationRisks;

  // Invite loading
  bool _isInviting = false;
  bool get isInviting => _isInviting;

  // Error
  String? _error;
  String? get error => _error;

  // ============ LOAD CAMPAIGNS FOR COORDINATION ============
  Future<void> loadCampaignsForCoordination() async {
    _isLoadingCampaigns = true;
    _error = null;
    notifyListeners();

    final result = await _repository.getCampaignsForCoordination();

    if (result.success) {
      // Filter only approved campaigns
      _campaigns = result.campaigns
          .where((c) => c.trangThai == 'da_duyet')
          .toList();

      // Auto-select first campaign
      if (_campaigns.isNotEmpty && _activeCampaign == null) {
        _activeCampaign = _campaigns.first;
      }
    } else {
      _error = result.message;
    }

    _isLoadingCampaigns = false;
    notifyListeners();
  }

  // ============ LOAD COORDINATION DATA ============
  Future<void> loadCoordinationData(String campaignId) async {
    // Find campaign
    _activeCampaign = _campaigns.firstWhere(
      (c) => c.id.toString() == campaignId,
      orElse: () => _campaigns.first,
    );

    _isLoadingRecommendations = true;
    _error = null;
    notifyListeners();

    final result = await _repository.getCoordinationRecommendations(
      campaignId: int.tryParse(campaignId) ?? 0,
    );

    if (result.success) {
      final data = result.data;

      _allocationPrimary = (data['recommended_primary'] as List?)
              ?.map((e) => VolunteerRecommendation.fromJson(e, 'primary'))
              .toList() ??
          [];

      _recommendedVolunteers = (data['recommended'] as List?)
              ?.map((e) => VolunteerRecommendation.fromJson(e, 'recommendation'))
              .toList() ??
          [];

      _remoteAreaVolunteers = (data['remote_area_matches'] as List?)
              ?.map((e) => VolunteerRecommendation.fromJson(e, 'remote_area'))
              .toList() ??
          [];

      _excludedVolunteers = (data['excluded'] as List?)
              ?.map((e) => VolunteerRecommendation.fromJson(e, 'excluded'))
              .toList() ??
          [];

      _allocationSummary = (data['resource_summary'] as Map<String, dynamic>?) ?? {};
      _allocationRisks = (data['risk_flags'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [];
    } else {
      _error = result.message;
    }

    _isLoadingRecommendations = false;
    notifyListeners();
  }

  // ============ INVITE VOLUNTEERS ============
  Future<bool> inviteVolunteers(String campaignId, List<int> volunteerIds) async {
    _isInviting = true;
    _error = null;
    notifyListeners();

    final result = await _repository.inviteVolunteers(
      int.tryParse(campaignId) ?? 0,
      volunteerIds,
    );

    _isInviting = false;

    if (result.success) {
      // Update local state - mark volunteers as invited
      _allocationPrimary = _allocationPrimary.map((v) {
        if (volunteerIds.contains(v.id)) {
          return VolunteerRecommendation(
            id: v.id,
            name: v.name,
            email: v.email,
            finalScore: v.finalScore,
            groupCode: v.groupCode,
            groupLabel: v.groupLabel,
            skills: v.skills,
            areaText: v.areaText,
            distanceText: v.distanceText,
            distanceValue: v.distanceValue,
            registrationStatus: 'da_dang_ky',
            breakdown: v.breakdown,
            reasons: v.reasons,
            warnings: v.warnings,
          );
        }
        return v;
      }).toList();

      _recommendedVolunteers = _recommendedVolunteers.map((v) {
        if (volunteerIds.contains(v.id)) {
          return VolunteerRecommendation(
            id: v.id,
            name: v.name,
            email: v.email,
            finalScore: v.finalScore,
            groupCode: v.groupCode,
            groupLabel: v.groupLabel,
            skills: v.skills,
            areaText: v.areaText,
            distanceText: v.distanceText,
            distanceValue: v.distanceValue,
            registrationStatus: 'da_dang_ky',
            breakdown: v.breakdown,
            reasons: v.reasons,
            warnings: v.warnings,
          );
        }
        return v;
      }).toList();

      // Update allocationSummary with invited count (like FE does)
      if (result.invitedCount > 0) {
        final currentRegistered = int.tryParse(_allocationSummary['so_dang_ky_hien_tai']?.toString() ?? '0') ?? 0;
        _allocationSummary = {
          ..._allocationSummary,
          'so_dang_ky_hien_tai': currentRegistered + result.invitedCount,
        };
      }

      notifyListeners();
      return true;
    }

    _error = result.message;
    notifyListeners();
    return false;
  }

  // ============ CLEAR STATE ============
  void clearState() {
    _campaigns = [];
    _activeCampaign = null;
    _allocationPrimary = [];
    _recommendedVolunteers = [];
    _remoteAreaVolunteers = [];
    _excludedVolunteers = [];
    _allocationSummary = {};
    _allocationRisks = [];
    _error = null;
    notifyListeners();
  }
}

// ============ VOLUNTEER RECOMMENDATION MODEL ============
class VolunteerRecommendation {
  final int id;
  final String name;
  final String? email;
  final int finalScore;
  final String groupCode;
  final String groupLabel;
  final List<String> skills;
  final String? areaText;
  final String? distanceText;
  final double? distanceValue;
  final String? registrationStatus;
  final Map<String, dynamic>? breakdown;
  final List<String> reasons;
  final List<String> warnings;

  VolunteerRecommendation({
    required this.id,
    required this.name,
    this.email,
    required this.finalScore,
    required this.groupCode,
    required this.groupLabel,
    required this.skills,
    this.areaText,
    this.distanceText,
    this.distanceValue,
    this.registrationStatus,
    this.breakdown,
    required this.reasons,
    required this.warnings,
  });

  factory VolunteerRecommendation.fromJson(
    Map<String, dynamic> json,
    String groupCode,
  ) {
    return VolunteerRecommendation(
      id: json['id'] ?? 0,
      name: json['ho_ten'] ?? json['name'] ?? 'Không xác định',
      email: json['email'],
      finalScore: (json['final_score'] ?? json['finalScore'] ?? 0).toInt(),
      groupCode: groupCode,
      groupLabel: _getGroupLabel(groupCode),
      skills: (json['ky_nangs'] as List?)
              ?.map((s) => (s is Map ? s['ten'] : s)?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .cast<String>()
              .toList() ??
          [],
      areaText: (json['khu_vucs'] as List?)?.map((k) => k['ten']).join(', '),
      distanceText: json['distance_km'] != null
          ? '${json['distance_km']} km'
          : null,
      distanceValue: json['distance_km']?.toDouble(),
      registrationStatus: json['registration_status'],
      breakdown: json['score_breakdown'] ?? json['breakdown'],
      reasons: List<String>.from(json['reasons'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }

  static String _getGroupLabel(String code) {
    switch (code) {
      case 'primary':
        return 'Đạt chuẩn';
      case 'recommendation':
        return 'Khuyến nghị';
      case 'remote_area':
        return 'Ở xa';
      case 'excluded':
        return 'Bị loại';
      default:
        return code;
    }
  }
}

// ============ COORDINATION RESULT ============
class CoordinationResult {
  final bool success;
  final Map<String, dynamic> recommendationData;
  final String? message;

  CoordinationResult({
    required this.success,
    this.recommendationData = const {},
    this.message,
  });

  factory CoordinationResult.success(Map<String, dynamic> data) {
    return CoordinationResult(
      success: true,
      recommendationData: data,
    );
  }

  factory CoordinationResult.failure(String message) {
    return CoordinationResult(
      success: false,
      message: message,
    );
  }
}
