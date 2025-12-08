import 'package:flutter/material.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/repositories/job_repository.dart';
import '../../core/models/profile_model.dart';
import '../../core/models/job_model.dart';
import 'job_detail_screen.dart';
import '../../widgets/animated_avatar.dart';
import '../../widgets/cards/job_card.dart';

class HomePageCandidate extends StatefulWidget {
  const HomePageCandidate({super.key});

  @override
  State<HomePageCandidate> createState() => _HomePageCandidateState();
}

class _HomePageCandidateState extends State<HomePageCandidate> {
  final ScrollController _scrollController = ScrollController();
  final _authRepo = AuthRepository();
  final _jobRepo = JobRepository();
  
  Profile? _profile;
  List<JobModel> _jobs = [];
  bool _isLoadingJobs = true;
  List<String> _savedJobIds = [];
  List<String> _appliedJobIds = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadJobs();
    _loadSavedJobs();
  }

  Future<void> _loadProfile() async {
    final profile = await _authRepo.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
      });
    }
  }

  Future<void> _loadJobs() async {
    try {
      final jobs = await _jobRepo.getActiveJobs();
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _isLoadingJobs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingJobs = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading jobs: $e')),
        );
      }
    }
  }

  Future<void> _loadSavedJobs() async {
    final user = SupabaseService.instance.currentUser;
    if (user != null) {
      final savedIds = await _jobRepo.getSavedJobIds(user.id);
      final appliedIds = await _jobRepo.getAppliedJobIds(user.id);
      if (mounted) {
        setState(() {
          _savedJobIds = savedIds;
          _appliedJobIds = appliedIds;
        });
      }
    }
  }

  Future<void> _toggleSaveJob(String jobId) async {
    final user = SupabaseService.instance.currentUser;
    if (user == null) return;

    try {
      // Optimistic update
      setState(() {
        if (_savedJobIds.contains(jobId)) {
          _savedJobIds.remove(jobId);
        } else {
          _savedJobIds.add(jobId);
        }
      });

      await _jobRepo.toggleSaveJob(user.id, jobId);
    } catch (e) {
      // Revert if error
      _loadSavedJobs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving job: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService.instance;
    final currentUser = supabaseService.currentUser;
    
    // Prioritize profile data, fallback to user metadata
    final avatarUrl = _profile?.avatarUrl ?? currentUser?.userMetadata?['avatar_url'];
    final fullName = _profile?.fullName ?? currentUser?.userMetadata?['full_name'] ?? 'Người dùng';
    final phone = _profile?.phone ?? currentUser?.userMetadata?['phone'];

    return Stack(
      children: [
        Container(
         decoration: const BoxDecoration(
        gradient: AppMainColors.lightGradient,
      ),
          child: SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
            // Profile Header
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
                    // Avatar - Rectangle with rounded corners
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: avatarUrl == null
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
                        child: AnimatedAvatar(
                          avatarUrl: avatarUrl,
                          width: 60,
                          height: 60,
                          borderRadius: 14,
                          // Let the outer container's gradient show through for placeholder
                          placeholderColor: Colors.transparent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),

                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
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
                          if (phone != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  phone,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Notification Icon
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
                              const SnackBar(
                                  content: Text('Bạn có 3 thông báo mới')),
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

            // Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Việc làm hôm nay',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${_jobs.length} việc',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Job List
            _isLoadingJobs
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _jobs.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(child: Text('Chưa có việc làm nào')),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final job = _jobs[index];
                              final isSaved = _savedJobIds.contains(job.id);
                              final isApplied = _appliedJobIds.contains(job.id);

                              return JobCard(
                                job: job,
                                isSaved: isSaved,
                                isApplied: isApplied,
                                onToggleSave: () => _toggleSaveJob(job.id!),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          JobDetailScreen(job: job),
                                    ),
                                  );
                                },
                              );
                            },
                            childCount: _jobs.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),
    ),
    // Gradient overlay để tạo sự chuyển tiếp mượt mà với navbar
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
}