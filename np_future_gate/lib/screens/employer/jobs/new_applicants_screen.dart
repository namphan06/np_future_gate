import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:np_future_gate/core/repositories/job_repository.dart';
import 'package:np_future_gate/core/services/cv_supabase_service.dart';
import 'package:np_future_gate/screens/candidate/job_detail_screen.dart';
import 'package:np_future_gate/screens/cv/cv_setting/cv_display_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewApplicantsScreen extends StatefulWidget {
  const NewApplicantsScreen({super.key});

  @override
  State<NewApplicantsScreen> createState() => _NewApplicantsScreenState();
}

class _NewApplicantsScreenState extends State<NewApplicantsScreen> {
  final JobRepository _jobRepository = JobRepository();
  final CVSupabaseService _cvService = CVSupabaseService();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _applications = [];

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final employerId = _supabase.auth.currentUser?.id;
    if (employerId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Bạn cần đăng nhập để xem CV mới.';
      });
      return;
    }

    try {
      final apps = await _jobRepository.getRecentEmployerApplicationsFromActivities(employerId, limit: 0);
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      final pendingApps = apps.where((app) {
        final status = (app['application_status'] ?? app['status'] ?? '').toString().toLowerCase();
        if (status != 'pending') return false;
        final appliedAt = DateTime.tryParse(app['applied_at']?.toString() ?? '');
        if (appliedAt == null) return false;
        return appliedAt.isAfter(cutoff);
      }).toList();

      if (pendingApps.isNotEmpty) {
        final userIds = pendingApps
            .map((app) => app['user_id']?.toString())
            .whereType<String>()
            .toSet()
            .toList();

        if (userIds.isNotEmpty) {
          final profilesResponse = await _supabase
              .from('profiles')
              .select('id, full_name, email, avatar_url')
              .filter('id', 'in', userIds);

          final profileMap = {
            for (final profile in (profilesResponse as List)) profile['id']: profile,
          };

          for (final app in pendingApps) {
            final userId = app['user_id']?.toString();
            if (userId != null) {
              app['profiles'] = profileMap[userId];
            }
          }
        }
      }

      setState(() {
        _applications = pendingApps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải danh sách CV mới: $e';
      });
    }
  }

  Future<void> _viewCV(Map<String, dynamic> application) async {
    final cvId = application['cv_id']?.toString() ?? '';
    final userId = application['user_id']?.toString() ?? '';
    final jobId = application['job_id']?.toString() ?? '';

    if (cvId.isEmpty || userId.isEmpty || jobId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thiếu dữ liệu CV để hiển thị.')),
        );
      }
      return;
    }

    try {
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
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải CV: $e')),
        );
      }
    }
  }

  Future<void> _openJobDetail(Map<String, dynamic> application) async {
    final jobId = application['job_id']?.toString() ?? '';

    if (jobId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy thông tin tin tuyển dụng.')),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final job = await _jobRepository.getJobById(jobId);
      if (mounted) Navigator.pop(context);

      if (job == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy tin tuyển dụng.')),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailScreen(job: job),
          ),
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách ứng viên: $e')),
        );
      }
    }
  }

  String _formatAppliedAt(String? appliedAt) {
    if (appliedAt == null) return 'Chưa rõ thời gian';
    final parsed = DateTime.tryParse(appliedAt);
    if (parsed == null) return appliedAt;
    return DateFormat('dd/MM/yyyy HH:mm').format(parsed);
  }

  String _getApplicantName(Map<String, dynamic> application) {
    final profile = application['profiles'] as Map<String, dynamic>?;
    final name = profile?['full_name']?.toString();
    if (name != null && name.isNotEmpty) return name;
    return 'Ứng viên';
  }

  String _getApplicantEmail(Map<String, dynamic> application) {
    final profile = application['profiles'] as Map<String, dynamic>?;
    final email = profile?['email']?.toString();
    if (email != null && email.isNotEmpty) return email;
    return 'Chưa cập nhật';
  }

  String _getJobTitle(Map<String, dynamic> application) {
    final job = application['jobs'] as Map<String, dynamic>?;
    final metadata = job?['metadata'] as Map<String, dynamic>?;
    final title = metadata?['title']?.toString();
    if (title != null && title.isNotEmpty) return title;
    return 'Vị trí ứng tuyển';
  }

  String _getAvatarUrl(Map<String, dynamic> application) {
    final profile = application['profiles'] as Map<String, dynamic>?;
    return profile?['avatar_url']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('CV mới'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _applications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.inbox_outlined, size: 48, color: Colors.red.shade300),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có CV mới',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _loadApplications,
                            child: const Text('Tải lại'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadApplications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _applications.length,
                        itemBuilder: (context, index) {
                          final application = _applications[index];
                          final avatarUrl = _getAvatarUrl(application);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
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
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                          image: avatarUrl.isNotEmpty
                                              ? DecorationImage(
                                                  image: NetworkImage(avatarUrl),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: avatarUrl.isEmpty
                                            ? Icon(Icons.person, color: Colors.grey.shade400, size: 28)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _getApplicantName(application),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _getApplicantEmail(application),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.work_outline, size: 14, color: Colors.grey[500]),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    _getJobTitle(application),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Ứng tuyển: ${_formatAppliedAt(application['applied_at']?.toString())}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _viewCV(application),
                                          icon: const Icon(Icons.description_outlined, size: 16),
                                          label: const Text('Xem CV'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.blue,
                                            side: const BorderSide(color: Colors.blue),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _openJobDetail(application),
                                          icon: const Icon(Icons.work_outline, size: 16),
                                          label: const Text('Việc làm ứng tuyển'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.orange,
                                            side: const BorderSide(color: Colors.orange),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
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
                    ),
    );
  }
}
