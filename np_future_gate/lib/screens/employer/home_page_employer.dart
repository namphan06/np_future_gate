import 'package:flutter/material.dart';
import '../../core/theme/app_main_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/cv_supabase_service.dart';
import '../../core/models/job_model.dart';
import '../../core/models/profile_model.dart';
import '../../core/repositories/job_repository.dart';
import '../../core/repositories/candidate_repository.dart';
import 'jobs/employer_jobs_screen.dart';
import 'jobs/edit_job_screen.dart';
import 'jobs/recent_applicants_screen.dart';
import 'search_page_employer.dart';
import '../cv/cv_setting/cv_display_manager.dart';

class HomePageEmployer extends StatefulWidget {
  const HomePageEmployer({super.key});

  @override
  State<HomePageEmployer> createState() => _HomePageEmployerState();
}

class _HomePageEmployerState extends State<HomePageEmployer> {
  final supabaseService = SupabaseService.instance;
  final _jobRepository = JobRepository();
  final _candidateRepository = CandidateRepository(); // Keeping if needed for other things
  final _cvService = CVSupabaseService();

  List<JobModel> _jobs = [];
  List<Map<String, dynamic>> _applications = [];
  Map<String, int> _stats = {
    'jobsCount': 0,
    'newApplicantsCount': 0,
    'totalApplicantsCount': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = supabaseService.currentUserId;
      if (userId == null) return;

      final jobs = await _jobRepository.getRecentEmployerJobs(userId);
      // Fetch applications (instead of random candidates)
      final apps = await _jobRepository.getRecentApplications(userId);
      // Fetch stats
      final stats = await _jobRepository.getEmployerStats(userId);

      if (mounted) {
        setState(() {
          _jobs = jobs;
          _applications = apps;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading home data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _viewCV(String cvId, String jobId, String userId, String currentStatus) async {
    try {
      if (currentStatus == 'pending') {
        await _jobRepository.updateApplicationStatus(jobId, userId, 'viewed');
        // Update local state if needed
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final cvData = await _cvService.getCVFullDataForEmployer(cvId);
      
      if (mounted) Navigator.pop(context);

      if (cvData != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CVDisplayManager.buildViewWidget(context, cvData),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CV không tồn tại hoặc đã bị xóa')),
          );
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải CV: $e')));
      }
    }
  }

  String _getJobStatus(JobModel job) {
    if (job.deadline != null && job.deadline!.isBefore(DateTime.now())) {
      return 'Hết hạn';
    }
    return 'Đang tuyển';
  }

  String _getSalaryString(JobSalary salary) {
    if (salary.min != null) {
      return '${salary.min} - ${salary.max} triệu';
    }
    return 'Thỏa thuận';
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  String _getDeadlineText(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Đã hết hạn';
    } else if (difference.inDays > 0) {
      return 'Còn ${difference.inDays} ngày';
    } else if (difference.inHours > 0) {
      return 'Còn ${difference.inHours} giờ';
    } else {
      return 'Sắp hết hạn';
    }
  }

  Color _getDeadlineColor(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return Colors.red;
    } else if (difference.inDays <= 3) {
      return Colors.orange.shade700;
    } else {
      return Colors.green.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = supabaseService.currentUser;

    return Stack(
      children: [
        SafeArea(
          child: CustomScrollView(
            slivers: [
              // Company Header
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Company Logo
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: currentUser?.userMetadata?['avatar_url'] == null
                              ? LinearGradient(
                                  colors: [
                                    AppMainColors.primary.withOpacity(0.8),
                                    AppMainColors.primaryDark,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: AppMainColors.primary.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: currentUser?.userMetadata?['avatar_url'] != null
                              ? Image.network(
                                  currentUser!.userMetadata!['avatar_url'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppMainColors.primary.withOpacity(0.8),
                                            AppMainColors.primaryDark,
                                          ],
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.business_rounded,
                                        size: 30,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.business_rounded,
                                  size: 30,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                      const SizedBox(width: 15),

                      // Company Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser?.userMetadata?['company_name'] ?? 'Công ty',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    currentUser?.email ?? 'No email',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Notification
                      Container(
                        decoration: BoxDecoration(
                          color: AppMainColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bạn có 8 thông báo mới')),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Stack(
                                children: [
                                  Icon(
                                    Icons.notifications_outlined,
                                    color: AppMainColors.primary,
                                    size: 24,
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Stats
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Tin đăng',
                          value: '${_stats['jobsCount']}',
                          icon: Icons.work_outline,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Ứng viên mới',
                          value: '${_stats['newApplicantsCount']}', // In 30 days
                          icon: Icons.person_add_outlined,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Tổng UV',
                          value: '${_stats['totalApplicantsCount']}',
                          icon: Icons.people_outline,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Job Postings Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tin tuyển dụng',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EmployerJobsScreen()),
                          );
                        },
                        icon: const Icon(Icons.remove_red_eye, size: 18),
                        label: const Text('Xem tất cả'), // Changed from "Đăng tin" per request (link to posted jobs)
                        style: TextButton.styleFrom(
                          foregroundColor: AppMainColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Job List
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (_jobs.isEmpty) {
                         // Should not happen due to itemcount check, but safe
                         return const SizedBox.shrink(); 
                      }
                      final job = _jobs[index];
                      return GestureDetector(
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EditJobScreen(job: job)),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      job.metadata.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _getJobStatus(job), // Helper
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.people_outline,
                                      size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${job.applicants.length} ứng viên',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(Icons.attach_money,
                                      size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getSalaryString(job.metadata.salary),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _getTimeAgo(job.createdAt!),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  if (job.deadline != null)
                                    Text(
                                      _getDeadlineText(job.deadline!),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getDeadlineColor(job.deadline!),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _jobs.length,
                  ),
                ),
              ),

              // Recent Applicants Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ứng viên mới nhất',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RecentApplicantsScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppMainColors.primary,
                        ),
                        child: const Text('Xem tất cả'),
                      ),
                    ],
                  ),
                ),
              ),

              // Applicants List
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (_applications.isEmpty) return const SizedBox.shrink();
                      final app = _applications[index];
                      // Extract data
                      final profile = app['profiles'] != null ? Profile.fromJson(app['profiles']) : null;
                      final job = app['jobs'] != null ? JobModel.fromJson(app['jobs']) : null;
                      final cvId = app['cv_id'];

                      if (profile == null) return const SizedBox.shrink();

                      return GestureDetector(
                        onTap: () {
                           if (cvId != null && job != null) {
                             _viewCV(cvId, job.id!, profile.id, app['application_status'] ?? 'pending');
                           }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: profile.avatarUrl != null 
                                      ? Image.network(profile.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.person_outline, color: Colors.blue))
                                      : const Icon(Icons.person_outline, color: Colors.blue, size: 24),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.fullName ?? 'No Name',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      job?.metadata.title ?? 'Việc làm không rõ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1, 
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      profile.email ?? '',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Icon(Icons.arrow_forward_ios,
                                      size: 16, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getTimeAgo(DateTime.parse(app['applied_at'])), // Ensure parsing
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _applications.length,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Gradient overlay
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0),
                    Colors.white.withOpacity(0.6),
                    Colors.white.withOpacity(0.85),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.2, 0.4, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
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
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
