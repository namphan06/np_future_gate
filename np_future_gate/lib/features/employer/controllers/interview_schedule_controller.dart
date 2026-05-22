import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:np_future_gate/core/controllers/base_controller.dart';
import 'package:np_future_gate/core/models/interview_model.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/models/profile_model.dart';
import 'package:np_future_gate/core/repositories/auth_repository.dart';
import 'package:np_future_gate/core/repositories/interview_repository.dart';
import 'package:np_future_gate/core/repositories/job_repository.dart';

/// Controller for InterviewScheduleScreen.
///
/// Handles all business logic for interview scheduling:
/// - Loading interviews, candidate profiles, and jobs from Supabase
/// - Filtering by search query, date range, and status
/// - Grouping interviews by date and by job title
class InterviewScheduleController extends BaseController {
  final InterviewRepository _interviewRepository = InterviewRepository();
  final AuthRepository _authRepository = AuthRepository();
  final JobRepository _jobRepository = JobRepository();

  List<InterviewModel> _allInterviews = [];
  Map<String, Profile> _candidateProfiles = {};
  final Map<String, JobModel> _jobs = {};

  // Filter state
  String _searchQuery = '';
  String _statusFilter = 'All';
  DateTimeRange? _dateRange;

  /// All loaded interviews (unfiltered).
  List<InterviewModel> get interviews => _allInterviews;

  /// Candidate profiles keyed by user ID.
  Map<String, Profile> get candidateProfiles => _candidateProfiles;

  /// Jobs keyed by job ID.
  Map<String, JobModel> get jobs => Map.unmodifiable(_jobs);

  /// The current search query.
  String get searchQuery => _searchQuery;

  /// The current status filter ('All', 'Scheduled', 'Completed', 'Postponed').
  String get statusFilter => _statusFilter;

  /// The current date range filter, or null if no date filter is active.
  DateTimeRange? get dateRange => _dateRange;

