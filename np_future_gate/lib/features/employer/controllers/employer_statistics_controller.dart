import 'package:flutter/foundation.dart';
import 'package:np_future_gate/core/controllers/base_controller.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';

/// Controller for EmployerStatisticsScreen.
///
/// Handles all business logic for employer statistics:
/// - Job statistics aggregation (total, active, expired)
/// - Application counting by status (pending, accepted, rejected)
/// - Chart data preparation (applications by month, jobs by field)
/// - Period selection (7 days, 30 days, 3 months, 6 months, 1 year)
/// - Recent applications with profile data
class EmployerStatisticsController extends BaseController {
  final _supabaseService = SupabaseService.instance;

  // Job statistics
  int _totalJobs = 0;
  int _activeJobs = 0;
  int _expiredJobs = 0;
  int _totalViews = 0;
  int _totalInterviews = 0;

  // Application statistics
  int _totalApplications = 0;
  int _pendingApplications = 0;
  int _acceptedApplications = 0;
  int _rejectedApplications = 0;

  // Chart data
  List<Map<String, dynamic>> _applicationsByMonth = [];
  List<Map<String, dynamic>> _jobsByField = [];
  List<Map<String, dynamic>> _recentApplications = [];

  // Period selection
  String _selectedPeriod = '30 ngày';
  final List<String> _periods = [
    '7 ngày',
    '30 ngày',
    '3 tháng',
    '6 tháng',
    '1 năm',
  ];

  // --- Getters ---

  /// Total number of jobs posted by this employer.
  int get totalJobs => _totalJobs;

  /// Number of currently active (not expired) jobs.
  int get activeJobs => _activeJobs;

  /// Number of expired jobs.
  int get expiredJobs => _expiredJobs;

  /// Total view count across all jobs.
  int get totalViews => _totalViews;

  /// Total number of interviews scheduled.
  int get totalInterviews => _totalInterviews;

  /// Total number of applications received.
  int get totalApplications => _totalApplications;

  /// Number of pending (including 'viewed') applications.
  int get pendingApplications => _pendingApplications;

  /// Number of accepted applications.
  int get acceptedApplications => _acceptedApplications;

  /// Number of rejected applications.
  int get rejectedApplications => _rejectedApplications;

  /// Applications grouped by month (last 6 months).
  /// Each entry: {'month': 'T{n}', 'count': int}
  List<Map<String, dynamic>> get applicationsByMonth => _applicationsByMonth;

  /// Jobs grouped by field, sorted by count descending.
  /// Each entry: {'field': String, 'count': int}
  List<Map<String, dynamic>> get jobsByField => _jobsByField;

  /// Recent applications with profile info (up to 5).
  /// Each entry: {'name': String, 'avatar': String?, 'status': String, 'created_at': String?}
  List<Map<String, dynamic>> get recentApplications => _recentApplications;

  /// The currently selected period label.
  String get selectedPeriod => _selectedPeriod;

  /// Available period options.
  List<String> get periods => _periods;

  // --- Actions ---

  /// Sets the period filter and reloads statistics.
  void setPeriod(String period) {
    _selectedPeriod = period;
    safeNotifyListeners();
    loadStatistics();
  }

  /// Loads all employer statistics from Supabase.
  ///
  /// Fetches jobs with applicants, computes aggregations,
  /// prepares chart data, and loads recent application profiles.
  Future<void> loadStatistics() async {
    isLoading = true;
    setError(null);

    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) {
        debugPrint('❌ User not logged in');
        isLoading = false;
        return;
      }

      debugPrint('📊 Loading employer statistics for user: $userId');

      // Get all jobs by this employer with applicants
      final jobsResponse = await _supabaseService.client
          .from('jobs')
          .select('id, metadata, deadline, view_count, created_at, applicants')
          .eq('creator_id', userId);

      final jobs = jobsResponse as List;

      _aggregateJobStatistics(jobs);
      final allApplications = _extractApplications(jobs);
      _countApplicationsByStatus(allApplications);
      _computeJobsByField(jobs);
      _computeApplicationsByMonth(allApplications);
      await _loadRecentApplications(allApplications);
      await _loadInterviewCount(userId);

