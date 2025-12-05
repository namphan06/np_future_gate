import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job_model.dart';

class JobRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- Employer Features ---

  Future<void> createJob(JobModel job) async {
    try {
      await _supabase.from('jobs').insert(job.toJson());
    } catch (e) {
      throw Exception('Failed to create job: $e');
    }
  }

  Future<void> updateJob(JobModel job) async {
    if (job.id == null) throw Exception('Job ID is required for update');
    try {
      await _supabase.from('jobs').update(job.toJson()).eq('id', job.id!);
    } catch (e) {
      throw Exception('Failed to update job: $e');
    }
  }

  Future<void> deleteJob(String jobId) async {
    try {
      await _supabase.from('jobs').delete().eq('id', jobId);
    } catch (e) {
      throw Exception('Failed to delete job: $e');
    }
  }

  Future<List<JobModel>> getEmployerJobs(String creatorId) async {
    try {
      final response = await _supabase
          .from('jobs')
          .select()
          .eq('creator_id', creatorId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => JobModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch employer jobs: $e');
    }
  }

  Future<void> updateApplicationStatus(
      String jobId, String userId, String newStatus) async {
    try {
      // 1. Fetch current job to get applicants list
      final response =
          await _supabase.from('jobs').select('applicants').eq('id', jobId).single();
      
      final List<dynamic> currentApplicantsJson = response['applicants'] ?? [];
      final List<JobApplication> applicants =
          currentApplicantsJson.map((e) => JobApplication.fromJson(e)).toList();

      // 2. Find and update the specific application
      final index = applicants.indexWhere((app) => app.userId == userId);
      if (index != -1) {
        final updatedApp = JobApplication(
          userId: applicants[index].userId,
          cvId: applicants[index].cvId,
          appliedAt: applicants[index].appliedAt,
          status: newStatus,
        );
        applicants[index] = updatedApp;

        // 3. Save back to DB
        await _supabase.from('jobs').update({
          'applicants': applicants.map((e) => e.toJson()).toList(),
        }).eq('id', jobId);
      } else {
        throw Exception('Application not found');
      }
    } catch (e) {
      throw Exception('Failed to update application status: $e');
    }
  }

  // --- Candidate Features ---

  Future<void> applyForJob(String jobId, String userId, String cvId) async {
    try {
      // Call the secure RPC function to update the 'applicants' column in the 'jobs' table.
      // This function adds the user_id, cv_id, applied_at, and status='pending' to the list.
      await _supabase.rpc('apply_to_job', params: {
        'p_job_id': jobId,
        'p_user_id': userId,
        'p_cv_id': cvId,
      });
    } catch (e) {
      throw Exception('Failed to apply for job: $e');
    }
  }
  
  Future<List<JobModel>> getActiveJobs() async {
    try {
      final response = await _supabase
          .from('jobs')
          .select()
          .eq('is_active', true)
          .eq('status', 'approved')
          .gt('deadline', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return (response as List).map((e) => JobModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch active jobs: $e');
    }
  }

  Future<void> toggleSaveJob(String userId, String jobId, bool isSaved) async {
    try {
      // Check if activity exists
      final existing = await _supabase
          .from('user_job_activities')
          .select()
          .eq('user_id', userId)
          .eq('job_id', jobId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('user_job_activities')
            .update({'is_saved': isSaved})
            .eq('id', existing['id']);
      } else {
        await _supabase.from('user_job_activities').insert({
          'user_id': userId,
          'job_id': jobId,
          'is_saved': isSaved,
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle save job: $e');
    }
  }

  Future<List<String>> getSavedJobIds(String userId) async {
    try {
      final response = await _supabase
          .from('user_job_activities')
          .select('job_id')
          .eq('user_id', userId)
          .eq('is_saved', true);
      
      return (response as List).map((e) => e['job_id'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAppliedJobs(String userId) async {
    try {
      // Fetch full CV data to allow viewing the CV later
      final response = await _supabase
          .from('user_job_activities')
          .select('*, jobs(*), cv_templates(*)')
          .eq('user_id', userId)
          .eq('is_applied', true)
          .order('applied_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching applied jobs: $e');
      return [];
    }
  }
}
