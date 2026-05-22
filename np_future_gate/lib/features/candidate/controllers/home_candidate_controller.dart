import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/models/profile_model.dart';
import 'package:np_future_gate/core/repositories/auth_repository.dart';
import 'package:np_future_gate/core/repositories/job_repository.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';

/// Controller for HomePageCandidate.
/// Handles all business logic: loading profile, managing saved/applied jobs,
/// filtering jobs by time and user interests.
class HomeCandidateController extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final JobRepository _jobRepo = JobRepository();

  Profile? _profile;
  List<String> _savedJobIds = [];
  List<String> _appliedJobIds = [];
  bool _isDisposed = false;

  // Getters
  Profile? get profile => _profile;
  List<String> get savedJobIds => _savedJobIds;
  List<String> get appliedJobIds => _appliedJobIds;
  Stream<List<JobModel>> get activeJobsStream => _jobRepo.activeJobsStream;

  String? get avatarUrl =>
      _profile?.avatarUrl ??
      SupabaseService.instance.currentUser?.userMetadata?['avatar_url'];

  String get fullName =>
      _profile?.fullName ??
      SupabaseService.instance.currentUser?.userMetadata?['full_name'] ??
      'Người dùng';

  String? get phone =>
      _profile?.phone ??
      SupabaseService.instance.currentUser?.userMetadata?['phone'];

  String? get email => SupabaseService.instance.currentUser?.email;

  /// Initialize controller - load profile and saved jobs.
  Future<void> init() async {
    await Future.wait([
      _loadProfile(),
      _loadSavedJobs(),
    ]);
  }

  Future<void> _loadProfile() async {
    final profile = await _authRepo.getCurrentUserProfile();
    if (!_isDisposed) {
      _profile = profile;
      notifyListeners();
    }
  }

  Future<void> _loadSavedJobs() async {
    final user = SupabaseService.instance.currentUser;
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
    final user = SupabaseService.instance.currentUser;
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
      // Revert on error
      await _loadSavedJobs();
      rethrow;
    }
  }

  /// Filter jobs: created within 24h AND matches user profile fields.
  List<JobModel> filterTodayJobs(List<JobModel> allJobs) {
    final now = DateTime.now();
    return allJobs.where((job) {
      // 1. 24h Filter
      if (job.createdAt == null) return false;
      final diff = now.difference(job.createdAt!);
      if (diff.inHours > 24) return false;

      // 2. Profile Fields Filter
      if (_profile != null) {
        final userFields = _profile!.metadata['interested_fields'];
        if (userFields is List && userFields.isNotEmpty) {
          final jobFields = job.metadata.fields;
          final hasMatch = userFields.any(
            (uField) => jobFields.any(
              (jField) =>
                  jField.toString().toLowerCase() ==
                  uField.toString().toLowerCase(),
            ),
          );
          if (!hasMatch) return false;
        }
      }
      return true;
    }).toList();
  }

  bool isJobSaved(String jobId) => _savedJobIds.contains(jobId);
  bool isJobApplied(String jobId) => _appliedJobIds.contains(jobId);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
