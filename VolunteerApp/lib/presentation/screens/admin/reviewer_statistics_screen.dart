import 'package:flutter/material.dart';
import '../../../data/repositories/reviewer_repository.dart';

class ReviewerStatisticsScreen extends StatefulWidget {
  const ReviewerStatisticsScreen({super.key});

  @override
  State<ReviewerStatisticsScreen> createState() => _ReviewerStatisticsScreenState();
}

class _ReviewerStatisticsScreenState extends State<ReviewerStatisticsScreen> {
  final ReviewerRepository _repository = ReviewerRepository();

  bool _isLoading = true;
  String? _error;
  ReviewerStatistics? _stats;

  String _period = 'month';
  bool _showCampaigns = true;

  static const List<Map<String, String>> _periodOptions = [
    {'value': 'week', 'label': '7 ngày'},
    {'value': 'month', 'label': 'Tháng'},
    {'value': 'quarter', 'label': 'Quý'},
    {'value': 'year', 'label': 'Năm'},
  ];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _repository.getStatistics(_period);
      if (!mounted) return;

      if (result.success) {
        _stats = result.data;
      } else {
        _error = result.message;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Lỗi kết nối');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  IconData _parseIcon(String iconName) {
    final iconMap = {
      'fa-solid fa-flag': Icons.flag,
      'fa-solid fa-users': Icons.people,
      'fa-solid fa-check-circle': Icons.check_circle,
      'fa-solid fa-clock': Icons.schedule,
      'fa-solid fa-star': Icons.star,
      'fa-solid fa-chart': Icons.bar_chart,
    };
    return iconMap[iconName] ?? Icons.circle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Thống kê'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStatistics,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _stats == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Không có dữ liệu',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadStatistics,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Period selector
                            _buildPeriodSelector(),
                            const SizedBox(height: 16),

                            // KPIs
                            _buildKpiSection(),
                            const SizedBox(height: 16),

                            // Chart section
                            _buildChartSection(),
                            const SizedBox(height: 16),

                            // Status distribution
                            _buildStatusSection(),
                            const SizedBox(height: 16),

                            // Top regions & skills
                            _buildTopSection(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.grey),
          const SizedBox(width: 12),
          const Text(
            'Kỳ thống kê:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          DropdownButton<String>(
            value: _period,
            underline: const SizedBox(),
            items: _periodOptions.map((opt) {
              return DropdownMenuItem<String>(
                value: opt['value'],
                child: Text(opt['label']!),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _period = value);
                _loadStatistics();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSection() {
    if (_stats!.kpis.isEmpty) return const SizedBox();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: _stats!.kpis.length,
      itemBuilder: (context, index) {
        final kpi = _stats!.kpis[index];
        return _buildKpiCard(kpi);
      },
    );
  }

  Widget _buildKpiCard(KpiItem kpi) {
    final bgColor = _parseColor(kpi.bgColor);
    final fgColor = _parseColor(kpi.color);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  kpi.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _parseIcon(kpi.icon),
                  color: fgColor,
                  size: 18,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            kpi.value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: fgColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                kpi.trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: kpi.trendUp ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                kpi.trendText,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    if (_stats!.monthlyData.isEmpty) return const SizedBox();

    final maxValue = _stats!.monthlyData.fold<int>(
      1,
      (max, item) {
        final value = _showCampaigns ? item.campaigns : item.volunteers;
        return value > max ? value : max;
      },
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getChartTitle(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  _buildChartToggle(
                    label: 'Chiến dịch',
                    isActive: _showCampaigns,
                    color: Theme.of(context).primaryColor,
                    onTap: () => setState(() => _showCampaigns = true),
                  ),
                  const SizedBox(width: 8),
                  _buildChartToggle(
                    label: 'TNV',
                    isActive: !_showCampaigns,
                    color: Colors.green,
                    onTap: () => setState(() => _showCampaigns = false),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tổng: ${_showCampaigns ? _stats!.periodSummary.campaigns : _stats!.periodSummary.volunteers} ${_showCampaigns ? 'chiến dịch' : 'tình nguyện viên'}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _stats!.monthlyData.map((data) {
                final value = _showCampaigns ? data.campaigns : data.volunteers;
                final heightPercent = maxValue > 0 ? (value / maxValue) : 0.0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          value.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final maxHeight = constraints.maxHeight - 24;
                              return Align(
                                alignment: Alignment.bottomCenter,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: double.infinity,
                                  height: maxHeight * heightPercent,
                                  decoration: BoxDecoration(
                                    color: _showCampaigns
                                        ? Theme.of(context).primaryColor
                                        : Colors.green,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartToggle({
    required String label,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  String _getChartTitle() {
    switch (_period) {
      case 'week':
        return 'Chiến dịch tuần';
      case 'month':
        return 'Chiến dịch tháng';
      case 'quarter':
        return 'Chiến dịch quý';
      case 'year':
        return 'Chiến dịch năm';
      default:
        return 'Chiến dịch';
    }
  }

  Widget _buildStatusSection() {
    if (_stats!.campaignStatuses.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Phân bố trạng thái',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._stats!.campaignStatuses.map((status) => _buildStatusItem(status)),
        ],
      ),
    );
  }

  Widget _buildStatusItem(CampaignStatusItem status) {
    final color = _parseColor(status.color);
    final bgColor = _parseColor(status.bgColor);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _parseIcon(status.icon),
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      status.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      status.count.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: status.percent / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildTopRegions()),
        const SizedBox(width: 12),
        Expanded(child: _buildTopSkills()),
      ],
    );
  }

  Widget _buildTopRegions() {
    if (_stats!.topRegions.isEmpty) return const SizedBox();

    final maxVolunteers = _stats!.topRegions.fold<int>(
      1,
      (max, item) => item.volunteers > max ? item.volunteers : max,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Top khu vực',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            _stats!.topRegions.length > 5 ? 5 : _stats!.topRegions.length,
            (index) {
              final region = _stats!.topRegions[index];
              final percent = maxVolunteers > 0 ? region.volunteers / maxVolunteers : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: index < 3
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: index < 3 ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  region.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${region.volunteers} TNV',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percent,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopSkills() {
    if (_stats!.topSkills.isEmpty) return const SizedBox();

    final maxCount = _stats!.topSkills.fold<int>(
      1,
      (max, item) => item.count > max ? item.count : max,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Top kỹ năng',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            _stats!.topSkills.length > 5 ? 5 : _stats!.topSkills.length,
            (index) {
              final skill = _stats!.topSkills[index];
              final percent = maxCount > 0 ? skill.count / maxCount : 0.0;
              final color = _parseColor(skill.color);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _parseIcon(skill.icon),
                        color: color,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  skill.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${skill.count} người',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percent,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
