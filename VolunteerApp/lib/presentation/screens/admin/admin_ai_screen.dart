import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AdminAIScreen extends StatefulWidget {
  const AdminAIScreen({super.key});

  @override
  State<AdminAIScreen> createState() => _AdminAIScreenState();
}

class _AdminAIScreenState extends State<AdminAIScreen> {
  final _searchController = TextEditingController();
  String _selectedRadius = '25';
  bool _showResults = false;

  // Mock data - replace with AI matching API when backend is ready
  final List<Map<String, dynamic>> _campaigns = [
    {
      'id': 1,
      'title': 'Chiến dịch cứu trợ miền Trung',
      'location': 'Quảng Bình',
      'startDate': '15/05/2026',
      'category': 'Nhân đạo',
      'priority': ' Cao',
    },
    {
      'id': 2,
      'title': 'Dạy học miễn phí cho trẻ em',
      'location': 'Hà Nội',
      'startDate': '20/05/2026',
      'category': 'Giáo dục',
      'priority': 'Trung bình',
    },
    {
      'id': 3,
      'title': 'Dọn dẹp bãi biển',
      'location': 'Đà Nẵng',
      'startDate': '01/06/2026',
      'category': 'Môi trường',
      'priority': 'Thấp',
    },
    {
      'id': 4,
      'title': 'Khám bệnh miễn phí',
      'location': 'TP.HCM',
      'startDate': '10/06/2026',
      'category': 'Y tế',
      'priority': 'Cao',
    },
  ];

  final List<Map<String, dynamic>> _suggestions = [
    {'name': 'Nguyễn Văn A', 'email': 'nvana@email.com', 'score': 92, 'skills': ['Y tế', 'Cứu hộ'], 'distance': '5km', 'experience': 4.8, 'availability': true},
    {'name': 'Trần Thị B', 'email': 'ttb@email.com', 'score': 87, 'skills': ['Giáo dục', 'Tổ chức'], 'distance': '8km', 'experience': 4.5, 'availability': true},
    {'name': 'Lê Văn C', 'email': 'lvc@email.com', 'score': 95, 'skills': ['Y tế', 'Cứu hộ', 'Tổ chức'], 'distance': '12km', 'experience': 5.0, 'availability': true},
    {'name': 'Phạm Thị D', 'email': 'ptd@email.com', 'score': 78, 'skills': ['Giáo dục'], 'distance': '3km', 'experience': 4.2, 'availability': false},
    {'name': 'Hoàng Văn E', 'email': 'hve@email.com', 'score': 88, 'skills': ['Môi trường', 'Tổ chức'], 'distance': '15km', 'experience': 4.6, 'availability': true},
    {'name': 'Vũ Thị F', 'email': 'vtf@email.com', 'score': 83, 'skills': ['Y tế', 'Giáo dục'], 'distance': '20km', 'experience': 4.3, 'availability': true},
    {'name': 'Đặng Văn G', 'email': 'dvg@email.com', 'score': 90, 'skills': ['Cứu hộ', 'Tổ chức', 'Y tế'], 'distance': '7km', 'experience': 4.9, 'availability': true},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.blue;
    if (score >= 60) return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchSection(),
                  if (_showResults) ...[
                    const SizedBox(height: 16),
                    _buildCampaignSelector(),
                    const SizedBox(height: 16),
                    _buildSuggestionsTable(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF3B6DE7)],
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
                'Quản lý AI',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Gợi ý tình nguyện viên phù hợp cho chiến dịch',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tìm kiếm chiến dịch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tên chiến dịch...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRadius,
                    items: const [
                      DropdownMenuItem(value: '10', child: Text('10km')),
                      DropdownMenuItem(value: '25', child: Text('25km')),
                      DropdownMenuItem(value: '50', child: Text('50km')),
                      DropdownMenuItem(value: '100', child: Text('100km')),
                      DropdownMenuItem(value: '0', child: Text('Không giới hạn')),
                    ],
                    onChanged: (v) => setState(() => _selectedRadius = v ?? '25'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _showResults = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đang phân tích...'), backgroundColor: Colors.blue, duration: Duration(seconds: 1)),
                  );
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Chạy AI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chiến dịch đã chọn', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._campaigns.map((c) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.flag, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${c['location']} • ${c['startDate']} • ${c['category']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(c['priority'] as String, style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSuggestionsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text('${_suggestions.length} tình nguyện viên được gợi ý', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
              columns: const [
                DataColumn(label: Text('Điểm', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Tình nguyện viên', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Kỹ năng', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Khoảng cách', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Kinh nghiệm', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _suggestions.map((s) {
                final score = (s['score'] as int).toDouble();
                final scoreColor = _getScoreColor(score);
                return DataRow(
                  color: score >= 90 ? WidgetStateProperty.all(Colors.green.withValues(alpha: 0.05)) : null,
                  cells: [
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${s['score']}',
                          style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(s['email'] as String, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    DataCell(
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: (s['skills'] as List<String>).map((sk) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(sk, style: const TextStyle(fontSize: 10, color: AppTheme.primaryColor)),
                        )).toList(),
                      ),
                    ),
                    DataCell(Text('${s['distance']}')),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text('${s['experience']}'),
                        ],
                      ),
                    ),
                    DataCell(
                      s['availability'] == true
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('Sẵn sàng', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('Bận', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                            ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