  /// Filtered and sorted interviews based on all active filters.
  ///
  /// Applies search query, date range, and status filters.
  /// Results are sorted with upcoming interviews first, then past interviews.
  List<InterviewModel> get filteredInterviews {
    final filtered = _allInterviews.where((interview) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final candidate = _candidateProfiles[interview.candidateId];
        final candidateName = candidate?.fullName?.toLowerCase() ?? '';
        final jobTitle = interview.jobTitle.toLowerCase();

        // Check tags and fields from job metadata
        final job = _jobs[interview.jobId];
        final tags = job?.metadata.requirementsTags
                .map((e) => e.toLowerCase())
                .toList() ??
            [];
        final fields =
            job?.metadata.fields.map((e) => e.toLowerCase()).toList() ?? [];

        final bool matchTags = tags.any((t) => t.contains(query));
        final bool matchFields = fields.any((f) => f.contains(query));

        if (!candidateName.contains(query) &&
            !jobTitle.contains(query) &&
            !matchTags &&
            !matchFields) {
          return false;
        }
      }

      // Date range filter
      if (_dateRange != null) {
        final date = interview.interviewTime;
        if (date.isBefore(_dateRange!.start) ||
            date.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      // Status filter
      if (_statusFilter != 'All') {
        if (interview.status.toLowerCase() != _statusFilter.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort: upcoming first, past interviews at bottom
    final now = DateTime.now();
    final upcoming =
        filtered.where((i) => i.interviewTime.isAfter(now)).toList();
    final past = filtered.where((i) => !i.interviewTime.isAfter(now)).toList();

    upcoming.sort((a, b) => a.interviewTime.compareTo(b.interviewTime));
    past.sort(
        (a, b) => b.interviewTime.compareTo(a.interviewTime)); // Latest first

    return [...upcoming, ...past];
  }

  /// Interviews grouped by date key (yyyy-MM-dd), with each date containing
  /// a map of job titles to their interview lists.
  ///
  /// This matches the original screen's grouping structure for the UI.
  Map<String, Map<String, List<InterviewModel>>> get groupedByDate {
    final interviews = filteredInterviews;
    final Map<String, Map<String, List<InterviewModel>>> grouped = {};

    for (var interview in interviews) {
      final dateKey =
          DateFormat('yyyy-MM-dd').format(interview.interviewTime);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = {};
      }

      final jobKey = interview.jobTitle;
      if (!grouped[dateKey]!.containsKey(jobKey)) {
        grouped[dateKey]![jobKey] = [];
      }

      grouped[dateKey]![jobKey]!.add(interview);
    }

    return grouped;
  }

  /// Date keys from [groupedByDate] sorted with upcoming dates first,
  /// then past dates (most recent first).
  ///
  /// This provides a ready-to-use ordering for the View's list display.
  List<String> get sortedDateKeys {
    final grouped = groupedByDate;
    final now = DateTime.now();
    final sortedDates = grouped.keys.toList();

    sortedDates.sort((a, b) {
      final dateA = DateTime.parse(a);
      final dateB = DateTime.parse(b);
      final isAFuture = dateA.isAfter(now);
      final isBFuture = dateB.isAfter(now);

      if (isAFuture && !isBFuture) return -1;
      if (!isAFuture && isBFuture) return 1;

      if (isAFuture) {
        return dateA.compareTo(dateB);
      } else {
        return dateB.compareTo(dateA);
      }
    });

    return sortedDates;
  }

  /// Interviews grouped by job title.
  ///
  /// Each key is a job title, and the value is the list of interviews
  /// for that job.
  Map<String, List<InterviewModel>> get groupedByJob {
    final interviews = filteredInterviews;
    final Map<String, List<InterviewModel>> grouped = {};

    for (var interview in interviews) {
      final jobKey = interview.jobTitle;
      if (!grouped.containsKey(jobKey)) {
        grouped[jobKey] = [];
      }
      grouped[jobKey]!.add(interview);
    }

    return grouped;
  }

  /// Sets the search query and notifies listeners.
  void setSearchQuery(String query) {
    _searchQuery = query;
    safeNotifyListeners();
  }

  /// Sets the status filter and notifies listeners.
  ///
  /// [status] should be one of 'All', 'Scheduled', 'Completed', 'Postponed'.
  void setStatusFilter(String status) {
    _statusFilter = status;
    safeNotifyListeners();
  }

  /// Sets the date range filter and notifies listeners.
  ///
  /// Pass null to clear the date range filter.
  void setDateRange(DateTimeRange? range) {
    _dateRange = range;
    safeNotifyListeners();
  }

  /// Loads all interview data from Supabase.
  ///
  /// Fetches interviews for the current employer, then loads associated
  /// candidate profiles and job details.
  Future<void> loadInterviews() async {
    isLoading = true;
    setError(null);

    final userId = _authRepository.currentUser?.id;
    if (userId == null) {
      setError('User not authenticated');
      isLoading = false;
      return;
    }

    try {
      // 1. Get Interviews
      final interviews =
          await _interviewRepository.getInterviewsByEmployer(userId);
      _allInterviews = interviews;

      // 2. Get Candidate Profiles
      final candidateIds =
          interviews.map((e) => e.candidateId).toSet().toList();
      if (candidateIds.isNotEmpty) {
        final profiles =
            await _authRepository.getProfilesByIds(candidateIds);
        _candidateProfiles = {for (var p in profiles) p.id: p};
      }

      // 3. Get Jobs (both regular and partnership jobs)
      final jobIds = interviews.map((e) => e.jobId).toSet().toList();
      if (jobIds.isNotEmpty) {
        // Load regular jobs
        for (var id in jobIds) {
          final job = await _jobRepository.getJobById(id);
          if (job != null) {
            _jobs[id] = job;
          }
        }

        // Load partnership jobs that weren't found in regular jobs
        final missingJobIds =
            jobIds.where((id) => !_jobs.containsKey(id)).toList();
        if (missingJobIds.isNotEmpty) {
          final partnershipJobs =
              await _jobRepository.getEmployerPartnershipJobs(userId);
          for (var job in partnershipJobs) {
            if (job.id != null && missingJobIds.contains(job.id)) {
              _jobs[job.id!] = job;
            }
          }
        }
      }

      debugPrint('📅 Loaded ${interviews.length} interviews');
    } catch (e) {
      debugPrint('❌ Error loading interviews: $e');
      setError(e.toString());
    } finally {
      isLoading = false;
    }
  }
}
