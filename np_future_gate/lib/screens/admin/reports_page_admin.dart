import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_main_colors.dart';

class ReportsPageAdmin extends StatefulWidget {
  const ReportsPageAdmin({super.key});

  @override
  State<ReportsPageAdmin> createState() => _ReportsPageAdminState();
}

class _ReportsPageAdminState extends State<ReportsPageAdmin> {
  final _supabase = Supabase.instance.client;
  
  bool _isLoading = true;
  String _selectedPeriod = '7';
  
  // Statistics data
  int _totalUsers = 0;
  int _totalJobs = 0;
  int _totalApplications = 0;
  int _totalInterviews = 0;
  
  int _newUsersThisPeriod = 0;
  int _newJobsThisPeriod = 0;
  int _newApplicationsThisPeriod = 0;
  int _newInterviewsThisPeriod = 0;
  
  double _applicationSuccessRate = 0.0;
  
  List<Map<String, dynamic>> _usersByDay = [];
  List<Map<String, dynamic>> _jobsByDay = [];
  List<Map<String, dynamic>> _applicationsByDay = [];
  
  Map<String, int> _usersByRole = {};
  Map<String, int> _jobsByStatus = {};
  
  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }
  
  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    
    try {
      final daysAgo = int.parse(_selectedPeriod);
      final periodStart = DateTime.now().subtract(Duration(days: daysAgo));
      
      // Load all data in parallel
      await Future.wait([
        _loadUserStats(periodStart),
        _loadJobStats(periodStart),
        _loadApplicationStats(periodStart),
        _loadInterviewStats(periodStart),
      ]);
      
      debugPrint('📊 Admin statistics loaded successfully');
    } catch (e) {
      debugPrint('❌ Error loading statistics: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadUserStats(DateTime periodStart) async {
    // Get total users and users by role
    final usersResponse = await _supabase
        .from('profiles')
        .select('id, role, created_at');
    
    final users = usersResponse as List;
    _totalUsers = users.length;
    
    // Count by role
    _usersByRole = {};
    for (var user in users) {
      final role = user['role']?.toString() ?? 'user';
      _usersByRole[role] = (_usersByRole[role] ?? 0) + 1;
    }
    
    // Count new users in period
    _newUsersThisPeriod = users.where((u) {
      final createdAt = DateTime.tryParse(u['created_at']?.toString() ?? '');
      return createdAt != null && createdAt.isAfter(periodStart);
    }).length;
    
    // Group by day
    _usersByDay = _groupByDay(users, 'created_at', periodStart);
  }
  
  Future<void> _loadJobStats(DateTime periodStart) async {
    // Get total jobs
    final jobsResponse = await _supabase
        .from('jobs')
        .select('id, status, created_at, deadline');
    
    final jobs = jobsResponse as List;
    _totalJobs = jobs.length;
    
    // Count by status
    _jobsByStatus = {};
    for (var job in jobs) {
      final deadline = DateTime.tryParse(job['deadline']?.toString() ?? '');
      final isExpired = deadline != null && deadline.isBefore(DateTime.now());
      final status = isExpired ? 'expired' : 'active';
      _jobsByStatus[status] = (_jobsByStatus[status] ?? 0) + 1;
    }
    
    // Count new jobs in period
    _newJobsThisPeriod = jobs.where((j) {
      final createdAt = DateTime.tryParse(j['created_at']?.toString() ?? '');
      return createdAt != null && createdAt.isAfter(periodStart);
    }).length;
    
    // Group by day
    _jobsByDay = _groupByDay(jobs, 'created_at', periodStart);
  }
  
  Future<void> _loadApplicationStats(DateTime periodStart) async {
    // Get all jobs with applicants
    final jobsResponse = await _supabase
        .from('jobs')
        .select('applicants');
    
    final jobs = jobsResponse as List;
    
    // Extract all applications
    final allApplications = <Map<String, dynamic>>[];
    for (var job in jobs) {
      final applicants = job['applicants'] as List?;
      if (applicants != null) {
        for (var applicant in applicants) {
          if (applicant is Map<String, dynamic>) {
            allApplications.add({
              'applied_at': applicant['applied_at'],
              'status': applicant['status']?.toString().toLowerCase() ?? 'pending',
            });
          }
        }
      }
    }
    
    _totalApplications = allApplications.length;
    
    // Count new applications in period
    _newApplicationsThisPeriod = allApplications.where((a) {
      final appliedAt = DateTime.tryParse(a['applied_at']?.toString() ?? '');
      return appliedAt != null && appliedAt.isAfter(periodStart);
    }).length;
    
    // Calculate success rate
    final acceptedCount = allApplications.where((a) => a['status'] == 'accepted').length;
    _applicationSuccessRate = _totalApplications > 0 
        ? (acceptedCount / _totalApplications * 100) 
        : 0.0;
    
    // Group by day
    _applicationsByDay = _groupByDay(allApplications, 'applied_at', periodStart);
  }
  
  Future<void> _loadInterviewStats(DateTime periodStart) async {
    // Get total interviews
    final interviewsResponse = await _supabase
        .from('interview_schedules')
        .select('id, created_at');
    
    final interviews = interviewsResponse as List;
    _totalInterviews = interviews.length;
    
    // Count new interviews in period
    _newInterviewsThisPeriod = interviews.where((i) {
      final createdAt = DateTime.tryParse(i['created_at']?.toString() ?? '');
      return createdAt != null && createdAt.isAfter(periodStart);
    }).length;
  }
  
  List<Map<String, dynamic>> _groupByDay(List<dynamic> items, String dateField, DateTime periodStart) {
    final grouped = <String, int>{};
    final daysAgo = int.parse(_selectedPeriod);
    
    // Initialize all days with 0
    for (var i = 0; i < daysAgo; i++) {
      final date = DateTime.now().subtract(Duration(days: daysAgo - i - 1));
      final key = '${date.month}/${date.day}';
      grouped[key] = 0;
    }
    
    // Count items by day
    for (var item in items) {
      final date = DateTime.tryParse(item[dateField]?.toString() ?? '');
      if (date != null && date.isAfter(periodStart)) {
        final key = '${date.month}/${date.day}';
        grouped[key] = (grouped[key] ?? 0) + 1;
      }
    }
    
    return grouped.entries.map((e) => {'day': e.key, 'count': e.value}).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _loadStatistics,
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
                    _totalUsers.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniStatCard(
                    'Việc làm',
                    _totalJobs.toString(),
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
                    _totalApplications.toString(),
                    Icons.description,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniStatCard(
                    'Phỏng vấn',
                    _totalInterviews.toString(),
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
              value: '+$_newUsersThisPeriod',
              description: 'Trong ${_selectedPeriod == "7" ? "7 ngày" : _selectedPeriod == "30" ? "30 ngày" : _selectedPeriod == "90" ? "90 ngày" : "1 năm"} qua',
              chart: _buildLineChart(_usersByDay, Colors.blue),
            ),
            const SizedBox(height: 16),
            _buildReportCard(
              title: 'Việc làm đăng',
              icon: Icons.work,
              color: Colors.orange,
              value: '+$_newJobsThisPeriod',
              description: 'Trong ${_selectedPeriod == "7" ? "7 ngày" : _selectedPeriod == "30" ? "30 ngày" : _selectedPeriod == "90" ? "90 ngày" : "1 năm"} qua',
              chart: _buildLineChart(_jobsByDay, Colors.orange),
            ),
            const SizedBox(height: 16),
            _buildReportCard(
              title: 'Ứng tuyển',
              icon: Icons.description,
              color: Colors.green,
              value: '+$_newApplicationsThisPeriod',
              description: 'Trong ${_selectedPeriod == "7" ? "7 ngày" : _selectedPeriod == "30" ? "30 ngày" : _selectedPeriod == "90" ? "90 ngày" : "1 năm"} qua',
              chart: _buildLineChart(_applicationsByDay, Colors.green),
            ),
            const SizedBox(height: 16),
            _buildReportCard(
              title: 'Tỷ lệ thành công',
              icon: Icons.check_circle,
              color: Colors.purple,
              value: '${_applicationSuccessRate.toStringAsFixed(1)}%',
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
                    data: _usersByRole,
                    colors: [Colors.blue, Colors.orange, Colors.green, Colors.purple],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDistributionCard(
                    title: 'Việc làm theo trạng thái',
                    data: _jobsByStatus,
                    colors: [Colors.green, Colors.red],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeButton(String label, String value) {
    final isActive = _selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = value;
        });
        _loadStatistics();
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
                    color: AppMainColors.primary.withOpacity(0.3),
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
            color: Colors.black.withOpacity(0.06),
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
          color: color.withOpacity(0.05),
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
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
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
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSuccessRateChart() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: _applicationSuccessRate / 100,
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
                '${_applicationSuccessRate.toStringAsFixed(1)}%',
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
              color: Colors.black.withOpacity(0.06),
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
            color: Colors.black.withOpacity(0.06),
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
                      Row(
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
                          Text(
                            _getRoleLabel(item.key),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
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
            color: Colors.black.withOpacity(0.06),
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
                      color: color.withOpacity(0.1),
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
