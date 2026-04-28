import 'package:flutter/material.dart';

class VolunteerTrustPanel extends StatefulWidget {
  final int volunteerId;

  const VolunteerTrustPanel({super.key, required this.volunteerId});

  @override
  State<VolunteerTrustPanel> createState() => _VolunteerTrustPanelState();
}

class _VolunteerTrustPanelState extends State<VolunteerTrustPanel> {
  bool _isLoading = false;
  String? _error;
  // Placeholder - implement when backend volunteer trust eval API is available
  Map<String, dynamic>? _evaluation;

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
    // TODO: Wire up volunteer trust eval API when backend is ready
    // final result = await _repo.getVolunteerTrustEval(widget.volunteerId);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isLoading = false;
        // Placeholder mock data
        _evaluation = null;
      });
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
            color: Colors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.verified_user, color: Colors.teal, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trust Evaluation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Đánh giá độ tin cậy tình nguyện viên', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
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
          Text('Chưa có đánh giá nào cho tình nguyện viên này', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // TODO: Implement when backend provides volunteer trust eval data
    return const Center(
      child: Text('Dữ liệu đánh giá TNV đang được cập nhật'),
    );
  }
}
