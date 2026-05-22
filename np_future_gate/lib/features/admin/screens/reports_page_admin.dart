import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:np_future_gate/features/admin/controllers/reports_admin_controller.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';

class ReportsPageAdmin extends StatefulWidget {
  const ReportsPageAdmin({super.key, this.isStandalone = false});

  final bool isStandalone;

  @override
  State<ReportsPageAdmin> createState() => _ReportsPageAdminState();
}

class _ReportsPageAdminState extends State<ReportsPageAdmin> {
  late final ReportsAdminController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReportsAdminController();
    _controller.addListener(_onControllerChanged);
    _controller.loadStatistics();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading && _controller.statistics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.hasError && _controller.statistics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Không thể tải dữ liệu',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _controller.loadStatistics,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final statistics = _controller.statistics;
    final selectedPeriod = _controller.selectedPeriod;

    final content = RefreshIndicator(
      onRefresh: _controller.loadStatistics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Báo cáo & Phân tích',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Reports & Analytics',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // Time Range Selector
            Row(
              children: [
                Expanded(
                  child: _buildTimeRangeButton('7 ngày', '7'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTimeRangeButton('30 ngày', '30'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTimeRangeButton('90 ngày', '90'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTimeRangeButton('1 năm', '365'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Overview Stats
            Row(
              children: [
                Expanded(
                  child: _buildMiniStatCard(
                    'Người dùng',
                    (statistics?.totalUsers ?? 0).toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniStatCard(
                    'Việc làm',
                    (statistics?.totalJobs ?? 0).toString(),
                    Icons.work,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMiniStatCard(
                    'Ứng tuyển',
                    (statistics?.totalApplications ?? 0).toString(),
                    Icons.description,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniStatCard(
                    'Phỏng vấn',
                    (statistics?.totalInterviews ?? 0).toString(),
                    Icons.event,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Detailed Charts
            _buildReportCard(
              title: 'Người dùng mới',
              icon: Icons.trending_up,
              color: Colors.blue,
              value: '+${statistics?.newUsersInPeriod ?? 0}',
              description: 'Trong ${selectedPeriod == "7" ? "7 ngày" : selectedPeriod == "30" ? "30 ngày" : selectedPeriod == "90" ? "90 ngày" : "1 năm"} qua',
              chart: _buildLineChart(_controller.usersByDay, Colors.blue),
            ),
            const SizedBox(height: 16),
            _buildReportCard(
              title: 'Việc làm đăng',
              icon: Icons.work,
              color: Colors.orange,
              value: '+${statistics?.newJobsInPeriod ?? 0}',
              description: 'Trong ${selectedPeriod == "7" ? "7 ngày" : selectedPeriod == "30" ? "30 ngày" : selectedPeriod == "90" ? "90 ngày" : "1 năm"} qua',
              chart: _buildLineChart(_controller.jobsByDay, Colors.orange),
            ),
            const SizedBox(height: 16),
            _buildReportCard(
              title: 'Ứng tuyển',
              icon: Icons.description,
              color: Colors.green,
              value: '+${statistics?.newApplicationsInPeriod ?? 0}',
              description: 'Trong ${selectedPeriod == "7" ? "7 ngày" : selectedPeriod == "30" ? "30 ngày" : selectedPeriod == "90" ? "90 ngày" : "1 năm"} qua',
              chart: _buildLineChart(_controller.applicationsByDay, Colors.green),
            ),
            const SizedBox(height: 16),
            _buildReportCard(
              title: 'Tỷ lệ thành công',
              icon: Icons.check_circle,
              color: Colors.purple,
              value: '${(statistics?.applicationSuccessRate ?? 0.0).toStringAsFixed(1)}%',
              description: 'Ứng tuyển được duyệt',
              chart: _buildSuccessRateChart(),
            ),
            const SizedBox(height: 16),

            // Distribution Charts
            Row(
              children: [
                Expanded(
                  child: _buildDistributionCard(
                    title: 'Người dùng theo vai trò',
                    data: statistics?.usersByRole ?? {},
                    colors: [Colors.blue, Colors.orange, Colors.green, Colors.purple],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDistributionCard(
                    title: 'Việc làm theo trạng thái',
                    data: statistics?.jobsByStatus ?? {},
                    colors: [Colors.green, Colors.red],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!widget.isStandalone) {
      return content;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Báo cáo'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(child: content),
    );
  }

  Widget _buildTimeRangeButton(String label, String value) {
    final isActive = _controller.selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        _controller.setPeriod(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppMainColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppMainColors.primary : Colors.grey.shade300,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppMainColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> data, Color color) {
    if (data.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Chưa có dữ liệu',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final maxValue = data.map((e) => e['count'] as int).reduce((a, b) => a > b ? a : b).toDouble();
    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), (entry.value['count'] as int).toDouble());
    }).toList();

    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,
          maxY: maxValue > 0 ? maxValue * 1.2 : 10,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessRateChart() {
    final successRate = _controller.statistics?.applicationSuccessRate ?? 0.0;
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: successRate / 100,
              strokeWidth: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${successRate.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              Text(
                'Tỷ lệ thành công',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionCard({
    required String title,
    required Map<String, int> data,
    required List<Color> colors,
  }) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Chưa có dữ liệu',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    final total = data.values.reduce((a, b) => a + b);
    final entries = data.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...entries.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final percentage = (item.value / total * 100).toStringAsFixed(1);
            final color = colors[index % colors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getRoleLabel(item.key),
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.value} ($percentage%)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: item.value / total,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getRoleLabel(String key) {
    final labels = {
      'student': 'Học sinh',
      'employer': 'Nhà tuyển dụng',
      'school': 'Trường học',
      'admin': 'Quản trị viên',
      'user': 'Người dùng',
      'active': 'Đang hoạt động',
      'expired': 'Đã hết hạn',
    };
    return labels[key] ?? key;
  }

  Widget _buildReportCard({
    required String title,
    required IconData icon,
    required Color color,
    required String value,
    required String description,
    required Widget chart,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          chart,
        ],
      ),
    );
  }
}
