import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/repositories/job_repository.dart';
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

                            final status = activity['application_status'] ?? 'pending';
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
