import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SchoolStatisticsScreen extends StatefulWidget {
  const SchoolStatisticsScreen({super.key});

  @override
  State<SchoolStatisticsScreen> createState() => _SchoolStatisticsScreenState();
}

class _SchoolStatisticsScreenState extends State<SchoolStatisticsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  
  // Statistics data
  int _totalJobs = 0;
  int _activeJobs = 0;
  int _totalApplications = 0;
  int _pendingApplications = 0;
  int _acceptedApplications = 0;
  int _rejectedApplications = 0;
  int _totalPartnerships = 0;
  int _activePartnerships = 0;
  
  // Chart data
  List<MapEntry<String, int>> _jobsByMonth = [];
  List<MapEntry<String, int>> _topDepartments = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Load all statistics in parallel
      await Future.wait([
        _loadJobStatistics(userId),
        _loadApplicationStatistics(userId),
        _loadPartnershipStatistics(userId),
        _loadChartData(userId),
      ]);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thống kê: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadJobStatistics(String schoolId) async {
    try {
      final jobsData = await _supabase
          .from('jobs')
          .select('id, status, is_active')
          .eq('creator_id', schoolId);
      
      _totalJobs = jobsData.length;
      _activeJobs = jobsData.where((job) => 
          job['status'] == 'approved' && job['is_active'] == true).length;
    } catch (e) {
      debugPrint('Error loading job statistics: $e');
    }
  }

  Future<void> _loadApplicationStatistics(String schoolId) async {
    try {
      // Lấy tất cả jobs (regular) của school
      final jobsData = await _supabase
          .from('jobs')
          .select('id')
          .eq('creator_id', schoolId);
      
      // Lấy tất cả partnership jobs của school
      final partnershipJobsData = await _supabase
          .from('school_partnership_jobs')
          .select('id')
          .eq('school_id', schoolId);
      
      final allJobIds = [
        ...(jobsData as List).map((j) => j['id'] as String),
        ...(partnershipJobsData as List).map((j) => j['id'] as String),
      ];
      
      if (allJobIds.isEmpty) {
        _totalApplications = 0;
        _pendingApplications = 0;
        _acceptedApplications = 0;
        _rejectedApplications = 0;
        return;
      }

      // Lấy activities từ tất cả jobs (regular + partnership)
      final activitiesData = await _supabase
          .from('user_job_activities')
          .select('application_status')
          .inFilter('job_id', allJobIds)
          .eq('is_applied', true);
      
      _totalApplications = activitiesData.length;
      _pendingApplications = activitiesData.where((app) => 
          app['application_status'] == 'pending').length;
      _acceptedApplications = activitiesData.where((app) => 
          app['application_status'] == 'accepted').length;
      _rejectedApplications = activitiesData.where((app) => 
          app['application_status'] == 'rejected').length;
    } catch (e) {
      debugPrint('Error loading application statistics: $e');
      _totalApplications = 0;
      _pendingApplications = 0;
      _acceptedApplications = 0;
      _rejectedApplications = 0;
    }
  }

  Future<void> _loadPartnershipStatistics(String schoolId) async {
    try {
      final partnershipJobsData = await _supabase
          .from('school_partnership_jobs')
          .select('id, company_status, admin_status')
          .eq('school_id', schoolId);
      
      _totalPartnerships = partnershipJobsData.length;
      // Active = company_status = 'accepted' AND admin_status = 'approved'
      _activePartnerships = partnershipJobsData.where((p) => 
          p['company_status'] == 'accepted' && p['admin_status'] == 'approved').length;
    } catch (e) {
      debugPrint('Error loading partnership statistics: $e');
    }
  }

  Future<void> _loadChartData(String schoolId) async {
    try {
      // Replace: Jobs by month -> Applications by week/month
      final last30Days = DateTime.now().subtract(const Duration(days: 30));
      final activitiesData = await _supabase
          .from('user_job_activities')
          .select('applied_at')
          .gte('applied_at', last30Days.toIso8601String())
          .eq('is_applied', true)
          .inFilter('job_id', await _getSchoolJobIds(schoolId));
      
      final Map<String, int> dayCounts = {};
      for (var activity in activitiesData) {
        try {
          final date = DateTime.parse(activity['applied_at']);
          final dayKey = DateFormat('dd/MM').format(date);
          dayCounts[dayKey] = (dayCounts[dayKey] ?? 0) + 1;
        } catch (e) {
          // Skip invalid dates
        }
      }
      _jobsByMonth = dayCounts.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      // Applications by status - sử dụng dữ liệu đã load

      // Top fields/positions with most jobs
      final jobsData = await _supabase
          .from('jobs')
          .select('metadata')
          .eq('creator_id', schoolId);
      
      final Map<String, int> fieldCounts = {};
      for (var job in jobsData) {
        try {
          final metadata = job['metadata'] as Map<String, dynamic>;
          final fields = metadata['fields'] as List?;
          if (fields != null && fields.isNotEmpty) {
            final field = fields.first.toString();
            fieldCounts[field] = (fieldCounts[field] ?? 0) + 1;
          }
        } catch (e) {
          // Skip if metadata parsing fails
        }
      }
      
      _topDepartments = fieldCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(5).toList();
    } catch (e) {
      debugPrint('Error loading chart data: $e');
    }
  }

  // Helper method to get all school's job IDs
  Future<List<String>> _getSchoolJobIds(String schoolId) async {
    final jobsData = await _supabase
        .from('jobs')
        .select('id')
        .eq('creator_id', schoolId);
    
    final partnershipJobsData = await _supabase
        .from('school_partnership_jobs')
        .select('id')
        .eq('school_id', schoolId);
    
    return [
      ...(jobsData as List).map((j) => j['id'] as String),
      ...(partnershipJobsData as List).map((j) => j['id'] as String),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadStatistics,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOverviewCards(),
                            const SizedBox(height: 24),
                            _buildJobsChart(),
                            const SizedBox(height: 24),
                            _buildApplicationsChart(),
                            const SizedBox(height: 24),
                            _buildDepartmentsChart(),
                            const SizedBox(height: 24),
                            _buildPartnershipCard(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2196F3),
            Color(0xFF1976D2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thống kê',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Báo cáo tuyển dụng',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tổng quan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Tin tuyển dụng',
              '$_totalJobs',
              Icons.work_outline,
              Colors.blue,
              subtitle: '$_activeJobs hoạt động',
            ),
            _buildStatCard(
              'Ứng tuyển',
              '$_totalApplications',
              Icons.description_outlined,
              Colors.green,
              subtitle: '$_pendingApplications chờ duyệt',
            ),
            _buildStatCard(
              'Liên kết DN',
              '$_totalPartnerships',
              Icons.handshake_outlined,
              Colors.purple,
              subtitle: '$_activePartnerships hoạt động',
            ),
            _buildStatCard(
              'Tỷ lệ chấp nhận',
              _totalApplications > 0 
                  ? '${(_acceptedApplications / _totalApplications * 100).toStringAsFixed(0)}%'
                  : 'N/A',
              Icons.check_circle_outline,
              Colors.orange,
              subtitle: '$_acceptedApplications/$_totalApplications đã chấp nhận',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJobsChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.trending_up, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ứng tuyển trong 30 ngày',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _jobsByMonth.isEmpty
                ? const Center(child: Text('Chưa có ứng tuyển'))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[200],
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: (_jobsByMonth.length / 4).ceilToDouble(),
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < _jobsByMonth.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _jobsByMonth[value.toInt()].key,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _jobsByMonth.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
                          }).toList(),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.blue,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pie_chart, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Trạng thái ứng tuyển',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _totalApplications == 0
              ? const SizedBox(
                  height: 150,
                  child: Center(child: Text('Chưa có ứng tuyển')),
                )
              : SizedBox(
                  height: 180,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 1,
                            centerSpaceRadius: 35,
                            sections: _buildPieChartSections(),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_pendingApplications > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildLegendItem('Chờ duyệt', Colors.orange, _pendingApplications),
                              ),
                            if (_acceptedApplications > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildLegendItem('Chấp nhận', Colors.green, _acceptedApplications),
                              ),
                            if (_rejectedApplications > 0)
                              _buildLegendItem('Từ chối', Colors.red, _rejectedApplications),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final sections = <PieChartSectionData>[];
    
    if (_pendingApplications > 0) {
      sections.add(
        PieChartSectionData(
          value: _pendingApplications.toDouble(),
          title: '$_pendingApplications',
          color: Colors.orange,
          radius: 45,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    
    if (_acceptedApplications > 0) {
      sections.add(
        PieChartSectionData(
          value: _acceptedApplications.toDouble(),
          title: '$_acceptedApplications',
          color: Colors.green,
          radius: 45,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    
    if (_rejectedApplications > 0) {
      sections.add(
        PieChartSectionData(
          value: _rejectedApplications.toDouble(),
          title: '$_rejectedApplications',
          color: Colors.red,
          radius: 45,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    
    return sections;
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentsChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart, color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Top ngành nghề',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _topDepartments.isEmpty
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Chưa có dữ liệu'),
                ))
              : Column(
                  children: _topDepartments.map((dept) {
                    final maxValue = _topDepartments.first.value;
                    final percentage = (dept.value / maxValue);
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  dept.key,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${dept.value} tin',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage,
                              minHeight: 8,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.purple.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildPartnershipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.handshake, color: Colors.teal, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Liên kết doanh nghiệp',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPartnershipInfo(
                  'Tổng liên kết',
                  _totalPartnerships.toString(),
                  Icons.business_outlined,
                  Colors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPartnershipInfo(
                  'Đang hoạt động',
                  _activePartnerships.toString(),
                  Icons.check_circle_outline,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartnershipInfo(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
