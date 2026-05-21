import 'package:flutter/material.dart';
import 'package:np_future_gate/core/controllers/home_employer_controller.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/services/subscription_service.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/notification/screens/notifications_screen.dart';
import 'package:np_future_gate/screens/cv/cv_setting/cv_display_manager.dart';
import 'package:np_future_gate/screens/employer/jobs/edit_job_screen.dart';
import 'package:np_future_gate/screens/employer/jobs/employer_jobs_screen.dart';
import 'package:np_future_gate/screens/employer/jobs/recent_applicants_screen.dart';
import 'package:np_future_gate/screens/employer/subscription/upgrade_account_screen.dart';

class HomePageEmployer extends StatefulWidget {
  const HomePageEmployer({super.key});

  @override
  State<HomePageEmployer> createState() => _HomePageEmployerState();
}

class _HomePageEmployerState extends State<HomePageEmployer> {
  late final HomeEmployerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeEmployerController();
    _controller.addListener(_onControllerChanged);
    _controller.init().then((_) => _checkSubscriptionNotifications());
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _checkSubscriptionNotifications() {
    final sub = _controller.subscriptionInfo;
    if (sub == null) return;

    if (sub.wasExpired) {
      _showSubscriptionExpiredNotification();
    } else if (sub.isAboutToExpire) {
      _showSubscriptionExpiringNotification(sub.daysRemaining);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildCompanyHeader(),
              _buildQuickStats(),
              if (_controller.subscriptionInfo != null)
                SliverToBoxAdapter(child: _buildSubscriptionInfoCard()),
              _buildJobPostingsSection(),
              _buildJobList(),
              _buildRecentApplicantsSection(),
              _buildApplicantsList(),
            ],
          ),
        ),
        _buildBottomGradient(),
      ],
    );
  }

  // ============================================================
  // UI COMPONENTS (View only)
  // ============================================================

  Widget _buildCompanyHeader() {
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
            _buildCompanyLogo(),
            const SizedBox(width: 15),
            _buildCompanyInfo(),
            _buildNotificationButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyLogo() {
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
        child: avatarUrl != null
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppMainColors.primary.withValues(alpha: 0.8),
                          AppMainColors.primaryDark,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.business_rounded,
                      size: 30,
                      color: Colors.white,
                    ),
                  );
                },
              )
            : const Icon(
                Icons.business_rounded,
                size: 30,
                color: Colors.white,
              ),
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _controller.companyName ?? 'Công ty',
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
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
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

  Widget _buildQuickStats() {
    final stats = _controller.stats;
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 15, 20, 10),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Tin đăng',
                value: '${stats['jobsCount']}',
                icon: Icons.work_outline,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Ứng viên mới',
                value: '${stats['newApplicantsCount']}',
                icon: Icons.person_add_outlined,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Tổng UV',
                value: '${stats['totalApplicantsCount']}',
                icon: Icons.people_outline,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionInfoCard() {
    final sub = _controller.subscriptionInfo!;
    final isExpiredOrFree = sub.wasExpired || sub.plan == SubscriptionPlan.free;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 5, 20, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpiredOrFree
              ? [Colors.grey[600]!, Colors.grey[500]!]
              : [
                  AppMainColors.primary,
                  AppMainColors.primary.withValues(alpha: 0.8),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isExpiredOrFree ? Colors.grey : AppMainColors.primary)
                .withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToUpgrade(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                sub.wasExpired
                    ? Icons.warning_amber_rounded
                    : sub.plan == SubscriptionPlan.free
                        ? Icons.card_giftcard
                        : Icons.workspace_premium,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        sub.wasExpired
                            ? 'Gói đã hết hạn'
                            : 'Gói ${sub.plan.displayName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          sub.plan.code,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Còn ${sub.remainingJobs}/${sub.maxJobsPerMonth} tin${sub.daysRemaining > 0 ? ' • ${sub.daysRemaining} ngày' : ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobPostingsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tin tuyển dụng',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton.icon(
              onPressed: () => _navigateToEmployerJobs(),
              icon: const Icon(Icons.remove_red_eye, size: 18),
              label: const Text('Xem tất cả'),
              style: TextButton.styleFrom(
                foregroundColor: AppMainColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (_controller.jobs.isEmpty) return const SizedBox.shrink();
            final job = _controller.jobs[index];
            return _buildJobCard(job);
          },
          childCount: _controller.jobs.length,
        ),
      ),
    );
  }

  Widget _buildJobCard(JobModel job) {
    return GestureDetector(
      onTap: () => _navigateToEditJob(job),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.metadata.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _controller.getJobStatus(job),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people_outline,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${job.applicants.length} ứng viên',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
                Icon(Icons.attach_money,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _controller.getSalaryString(job.metadata.salary),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _controller.getTimeAgo(job.createdAt!),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                if (job.deadline != null)
                  Text(
                    _controller.getDeadlineText(job.deadline!),
                    style: TextStyle(
                      fontSize: 12,
                      color: _controller.getDeadlineColor(job.deadline!),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentApplicantsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ứng viên mới nhất',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToRecentApplicants(),
              style: TextButton.styleFrom(
                foregroundColor: AppMainColors.primary,
              ),
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantsList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (_controller.applications.isEmpty) {
              return const SizedBox.shrink();
            }
            final app = _controller.applications[index];
            return _buildApplicantCard(app);
          },
          childCount: _controller.applications.length,
        ),
      ),
    );
  }

  Widget _buildApplicantCard(Map<String, dynamic> app) {
    final profile = _controller.getProfileFromApplication(app);
    final job = _controller.getJobFromApplication(app);
    final cvId = app['cv_id'] as String?;

    if (profile == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        if (cvId != null && job != null) {
          _viewCV(cvId, job.id!, profile.id,
              app['application_status'] as String? ?? 'pending');
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
              color: Colors.black.withValues(alpha: 0.06),
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
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: profile.avatarUrl != null
                    ? Image.network(
                        profile.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_outline,
                            color: Colors.blue),
                      )
                    : const Icon(Icons.person_outline,
                        color: Colors.blue, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName ?? 'No Name',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job?.metadata.title ?? 'Việc làm không rõ',
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
                    profile.email ?? '',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
                  _controller
                      .getTimeAgo(DateTime.parse(app['applied_at'] as String)),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
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

  void _navigateToUpgrade() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UpgradeAccountScreen()),
    );
  }

  void _navigateToEmployerJobs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmployerJobsScreen()),
    );
  }

  void _navigateToEditJob(JobModel job) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditJobScreen(job: job)),
    );
  }

  void _navigateToRecentApplicants() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecentApplicantsScreen()),
    );
  }

  Future<void> _viewCV(
    String cvId,
    String jobId,
    String userId,
    String currentStatus,
  ) async {
    try {
      await _controller.markApplicationViewed(jobId, userId, currentStatus);

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final cvData = await _controller.getCVData(cvId);

      if (mounted) Navigator.pop(context);

      if (cvData != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CVDisplayManager.buildViewWidget(context, cvData),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('CV không tồn tại hoặc đã bị xóa')),
          );
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tải CV: $e')));
      }
    }
  }

  void _showSubscriptionExpiredNotification() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Gói đăng ký đã hết hạn! Bạn đang dùng gói miễn phí.'),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Gia hạn',
            textColor: Colors.white,
            onPressed: () => _navigateToUpgrade(),
          ),
        ),
      );
    });
  }

  void _showSubscriptionExpiringNotification(int daysRemaining) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Gói đăng ký sẽ hết hạn trong $daysRemaining ngày.'),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Gia hạn',
            textColor: Colors.white,
            onPressed: () => _navigateToUpgrade(),
          ),
        ),
      );
    });
  }
}
