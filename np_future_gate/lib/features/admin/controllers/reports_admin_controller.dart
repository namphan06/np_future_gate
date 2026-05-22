import 'package:flutter/foundation.dart';
import 'package:np_future_gate/core/controllers/base_controller.dart';
import 'package:np_future_gate/core/models/statistics_model.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:np_future_gate/core/utils/statistics_utils.dart';

/// Controller for ReportsPageAdmin.
///
/// Handles all business logic for admin statistics:
/// - Loading user, job, application, and interview stats from Supabase
/// - Period filtering (7, 30, 90, 365 days)
/// - Grouping data by day for chart display
class ReportsAdminController extends BaseController {
  final _supabaseService = SupabaseService.instance;

  StatisticsModel? _statistics;
  String _selectedPeriod = '7';

  // Raw data lists for groupByDay computation
  List<dynamic> _rawUsers = [];
  List<dynamic> _rawJobs = [];
  List<dynamic> _rawApplications = [];

  /// The current statistics data, or null if not yet loaded.
  StatisticsModel? get statistics => _statistics;

  /// The currently selected period filter value ('7', '30', '90', '365').
  String get selectedPeriod => _selectedPeriod;

  /// Users grouped by day within the selected period.
  List<Map<String, dynamic>> get usersByDay {
    final daysAgo = int.parse(_selectedPeriod);
    final periodStart = DateTime.now().subtract(Duration(days: daysAgo));
    return StatisticsUtils.groupByDay(
      _rawUsers,
      'created_at',
      periodStart,
      daysAgo,
    );
  }

  /// Jobs grouped by day within the selected period.
  List<Map<String, dynamic>> get jobsByDay {
    final daysAgo = int.parse(_selectedPeriod);
    final periodStart = DateTime.now().subtract(Duration(days: daysAgo));
    return StatisticsUtils.groupByDay(
      _rawJobs,
      'created_at',
      periodStart,
      daysAgo,
    );
  }

  /// Applications grouped by day within the selected period.
  List<Map<String, dynamic>> get applicationsByDay {
    final daysAgo = int.parse(_selectedPeriod);
    final periodStart = DateTime.now().subtract(Duration(days: daysAgo));
    return StatisticsUtils.groupByDay(
      _rawApplications,
      'applied_at',
      periodStart,
      daysAgo,
    );
  }

  /// Sets the period filter and reloads statistics.
  ///
  /// [period] must be one of '7', '30', '90', '365'.
  void setPeriod(String period) {
    _selectedPeriod = period;
    safeNotifyListeners();
    loadStatistics();
  }

  /// Loads all statistics data from Supabase in parallel.
  ///
  /// Fetches user stats, job stats, application stats, and interview stats,
  /// then builds a [StatisticsModel] from the aggregated data.
  Future<void> loadStatistics() async {
    isLoading = true;
    setError(null);

    try {
      final daysAgo = int.parse(_selectedPeriod);
      final periodStart = DateTime.now().subtract(Duration(days: daysAgo));

      // Load all data in parallel
      await Future.wait([
        _loadUserStats(periodStart),
        _loadJobStats(periodStart),
        _loadApplicationStats(periodStart),
        _loadInterviewStats(),
      ]);

      debugPrint('📊 Admin statistics loaded successfully');
    } catch (e) {
      debugPrint('❌ Error loading statistics: $e');
      setError(e.toString());
    } finally {
      isLoading = false;
    }
  }

  Future<void> _loadUserStats(DateTime periodStart) async {
    final usersResponse = await _supabaseService.client
        .from('profiles')
        .select('id, role, created_at');

    final users = usersResponse as List;
    _rawUsers = users;

    // Count by role
    final usersByRole = <String, int>{};
    for (var user in users) {
      final role = user['role']?.toString() ?? 'user';
      usersByRole[role] = (usersByRole[role] ?? 0) + 1;
    }

    // Count new users in period
    final newUsersInPeriod = users.where((u) {
      final createdAt = DateTime.tryParse(u['created_at']?.toString() ?? '');
      return createdAt != null && createdAt.isAfter(periodStart);
    }).length;

    _statistics = (_statistics ?? _emptyStatistics()).copyWith(
      totalUsers: users.length,
      usersByRole: usersByRole,
      newUsersInPeriod: newUsersInPeriod,
    );
  }

