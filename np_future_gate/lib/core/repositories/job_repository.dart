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
      // 1. Update user_job_activities
      final existing = await _supabase
          .from('user_job_activities')
          .select('id')
          .eq('user_id', userId)
          .eq('job_id', jobId)
          .maybeSingle();

      if (existing != null) {
        await _supabase.from('user_job_activities').update({
          'is_applied': true,
          'cv_id': cvId,
          'application_status': 'pending',
          'applied_at': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);
      } else {
        await _supabase.from('user_job_activities').insert({
          'user_id': userId,
          'job_id': jobId,
          'is_applied': true,
          'cv_id': cvId,
          'application_status': 'pending',
          'applied_at': DateTime.now().toIso8601String(),
        });
      }

      // 2. Call RPC to update jobs table (legacy support or for employer view if needed)
      // Note: Ideally we should migrate employer view to use user_job_activities too
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
      // 1. Fetch active jobs
      final jobsResponse = await _supabase
          .from('jobs')
          .select()
          .eq('is_active', true)
          .eq('status', 'approved')
          .gt('deadline', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      final jobsList = jobsResponse as List<dynamic>;
      if (jobsList.isEmpty) return [];

      // 2. Extract creator IDs
      final creatorIds = jobsList
          .map((job) => job['creator_id'] as String)
          .toSet()
          .toList();

      // 3. Fetch profiles for these creators
      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, full_name, avatar_url, metadata')
          .filter('id', 'in', '(${creatorIds.join(',')})');
      
      final profilesList = profilesResponse as List<dynamic>;
      
      // 4. Create a map of profiles for easy lookup
      final profilesMap = {
        for (var profile in profilesList) 
          profile['id'] as String: profile
      };

      // 5. Merge data and create JobModels
      return jobsList.map((jobData) {
        final creatorId = jobData['creator_id'];
        final profile = profilesMap[creatorId];
        
        // Create a mutable copy of jobData to inject profile
        final Map<String, dynamic> jobWithProfile = Map.from(jobData);
        
        if (profile != null) {
          // JobModel.fromJson expects 'profiles' key
          jobWithProfile['profiles'] = profile;
        }
        
        return JobModel.fromJson(jobWithProfile);
      }).toList();

    } catch (e) {
      throw Exception('Failed to fetch active jobs: $e');
    }
  }

  // --- Saved Jobs ---

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

  Future<void> toggleSaveJob(String userId, String jobId) async {
    try {
      // Check if activity exists
      final existing = await _supabase
          .from('user_job_activities')
          .select('id, is_saved')
          .eq('user_id', userId)
          .eq('job_id', jobId)
          .maybeSingle();

      if (existing != null) {
        // Update existing
        final currentStatus = existing['is_saved'] as bool;
        await _supabase
            .from('user_job_activities')
            .update({'is_saved': !currentStatus})
            .eq('id', existing['id']);
      } else {
        // Insert new
        await _supabase.from('user_job_activities').insert({
          'user_id': userId,
          'job_id': jobId,
          'is_saved': true,
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle save job: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAppliedJobs(String userId) async {
    try {
      final response = await _supabase
          .from('user_job_activities')
          .select('*, jobs(*), cv_templates(*)')
          .eq('user_id', userId)
          .eq('is_applied', true)
          .order('applied_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch applied jobs: $e');
    }
  }

  Future<List<JobModel>> getSavedJobs(String userId) async {
    try {
      final response = await _supabase
          .from('user_job_activities')
          .select('jobs(*)')
          .eq('user_id', userId)
          .eq('is_saved', true);
      
      final jobs = (response as List).map((item) {
        final jobData = item['jobs'];
        if (jobData != null) {
          return JobModel.fromJson(jobData);
        }
        return null;
      }).whereType<JobModel>().toList();

      return jobs;
    } catch (e) {
      throw Exception('Failed to fetch saved jobs: $e');
    }
  }

  Future<bool> hasApplied(String userId, String jobId) async {
    try {
      final response = await _supabase
          .from('user_job_activities')
          .select('is_applied')
          .eq('user_id', userId)
          .eq('job_id', jobId)
          .maybeSingle();

      if (response != null) {
        return response['is_applied'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSavedJobsWithStatus(String userId) async {
    try {
      final response = await _supabase
          .from('user_job_activities')
          .select('*, jobs(*, profiles(full_name, avatar_url))')
          .eq('user_id', userId)
          .eq('is_saved', true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Fallback without profiles join
      try {
        final response = await _supabase
            .from('user_job_activities')
            .select('*, jobs(*)')
            .eq('user_id', userId)
            .eq('is_saved', true);
        
        return List<Map<String, dynamic>>.from(response);
      } catch (e2) {
        throw Exception('Failed to fetch saved jobs with status: $e2');
      }
    }
  }

  Future<List<String>> getAppliedJobIds(String userId) async {
    try {
      final response = await _supabase
          .from('user_job_activities')
          .select('job_id')
          .eq('user_id', userId)
          .eq('is_applied', true);
      
      return (response as List).map((e) => e['job_id'] as String).toList();
    } catch (e) {
      return [];
    }
  }
}
