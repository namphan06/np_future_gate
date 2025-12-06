import 'package:flutter/material.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/repositories/job_repository.dart';
import '../../core/models/profile_model.dart';
import '../../core/models/job_model.dart';
import 'job_detail_screen.dart';

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
      if (mounted) {
        setState(() {
          _savedJobIds = savedIds;
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

  String _getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Vừa xong';
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
                        child: avatarUrl != null
                            ? Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppMainColors.primary.withOpacity(0.8),
                                          AppMainColors.primaryDark,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              )
                            : const Icon(
                                Icons.person_rounded,
                                size: 30,
                                color: Colors.white,
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
                              final meta = job.metadata;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 15),
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
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              JobDetailScreen(job: job),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    meta.title.isNotEmpty
                                                        ? meta.title[0]
                                                            .toUpperCase()
                                                        : 'J',
                                                    style: const TextStyle(
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.bold,
                                                      color:
                                                          AppMainColors.primary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      meta.title,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      meta.workingRegions
                                                              .isNotEmpty
                                                          ? meta.workingRegions
                                                              .first
                                                          : 'Toàn quốc',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey
                                                            .shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () => _toggleSaveJob(job.id!),
                                                child: Icon(
                                                  _savedJobIds.contains(job.id)
                                                      ? Icons.bookmark
                                                      : Icons.bookmark_border,
                                                  color: _savedJobIds.contains(job.id)
                                                      ? AppMainColors.primary
                                                      : Colors.grey.shade400,
                                                  size: 22,
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 12),

                                          Row(
                                            children: [
                                              Icon(Icons.location_on_outlined,
                                                  size: 16,
                                                  color: Colors.grey.shade600),
                                              const SizedBox(width: 4),
                                              Text(
                                                meta.workLocations.isNotEmpty
                                                    ? meta.workLocations.first
                                                    : 'N/A',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Icon(Icons.work_outline,
                                                  size: 16,
                                                  color: Colors.grey.shade600),
                                              const SizedBox(width: 4),
                                              Text(
                                                meta.employmentTypes.isNotEmpty
                                                    ? meta.employmentTypes.first
                                                    : 'Full-time',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 10),

                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: meta.requirementsTags
                                                .take(3)
                                                .map((tag) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppMainColors
                                                      .backgroundLightStart,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  tag,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppMainColors
                                                        .primaryDark,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),

                                          const SizedBox(height: 10),

                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Builder(
                                                builder: (context) {
                                                  String salaryText = 'Thỏa thuận';
                                                  if (meta.salary.isNegotiable) {
                                                    salaryText = 'Thỏa thuận';
                                                  } else {
                                                    final min = meta.salary.min;
                                                    final max = meta.salary.max;
                                                    final currency = meta.salary.currency;
                                                    
                                                    if (min != null && max != null) {
                                                      salaryText = '$min - $max $currency';
                                                    } else if (min != null) {
                                                      salaryText = 'Từ $min $currency';
                                                    } else if (max != null) {
                                                      salaryText = 'Đến $max $currency';
                                                    }
                                                  }
                                                  return Text(
                                                    salaryText,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.green.shade700,
                                                    ),
                                                  );
                                                },
                                              ),
                                              Text(
                                                _getTimeAgo(job.createdAt),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
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