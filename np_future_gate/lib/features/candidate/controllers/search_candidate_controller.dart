import 'package:np_future_gate/core/controllers/base_controller.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/repositories/job_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Controller for SearchPageCandidate.
/// Handles search, filtering, pagination, and saved job management.
class SearchCandidateController extends BaseController {
  final JobRepository _jobRepo = JobRepository();

  // Filter state (private with public getters/setters)
  String? _selectedCity;
  String? _selectedExperience;
  String? _selectedJobType;
  String? _selectedWorkType;
  bool _showFilters = false;

  // Saved/Applied state
  List<String> _savedJobIds = [];
  List<String> _appliedJobIds = [];

  // Pagination
  int _currentPage = 1;
  final int itemsPerPage = 3;

  // ============================================================
  // GETTERS
  // ============================================================

  String? get selectedCity => _selectedCity;
  String? get selectedExperience => _selectedExperience;
  String? get selectedJobType => _selectedJobType;
  String? get selectedWorkType => _selectedWorkType;
  bool get showFilters => _showFilters;

  List<String> get savedJobIds => _savedJobIds;
  List<String> get appliedJobIds => _appliedJobIds;

  int get currentPage => _currentPage;

  Stream<List<JobModel>> get activeJobsStream => _jobRepo.activeJobsStream;

  /// Whether any filter is currently active.
  bool get hasActiveFilters =>
      _selectedCity != null ||
      _selectedExperience != null ||
      _selectedJobType != null ||
      _selectedWorkType != null;

  // ============================================================
  // SETTERS (encapsulated with notifyListeners)
  // ============================================================

  /// Set the city filter and notify listeners.
  void setSelectedCity(String? city) {
    _selectedCity = city;
    _currentPage = 1;
    safeNotifyListeners();
  }

  /// Set the experience filter and notify listeners.
  void setSelectedExperience(String? experience) {
    _selectedExperience = experience;
    _currentPage = 1;
    safeNotifyListeners();
  }

  /// Set the job type filter and notify listeners.
  void setSelectedJobType(String? jobType) {
    _selectedJobType = jobType;
    _currentPage = 1;
    safeNotifyListeners();
  }

  /// Set the work type filter and notify listeners.
  void setSelectedWorkType(String? workType) {
    _selectedWorkType = workType;
    _currentPage = 1;
    safeNotifyListeners();
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  /// Initialize controller — loads saved/applied job IDs.
  Future<void> init() async {
    isLoading = true;
    try {
      await _loadSavedJobs();
      setError(null);
    } catch (e) {
      setError(e.toString());
    } finally {
      isLoading = false;
    }
  }

  Future<void> _loadSavedJobs() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final savedIds = await _jobRepo.getSavedJobIds(user.id);
      final appliedIds = await _jobRepo.getAppliedJobIds(user.id);
      _savedJobIds = savedIds;
      _appliedJobIds = appliedIds;
      safeNotifyListeners();
    }
  }

  /// Toggle save/unsave a job with optimistic update.
  Future<void> toggleSaveJob(String jobId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Optimistic update
    final wasSaved = _savedJobIds.contains(jobId);
    if (wasSaved) {
      _savedJobIds.remove(jobId);
    } else {
      _savedJobIds.add(jobId);
    }
    safeNotifyListeners();

    try {
      await _jobRepo.toggleSaveJob(user.id, jobId);
    } catch (e) {
      // Rollback on failure
      if (wasSaved) {
        _savedJobIds.add(jobId);
      } else {
        _savedJobIds.remove(jobId);
      }
      safeNotifyListeners();
      rethrow;
    }
  }

  /// Filter jobs based on current filter criteria.
  List<JobModel> filterJobs(
    List<JobModel> jobs, {
    required String searchQuery,
    required String minSalary,
    required String maxSalary,
  }) {
    return jobs.where((job) {
      final meta = job.metadata;

      // Search by Title OR Tags
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final titleMatch = meta.title.toLowerCase().contains(query);
        final tagMatch = meta.requirementsTags
            .any((tag) => tag.toLowerCase().contains(query));
        if (!titleMatch && !tagMatch) return false;
      }

      // Filter by City
      if (_selectedCity != null &&
          !meta.workingRegions.contains(_selectedCity)) {
        return false;
      }

      // Filter by Experience
      if (_selectedExperience != null &&
          meta.experienceRequired != _selectedExperience) {
        return false;
      }

      // Filter by Job Type (Fields)
      if (_selectedJobType != null && !meta.fields.contains(_selectedJobType)) {
        return false;
      }

      // Filter by Work Type (Employment Types)
      if (_selectedWorkType != null &&
          !meta.employmentTypes.contains(_selectedWorkType)) {
        return false;
      }

      // Salary Filter
      if (minSalary.isNotEmpty) {
        final minFilter = double.tryParse(minSalary);
        if (minFilter != null && (meta.salary.max ?? 0) < minFilter) {
          return false;
        }
      }

      if (maxSalary.isNotEmpty) {
        final maxFilter = double.tryParse(maxSalary);
        if (maxFilter != null && (meta.salary.min ?? 0) > maxFilter) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Get paginated subset of jobs.
  List<JobModel> getPaginatedJobs(List<JobModel> filteredJobs) {
    final totalPages = getTotalPages(filteredJobs.length);
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = totalPages;
    }
    final startIndex = (_currentPage - 1) * itemsPerPage;
    final endIndex =
        (startIndex + itemsPerPage).clamp(0, filteredJobs.length);
    return filteredJobs.sublist(startIndex, endIndex);
  }

  int getTotalPages(int totalItems) {
    return (totalItems / itemsPerPage).ceil();
  }

  // ============================================================
  // PAGINATION CONTROLS
  // ============================================================

  /// Go to the next page.
  void nextPage() {
    _currentPage++;
    safeNotifyListeners();
  }

  /// Go to the previous page.
  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      safeNotifyListeners();
    }
  }

  /// Go to a specific page.
  void goToPage(int page) {
    if (page >= 1) {
      _currentPage = page;
      safeNotifyListeners();
    }
  }

  // ============================================================
  // FILTER PANEL & RESET
  // ============================================================

  /// Toggle filter panel visibility.
  void toggleFilterPanel() {
    _showFilters = !_showFilters;
    safeNotifyListeners();
  }

  /// Reset all filters.
  void resetFilters() {
    _selectedCity = null;
    _selectedExperience = null;
    _selectedJobType = null;
    _selectedWorkType = null;
    _currentPage = 1;
    safeNotifyListeners();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool isJobSaved(String jobId) => _savedJobIds.contains(jobId);
  bool isJobApplied(String jobId) => _appliedJobIds.contains(jobId);
}
