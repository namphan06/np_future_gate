import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:np_future_gate/features/candidate/screens/partnership_job_detail_screen.dart';

class SchoolJobsForCandidateScreen extends StatefulWidget {
  const SchoolJobsForCandidateScreen({super.key});

  @override
  State<SchoolJobsForCandidateScreen> createState() => _SchoolJobsForCandidateScreenState();
}

class _SchoolJobsForCandidateScreenState extends State<SchoolJobsForCandidateScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _internJobs = [];
  bool _isLoading = true;
  String? _userEmailDomain;
  String? _userId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _userId = SupabaseService.instance.client.auth.currentUser?.id;
    _tabController = TabController(length: 2, vsync: this);
    _loadJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    try {
      final userEmail = SupabaseService.instance.client.auth.currentUser?.email;
      if (userEmail == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Extract email domain
      _userEmailDomain = '@${userEmail.split('@').last}';

      // Load approved partnership jobs with matching email domain
      final response = await SupabaseService.instance.client
          .from('school_partnership_jobs')
          .select()
          .eq('email', _userEmailDomain!)
          .eq('company_status', 'accepted')
          .eq('admin_status', 'approved')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final allJobs = List<Map<String, dynamic>>.from(response);
      
      // Separate regular jobs and intern jobs
      final regularJobs = <Map<String, dynamic>>[];
      final internJobs = <Map<String, dynamic>>[];
      
      for (final job in allJobs) {
        final metadata = job['metadata'] as Map<String, dynamic>?;
        final isIntern = metadata?['is_intern'] == true;
        
        if (isIntern) {
          // For intern jobs, only show if user is in assigned_students
          final assignedStudents = metadata?['assigned_students'] as List?;
          if (assignedStudents != null && _userId != null) {
            if (assignedStudents.contains(_userId)) {
              internJobs.add(job);
            }
          }
        } else {
          // Regular jobs - show to all
          regularJobs.add(job);
        }
      }

      setState(() {
        _jobs = regularJobs;
        _internJobs = internJobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Việc làm từ trường'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Việc làm thường'),
            Tab(text: 'Chương trình thực tập'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildJobsList(_jobs, 'Chưa có việc làm từ trường'),
                _buildJobsList(_internJobs, 'Chưa được phân công vào chương trình thực tập nào'),
              ],
            ),
    );
  }

  Widget _buildJobsList(List<Map<String, dynamic>> jobs, String emptyMessage) {
    if (jobs.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }
    
    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return _buildJobCard(job);
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _userEmailDomain != null
                  ? 'Email: $_userEmailDomain'
                  : 'Đăng nhập để xem tin tuyển dụng từ trường',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasApplied(Map<String, dynamic> job) {
    if (_userId == null) return false;
    final applicants = job['applicants'] as List?;
    if (applicants == null || applicants.isEmpty) return false;
    return applicants.any((app) => app['user_id'] == _userId);
  }

  String? _getRecruitmentStatus(Map<String, dynamic> job) {
    if (_userId == null) return null;
    final applicants = job['applicants'] as List?;
    if (applicants == null || applicants.isEmpty) return null;
    
    try {
      final application = applicants.firstWhere(
        (app) => app['user_id'] == _userId,
        orElse: () => null,
      );
      if (application == null) return null;
      return application['recruitment_status'] as String? ?? 'pending';
    } catch (e) {
      return null;
    }
  }

  Color _getRecruitmentStatusColor(String? status) {
    final actualStatus = status ?? 'pending';
    switch (actualStatus.toLowerCase()) {
      case 'pending':
        return Colors.amber;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<Map<String, dynamic>?> _loadWorkProgress(String jobId) async {
    if (_userId == null) return null;
    
    try {
      final response = await SupabaseService.instance.client
          .from('student_work_progress')
          .select()
          .eq('job_id', jobId)
          .eq('student_id', _userId!)
          .maybeSingle();
      
      return response;
    } catch (e) {
      debugPrint('Error loading work progress: $e');
      return null;
    }
  }

  void _showWorkProgressDialog(Map<String, dynamic> progress) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assignment, color: Colors.purple),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Đánh giá thực tập',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (progress['employer_feedback'] != null) ...[
                        _buildProgressSection(
                          'Đánh giá từ nhà tuyển dụng',
                          progress['employer_feedback'],
                          Colors.blue,
                          Icons.business,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (progress['school_feedback'] != null) ...[
                        _buildProgressSection(
                          'Đánh giá từ trường',
                          progress['school_feedback'],
                          Colors.purple,
                          Icons.school,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (progress['rating'] != null) ...[
                        _buildRatingSection(progress['rating']),
                        const SizedBox(height: 16),
                      ],
                      if (progress['status'] != null) ...[
                        _buildStatusChip(progress['status']),
                      ],
                      if (progress['employer_feedback'] == null && 
                          progress['school_feedback'] == null &&
                          progress['rating'] == null) ...[
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  'Chưa có đánh giá',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(String title, String content, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(dynamic rating) {
    final score = rating is num ? rating.toDouble() : double.tryParse(rating.toString()) ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Text(
            'Điểm đánh giá:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            score.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          const Text(' / 10', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        text = 'Hoàn thành';
        break;
      case 'in_progress':
        color = Colors.blue;
        text = 'Đang thực tập';
        break;
      case 'pending':
        color = Colors.orange;
        text = 'Chờ bắt đầu';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            'Trạng thái: $text',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getRecruitmentStatusText(String? status) {
    final actualStatus = status ?? 'pending';
    switch (actualStatus.toLowerCase()) {
      case 'pending':
        return 'Chờ duyệt';
      case 'accepted':
        return 'Đã nhận';
      case 'rejected':
        return 'Đã từ chối';
      default:
        return actualStatus;
    }
  }

  IconData _getRecruitmentStatusIcon(String? status) {
    final actualStatus = status ?? 'pending';
    switch (actualStatus.toLowerCase()) {
      case 'pending':
        return Icons.access_time;
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final metadata = job['metadata'] as Map<String, dynamic>? ?? {};
    final salary = metadata['salary'] as Map<String, dynamic>? ?? {};
    final createdAt = DateTime.parse(job['created_at']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            try {
              // Prepare job data for JobModel conversion
              // school_partnership_jobs uses company_id, but JobModel expects creator_id
              final jobData = Map<String, dynamic>.from(job);
              jobData['creator_id'] = job['company_id']; // Map company as creator
              
              // Convert to JobModel
              final jobModel = JobModel.fromJson(jobData);
              
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PartnershipJobDetailScreen(job: jobModel),
                ),
              );
            } catch (e, stackTrace) {
              debugPrint('Error navigating to job detail: $e');
              debugPrint('Stack trace: $stackTrace');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi xem chi tiết: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Header: School badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.school, size: 14, color: Colors.purple),
                          const SizedBox(width: 6),
                          Text(
                            'Từ trường',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (_hasApplied(job)) ...[
                            // Recruitment status badge
                            Builder(
                              builder: (context) {
                                final status = _getRecruitmentStatus(job);
                                if (status != null) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _getRecruitmentStatusColor(status),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getRecruitmentStatusIcon(status),
                                          size: 12,
                                          color: _getRecruitmentStatusColor(status),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getRecruitmentStatusText(status),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: _getRecruitmentStatusColor(status),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, size: 12, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Đã ứng tuyển',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Text(
                            _getTimeAgo(createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Job Title
                Text(
                  metadata['title'] ?? 'Không có tiêu đề',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Salary
                if (salary.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.monetization_on_outlined, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getSalaryText(salary),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 8),

                // Location
                if ((metadata['working_regions'] as List?)?.isNotEmpty == true)
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (metadata['working_regions'] as List).join(', '),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 8),

                // Experience
                if (metadata['experience_required'] != null)
                  Row(
                    children: [
                      Icon(Icons.business_center_outlined, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        metadata['experience_required'].toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),

                // Fields/Tags
                if ((metadata['fields'] as List?)?.isNotEmpty == true)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (metadata['fields'] as List).take(3).map((field) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          field.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                // Work Progress button for intern jobs
                if (metadata['is_intern'] == true) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _loadWorkProgress(job['id']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      
                      final hasProgress = snapshot.data != null;
                      
                      return InkWell(
                        onTap: () {
                          if (hasProgress) {
                            _showWorkProgressDialog(snapshot.data!);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 20,
                                color: hasProgress ? Colors.purple : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  hasProgress ? 'Xem đánh giá thực tập' : 'Chưa có đánh giá',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: hasProgress ? Colors.purple : Colors.grey,
                                  ),
                                ),
                              ),
                              if (hasProgress)
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.purple,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  String _getSalaryText(Map<String, dynamic> salary) {
    if (salary['is_negotiable'] == true) return 'Thỏa thuận';
    final min = salary['min'];
    final max = salary['max'];
    if (min != null && max != null) return '$min - $max triệu VND';
    if (min != null) return 'Từ $min triệu VND';
    if (max != null) return 'Đến $max triệu VND';
    return 'Thỏa thuận';
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays} ngày trước';
    if (difference.inHours > 0) return '${difference.inHours} giờ trước';
    if (difference.inMinutes > 0) return '${difference.inMinutes} phút trước';
    return 'Vừa xong';
  }
}
