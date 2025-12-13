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

  Future<JobModel?> getJobById(String jobId) async {
    try {
      final response = await _supabase
          .from('jobs')
          .select()
          .eq('id', jobId)
          .maybeSingle();

      if (response == null) return null;
      return JobModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch job: $e');
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

  Future<void> deleteApplication(String jobId, String userId) async {
    try {
      // 1. Fetch current job to get applicants list
      final response =
          await _supabase.from('jobs').select('applicants').eq('id', jobId).single();
      
      final List<dynamic> currentApplicantsJson = response['applicants'] ?? [];
      final List<JobApplication> applicants =
          currentApplicantsJson.map((e) => JobApplication.fromJson(e)).toList();

      // 2. Remove the application
      applicants.removeWhere((app) => app.userId == userId);

      // 3. Save back to DB
      await _supabase.from('jobs').update({
        'applicants': applicants.map((e) => e.toJson()).toList(),
      }).eq('id', jobId);
    } catch (e) {
      throw Exception('Failed to delete application: $e');
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

  // --- Realtime Streams ---

  Stream<List<JobModel>> get activeJobsStream {
    return _supabase
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .asyncMap((jobsList) async {
          if (jobsList.isEmpty) return <JobModel>[];
          
          // Filter locally
          final now = DateTime.now();
          final validJobs = jobsList.where((job) {
            final status = job['status'] as String?;
            if (status != 'approved') return false;

            final deadlineStr = job['deadline'] as String?;
            if (deadlineStr == null) return true;
            final deadline = DateTime.parse(deadlineStr);
            return deadline.isAfter(now);
          }).toList();

          if (validJobs.isEmpty) return <JobModel>[];

          final creatorIds = validJobs
              .map((job) => job['creator_id'] as String)
              .toSet()
              .toList();

          if (creatorIds.isEmpty) {
             return validJobs.map((e) => JobModel.fromJson(e)).toList();
          }

          final profilesResponse = await _supabase
              .from('profiles')
              .select('id, full_name, avatar_url, metadata')
              .filter('id', 'in', creatorIds);
          
          final profilesList = profilesResponse as List<dynamic>;
          final profilesMap = {
            for (var profile in profilesList) 
              profile['id'] as String: profile
          };

          return validJobs.map((jobData) {
            final creatorId = jobData['creator_id'];
            final profile = profilesMap[creatorId];
            
            final Map<String, dynamic> jobWithProfile = Map.from(jobData);
            if (profile != null) {
              jobWithProfile['profiles'] = profile;
            }
            return JobModel.fromJson(jobWithProfile);
          }).toList();
        });
  }

  Stream<List<JobModel>> getEmployerJobsStream(String creatorId) {
    return _supabase
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('creator_id', creatorId)
        .order('created_at', ascending: false)
        .map((event) => event.map((e) => JobModel.fromJson(e)).toList());
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

  Stream<List<Map<String, dynamic>>> getSavedJobsStream(String userId) {
    return _supabase
        .from('user_job_activities')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .asyncMap((activities) async {
          try {
            final savedActivities = activities.where((a) => a['is_saved'] == true).toList();
            if (savedActivities.isEmpty) return <Map<String, dynamic>>[];
            
            final jobIds = savedActivities.map((a) => a['job_id'] as String).toList();
            if (jobIds.isEmpty) return <Map<String, dynamic>>[];

            // Fetch jobs
            final jobsResponse = await _supabase
                .from('jobs')
                .select()
                .filter('id', 'in', jobIds);
                
            final jobsList = jobsResponse as List<dynamic>;
            if (jobsList.isEmpty) return <Map<String, dynamic>>[];

            // Fetch profiles for these jobs
            final creatorIds = jobsList.map((j) => j['creator_id'] as String).toSet().toList();
            Map<String, dynamic> profilesMap = {};
            
            if (creatorIds.isNotEmpty) {
               final profilesResponse = await _supabase
                   .from('profiles')
                   .select('id, full_name, avatar_url, metadata')
                   .filter('id', 'in', creatorIds);
               for (var p in (profilesResponse as List)) {
                 profilesMap[p['id']] = p;
               }
            }
            
            final jobsMap = { 
              for (var j in jobsList) 
              j['id']: <String, dynamic>{
                ...Map<String, dynamic>.from(j as Map),
                'profiles': profilesMap[j['creator_id']]
              }
            };
            
            return savedActivities.map((activity) {
               final jobId = activity['job_id'];
               final job = jobsMap[jobId];
               
               final Map<String, dynamic> result = Map.from(activity);
               if (job != null) result['jobs'] = job;
               
               return result;
            }).toList();
          } catch (e) {
            print('Error in getSavedJobsStream: $e');
            return <Map<String, dynamic>>[];
          }
        });
  }

  Stream<List<Map<String, dynamic>>> getAppliedJobsStream(String userId) {
    return _supabase
        .from('user_job_activities')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .asyncMap((activities) async {
          try {
            final appliedActivities = activities.where((a) => a['is_applied'] == true).toList();
            if (appliedActivities.isEmpty) return <Map<String, dynamic>>[];
            
            final jobIds = appliedActivities.map((a) => a['job_id'] as String).toList();
            final cvIds = appliedActivities.map((a) => a['cv_id'] as String?).where((e) => e != null).toList();
            
            if (jobIds.isEmpty) return <Map<String, dynamic>>[];

            // Fetch jobs
            final jobsResponse = await _supabase
                .from('jobs')
                .select()
                .filter('id', 'in', jobIds);
            
            final jobsList = jobsResponse as List<dynamic>;
            
            // Fetch profiles
            final creatorIds = jobsList.map((j) => j['creator_id'] as String).toSet().toList();
            Map<String, dynamic> profilesMap = {};
            if (creatorIds.isNotEmpty) {
               final profilesResponse = await _supabase
                   .from('profiles')
                   .select('id, full_name, avatar_url, metadata')
                   .filter('id', 'in', creatorIds);
               for (var p in (profilesResponse as List)) {
                 profilesMap[p['id']] = p;
               }
            }

            final jobsMap = { 
              for (var j in jobsList) 
              j['id']: <String, dynamic>{
                ...Map<String, dynamic>.from(j as Map),
                'profiles': profilesMap[j['creator_id']]
              }
            };
            
            Map<String, dynamic> cvsMap = {};
            if (cvIds.isNotEmpty) {
               final cvsResponse = await _supabase
                   .from('cv_templates')
                   .select()
                   .filter('id', 'in', cvIds);
               cvsMap = { for (var c in (cvsResponse as List)) c['id']: c };
            }

            return appliedActivities.map((activity) {
               final jobId = activity['job_id'];
               final cvId = activity['cv_id'];
               
               final job = jobsMap[jobId];
               final cv = cvsMap[cvId];
               
               final Map<String, dynamic> result = Map.from(activity);
               if (job != null) {
                 result['jobs'] = job;
                 
                 // Extract status from job applicants list
                 if (job['applicants'] != null) {
                   final applicants = job['applicants'] as List;
                   final myApplication = applicants.firstWhere(
                     (app) => app['user_id'] == userId,
                     orElse: () => null,
                   );
                   
                   if (myApplication != null && myApplication['status'] != null) {
                     result['status'] = myApplication['status'];
                     result['application_status'] = myApplication['status'];
                   }
                 }
               }
               if (cv != null) result['cv_templates'] = cv;
               
               return result;
            }).toList();
          } catch (e) {
            print('Error in getAppliedJobsStream: $e');
            return <Map<String, dynamic>>[];
          }
        });
  }
}
