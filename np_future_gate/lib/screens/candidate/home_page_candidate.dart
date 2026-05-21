import 'package:flutter/material.dart';
import 'package:np_future_gate/core/controllers/home_candidate_controller.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/notification/screens/notifications_screen.dart';
import 'package:np_future_gate/screens/candidate/job_detail_screen.dart';
import 'package:np_future_gate/widgets/animated_avatar.dart';
import 'package:np_future_gate/widgets/cards/job_card.dart';

class HomePageCandidate extends StatefulWidget {
  const HomePageCandidate({super.key});

  @override
  State<HomePageCandidate> createState() => _HomePageCandidateState();
}

class _HomePageCandidateState extends State<HomePageCandidate> {
  final ScrollController _scrollController = ScrollController();
  late final HomeCandidateController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeCandidateController();
    _controller.addListener(_onControllerChanged);
    _controller.init();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: AppMainColors.lightGradient,
          ),
          child: SafeArea(
            child: StreamBuilder<List<JobModel>>(
              stream: _controller.activeJobsStream,
              builder: (context, snapshot) {
                final allJobs = snapshot.data ?? [];
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting;
                final jobs = _controller.filterTodayJobs(allJobs);

                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    _buildProfileHeader(),
                    _buildSectionTitle(jobs.length),
                    _buildJobList(jobs, isLoading),
                  ],
                );
              },
            ),
          ),
        ),
        _buildBottomGradient(),
      ],
    );
  }

  // ============================================================
  // UI COMPONENTS (View only - no business logic)
  // ============================================================

  Widget _buildProfileHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 15),
            _buildUserInfo(),
            _buildNotificationButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final avatarUrl = _controller.avatarUrl;
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: avatarUrl == null
            ? LinearGradient(
                colors: [
                  AppMainColors.primary.withValues(alpha: 0.8),
                  AppMainColors.primaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: AppMainColors.primary.withValues(alpha: 0.2),
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
          placeholderColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _controller.fullName,
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
              Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _controller.email ?? 'No email',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (_controller.phone != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.phone_outlined,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _controller.phone!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppMainColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Stack(
              children: [
                const Icon(
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
    );
  }

  Widget _buildSectionTitle(int jobCount) {
    return SliverToBoxAdapter(
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
              '$jobCount việc',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobList(List<JobModel> jobs, bool isLoading) {
    if (isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (jobs.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('Chưa có việc làm nào')),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final job = jobs[index];
            final isSaved = _controller.isJobSaved(job.id!);
            final isApplied = _controller.isJobApplied(job.id!);

            return JobCard(
              job: job,
              isSaved: isSaved,
              isApplied: isApplied,
              onToggleSave: () => _handleToggleSave(job.id!),
              onTap: () => _navigateToJobDetail(job),
            );
          },
          childCount: jobs.length,
        ),
      ),
    );
  }

  Widget _buildBottomGradient() {
    return Positioned(
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
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.6),
                Colors.white.withValues(alpha: 0.85),
                Colors.white,
              ],
              stops: const [0.0, 0.2, 0.4, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NAVIGATION & USER ACTIONS
  // ============================================================

  void _navigateToJobDetail(JobModel job) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JobDetailScreen(job: job)),
    );
  }

  Future<void> _handleToggleSave(String jobId) async {
    try {
      await _controller.toggleSaveJob(jobId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving job: $e')),
        );
      }
    }
  }
}
