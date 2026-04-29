import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/admin_repository.dart';

class TrustEvalDashboardScreen extends StatefulWidget {
  const TrustEvalDashboardScreen({super.key});

  @override
  State<TrustEvalDashboardScreen> createState() =>
      _TrustEvalDashboardScreenState();
}

class _TrustEvalDashboardScreenState extends State<TrustEvalDashboardScreen> {
  final AdminRepository _repo = AdminRepository();

  bool _isLoading = false;
  String? _error;
  TrustEvalStats? _stats;
  TrustEvalHealth? _health;
  List<HighRiskCampaign> _recentHighRisk = [];
  Map<String, int> _riskDistribution = {};
  Map<String, int> _trustDistribution = {};
  Map<String, int> _actionDistribution = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final statsResult = await _repo.getTrustEvalStats();
      final healthResult = await _repo.getTrustEvalHealth();

      if (mounted) {
        if (statsResult.success && statsResult.data != null) {
          final data = statsResult.data!;
          setState(() {
            _stats = data;
            _recentHighRisk = data.recentHighRisk;
            _riskDistribution = data.byRiskLevel;
            _trustDistribution = data.byTrustLabel;
            _actionDistribution = data.byRecommendedAction;
          });
        } else {
          setState(
              () => _error = statsResult.message ?? 'Không lấy được thống kê');
        }

        if (healthResult.success && healthResult.data != null) {
          setState(() => _health = healthResult.data);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Đã xảy ra lỗi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_health != null) _buildMlStatusBanner(),
                      if (_health != null) const SizedBox(height: 16),
                      _buildKpiCards(),
                      const SizedBox(height: 16),
                      _buildChartsRow(),
                      const SizedBox(height: 16),
                      _buildActionAndSourceRow(),
                      const SizedBox(height: 16),
                      _buildHighRiskTable(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple, Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Trust Evaluation',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Dashboard đánh giá độ tin cậy AI',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMlStatusBanner() {
    final h = _health!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: h.healthy
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: h.healthy
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: h.healthy ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.healthy ? 'ML Service Online' : 'ML Service Offline',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: h.healthy ? Colors.green : Colors.red,
                  ),
                ),
                if (h.modelsLoaded != null)
                  Text(
                    '${h.modelsLoaded} models loaded',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          if (!h.healthy)
            OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKpiCards() {
    final stats = _stats;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildKpiCard(
          'Tổng đánh giá',
          '${stats?.totalEvaluations ?? 0}',
          Icons.analytics,
          Colors.blue,
        ),
        _buildKpiCard(
          'Trust Score TB',
          '${((stats?.avgTrustScore ?? 0) * 100).toStringAsFixed(1)}%',
          Icons.verified_user,
          _getTrustColor(stats?.avgTrustScore ?? 0),
        ),
        _buildKpiCard(
          'Risk Score TB',
          '${((stats?.avgRiskScore ?? 0) * 100).toStringAsFixed(1)}%',
          Icons.warning_amber,
          _getRiskColor(stats?.avgRiskScore ?? 0),
        ),
        _buildKpiCard(
          'Cao rủi ro',
          '${stats?.recentHighRisk.length ?? 0}',
          Icons.error,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Text(
            value,
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121)),
          ),
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildChartsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildRiskDistribution()),
        const SizedBox(width: 12),
        Expanded(child: _buildTrustDistribution()),
      ],
    );
  }

  Widget _buildRiskDistribution() {
    final total = _riskDistribution.values.fold(0, (a, b) => a + b);
    final items = [
      ('LOW', 'Thấp', Colors.green),
      ('MEDIUM', 'TB', Colors.orange),
      ('HIGH', 'Cao', Colors.red),
      ('CRITICAL', 'Nghiêm trọng', Colors.purple),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phân bố mức rủi ro',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          ...items.map((item) {
            final count = _riskDistribution[item.$1] ?? 0;
            final percent = total > 0 ? count / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: item.$3,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(item.$2, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      Text('$count (${(percent * 100).toStringAsFixed(0)}%)',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(item.$3),
                      minHeight: 6,
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

  Widget _buildTrustDistribution() {
    final total = _trustDistribution.values.fold(0, (a, b) => a + b);
    final items = [
      ('RELIABLE_HIGH', 'Rất tin cậy', Colors.green),
      ('RELIABLE', 'Tin cậy', Colors.blue),
      ('NEUTRAL', 'Trung lập', Colors.grey),
      ('SUSPICIOUS', 'Đáng nghi', Colors.orange),
      ('SUSPICIOUS_HIGH', 'Rất đáng nghi', Colors.red),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phân bố mức tin cậy',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          ...items.map((item) {
            final count = _trustDistribution[item.$1] ?? 0;
            final percent = total > 0 ? count / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: item.$3,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(item.$2, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      Text('$count (${(percent * 100).toStringAsFixed(0)}%)',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(item.$3),
                      minHeight: 6,
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

  Widget _buildHighRiskTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                'Chiến dịch cao rủi ro gần đây (${_recentHighRisk.length})',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentHighRisk.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle,
                        size: 48, color: Colors.green[300]),
                    const SizedBox(height: 8),
                    Text('Không có chiến dịch cao rủi ro',
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            )
          else
            ..._recentHighRisk.map((c) => _buildHighRiskRow(c)),
        ],
      ),
    );
  }

  Widget _buildActionAndSourceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildActionDistribution()),
        const SizedBox(width: 12),
        Expanded(child: _buildSourceDistribution()),
      ],
    );
  }

  Widget _buildActionDistribution() {
    final total = _actionDistribution.values.fold(0, (a, b) => a + b);
    const items = [
      'APPROVE',
      'APPROVE_WITH_NOTE',
      'REQUEST_ADDITIONAL_INFO',
      'REJECT'
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recommended actions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          ...items.map((action) {
            final count = _actionDistribution[action] ?? 0;
            if (count == 0) return const SizedBox.shrink();
            final percent = total > 0 ? (count * 100 / total) : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_actionLabel(action),
                      style: const TextStyle(fontSize: 12)),
                  Text('$count (${percent.toStringAsFixed(0)}%)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSourceDistribution() {
    final source = _stats?.byEvaluationSource ?? const <String, int>{};
    final total = source.values.fold(0, (a, b) => a + b);
    final mlCount = source['ml_service'] ?? 0;
    final fallbackCount = source['fallback'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Evaluation source',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          _sourceRow('ML service', mlCount, total, Colors.blue),
          const SizedBox(height: 8),
          _sourceRow('Fallback', fallbackCount, total, Colors.grey),
        ],
      ),
    );
  }

  Widget _sourceRow(String label, int count, int total, Color color) {
    final percent = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text('$count (${(percent * 100).toStringAsFixed(0)}%)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percent,
          minHeight: 6,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'APPROVE':
        return 'Approve';
      case 'APPROVE_WITH_NOTE':
        return 'Approve with note';
      case 'REQUEST_ADDITIONAL_INFO':
        return 'Request info';
      case 'REJECT':
        return 'Reject';
      default:
        return action;
    }
  }

  Widget _buildHighRiskRow(HighRiskCampaign campaign) {
    final riskColor = switch (campaign.riskLevel.toUpperCase()) {
      'HIGH' => Colors.red,
      'CRITICAL' => Colors.purple,
      'MEDIUM' => Colors.orange,
      _ => Colors.grey,
    };

    return GestureDetector(
      onTap: () =>
          context.push('/admin/trust-eval/campaign/${campaign.campaignId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: riskColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: riskColor.withValues(alpha: 0.2)),
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
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (campaign.evaluatedAt != null)
                    Text(
                      'Đánh giá: ${DateFormat('dd/MM HH:mm').format(campaign.evaluatedAt!)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            if (campaign.isAnomaly)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, size: 12, color: Colors.purple),
                    SizedBox(width: 4),
                    Text('Anomaly',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.purple,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                campaign.riskLevel.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    color: riskColor,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Color _getTrustColor(double score) {
    if (score >= 0.9) return Colors.green;
    if (score >= 0.75) return Colors.blue;
    if (score >= 0.6) return Colors.orange;
    return Colors.grey;
  }

  Color _getRiskColor(double score) {
    if (score < 0.3) return Colors.green;
    if (score < 0.6) return Colors.orange;
    return Colors.red;
  }
}