  Future<void> _loadJobStats(DateTime periodStart) async {
    final jobsResponse = await _supabaseService.client
        .from('jobs')
        .select('id, status, created_at, deadline');

    final jobs = jobsResponse as List;
    _rawJobs = jobs;

    // Count by status (active vs expired based on deadline)
    final jobsByStatus = <String, int>{};
    for (var job in jobs) {
      final deadline = DateTime.tryParse(job['deadline']?.toString() ?? '');
      final isExpired = deadline != null && deadline.isBefore(DateTime.now());
      final status = isExpired ? 'expired' : 'active';
      jobsByStatus[status] = (jobsByStatus[status] ?? 0) + 1;
    }

    // Count new jobs in period
    final newJobsInPeriod = jobs.where((j) {
      final createdAt = DateTime.tryParse(j['created_at']?.toString() ?? '');
      return createdAt != null && createdAt.isAfter(periodStart);
    }).length;

    _statistics = (_statistics ?? _emptyStatistics()).copyWith(
      totalJobs: jobs.length,
      jobsByStatus: jobsByStatus,
      newJobsInPeriod: newJobsInPeriod,
    );
  }

  Future<void> _loadApplicationStats(DateTime periodStart) async {
    final jobsResponse = await _supabaseService.client
        .from('jobs')
        .select('applicants');

    final jobs = jobsResponse as List;

    // Extract all applications from jobs' applicants arrays
    final allApplications = <Map<String, dynamic>>[];
    for (var job in jobs) {
      final applicants = job['applicants'] as List?;
      if (applicants != null) {
        for (var applicant in applicants) {
          if (applicant is Map<String, dynamic>) {
            allApplications.add({
              'applied_at': applicant['applied_at'],
              'status':
                  applicant['status']?.toString().toLowerCase() ?? 'pending',
            });
          }
        }
      }
    }

    _rawApplications = allApplications;

    // Count new applications in period
    final newApplicationsInPeriod = allApplications.where((a) {
      final appliedAt = DateTime.tryParse(a['applied_at']?.toString() ?? '');
      return appliedAt != null && appliedAt.isAfter(periodStart);
    }).length;

    // Calculate success rate
    final acceptedCount =
        allApplications.where((a) => a['status'] == 'accepted').length;
    final applicationSuccessRate = allApplications.isNotEmpty
        ? (acceptedCount / allApplications.length * 100)
        : 0.0;

    _statistics = (_statistics ?? _emptyStatistics()).copyWith(
      totalApplications: allApplications.length,
      newApplicationsInPeriod: newApplicationsInPeriod,
      applicationSuccessRate: applicationSuccessRate,
    );
  }

  Future<void> _loadInterviewStats() async {
    final interviewsResponse = await _supabaseService.client
        .from('interview_schedules')
        .select('id, created_at');

    final interviews = interviewsResponse as List;

    _statistics = (_statistics ?? _emptyStatistics()).copyWith(
      totalInterviews: interviews.length,
    );
  }

  /// Creates an empty [StatisticsModel] with all zero values.
  StatisticsModel _emptyStatistics() {
    return StatisticsModel(
      totalUsers: 0,
      totalJobs: 0,
      totalApplications: 0,
      totalInterviews: 0,
      newUsersInPeriod: 0,
      newJobsInPeriod: 0,
      newApplicationsInPeriod: 0,
      applicationSuccessRate: 0.0,
      usersByRole: {},
      jobsByStatus: {},
    );
  }
}
