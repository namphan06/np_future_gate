import 'package:flutter/material.dart';
import '../../../core/repositories/job_repository.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/services/cv_supabase_service.dart';
import '../../cv/cv_setting/cv_display_manager.dart';
import '../../../core/theme/app_main_colors.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/models/job_model.dart';

class RecentApplicantsScreen extends StatefulWidget {
  const RecentApplicantsScreen({super.key});

  @override
  State<RecentApplicantsScreen> createState() => _RecentApplicantsScreenState();
}

class _RecentApplicantsScreenState extends State<RecentApplicantsScreen> {
  final JobRepository _jobRepository = JobRepository();
  final AuthRepository _authRepository = AuthRepository();
  final CVSupabaseService _cvService = CVSupabaseService();

  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = _authRepository.currentUser?.id;
      if (userId == null) return;

      final apps = await _jobRepository.getRecentApplications(userId, limit: 50);
      
      if (mounted) {
        setState(() {
          _applications = apps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _getTimeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final dateTime = DateTime.parse(dateStr);
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

  Future<void> _viewCV(String cvId, String jobId, String userId, String currentStatus) async {
    try {
      if (currentStatus == 'pending') {
        await _jobRepository.updateApplicationStatus(jobId, userId, 'viewed');
        // Update local state
        final index = _applications.indexWhere((app) => 
            app['job_id'] == jobId && app['user_id'] == userId);
        if (index != -1) {
          setState(() {
            _applications[index]['application_status'] = 'viewed';
          });
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Ứng viên gần đây'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
              ? const Center(child: Text('Chưa có ứng viên nào'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _applications.length,
                  itemBuilder: (context, index) {
                    final app = _applications[index];
                    final profile = app['profiles'] != null ? Profile.fromJson(app['profiles']) : null;
                    final job = app['jobs'] != null ? JobModel.fromJson(app['jobs']) : null;
                    final cvId = app['cv_id'];
                    
                    return GestureDetector(
                      onTap: () {
                        if (cvId != null && job != null && profile != null) {
                          _viewCV(cvId, job.id!, profile.id, app['application_status'] ?? 'pending');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Thông tin ứng viên không đầy đủ')),
                          );
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
                                child: profile?.avatarUrl != null 
                                    ? Image.network(profile!.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.person_outline, color: Colors.blue))
                                    : const Icon(Icons.person_outline, color: Colors.blue, size: 24),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile?.fullName ?? 'Ứng viên',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    job?.metadata.title ?? 'Việc làm bị xóa',
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
                                    profile?.email ?? '',
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
                                  _getTimeAgo(app['applied_at']),
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
                ),
    );
  }
}
