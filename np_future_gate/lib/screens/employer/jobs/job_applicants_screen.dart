import 'package:flutter/material.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/models/job_model.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/job_repository.dart';
import '../../../core/services/cv_supabase_service.dart';
import '../../cv/cv_setting/cv_display_manager.dart';
import '../../../core/theme/app_main_colors.dart';

class JobApplicantsScreen extends StatefulWidget {
  final String jobId;
  final List<JobApplication> applicants;

  const JobApplicantsScreen({
    super.key,
    required this.jobId,
    required this.applicants,
  });

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> {
  final AuthRepository _authRepository = AuthRepository();
  final JobRepository _jobRepository = JobRepository();
  final CVSupabaseService _cvService = CVSupabaseService();
  
  List<Profile> _profiles = [];
  bool _isLoading = true;
  late List<JobApplication> _currentApplicants;

  @override
  void initState() {
    super.initState();
    _currentApplicants = widget.applicants;
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final userIds = _currentApplicants.map((e) => e.userId).toList();
      if (userIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final profiles = await _authRepository.getProfilesByIds(userIds);
      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profiles: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(String userId, String newStatus) async {
    try {
      await _jobRepository.updateApplicationStatus(widget.jobId, userId, newStatus);
      
      setState(() {
        final index = _currentApplicants.indexWhere((app) => app.userId == userId);
        if (index != -1) {
          _currentApplicants[index] = JobApplication(
            userId: _currentApplicants[index].userId,
            cvId: _currentApplicants[index].cvId,
            appliedAt: _currentApplicants[index].appliedAt,
            status: newStatus,
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  Future<void> _viewCV(String cvId) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final cvData = await _cvService.getCVFullData(cvId);
      
      // Hide loading indicator
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
            const SnackBar(content: Text('CV not found or deleted')),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator if error
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading CV: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applicants'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentApplicants.isEmpty
              ? const Center(child: Text('No applicants yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _currentApplicants.length,
                  itemBuilder: (context, index) {
                    final application = _currentApplicants[index];
                    final profile = _profiles.firstWhere(
                      (p) => p.id == application.userId,
                      orElse: () => Profile(
                        id: application.userId,
                        email: 'Unknown',
                        fullName: 'Unknown User',
                        role: UserRole.candidate,
                        metadata: {},
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundImage: profile.avatarUrl != null
                                      ? NetworkImage(profile.avatarUrl!)
                                      : null,
                                  child: profile.avatarUrl == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile.fullName ?? 'No Name',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Applied: ${application.appliedAt.toString().split(' ')[0]}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildStatusBadge(application.status),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _viewCV(application.cvId),
                                  icon: const Icon(Icons.description_outlined, size: 18),
                                  label: const Text('View CV'),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  onSelected: (status) => _updateStatus(application.userId, status),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'pending',
                                      child: Text('Mark as Pending'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'accepted',
                                      child: Text('Accept', style: TextStyle(color: Colors.green)),
                                    ),
                                    const PopupMenuItem(
                                      value: 'rejected',
                                      child: Text('Reject', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppMainColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Update Status',
                                          style: TextStyle(
                                            color: AppMainColors.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(Icons.arrow_drop_down, color: AppMainColors.primary),
                                      ],
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
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'accepted':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
