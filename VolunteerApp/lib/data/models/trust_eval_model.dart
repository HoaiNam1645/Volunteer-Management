import 'package:equatable/equatable.dart';

/// Trust evaluation response from ML service
/// Matching SPEC-TRUST-RISK-EVAL.md structure

/// Parse số dạng String/num/null an toàn — backend ML đôi khi trả String "0.95"
double _safeDouble(dynamic v, {double fallback = 0.0}) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

double? _safeDoubleNullable(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

enum TrustLabel {
  reliableHigh('RELIABLE_HIGH', 'Đáng tin cậy cao'),
  reliable('RELIABLE', 'Đáng tin cậy'),
  neutral('NEUTRAL', 'Trung lập'),
  suspicious('SUSPICIOUS', 'Đáng ngờ'),
  suspiciousHigh('SUSPICIOUS_HIGH', 'Đáng ngờ cao');

  final String value;
  final String displayName;

  const TrustLabel(this.value, this.displayName);

  static TrustLabel fromString(String value) {
    return TrustLabel.values.firstWhere(
      (l) => l.value == value,
      orElse: () => TrustLabel.neutral,
    );
  }
}

enum RiskLevel {
  low('LOW', 'Thấp'),
  medium('MEDIUM', 'Trung bình'),
  high('HIGH', 'Cao'),
  critical('CRITICAL', 'Nghiêm trọng');

  final String value;
  final String displayName;

  const RiskLevel(this.value, this.displayName);

  static RiskLevel fromString(String value) {
    return RiskLevel.values.firstWhere(
      (r) => r.value == value,
      orElse: () => RiskLevel.low,
    );
  }
}

class TrustScore extends Equatable {
  final double rawScore;
  final double calibratedScore;
  final String label;
  final double confidence;

  const TrustScore({
    required this.rawScore,
    required this.calibratedScore,
    required this.label,
    required this.confidence,
  });

  factory TrustScore.fromJson(Map<String, dynamic> json) {
    return TrustScore(
      rawScore: _safeDouble(json['raw_score']),
      calibratedScore: _safeDouble(json['calibrated_score']),
      label: json['label'] ?? 'NEUTRAL',
      confidence: _safeDouble(json['confidence']),
    );
  }

  TrustLabel get trustLabel => TrustLabel.fromString(label);

  @override
  List<Object?> get props => [rawScore, calibratedScore, label, confidence];
}

class RiskFlag extends Equatable {
  final String code;
  final String severity;
  final String category;
  final String message;
  final String? suggestion;

  const RiskFlag({
    required this.code,
    required this.severity,
    required this.category,
    required this.message,
    this.suggestion,
  });

  factory RiskFlag.fromJson(Map<String, dynamic> json) {
    return RiskFlag(
      code: json['code'] ?? '',
      severity: json['severity'] ?? 'MEDIUM',
      category: json['category'] ?? '',
      message: json['message'] ?? '',
      suggestion: json['suggestion'],
    );
  }

  RiskLevel get riskLevel => RiskLevel.fromString(severity);

  @override
  List<Object?> get props => [code, severity, category, message];
}

class SHAPFeature extends Equatable {
  final String feature;
  final String displayName;
  final double contribution;
  final double? value;

  const SHAPFeature({
    required this.feature,
    required this.displayName,
    required this.contribution,
    this.value,
  });

  factory SHAPFeature.fromJson(Map<String, dynamic> json) {
    return SHAPFeature(
      feature: json['feature'] ?? '',
      displayName: json['display_name'] ?? json['feature'] ?? '',
      contribution: _safeDouble(json['contribution']),
      value: _safeDoubleNullable(json['value']),
    );
  }

  @override
  List<Object?> get props => [feature, contribution];
}

class CampaignEvaluation extends Equatable {
  final int campaignId;
  final TrustScore trustScore;
  final String riskLevel;
  final List<RiskFlag> riskFlags;
  final List<SHAPFeature> topPositiveFactors;
  final List<SHAPFeature> topNegativeFactors;
  final double? anomalyScore;
  final bool isAnomaly;
  final List<String> anomalyTypes;
  final String? recommendation;
  final DateTime evaluatedAt;

  const CampaignEvaluation({
    required this.campaignId,
    required this.trustScore,
    required this.riskLevel,
    required this.riskFlags,
    required this.topPositiveFactors,
    required this.topNegativeFactors,
    this.anomalyScore,
    required this.isAnomaly,
    required this.anomalyTypes,
    this.recommendation,
    required this.evaluatedAt,
  });

  factory CampaignEvaluation.fromJson(Map<String, dynamic> json) {
    return CampaignEvaluation(
      campaignId: json['campaign_id'] ?? 0,
      trustScore: TrustScore.fromJson(json['trust_score'] ?? {}),
      riskLevel: json['risk_level'] ?? 'LOW',
      riskFlags: (json['risk_flags'] as List?)
          ?.map((e) => RiskFlag.fromJson(e))
          .toList() ?? [],
      topPositiveFactors: (json['top_positive_factors'] as List?)
          ?.map((e) => SHAPFeature.fromJson(e))
          .toList() ?? [],
      topNegativeFactors: (json['top_negative_factors'] as List?)
          ?.map((e) => SHAPFeature.fromJson(e))
          .toList() ?? [],
      anomalyScore: _safeDoubleNullable(json['anomaly_score']),
      isAnomaly: json['is_anomaly'] ?? false,
      anomalyTypes: json['anomaly_types'] != null
          ? List<String>.from(json['anomaly_types'])
          : [],
      recommendation: json['recommendation'],
      evaluatedAt: json['evaluated_at'] != null
          ? DateTime.parse(json['evaluated_at'])
          : DateTime.now(),
    );
  }

  RiskLevel get risk => RiskLevel.fromString(riskLevel);

  @override
  List<Object?> get props => [campaignId, trustScore, riskLevel, isAnomaly];
}

class VolunteerEvaluation extends Equatable {
  final int volunteerId;
  final TrustScore trustScore;
  final double registrationCount;
  final double cancellationRate;
  final double noShowRate;
  final double completionRate;
  final DateTime evaluatedAt;

  const VolunteerEvaluation({
    required this.volunteerId,
    required this.trustScore,
    required this.registrationCount,
    required this.cancellationRate,
    required this.noShowRate,
    required this.completionRate,
    required this.evaluatedAt,
  });

  factory VolunteerEvaluation.fromJson(Map<String, dynamic> json) {
    return VolunteerEvaluation(
      volunteerId: json['volunteer_id'] ?? 0,
      trustScore: TrustScore.fromJson(json['trust_score'] ?? {}),
      registrationCount: _safeDouble(json['registration_count']),
      cancellationRate: _safeDouble(json['cancellation_rate']),
      noShowRate: _safeDouble(json['no_show_rate']),
      completionRate: _safeDouble(json['completion_rate']),
      evaluatedAt: json['evaluated_at'] != null
          ? DateTime.parse(json['evaluated_at'])
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [volunteerId, trustScore];
}

class TrustEvalDashboard extends Equatable {
  final int totalCampaigns;
  final int evaluatedCampaigns;
  final int reliableCampaigns;
  final int suspiciousCampaigns;
  final double avgTrustScore;
  final List<TrustEvalStatsItem> trustDistribution;
  final List<TrustEvalStatsItem> riskDistribution;
  final String mlServiceStatus;
  final DateTime lastUpdated;

  const TrustEvalDashboard({
    required this.totalCampaigns,
    required this.evaluatedCampaigns,
    required this.reliableCampaigns,
    required this.suspiciousCampaigns,
    required this.avgTrustScore,
    required this.trustDistribution,
    required this.riskDistribution,
    required this.mlServiceStatus,
    required this.lastUpdated,
  });

  factory TrustEvalDashboard.fromJson(Map<String, dynamic> json) {
    return TrustEvalDashboard(
      totalCampaigns: json['total_campaigns'] ?? 0,
      evaluatedCampaigns: json['evaluated_campaigns'] ?? 0,
      reliableCampaigns: json['reliable_campaigns'] ?? 0,
      suspiciousCampaigns: json['suspicious_campaigns'] ?? 0,
      avgTrustScore: _safeDouble(json['avg_trust_score']),
      trustDistribution: (json['trust_distribution'] as List?)
          ?.map((e) => TrustEvalStatsItem.fromJson(e))
          .toList() ?? [],
      riskDistribution: (json['risk_distribution'] as List?)
          ?.map((e) => TrustEvalStatsItem.fromJson(e))
          .toList() ?? [],
      mlServiceStatus: json['ml_service_status'] ?? 'unknown',
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [totalCampaigns, evaluatedCampaigns, mlServiceStatus];
}

class TrustEvalStatsItem extends Equatable {
  final String label;
  final int count;
  final double percentage;

  const TrustEvalStatsItem({
    required this.label,
    required this.count,
    required this.percentage,
  });

  factory TrustEvalStatsItem.fromJson(Map<String, dynamic> json) {
    return TrustEvalStatsItem(
      label: json['label'] ?? '',
      count: json['count'] ?? 0,
      percentage: _safeDouble(json['percentage']),
    );
  }

  @override
  List<Object?> get props => [label, count];
}
