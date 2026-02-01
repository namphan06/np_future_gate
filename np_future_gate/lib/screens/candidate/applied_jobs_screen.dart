import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/repositories/job_repository.dart';
import '../../core/repositories/interview_repository.dart';
import '../../core/models/job_model.dart';
import '../../core/theme/app_main_colors.dart';
import 'job_detail_screen.dart';
import '../cv/cv_setting/cv_display_manager.dart';
import '../../widgets/cards/job_card.dart';

class AppliedJobsScreen extends StatefulWidget {
  const AppliedJobsScreen({super.key});

  @override
  State<AppliedJobsScreen> createState() => _AppliedJobsScreenState();
}

class _AppliedJobsScreenState extends State<AppliedJobsScreen> {
  final JobRepository _jobRepository = JobRepository();
  final InterviewRepository _interviewRepository = InterviewRepository();
  final String? _userId = Supabase.instance.client.auth.currentUser?.id;
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'viewed':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Đang chờ';
      case 'viewed':
        return 'Đã xem';
      case 'accepted':
        return 'Được nhận';
      case 'rejected':
        return 'Từ chối';
      default:
        return status;
    }
  }

  Future<void> _viewEvaluation(String jobId, String jobTitle) async {
    if (_userId == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final evaluationData = await _interviewRepository.getEvaluationForCandidate(
        candidateId: _userId!,
        jobId: jobId,
      );

      if (mounted) Navigator.pop(context); // Close loading

      if (evaluationData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chưa có đánh giá cho công việc này')),
          );
        }
        return;
      }

      final isShared = evaluationData['is_shared'] as bool;
      
      if (!isShared) {
        if (mounted) {
          _showNotSharedDialog();
        }
        return;
      }

      // Show evaluation detail
      final evaluation = evaluationData['evaluation'] as Map<String, dynamic>;
      final interviewTime = evaluationData['interview_time'] as String;
      
      if (mounted) {
        _showEvaluationDetail(jobTitle, evaluation, interviewTime);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải đánh giá: $e')),
        );
      }
    }
  }

  void _showNotSharedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange),
            SizedBox(width: 12),
            Text('Đánh giá không được chia sẻ'),
          ],
        ),
        content: const Text(
          'Nhà tuyển dụng chưa cho phép chia sẻ thông tin đánh giá cho bạn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showEvaluationDetail(String jobTitle, Map<String, dynamic> evaluation, String interviewTime) {
    final rating = (evaluation['rating'] as num?)?.toDouble() ?? 0;
    final envRating = (evaluation['environment_rating'] as num?)?.toDouble() ?? 0;
    final posRating = (evaluation['position_rating'] as num?)?.toDouble() ?? 0;
    final potRating = (evaluation['potential_rating'] as num?)?.toDouble() ?? 0;
    final commRating = (evaluation['communication_rating'] as num?)?.toDouble() ?? 0;
    final tags = (evaluation['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final note = evaluation['note'] as String? ?? '';
    final reqEval = evaluation['requirements_evaluation'] as Map<String, dynamic>? ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppMainColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.star, color: AppMainColors.primary, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Đánh giá phỏng vấn',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                jobTitle,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Phỏng vấn: ${DateFormat('dd/MM/yyyy HH:mm', 'vi').format(DateTime.parse(interviewTime).toLocal())}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const Divider(height: 32),

                    // Overall Rating
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppMainColors.primary.withOpacity(0.1), AppMainColors.primary.withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber, size: 48),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Đánh giá tổng quan',
                                style: TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${rating.toStringAsFixed(1)}/5.0',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Requirements Evaluation
                    if (reqEval.isNotEmpty) ...[
                      const Text(
                        'Yêu cầu công việc',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...reqEval.entries.map((entry) {
                        final value = (entry.value as num?)?.toDouble() ?? 0;
                        return _buildEvalRatingRow(entry.key, value);
                      }),
                      const Divider(height: 32),
                    ],

                    // Detailed Ratings
                    const Text(
                      'Đánh giá chi tiết',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildEvalRatingRow('Phù hợp vị trí', posRating),
                    _buildEvalRatingRow('Môi trường/Văn hóa', envRating),
                    _buildEvalRatingRow('Kỹ năng giao tiếp', commRating),
                    _buildEvalRatingRow('Tiềm năng phát triển', potRating),

                    if (tags.isNotEmpty) ...[
                      const Divider(height: 32),
                      const Text(
                        'Tags',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppMainColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppMainColors.primary.withOpacity(0.3)),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: AppMainColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )).toList(),
                      ),
                    ],

                    if (note.isNotEmpty) ...[
                      const Divider(height: 32),
                      const Text(
                        'Nhận xét',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          note,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvalRatingRow(String label, double rating) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppMainColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${rating.toStringAsFixed(1)}/10',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppMainColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: rating / 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(AppMainColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppMainColors.backgroundLightStart,
      body: _userId == null 
          ? const Center(child: Text('Vui lòng đăng nhập'))
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Việc làm đã ứng tuyển',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _jobRepository.getAppliedJobsStream(_userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        final appliedJobs = snapshot.data ?? [];
                        
                        if (appliedJobs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.work_off_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'Bạn chưa ứng tuyển công việc nào',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: appliedJobs.length,
                          itemBuilder: (context, index) {
                            final activity = appliedJobs[index];
                            final jobData = activity['jobs'];
                            final cvData = activity['cv_templates'];
                            
                            JobModel? job;
                            try {
                              if (jobData != null) {
                                job = JobModel.fromJson(Map<String, dynamic>.from(jobData as Map));
                              }
                            } catch (e) {
                              debugPrint('Error parsing job: $e');
                            }

                            final status = activity['status'] ?? 'unknown';
                            final appliedAt = activity['applied_at'] != null 
                                ? DateTime.parse(activity['applied_at']) 
                                : DateTime.now();
                            
                            if (job == null) return const SizedBox.shrink();

                            return JobCard(
                              job: job,
                              isApplied: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => JobDetailScreen(job: job!),
                                  ),
                                );
                              },
                              bottomAction: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(status).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _getStatusText(status),
                                            style: TextStyle(
                                              color: _getStatusColor(status),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat('dd/MM/yyyy').format(appliedAt),
                                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        // View Evaluation button (only for accepted status)
                                        if (status.toLowerCase() == 'accepted')
                                          InkWell(
                                            onTap: () {
                                              final jobId = job!.id ?? '';
                                              final jobTitle = job.metadata.title ?? 'Công việc';
                                              if (jobId.isNotEmpty) {
                                                _viewEvaluation(jobId, jobTitle);
                                              }
                                            },
                                            child: Row(
                                              children: [
                                                Icon(Icons.rate_review_outlined, size: 16, color: Colors.purple[600]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Đánh giá',
                                                  style: TextStyle(
                                                    color: Colors.purple[600],
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (status.toLowerCase() == 'accepted' && cvData != null)
                                          const SizedBox(width: 12),
                                        // View CV button
                                        if (cvData != null)
                                          InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => CVDisplayManager.buildViewWidget(context, cvData),
                                                ),
                                              );
                                            },
                                            child: Row(
                                              children: [
                                                Icon(Icons.description_outlined, size: 16, color: Colors.blue[600]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Xem CV',
                                                  style: TextStyle(
                                                    color: Colors.blue[600],
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
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
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
