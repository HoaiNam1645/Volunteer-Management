import 'package:flutter/material.dart';
import '../../../data/repositories/admin_repository.dart';

class TrustEvalPanel extends StatefulWidget {
  final int campaignId;
  final bool autoLoad;

  const TrustEvalPanel({
    super.key,
    required this.campaignId,
    this.autoLoad = true,
  });

  @override
  State<TrustEvalPanel> createState() => _TrustEvalPanelState();
}

class _TrustEvalPanelState extends State<TrustEvalPanel> {
  final AdminRepository _repo = AdminRepository();

  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  CampaignTrustEval? _evaluation;
  bool _mlHealthy = false;
  int? _modelsLoaded;

  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) {
      _loadAll();
    }
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final evalResult = await _repo.getCampaignTrustEval(widget.campaignId);
      final healthResult = await _repo.getTrustEvalHealth();

      if (mounted) {
        if (evalResult.success && evalResult.data != null) {
          setState(() {
            _evaluation = evalResult.data;
          });
        } else {
          setState(() {
            _error = evalResult.message ?? 'Không lấy được đánh giá';
          });
        }

        if (healthResult.success && healthResult.data != null) {
          setState(() {
            _mlHealthy = healthResult.data!.healthy;
            _modelsLoaded = healthResult.data!.modelsLoaded;
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    try {
      final result = await _repo.refreshCampaignTrustEval(widget.campaignId);
      if (mounted) {
        if (result.success && result.data != null) {
          setState(() => _evaluation = result.data);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã làm mới đánh giá'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? 'Làm mới thất bại'), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_error != null)
            _buildErrorState()
          else if (_evaluation != null)
            _buildContent()
          else
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.psychology, color: Colors.purple, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trust Evaluation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Đánh giá độ tin cậy chiến dịch bằng AI', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        if (!_isLoading)
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh, size: 20),
            onPressed: _isRefreshing ? null : _handleRefresh,
            color: Colors.purple,
            tooltip: 'Làm mới đánh giá',
          ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.warning_amber, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.auto_graph, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text('Chưa có đánh giá nào', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _handleRefresh,
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Chạy đánh giá'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final eval = _evaluation!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildScoreCircle(
              label: 'Trust Score',
              value: eval.trustScore,
              color: _getTrustColor(eval.trustScore),
            ),
            const SizedBox(width: 24),
            _buildScoreCircle(
              label: 'Risk Score',
              value: eval.riskScore,
              color: _getRiskColor(eval.riskScore),
            ),
            const SizedBox(width: 24),
            Expanded(child: _buildRiskLevelBadge(eval.riskLevel)),
          ],
        ),
        const SizedBox(height: 16),
        _buildRecommendationRow(eval.recommendedAction),
        const SizedBox(height: 16),
        if (eval.validation != null)
          _buildValidationSection(eval.validation!),
        if (eval.contentAnalysis != null) ...[
          const SizedBox(height: 16),
          _buildContentAnalysisSection(eval.contentAnalysis!),
        ],
        if (eval.evaluatedAt != null) ...[
          const SizedBox(height: 16),
          Text(
            'Đánh giá lúc: ${_formatDateTime(eval.evaluatedAt!)}',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ],
    );
  }

  Widget _buildScoreCircle({required String label, required double value, required Color color}) {
    final percent = (value * 100).toInt();
    return Column(
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  strokeWidth: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildRiskLevelBadge(String level) {
    final config = switch (level.toUpperCase()) {
      'LOW' => ('Thấp', Colors.green),
      'MEDIUM' => ('Trung bình', Colors.orange),
      'HIGH' => ('Cao', Colors.red),
      'CRITICAL' => ('Nghiêm trọng', Colors.purple),
      _ => ('Không xác định', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (config.$2 as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: config.$2 as Color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mức độ rủi ro', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            config.$1,
            style: TextStyle(fontWeight: FontWeight.bold, color: config.$2 as Color),
          ),
          if (_mlHealthy)
            Row(
              children: [
                Container(
                  width: 6, height: 6,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  '$_modelsLoaded ML models',
                  style: const TextStyle(fontSize: 10, color: Colors.green),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationRow(String action) {
    final config = switch (action.toUpperCase()) {
      'APPROVE' => ('✓ Duyệt', Colors.green),
      'APPROVE_WITH_NOTE' => ('⚠ Duyệt kèm ghi chú', Colors.orange),
      'REQUEST_ADDITIONAL_INFO' => ('? Yêu cầu bổ sung', Colors.blue),
      'REJECT' => ('✗ Từ chối', Colors.red),
      _ => ('— Không rõ', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (config.$2 as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(config.$1, style: TextStyle(fontWeight: FontWeight.bold, color: config.$2 as Color)),
          const Spacer(),
          Text('Hành động khuyến nghị', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildValidationSection(ValidationResult validation) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: validation.passed
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: validation.passed
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                validation.passed ? Icons.check_circle : Icons.error,
                color: validation.passed ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                validation.passed ? 'Hợp lệ' : 'Cảnh báo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: validation.passed ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          if (validation.criticalErrors.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...validation.criticalErrors.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.close, size: 12, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(child: Text(e, style: const TextStyle(fontSize: 12, color: Colors.red))),
                ],
              ),
            )),
          ],
          if (validation.warnings.isNotEmpty) ...[
            ...validation.warnings.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.warning, size: 12, color: Colors.orange),
                  const SizedBox(width: 4),
                  Expanded(child: Text(w, style: const TextStyle(fontSize: 12, color: Colors.orange))),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildContentAnalysisSection(ContentAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Phân tích nội dung', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        if (analysis.riskKeywords.isNotEmpty) ...[
          const Text('Từ khóa rủi ro:', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: analysis.riskKeywords.map((kw) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                kw.keyword,
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
            )).toList(),
          ),
        ],
        if (analysis.vaguenessSignals.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Tín hiệu mơ hồ:', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ...analysis.vaguenessSignals.map((s) => Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('• $s', style: const TextStyle(fontSize: 12)),
          )),
        ],
        if (analysis.safetyDescriptions.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Mô tả an toàn:', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ...analysis.safetyDescriptions.map((s) => Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('✓ $s', style: const TextStyle(fontSize: 12, color: Colors.green)),
          )),
        ],
      ],
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

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
