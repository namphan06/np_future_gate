import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/models/profile_model.dart';
import 'package:np_future_gate/core/repositories/job_repository.dart';
import 'package:np_future_gate/core/services/cv_supabase_service.dart';
import 'package:np_future_gate/core/services/subscription_service.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:np_future_gate/core/utils/date_time_utils.dart';
import 'package:np_future_gate/core/utils/job_utils.dart';

/// Controller for HomePageEmployer.
/// Handles all business logic: loading jobs, applications, stats,
/// subscription checks, and CV viewing.
class HomeEmployerController extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final JobRepository _jobRepository = JobRepository();
  final CVSupabaseService _cvService = CVSupabaseService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  List<JobModel> _jobs = [];
  List<Map<String, dynamic>> _applications = [];
  Map<String, int> _stats = {
    'jobsCount': 0,
    'newApplicantsCount': 0,
    'totalApplicantsCount': 0,
  };
  bool _isLoading = true;
  SubscriptionInfo? _subscriptionInfo;
  bool _isDisposed = false;

  // Getters
  List<JobModel> get jobs => _jobs;
  List<Map<String, dynamic>> get applications => _applications;
  Map<String, int> get stats => _stats;
  bool get isLoading => _isLoading;
  SubscriptionInfo? get subscriptionInfo => _subscriptionInfo;

  String? get currentUserId => _supabaseService.currentUserId;
  String? get companyName =>
      _supabaseService.currentUser?.userMetadata?['company_name'] ?? 'Công ty';
  String? get email => _supabaseService.currentUser?.email;
  String? get avatarUrl =>
      _supabaseService.currentUser?.userMetadata?['avatar_url'];

  /// Initialize controller - load all data.
  Future<void> init() async {
    await Future.wait([
      loadData(),
      checkSubscription(),
    ]);
  }

  Future<void> loadData() async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) return;

      final jobs = await _jobRepository.getRecentEmployerJobs(userId);
      final apps = await _jobRepository.getRecentApplications(userId);
      final stats = await _jobRepository.getEmployerStats(userId);

      if (!_isDisposed) {
        _jobs = jobs;
        _applications = apps;
        _stats = stats;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading home data: $e');
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> checkSubscription() async {
    try {
      final subscription = await _subscriptionService.getCurrentSubscription();
      if (!_isDisposed) {
        _subscriptionInfo = subscription;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error checking subscription: $e');
    }
  }

  /// Get CV data for viewing.
  Future<Map<String, dynamic>?> getCVData(String cvId) async {
    return await _cvService.getCVFullDataForEmployer(cvId);
  }

  /// Update application status when employer views a CV.
  Future<void> markApplicationViewed(
    String jobId,
    String userId,
    String currentStatus,
  ) async {
    if (currentStatus == 'pending') {
      await _jobRepository.updateApplicationStatus(jobId, userId, 'viewed');
    }
  }

  /// Get profile from application data.
  Profile? getProfileFromApplication(Map<String, dynamic> app) {
    if (app['profiles'] != null) {
      return Profile.fromJson(app['profiles']);
    }
    return null;
  }

  /// Get job from application data.
  JobModel? getJobFromApplication(Map<String, dynamic> app) {
    if (app['jobs'] != null) {
      return JobModel.fromJson(app['jobs']);
    }
    return null;
  }

  // Delegate utility methods
  String getJobStatus(JobModel job) => JobUtils.getJobStatus(job);
  String getSalaryString(JobSalary salary) => JobUtils.getSalaryString(salary);
  String getTimeAgo(DateTime dateTime) => DateTimeUtils.getTimeAgo(dateTime);
  String getDeadlineText(DateTime deadline) =>
      DateTimeUtils.getDeadlineText(deadline);
  Color getDeadlineColor(DateTime deadline) =>
      JobUtils.getDeadlineColor(deadline);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
