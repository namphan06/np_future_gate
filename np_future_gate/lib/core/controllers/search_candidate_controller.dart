import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/repositories/job_repository.dart';

/// Controller for SearchPageCandidate.
/// Handles search, filtering, pagination, and saved job management.
class SearchCandidateController extends ChangeNotifier {
  final JobRepository _jobRepo = JobRepository();

  // Filter state
  String? selectedCity;
  String? selectedExperience;
  String? selectedJobType;
  String? selectedWorkType;
  bool showFilters = false;

  // Saved/Applied state
  List<String> _savedJobIds = [];
  List<String> _appliedJobIds = [];

  // Pagination
  int currentPage = 1;
  final int itemsPerPage = 3;

  bool _isDisposed = false;

  // Getters
  List<String> get savedJobIds => _savedJobIds;
  List<String> get appliedJobIds => _appliedJobIds;
  Stream<List<JobModel>> get activeJobsStream => _jobRepo.activeJobsStream;

  /// Initialize controller.
  Future<void> init() async {
    await _loadSavedJobs();
  }

  Future<void> _loadSavedJobs() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final savedIds = await _jobRepo.getSavedJobIds(user.id);
      final appliedIds = await _jobRepo.getAppliedJobIds(user.id);
      if (!_isDisposed) {
        _savedJobIds = savedIds;
        _appliedJobIds = appliedIds;
        notifyListeners();
      }
    }
  }

  /// Toggle save/unsave a job with optimistic update.
  Future<void> toggleSaveJob(String jobId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Optimistic update
    if (_savedJobIds.contains(jobId)) {
      _savedJobIds.remove(jobId);
    } else {
      _savedJobIds.add(jobId);
    }
    notifyListeners();

    try {
      await _jobRepo.toggleSaveJob(user.id, jobId);
    } catch (e) {
      await _loadSavedJobs();
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
      if (selectedCity != null &&
          !meta.workingRegions.contains(selectedCity)) {
        return false;
      }

      // Filter by Experience
      if (selectedExperience != null &&
          meta.experienceRequired != selectedExperience) {
        return false;
      }

      // Filter by Job Type (Fields)
      if (selectedJobType != null && !meta.fields.contains(selectedJobType)) {
        return false;
      }

      // Filter by Work Type (Employment Types)
      if (selectedWorkType != null &&
          !meta.employmentTypes.contains(selectedWorkType)) {
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
    if (currentPage > totalPages && totalPages > 0) {
      currentPage = totalPages;
    }
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex =
        (startIndex + itemsPerPage).clamp(0, filteredJobs.length);
    return filteredJobs.sublist(startIndex, endIndex);
  }

  int getTotalPages(int totalItems) {
    return (totalItems / itemsPerPage).ceil();
  }

  /// Reset all filters.
  void resetFilters() {
    selectedCity = null;
    selectedExperience = null;
    selectedJobType = null;
    selectedWorkType = null;
    currentPage = 1;
    notifyListeners();
  }

  /// Toggle filter panel visibility.
  void toggleFilterPanel() {
    showFilters = !showFilters;
    notifyListeners();
  }

  bool isJobSaved(String jobId) => _savedJobIds.contains(jobId);
  bool isJobApplied(String jobId) => _appliedJobIds.contains(jobId);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