      debugPrint('✅ Employer statistics loaded successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading employer statistics: $e');
      debugPrint('Stack trace: $stackTrace');
      setError(e.toString());
    } finally {
      isLoading = false;
    }
  }

  /// Aggregates job-level statistics (total, active, expired, views).
  void _aggregateJobStatistics(List<dynamic> jobs) {
    _totalJobs = jobs.length;
    _activeJobs = jobs.where((j) {
      final deadline = DateTime.tryParse(j['deadline'] ?? '');
      return deadline != null && deadline.isAfter(DateTime.now());
    }).length;
    _expiredJobs = _totalJobs - _activeJobs;
    _totalViews =
        jobs.fold(0, (sum, j) => sum + ((j['view_count'] as int?) ?? 0));
  }

  /// Extracts all applications from jobs' applicants arrays.
  List<Map<String, dynamic>> _extractApplications(List<dynamic> jobs) {
    final allApplications = <Map<String, dynamic>>[];
    for (final job in jobs) {
      final applicants = job['applicants'] as List?;
      if (applicants != null && applicants.isNotEmpty) {
        for (final applicant in applicants) {
          if (applicant is Map<String, dynamic>) {
            allApplications.add({
              'user_id': applicant['user_id'],
              'cv_id': applicant['cv_id'],
              'applied_at': applicant['applied_at'],
              'status': applicant['status']?.toString() ?? 'pending',
              'job_id': job['id'],
            });
          }
        }
      }
    }
    return allApplications;
  }

  /// Counts applications by status (pending/viewed, accepted, rejected).
  void _countApplicationsByStatus(List<Map<String, dynamic>> applications) {
    _totalApplications = applications.length;
    _pendingApplications = applications.where((a) {
      final status = a['status']?.toString().toLowerCase() ?? 'pending';
      return status == 'pending' || status == 'viewed';
    }).length;
    _acceptedApplications = applications
        .where((a) => a['status']?.toString().toLowerCase() == 'accepted')
        .length;
    _rejectedApplications = applications
        .where((a) => a['status']?.toString().toLowerCase() == 'rejected')
        .length;
  }

  /// Computes jobs grouped by field from metadata.fields array.
  void _computeJobsByField(List<dynamic> jobs) {
    final fieldCounts = <String, int>{};
    for (final job in jobs) {
      final metadata = job['metadata'] as Map<String, dynamic>?;
      final fields = metadata?['fields'] as List?;
      if (fields != null && fields.isNotEmpty) {
        final field = fields.first.toString();
        fieldCounts[field] = (fieldCounts[field] ?? 0) + 1;
      } else {
        fieldCounts['Khác'] = (fieldCounts['Khác'] ?? 0) + 1;
      }
    }
    _jobsByField = fieldCounts.entries
        .map((e) => {'field': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
  }

  /// Computes applications grouped by month (last 6 months).
  void _computeApplicationsByMonth(List<Map<String, dynamic>> applications) {
    if (applications.isEmpty) {
      _applicationsByMonth = [];
      return;
    }

    final now = DateTime.now();
    _applicationsByMonth = List.generate(6, (index) {
      final month = DateTime(now.year, now.month - (5 - index), 1);
      final monthEnd = DateTime(month.year, month.month + 1, 0);
      final count = applications.where((a) {
        final createdAt = DateTime.tryParse(a['applied_at'] ?? '');
        return createdAt != null &&
            createdAt.isAfter(month.subtract(const Duration(days: 1))) &&
            createdAt.isBefore(monthEnd.add(const Duration(days: 1)));
      }).length;
      return {
        'month': 'T${month.month}',
        'count': count,
      };
    });
  }

  /// Loads recent applications with profile data (up to 5).
  Future<void> _loadRecentApplications(
      List<Map<String, dynamic>> allApplications) async {
    if (allApplications.isEmpty) {
      _recentApplications = [];
      return;
    }

    // Sort by applied_at (newest first)
    allApplications.sort((a, b) {
      final aDate = DateTime.tryParse(a['applied_at'] ?? '');
      final bDate = DateTime.tryParse(b['applied_at'] ?? '');
      if (aDate == null || bDate == null) return 0;
      return bDate.compareTo(aDate);
    });

    // Get unique user IDs for recent applications
    final recentUserIds = allApplications
        .take(5)
        .map((a) => a['user_id'] as String)
        .toSet()
        .toList();

    if (recentUserIds.isEmpty) {
      _recentApplications = [];
      return;
    }

    try {
      final profilesResponse = await _supabaseService.client
          .from('profiles')
          .select('id, full_name, avatar_url')
          .inFilter('id', recentUserIds);

      final profilesMap = {
        for (var p in profilesResponse as List) p['id']: p
      };

      _recentApplications = allApplications.take(5).map((a) {
        final profile = profilesMap[a['user_id']] as Map<String, dynamic>?;
        return {
          'name': profile?['full_name'] ?? 'Ứng viên',
          'avatar': profile?['avatar_url'],
          'status': a['status'],
          'created_at': a['applied_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error loading profiles: $e');
      _recentApplications = allApplications.take(5).map((a) {
        return {
          'name': 'Ứng viên',
          'avatar': null,
          'status': a['status'],
          'created_at': a['applied_at'],
        };
      }).toList();
    }
  }

  /// Loads the interview count for this employer.
  Future<void> _loadInterviewCount(String userId) async {
    try {
      final interviewsResponse = await _supabaseService.client
          .from('interview_schedules')
          .select('id')
          .eq('employer_id', userId);
      _totalInterviews = (interviewsResponse as List).length;
    } catch (e) {
      debugPrint('⚠️ Error loading interviews: $e');
      _totalInterviews = 0;
    }
  }
}
