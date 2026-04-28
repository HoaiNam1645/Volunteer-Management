import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/admin_repository.dart';

class TrustEvalVolunteerDetailScreen extends StatefulWidget {
  final int volunteerId;

  const TrustEvalVolunteerDetailScreen({super.key, required this.volunteerId});

  @override
  State<TrustEvalVolunteerDetailScreen> createState() => _TrustEvalVolunteerDetailScreenState();
}

class _TrustEvalVolunteerDetailScreenState extends State<TrustEvalVolunteerDetailScreen> {
  final AdminRepository _repo = AdminRepository();

  bool _isLoading = true;
  String? _error;
  VolunteerTrustEval? _evaluation;

  @override
  void initState() {
    super.initState();
    _loadEvaluation();
  }

  Future<void> _loadEvaluation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _repo.getVolunteerTrustEval(widget.volunteerId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _evaluation = result.data;
        } else {
          _error = result.message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Đánh giá TNV'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEvaluation,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final eval = _evaluation!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(eval),
          const SizedBox(height: 16),
          _buildScoreSection(eval),
          const SizedBox(height: 16),
          _buildActivityStats(eval),
          const SizedBox(height: 16),
          _buildReputationSection(eval),
          const SizedBox(height: 16),
          if (eval.recentCampaignEvals.isNotEmpty) ...[
            _buildRecentCampaignEvals(eval),
            const SizedBox(height: 16),
          ],
          if (eval.shapValues != null && eval.shapValues!.isNotEmpty) ...[
            _buildShapSection(eval),
            const SizedBox(height: 16),
          ],
          _buildMetadataSection(eval),
        ],
      ),
    );
  }

  Widget _buildHeader(VolunteerTrustEval eval) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                child: Text(
                  eval.hoTen.isNotEmpty ? eval.hoTen[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eval.hoTen,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      eval.email,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              _buildRiskBadge(eval.riskLevel),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(Icons.shield, eval.trustLabel.replaceAll('_', ' '), _getTrustColor(eval.trustScore)),
              _buildInfoChip(Icons.recommend, eval.recommendedAction.replaceAll('_', ' '), _getActionColor(eval.recommendedAction)),
              if (eval.isAnomaly)
                _buildInfoChip(Icons.warning, 'Anomaly', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRiskBadge(String riskLevel) {
    final color = switch (riskLevel.toUpperCase()) {
      'CRITICAL' => Colors.purple,
      'HIGH' => Colors.red,
      'MEDIUM' => Colors.orange,
      'LOW' => Colors.green,
      _ => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber, size: 16, color: color),
          const SizedBox(width: 4),
          Text(riskLevel.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildScoreSection(VolunteerTrustEval eval) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Điểm số đánh giá', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildScoreCard(
                  'Trust Score',
                  eval.trustScore,
                  _getTrustColor(eval.trustScore),
                  Icons.verified_user,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildScoreCard(
                  'Risk Score',
                  eval.riskScore,
                  _getRiskColor(eval.riskScore),
                  Icons.security,
                ),
              ),
            ],
          ),
          if (eval.confidence != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Confidence: ${(eval.confidence! * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreCard(String title, double score, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            (score * 100).toStringAsFixed(1),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            '%',
            style: TextStyle(fontSize: 16, color: color),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildActivityStats(VolunteerTrustEval eval) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hoạt động', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Tổng chiến dịch', '${eval.totalCampaigns}', Icons.campaign, Colors.blue),
              ),
              Expanded(
                child: _buildStatItem('Đã hoàn thành', '${eval.completedCampaigns}', Icons.check_circle, Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Đã hủy', '${eval.cancelledCampaigns}', Icons.cancel, Colors.red),
              ),
              Expanded(
                child: _buildStatItem('Báo cáo', '${eval.totalReports}', Icons.flag, Colors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReputationSection(VolunteerTrustEval eval) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Đánh giá từ chiến dịch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getFeedbackColor(eval.avgFeedbackScore).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        if (eval.avgFeedbackScore >= starValue) {
                          return const Icon(Icons.star, color: Colors.amber, size: 24);
                        } else if (eval.avgFeedbackScore >= starValue - 0.5) {
                          return const Icon(Icons.star_half, color: Colors.amber, size: 24);
                        } else {
                          return const Icon(Icons.star_border, color: Colors.amber, size: 24);
                        }
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      eval.avgFeedbackScore.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getFeedbackColor(eval.avgFeedbackScore),
                      ),
                    ),
                    Text(
                      'Điểm TB',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeedbackStat('Hoàn thành tốt', Colors.green),
                    const SizedBox(height: 8),
                    _buildFeedbackStat('Đáng tin cậy', Colors.blue),
                    const SizedBox(height: 8),
                    _buildFeedbackStat('Cần cải thiện', Colors.orange),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackStat(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildRecentCampaignEvals(VolunteerTrustEval eval) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Đánh giá chiến dịch gần đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...eval.recentCampaignEvals.take(5).map((c) => _buildCampaignEvalItem(c)),
        ],
      ),
    );
  }

  Widget _buildCampaignEvalItem(CampaignEvalSummary campaign) {
    final riskColor = switch (campaign.riskLevel.toUpperCase()) {
      'HIGH' => Colors.red,
      'MEDIUM' => Colors.orange,
      'LOW' => Colors.green,
      _ => Colors.grey,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: riskColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.tieuDe ?? 'Chiến dịch #${campaign.campaignId}',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (campaign.evaluatedAt != null)
                  Text(
                    DateFormat('dd/MM/yyyy').format(campaign.evaluatedAt!),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(campaign.trustScore * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getTrustColor(campaign.trustScore),
                ),
              ),
              Text(
                campaign.riskLevel,
                style: TextStyle(fontSize: 10, color: riskColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShapSection(VolunteerTrustEval eval) {
    final shapValues = eval.shapValues!;
    final sortedEntries = shapValues.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, size: 20),
              const SizedBox(width: 8),
              const Text('Yếu tố ảnh hưởng (SHAP)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedEntries.take(5).map((entry) {
            final isPositive = entry.value >= 0;
            final absValue = entry.value.abs();
            final color = isPositive ? Colors.green : Colors.red;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _formatShapKey(entry.key),
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${isPositive ? '+' : ''}${entry.value.toStringAsFixed(3)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: absValue.clamp(0, 1),
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatShapKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  Widget _buildMetadataSection(VolunteerTrustEval eval) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin đánh giá', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildMetaRow('Volunteer ID', '#${eval.volunteerId}'),
          if (eval.evaluatedAt != null)
            _buildMetaRow('Đánh giá lúc', DateFormat('dd/MM/yyyy HH:mm').format(eval.evaluatedAt!)),
          _buildMetaRow('Anomaly Detection', eval.isAnomaly ? 'Có' : 'Không'),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _getTrustColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.blue;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Color _getRiskColor(double score) {
    if (score < 0.3) return Colors.green;
    if (score < 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getActionColor(String action) {
    switch (action.toUpperCase()) {
      case 'APPROVE':
        return Colors.green;
      case 'REVIEW':
        return Colors.orange;
      case 'REJECT':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getFeedbackColor(double score) {
    if (score >= 4.5) return Colors.green;
    if (score >= 3.5) return Colors.blue;
    if (score >= 2.5) return Colors.orange;
    return Colors.red;
  }
}
