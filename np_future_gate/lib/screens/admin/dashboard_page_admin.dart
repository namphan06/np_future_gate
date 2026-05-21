import 'package:flutter/material.dart';
import 'package:np_future_gate/core/repositories/job_repository.dart';
import 'package:np_future_gate/screens/admin/create_user_screen_admin.dart';
import 'package:np_future_gate/screens/admin/job_approval_page_admin.dart';
import 'package:np_future_gate/screens/admin/reports_page_admin.dart';
import 'package:np_future_gate/screens/admin/settings_page_admin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPageAdmin extends StatefulWidget {
  const DashboardPageAdmin({super.key});

  @override
  State<DashboardPageAdmin> createState() => _DashboardPageAdminState();
}

class _DashboardPageAdminState extends State<DashboardPageAdmin> {
  final JobRepository _jobRepository = JobRepository();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Loading state
  bool _isLoading = true;
  
  // Dashboard stats
  int _totalUsersCount = 0;
  int _pendingJobsCount = 0;
  int _totalApplicationsCount = 0;
  int _totalCompaniesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      // Load all stats in parallel
      final results = await Future.wait([
        _getTotalUsersCount(),
        _getPendingJobsCount(),
        _getTotalApplicationsCount(),
        _getTotalCompaniesCount(),
      ]);
      
      if (mounted) {
        setState(() {
          _totalUsersCount = results[0];
          _pendingJobsCount = results[1];
          _totalApplicationsCount = results[2];
          _totalCompaniesCount = results[3];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Get total users count (all roles)
  Future<int> _getTotalUsersCount() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .count(CountOption.exact);
      
      return response.count;
    } catch (e) {
      debugPrint('Error fetching total users: $e');
      return 0;
    }
  }

  /// Get pending jobs count (from both regular and partnership jobs)
  Future<int> _getPendingJobsCount() async {
    try {
      final results = await Future.wait([
        _jobRepository.getPendingJobs(),
        _jobRepository.getPendingPartnershipJobs(),
      ]);
      
      final regularJobs = results[0] as List;
      final partnershipJobs = results[1] as List;
      
      return regularJobs.length + partnershipJobs.length;
    } catch (e) {
      debugPrint('Error fetching pending jobs: $e');
      return 0;
    }
  }

  /// Get total applications count
  Future<int> _getTotalApplicationsCount() async {
    try {
      // Get all jobs to count applications
      final jobsResponse = await _supabase
          .from('jobs')
          .select('applicants');
      
      int totalApplications = 0;
      for (var job in jobsResponse as List) {
        final applicants = job['applicants'] as List?;
        if (applicants != null) {
          totalApplications += applicants.length;
        }
      }
      
      // Also count partnership job applications
      final partnershipJobsResponse = await _supabase
          .from('school_partnership_jobs')
          .select('applicants');
      
      for (var job in partnershipJobsResponse as List) {
        final applicants = job['applicants'] as List?;
        if (applicants != null) {
          totalApplications += applicants.length;
        }
      }
      
      return totalApplications;
    } catch (e) {
      debugPrint('Error fetching total applications: $e');
      return 0;
    }
  }

  /// Get total companies count (employers)
  Future<int> _getTotalCompaniesCount() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('role', 'employer')
          .count(CountOption.exact);
      
      return response.count;
    } catch (e) {
      debugPrint('Error fetching total companies: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tổng quan hệ thống',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Stats Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildStatCard(
                title: 'Tổng người dùng',
                value: _isLoading ? '...' : '$_totalUsersCount',
                change: '+12.5%',
                isPositive: true,
                icon: Icons.people,
                color: Colors.blue,
              ),
              _buildStatCard(
                title: 'Việc chờ duyệt',
                value: _isLoading ? '...' : '$_pendingJobsCount',
                change: _pendingJobsCount > 0 ? 'Cần xử lý' : 'Hoàn tất',
                isPositive: _pendingJobsCount == 0,
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
              _buildStatCard(
                title: 'Ứng tuyển',
                value: _isLoading ? '...' : '$_totalApplicationsCount',
                change: '+15.3%',
                isPositive: true,
                icon: Icons.description,
                color: Colors.green,
              ),
              _buildStatCard(
                title: 'Công ty',
                value: _isLoading ? '...' : '$_totalCompaniesCount',
                change: '-2.4%',
                isPositive: false,
                icon: Icons.business,
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Hành động nhanh',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Thêm người dùng',
                  icon: Icons.person_add,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateUserScreenAdmin(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Duyệt việc làm',
                  icon: Icons.approval,
                  color: Colors.orange,
                  badge: _pendingJobsCount > 0 ? _pendingJobsCount : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const JobApprovalPageAdmin(),
                      ),
                    ).then((_) => _loadStats()); // Refresh stats when coming back
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Xem báo cáo',
                  icon: Icons.assessment,
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReportsPageAdmin(isStandalone: true),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Cài đặt',
                  icon: Icons.settings,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPageAdmin(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Activities
          const Text(
            'Hoạt động gần đây',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          _buildActivityCard(
            icon: Icons.person_add,
            title: 'Người dùng mới đăng ký',
            subtitle: 'John Doe đã tạo tài khoản Candidate',
            time: '5 phút trước',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildActivityCard(
            icon: Icons.work,
            title: 'Việc làm mới',
            subtitle: 'FPT Software đăng "Senior Flutter Developer"',
            time: '15 phút trước',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildActivityCard(
            icon: Icons.description,
            title: 'Ứng tuyển mới',
            subtitle: 'Nguyễn Văn A ứng tuyển vị trí Backend Developer',
            time: '30 phút trước',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildActivityCard(
            icon: Icons.business,
            title: 'Công ty mới',
            subtitle: 'VinGroup đăng ký tài khoản Employer',
            time: '1 giờ trước',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String change,
    required bool isPositive,
    required IconData icon,
    required Color color,
  }) {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int? badge,
  }) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    if (badge != null && badge > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            badge > 99 ? '99+' : '$badge',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
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
      child: Row(
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
          Expanded(
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
