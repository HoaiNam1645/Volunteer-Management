import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/admin_repository.dart';

class TrustEvalCampaignDetailScreen extends StatefulWidget {
  final int campaignId;

  const TrustEvalCampaignDetailScreen({super.key, required this.campaignId});

  @override
  State<TrustEvalCampaignDetailScreen> createState() => _TrustEvalCampaignDetailScreenState();
}

class _TrustEvalCampaignDetailScreenState extends State<TrustEvalCampaignDetailScreen> {
  final AdminRepository _repo = AdminRepository();

  bool _isLoading = true;
  String? _error;
  CampaignTrustEval? _evaluation;
  bool _isRefreshing = false;

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

    final result = await _repo.getCampaignTrustEval(widget.campaignId);
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

  Future<void> _refreshEvaluation() async {
    setState(() => _isRefreshing = true);

    final result = await _repo.refreshCampaignTrustEval(widget.campaignId);
    if (mounted) {
      setState(() => _isRefreshing = false);
      if (result.success) {
        setState(() => _evaluation = result.data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã làm mới đánh giá thành công')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Làm mới thất bại'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Chi tiết đánh giá'),
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _refreshEvaluation,
            icon: _isRefreshing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            tooltip: 'Làm mới đánh giá',
          ),
        ],
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
          _buildValidationSection(eval),
          const SizedBox(height: 16),
          if (eval.contentAnalysis != null) ...[
            _buildContentAnalysisSection(eval),
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

  Widget _buildHeader(CampaignTrustEval eval) {
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
              Expanded(
                child: Text(
                  eval.tieuDe,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              _buildRiskBadge(eval.riskLevel),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(Icons.shield, eval.trustLabel.replaceAll('_', ' '), _getTrustColor(eval.trustScore)),
              _buildInfoChip(Icons.recommend, eval.recommendedAction.replaceAll('_', ' '), _getActionColor(eval.recommendedAction)),
              if (eval.isAnomaly)
                _buildInfoChip(Icons.warning, 'Anomaly', Colors.purple),
              if (eval.confidence != null)
                _buildInfoChip(Icons.verified, 'Confidence: ${(eval.confidence! * 100).toStringAsFixed(0)}%', Colors.blue),
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

  Widget _buildScoreSection(CampaignTrustEval eval) {
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
          const Text('Điểm số', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildValidationSection(CampaignTrustEval eval) {
    final validation = eval.validation;
    if (validation == null) return const SizedBox.shrink();

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
              Icon(
                validation.passed ? Icons.check_circle : Icons.error,
                color: validation.passed ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                'Kết quả kiểm tra',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: validation.passed ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (validation.criticalErrors.isNotEmpty) ...[
            const Text('Lỗi nghiêm trọng:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
            const SizedBox(height: 8),
            ...validation.criticalErrors.map((e) => _buildErrorItem(e, Colors.red)),
            const SizedBox(height: 12),
          ],
          if (validation.warnings.isNotEmpty) ...[
            const Text('Cảnh báo:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange)),
            const SizedBox(height: 8),
            ...validation.warnings.map((e) => _buildErrorItem(e, Colors.orange)),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorItem(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildContentAnalysisSection(CampaignTrustEval eval) {
    final content = eval.contentAnalysis!;

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
          const Text('Phân tích nội dung', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (content.riskKeywords.isNotEmpty) ...[
            const Text('Từ khóa rủi ro:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: content.riskKeywords.map((kw) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kw.keyword, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 12)),
                      if (kw.score != null)
                        Text(
                          'Score: ${kw.score!.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 10, color: Colors.red[700]),
                        ),
                      if (kw.context != null)
                        Text(
                          '"${kw.context}"',
                          style: TextStyle(fontSize: 10, color: Colors.grey[600], fontStyle: FontStyle.italic),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (content.vaguenessSignals.isNotEmpty) ...[
            const Text('Tín hiệu mơ hồ:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange)),
            const SizedBox(height: 8),
            ...content.vaguenessSignals.map((s) => _buildSignalItem(s, Icons.help_outline, Colors.orange)),
            const SizedBox(height: 12),
          ],
          if (content.safetyDescriptions.isNotEmpty) ...[
            const Text('Mô tả an toàn:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
            const SizedBox(height: 8),
            ...content.safetyDescriptions.map((s) => _buildSignalItem(s, Icons.check_circle, Colors.green)),
          ],
        ],
      ),
    );
  }

  Widget _buildSignalItem(String text, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildShapSection(CampaignTrustEval eval) {
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
              const Text('SHAP Values', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                'Top ${sortedEntries.length > 5 ? 5 : sortedEntries.length} factors',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
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

  Widget _buildMetadataSection(CampaignTrustEval eval) {
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
          _buildMetaRow('Campaign ID', '#${eval.campaignId}'),
          if (eval.evaluatedAt != null)
            _buildMetaRow('Đánh giá lúc', DateFormat('dd/MM/yyyy HH:mm').format(eval.evaluatedAt!)),
          _buildMetaRow('Anomaly Detection', eval.isAnomaly ? 'Có' : 'Không'),
          _buildMetaRow('Confidence', eval.confidence != null ? '${(eval.confidence! * 100).toStringAsFixed(1)}%' : 'N/A'),
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
}
