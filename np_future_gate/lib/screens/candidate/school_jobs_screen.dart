import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_main_colors.dart';
import '../../core/models/job_model.dart';
import 'partnership_job_detail_screen.dart';

class SchoolJobsForCandidateScreen extends StatefulWidget {
  const SchoolJobsForCandidateScreen({super.key});

  @override
  State<SchoolJobsForCandidateScreen> createState() => _SchoolJobsForCandidateScreenState();
}

class _SchoolJobsForCandidateScreenState extends State<SchoolJobsForCandidateScreen> {
  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;
  String? _userEmailDomain;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = SupabaseService.instance.client.auth.currentUser?.id;
    _loadJobs();
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

      setState(() {
        _jobs = List<Map<String, dynamic>>.from(response);
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : _jobs.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadJobs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _jobs.length,
                    itemBuilder: (context, index) {
                      final job = _jobs[index];
                      return _buildJobCard(job);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
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
            'Chưa có việc làm từ trường',
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
                  ? 'Không có tin tuyển dụng nào cho email $_userEmailDomain'
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.purple.withOpacity(0.2),
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
              print('Error navigating to job detail: $e');
              print('Stack trace: $stackTrace');
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
          child: Padding(
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
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.3),
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
                    const Spacer(),
                    if (_hasApplied(job)) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
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
                      const SizedBox(width: 8),
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
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
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
              ],
            ),
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
