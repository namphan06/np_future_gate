import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerStatisticsScreen extends StatefulWidget {
  const EmployerStatisticsScreen({super.key});

  @override
  State<EmployerStatisticsScreen> createState() => _EmployerStatisticsScreenState();
}

class _EmployerStatisticsScreenState extends State<EmployerStatisticsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  
  // Statistics data
  int _totalJobs = 0;
  int _activeJobs = 0;
  int _expiredJobs = 0;
  int _totalApplications = 0;
  int _pendingApplications = 0;
  int _acceptedApplications = 0;
  int _rejectedApplications = 0;
  int _totalViews = 0;
  int _totalInterviews = 0;
  
  List<Map<String, dynamic>> _applicationsByMonth = [];
  List<Map<String, dynamic>> _jobsByField = [];
  List<Map<String, dynamic>> _recentApplications = [];

  String _selectedPeriod = '30 ngày';
  final List<String> _periods = ['7 ngày', '30 ngày', '3 tháng', '6 tháng', '1 năm'];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ User not logged in');
        setState(() => _isLoading = false);
        return;
      }

      debugPrint('📊 Loading statistics for user: $userId');

      // Get all jobs by this employer with applicants
      final jobsResponse = await _supabase
          .from('jobs')
          .select('id, metadata, deadline, view_count, created_at, applicants')
          .eq('creator_id', userId);
      
      debugPrint('✅ Jobs response: ${jobsResponse.length} jobs');
      
      final jobs = jobsResponse as List;
      
      _totalJobs = jobs.length;
      _activeJobs = jobs.where((j) {
        final deadline = DateTime.tryParse(j['deadline'] ?? '');
        return deadline != null && deadline.isAfter(DateTime.now());
      }).length;
      _expiredJobs = _totalJobs - _activeJobs;
      _totalViews = jobs.fold(0, (sum, j) => sum + ((j['view_count'] as int?) ?? 0));

      debugPrint('📊 Total jobs: $_totalJobs, Active: $_activeJobs, Views: $_totalViews');

      // Extract all applications from jobs' applicants array
      final allApplications = <Map<String, dynamic>>[];
      for (final job in jobs) {
        final applicants = job['applicants'] as List?;
        debugPrint('📋 Job ${job['id']}: ${applicants?.length ?? 0} applicants');
        
        if (applicants != null && applicants.isNotEmpty) {
          for (final applicant in applicants) {
            if (applicant is Map<String, dynamic>) {
              final status = applicant['status']?.toString() ?? 'pending';
              debugPrint('  👤 Applicant: user=${applicant['user_id']}, status=$status, applied=${applicant['applied_at']}');
              
              allApplications.add({
                'user_id': applicant['user_id'],
                'cv_id': applicant['cv_id'],
                'applied_at': applicant['applied_at'],
                'status': status,
                'job_id': job['id'],
              });
            }
          }
        }
      }
      
      debugPrint('📊 Total applications from jobs.applicants: ${allApplications.length}');
      
      // Count applications by status (case-insensitive, 'viewed' counts as pending)
      _totalApplications = allApplications.length;
      _pendingApplications = allApplications.where((a) {
        final status = a['status']?.toString().toLowerCase() ?? 'pending';
        return status == 'pending' || status == 'viewed';
      }).length;
      _acceptedApplications = allApplications.where((a) => 
        a['status']?.toString().toLowerCase() == 'accepted'
      ).length;
      _rejectedApplications = allApplications.where((a) => 
        a['status']?.toString().toLowerCase() == 'rejected'
      ).length;
      
      // Log status distribution
      final statusCounts = <String, int>{};
      for (var app in allApplications) {
        final status = app['status']?.toString() ?? 'null';
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }
      debugPrint('📊 Status distribution: $statusCounts');
      debugPrint('📊 Applications - Total: $_totalApplications, Pending: $_pendingApplications, Accepted: $_acceptedApplications, Rejected: $_rejectedApplications');
      
      // Unique users
      final uniqueUsers = allApplications.map((a) => a['user_id']).toSet().length;
      debugPrint('📊 Unique users: $uniqueUsers');

      // Count jobs by field (from metadata.fields array)
      final fieldCounts = <String, int>{};
      for (final job in jobs) {
        final metadata = job['metadata'] as Map<String, dynamic>?;
        final fields = metadata?['fields'] as List?;
        if (fields != null && fields.isNotEmpty) {
          final field = fields.first.toString();
          fieldCounts[field] = (fieldCounts[field] ?? 0) + 1;
        } else {
          fieldCounts['Khác'] = (fieldCounts['Khác'] ?? 0) + 1;
        }
      }
      _jobsByField = fieldCounts.entries
          .map((e) => {'field': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      // Process recent applications and get profiles
      if (allApplications.isNotEmpty) {
        // Sort by applied_at
        allApplications.sort((a, b) {
          final aDate = DateTime.tryParse(a['applied_at'] ?? '');
          final bDate = DateTime.tryParse(b['applied_at'] ?? '');
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate); // newest first
        });
        
        // Get unique user IDs for recent applications
        final recentUserIds = allApplications
            .take(5)
            .map((a) => a['user_id'] as String)
            .toSet()
            .toList();
        
        if (recentUserIds.isNotEmpty) {
          try {
            final profilesResponse = await _supabase
                .from('profiles')
                .select('id, full_name, avatar_url')
                .inFilter('id', recentUserIds);
            
            debugPrint('✅ Profiles loaded: ${profilesResponse.length} profiles');
            
            final profilesMap = {
              for (var p in profilesResponse as List)
                p['id']: p
            };
            
            // Recent applications with profiles
            _recentApplications = allApplications.take(5).map((a) {
              final profile = profilesMap[a['user_id']] as Map<String, dynamic>?;
              return {
                'name': profile?['full_name'] ?? 'Ứng viên',
                'avatar': profile?['avatar_url'],
                'status': a['status'],
                'created_at': a['applied_at'],
              };
            }).toList();
            
            debugPrint('✅ Recent applications: ${_recentApplications.length}');
          } catch (e) {
            debugPrint('⚠️ Error loading profiles: $e');
            _recentApplications = allApplications.take(5).map((a) {
              return {
                'name': 'Ứng viên',
                'avatar': null,
                'status': a['status'],
                'created_at': a['applied_at'],
              };
            }).toList();
          }
        }

        // Applications by month (last 6 months)
        final now = DateTime.now();
        _applicationsByMonth = List.generate(6, (index) {
          final month = DateTime(now.year, now.month - (5 - index), 1);
          final monthEnd = DateTime(month.year, month.month + 1, 0);
          final count = allApplications.where((a) {
            final createdAt = DateTime.tryParse(a['applied_at'] ?? '');
            return createdAt != null && 
                   createdAt.isAfter(month.subtract(const Duration(days: 1))) && 
                   createdAt.isBefore(monthEnd.add(const Duration(days: 1)));
          }).length;
          return {
            'month': 'T${month.month}',
            'count': count,
          };
        });
        
        debugPrint('✅ Applications by month calculated');
      }

      // Get interviews count
      try {
        final interviewsResponse = await _supabase
            .from('interview_schedules')
            .select('id')
            .eq('employer_id', userId);
        _totalInterviews = (interviewsResponse as List).length;
        debugPrint('✅ Interviews: $_totalInterviews');
      } catch (e) {
        debugPrint('⚠️ Error loading interviews (table may not exist): $e');
        _totalInterviews = 0;
      }

      debugPrint('✅ Statistics loaded successfully');

    } catch (e, stackTrace) {
      debugPrint('❌ Error loading statistics: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: ${e.toString().split('\n').first}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: _loadStatistics,
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: CustomScrollView(
                slivers: [
                  // Custom AppBar
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 16,
                        left: 20,
                        right: 20,
                        bottom: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.arrow_back, size: 22),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Thống kê tuyển dụng',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Báo cáo tổng quan hoạt động',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Period selector
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppMainColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppMainColors.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedPeriod,
                                  isDense: true,
                                  underline: const SizedBox(),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: AppMainColors.primary,
                                    size: 18,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppMainColors.primary,
                                  ),
                                  items: _periods.map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p),
                                  )).toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedPeriod = value!);
                                    _loadStatistics();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Overview Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
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
                          const SizedBox(height: 16),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.15,
                            children: [
                              _buildStatCard(
                                title: 'Tin tuyển dụng',
                                value: _totalJobs.toString(),
                                subtitle: '$_activeJobs đang hoạt động',
                                icon: Icons.work_outline,
                                color: AppMainColors.primary,
                              ),
                              _buildStatCard(
                                title: 'Đơn ứng tuyển',
                                value: _totalApplications.toString(),
                                subtitle: '$_pendingApplications chờ xử lý',
                                icon: Icons.description_outlined,
                                color: Colors.orange,
                              ),
                              _buildStatCard(
                                title: 'Lượt xem',
                                value: _formatNumber(_totalViews),
                                subtitle: 'Tổng lượt xem tin',
                                icon: Icons.visibility_outlined,
                                color: Colors.teal,
                              ),
                              _buildStatCard(
                                title: 'Lịch phỏng vấn',
                                value: _totalInterviews.toString(),
                                subtitle: 'Buổi đã lên lịch',
                                icon: Icons.calendar_today_outlined,
                                color: Colors.purple,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Applications Line Chart
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildApplicationsChart(),
                    ),
                  ),

                  // Application Status Pie Chart
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(child: _buildApplicationStatusChart()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildJobStatusChart()),
                        ],
                      ),
                    ),
                  ),

                  // Jobs by Field Chart
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildJobsByFieldChart(),
                    ),
                  ),

                  // Recent Applications
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildRecentApplications(),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 40),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Icon(Icons.trending_up, color: Colors.green.shade400, size: 14),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppMainColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: AppMainColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Đơn ứng tuyển theo tháng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: _applicationsByMonth.isEmpty
                ? Center(
                    child: Text(
                      'Chưa có dữ liệu',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (_applicationsByMonth.map((e) => (e['count'] as int).toDouble()).reduce((a, b) => a > b ? a : b) * 1.3).clamp(5, double.infinity),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => Colors.blueGrey.shade800,
                          tooltipRoundedRadius: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${_applicationsByMonth[groupIndex]['count']} đơn',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= _applicationsByMonth.length) {
                                return const SizedBox();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _applicationsByMonth[index]['month'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                            reservedSize: 28,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 2,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _applicationsByMonth.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: (data['count'] as int).toDouble(),
                              gradient: const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppMainColors.primary,
                                  AppMainColors.primaryLight,
                                ],
                              ),
                              width: 24,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationStatusChart() {
    final total = _totalApplications;
    if (total == 0) {
      return _buildEmptyChartCard('Trạng thái đơn', Icons.pie_chart_outline);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Trạng thái đơn',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 24,
                sections: [
                  PieChartSectionData(
                    value: _pendingApplications.toDouble(),
                    color: Colors.orange.shade400,
                    radius: 20,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: _acceptedApplications.toDouble(),
                    color: Colors.green.shade400,
                    radius: 20,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: _rejectedApplications.toDouble(),
                    color: Colors.red.shade400,
                    radius: 20,
                    showTitle: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildLegendItem('Chờ xử lý', _pendingApplications, Colors.orange.shade400),
          _buildLegendItem('Chấp nhận', _acceptedApplications, Colors.green.shade400),
          _buildLegendItem('Từ chối', _rejectedApplications, Colors.red.shade400),
        ],
      ),
    );
  }

  Widget _buildJobStatusChart() {
    if (_totalJobs == 0) {
      return _buildEmptyChartCard('Trạng thái tin', Icons.donut_large);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.donut_large, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Trạng thái tin',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 24,
                sections: [
                  PieChartSectionData(
                    value: _activeJobs.toDouble(),
                    color: AppMainColors.primary,
                    radius: 20,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: _expiredJobs.toDouble(),
                    color: Colors.grey.shade400,
                    radius: 20,
                    showTitle: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildLegendItem('Đang hoạt động', _activeJobs, AppMainColors.primary),
          _buildLegendItem('Đã hết hạn', _expiredJobs, Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChartCard(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Icon(icon, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            'Chưa có dữ liệu',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildJobsByFieldChart() {
    if (_jobsByField.isEmpty) {
      return const SizedBox();
    }

    final colors = [
      AppMainColors.primary,
      Colors.orange,
      Colors.teal,
      Colors.purple,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
                child: const Icon(
                  Icons.category_outlined,
                  color: Colors.purple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tin tuyển dụng theo lĩnh vực',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._jobsByField.take(5).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final percentage = (_totalJobs > 0) 
                ? ((data['count'] as int) / _totalJobs * 100) 
                : 0.0;
            final color = colors[index % colors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['field'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${data['count']} tin',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percentage / 100,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withValues(alpha: 0.7)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentApplications() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
                child: const Icon(
                  Icons.person_add_outlined,
                  color: Colors.green,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ứng viên gần đây',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentApplications.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'Chưa có ứng viên nào',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_recentApplications.map((app) => _buildApplicationItem(app))),
        ],
      ),
    );
  }

  Widget _buildApplicationItem(Map<String, dynamic> app) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: app['avatar'] != null 
                ? NetworkImage(app['avatar'] as String) 
                : null,
            child: app['avatar'] == null 
                ? Icon(Icons.person, color: Colors.grey.shade400, size: 20) 
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app['name'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDate(app['created_at'] as String?),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          //   decoration: BoxDecoration(
          //     color: statusColor.withValues(alpha: 0.1),
          //     borderRadius: BorderRadius.circular(12),
          //   ),
          //   child: Text(
          //     statusText,
          //     style: TextStyle(
          //       fontSize: 11,
          //       fontWeight: FontWeight.w600,
          //       color: statusColor,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    final date = DateTime.tryParse(dateString);
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} phút trước';
      }
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
