import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/features/school/screens/jobs/create_school_job_screen.dart';
import 'package:np_future_gate/features/school/screens/jobs/school_jobs_screen.dart';

class HomePageSchool extends StatefulWidget {
  const HomePageSchool({super.key});

  @override
  State<HomePageSchool> createState() => _HomePageSchoolState();
}

class _HomePageSchoolState extends State<HomePageSchool> {
  bool _isLoading = true;
  
  // Statistics
  int _totalRegularJobs = 0;
  int _totalPartnershipJobs = 0;
  int _pendingPartnershipJobs = 0; // Đang chờ công ty duyệt
  int _totalApplicants = 0;
  int _newApplicants = 0;

  // Recent data
  List<Map<String, dynamic>> _recentPartnershipJobs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      debugPrint('📊 Loading school home data for user: $userId');

      // Load regular jobs (jobs table where creator_id = school)
      final regularJobsData = await SupabaseService.instance.client
          .from('jobs')
          .select()
          .eq('creator_id', userId)
          .order('created_at', ascending: false);
      
      final regularJobs = (regularJobsData as List)
          .map((e) => JobModel.fromJson(e))
          .toList();
      
      debugPrint('📝 Regular jobs count: ${regularJobs.length}');
      
      // Load partnership jobs
      final partnershipJobsData = await SupabaseService.instance.client
          .from('school_partnership_jobs')
          .select()
          .eq('school_id', userId)
          .order('created_at', ascending: false);

      debugPrint('🤝 Partnership jobs count: ${(partnershipJobsData as List).length}');

      // Calculate statistics for partnership jobs
      final pendingPartnership = (partnershipJobsData as List).where(
        (job) => job['company_status'] == 'pending' || job['admin_status'] == 'pending'
      ).length;

      debugPrint('⏳ Pending partnership jobs: $pendingPartnership');

      // Count applicants from regular jobs
      int totalApplicants = 0;
      int newApplicants = 0;
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));

      for (var job in regularJobs) {
        final applicants = job.applicants;
        totalApplicants += applicants.length;
        for (var applicant in applicants) {
          try {
            final appliedAt = applicant.appliedAt;
            if (appliedAt.isAfter(oneDayAgo)) {
              newApplicants++;
            }
          } catch (e) {
            debugPrint('Error parsing applicant date: $e');
          }
        }
      }

      // Count applicants from partnership jobs
      for (var job in partnershipJobsData) {
        final applicants = job['applicants'] as List? ?? [];
        totalApplicants += applicants.length;
        for (var applicant in applicants) {
          try {
            final appliedAtStr = applicant['applied_at'] as String?;
            if (appliedAtStr != null) {
              final appliedAt = DateTime.parse(appliedAtStr);
              if (appliedAt.isAfter(oneDayAgo)) {
                newApplicants++;
              }
            }
          } catch (e) {
            debugPrint('Error parsing partnership applicant date: $e');
          }
        }
      }

      debugPrint('👥 Total applicants: $totalApplicants');
      debugPrint('🆕 New applicants (last 24h): $newApplicants');

      setState(() {
        _totalRegularJobs = regularJobs.length;
        _totalPartnershipJobs = partnershipJobsData.length;
        _pendingPartnershipJobs = pendingPartnership;
        _totalApplicants = totalApplicants;
        _newApplicants = newApplicants;
        _recentPartnershipJobs = List<Map<String, dynamic>>.from(partnershipJobsData.take(5));
        _isLoading = false;
      });

      debugPrint('✅ School home data loaded successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading school home data: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays} ngày trước';
    if (difference.inHours > 0) return '${difference.inHours} giờ trước';
    if (difference.inMinutes > 0) return '${difference.inMinutes} phút trước';
    return 'Vừa xong';
  }

  String _getPartnershipStatus(Map<String, dynamic> job) {
    final companyStatus = job['company_status'] as String;
    final adminStatus = job['admin_status'] as String;
    
    if (companyStatus == 'pending') return 'Chờ công ty duyệt';
    if (companyStatus == 'rejected') return 'Công ty từ chối';
    if (adminStatus == 'pending') return 'Chờ admin duyệt';
    if (adminStatus == 'rejected') return 'Admin từ chối';
    if (adminStatus == 'approved') return 'Đã duyệt';
    return 'Không xác định';
  }

  Color _getPartnershipStatusColor(Map<String, dynamic> job) {
    final companyStatus = job['company_status'] as String;
    final adminStatus = job['admin_status'] as String;
    
    if (companyStatus == 'pending' || adminStatus == 'pending') return Colors.orange;
    if (companyStatus == 'rejected' || adminStatus == 'rejected') return Colors.red;
    if (adminStatus == 'approved') return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // Header với avatar và greeting
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                child: const Icon(Icons.school, color: Colors.white, size: 30),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Xin chào! 👋',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: Colors.white.withValues(alpha: 0.9),
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Quản lý tuyển dụng nhà trường',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.white.withValues(alpha: 0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Statistics Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Tin thường',
                                  value: _totalRegularJobs.toString(),
                                  icon: Icons.work_outline,
                                  color: AppMainColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Tin liên kết',
                                  value: _totalPartnershipJobs.toString(),
                                  icon: Icons.handshake_outlined,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Chờ duyệt',
                                  value: _pendingPartnershipJobs.toString(),
                                  icon: Icons.pending_outlined,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Ứng viên',
                                  value: _totalApplicants.toString(),
                                  icon: Icons.people_outline,
                                  color: Colors.green,
                                  badge: _newApplicants > 0 ? '+$_newApplicants' : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

                  // Quick Actions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tạo tin tuyển dụng',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionCard(
                                  title: 'Tạo tin thường',
                                  subtitle: 'Tuyển dụng trực tiếp',
                                  icon: Icons.add_circle_outline,
                                  gradient: LinearGradient(
                                    colors: [AppMainColors.primary, AppMainColors.primary.withValues(alpha: 0.7)],
                                  ),
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const CreateSchoolJobScreen(isPartnership: false),
                                      ),
                                    );
                                    if (result == true) _loadData();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildActionCard(
                                  title: 'Tin liên kết',
                                  subtitle: 'Kết nối doanh nghiệp',
                                  icon: Icons.business_outlined,
                                  gradient: const LinearGradient(
                                    colors: [Colors.purple, Color(0xFF9C27B0)],
                                  ),
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const CreateSchoolJobScreen(isPartnership: true),
                                      ),
                                    );
                                    if (result == true) _loadData();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

                  // Recent Partnership Jobs
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tin liên kết gần đây',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SchoolJobsScreen(),
                                ),
                              );
                            },
                            child: const Text('Xem tất cả', style: TextStyle(color: Colors.white70)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Partnership Jobs List
                  _recentPartnershipJobs.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Text(
                                  'Chưa có tin liên kết nào',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final job = _recentPartnershipJobs[index];
                                return _buildPartnershipJobCard(job);
                              },
                              childCount: _recentPartnershipJobs.length,
                            ),
                          ),
                        ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnershipJobCard(Map<String, dynamic> job) {
    final metadata = job['metadata'] as Map<String, dynamic>? ?? {};
    final title = metadata['title'] as String? ?? 'Không có tiêu đề';
    final createdAt = DateTime.parse(job['created_at']);
    final status = _getPartnershipStatus(job);
    final statusColor = _getPartnershipStatusColor(job);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to detail
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _getTimeAgo(createdAt),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.people_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${(job['applicants'] as List?)?.length ?? 0} ứng viên',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
