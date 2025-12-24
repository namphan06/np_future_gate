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

  Future<List<JobModel>> getRecentEmployerJobs(String creatorId, {int limit = 3}) async {
    try {
      final response = await _supabase
          .from('jobs')
          .select()
          .eq('creator_id', creatorId)
          .gt('deadline', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((e) => JobModel.fromJson(e)).toList();
    } catch (e) {
      // Return empty list instead of throwing to avoid crashing UI
      print('Failed to fetch recent employer jobs: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecentApplications(String employerId, {int limit = 3}) async {
    try {
      // 1. Fetch jobs with applicants
      final jobsResponse = await _supabase
          .from('jobs')
          .select()
          .eq('creator_id', employerId);
      
      final jobs = jobsResponse as List<dynamic>;
      List<Map<String, dynamic>> allApps = [];

      // 2. Flatten applicants
      for (var job in jobs) {
        final Map<String, dynamic> jobMap = Map<String, dynamic>.from(job as Map);
        final applicants = job['applicants'] as List?;
        
        if (applicants != null) {
          for (var app in applicants) {
             final appMap = Map<String, dynamic>.from(app as Map);
             // Normalize fields
             appMap['job_id'] = job['id'];
             appMap['jobs'] = jobMap;
             appMap['application_status'] = appMap['status']; // Map status
             allApps.add(appMap);
          }
        }
      }

      // 3. Sort by applied_at desc
      allApps.sort((a, b) {
        final tA = DateTime.tryParse(a['applied_at']?.toString() ?? '') ?? DateTime(0);
        final tB = DateTime.tryParse(b['applied_at']?.toString() ?? '') ?? DateTime(0);
        return tB.compareTo(tA);
      });

      // 4. Limit
      if (limit > 0 && allApps.length > limit) {
        allApps = allApps.sublist(0, limit);
      }

      // 5. Fetch Profiles
      final userIds = allApps.map((a) => a['user_id'] as String).toSet().toList();
      if (userIds.isNotEmpty) {
        final profilesResponse = await _supabase
            .from('profiles')
            .select()
            .filter('id', 'in', userIds);
        
        final profileMap = { for (var p in (profilesResponse as List)) p['id']: p };
        
        for (var app in allApps) {
          app['profiles'] = profileMap[app['user_id']];
        }
      }

      return allApps;
    } catch (e) {
      print('Failed to fetch recent applications: $e');
      return [];
    }
  }

  Future<Map<String, int>> getEmployerStats(String employerId) async {
    try {
      // 1. Fetch jobs
      final jobsResponse = await _supabase
          .from('jobs')
          .select('applicants')
          .eq('creator_id', employerId);
      
      final jobs = jobsResponse as List;
      int jobsCount = jobs.length;
      int totalApplicantsCount = 0;
      int newApplicantsCount = 0;
      
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      for (var job in jobs) {
        final applicants = job['applicants'] as List?;
        if (applicants != null) {
          totalApplicantsCount += applicants.length;
          
          for (var app in applicants) {
            final appliedAtStr = app['applied_at'] as String?;
            if (appliedAtStr != null) {
              final appliedAt = DateTime.tryParse(appliedAtStr);
              if (appliedAt != null && appliedAt.isAfter(thirtyDaysAgo)) {
                newApplicantsCount++;
              }
            }
          }
        }
      }

      return {
        'jobsCount': jobsCount,
        'newApplicantsCount': newApplicantsCount,
        'totalApplicantsCount': totalApplicantsCount,
      };
    } catch (e) {
      print('Failed to fetch stats: $e');
      return {
        'jobsCount': 0,
        'newApplicantsCount': 0,
        'totalApplicantsCount': 0,
      };
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

  // --- Partnership Jobs ---
  
  Future<List<JobModel>> getEmployerPartnershipJobs(String companyId) async {
    try {
      final response = await _supabase
          .from('school_partnership_jobs')
          .select()
          .eq('company_id', companyId)
          .eq('company_status', 'accepted')
          .eq('admin_status', 'approved')
          .order('created_at', ascending: false);

      // Map school_partnership_jobs to JobModel format
      // school_partnership_jobs uses company_id, but JobModel expects creator_id
      // school_partnership_jobs uses admin_status, but JobModel expects status
      return (response as List).map((e) {
        final jobData = Map<String, dynamic>.from(e);
        // Map company_id to creator_id for JobModel compatibility
        jobData['creator_id'] = e['company_id'];
        // Map admin_status to status for JobModel compatibility
        jobData['status'] = e['admin_status'] ?? 'pending';
        return JobModel.fromJson(jobData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch employer partnership jobs: $e');
    }
  }

  Future<void> applyForPartnershipJob(String jobId, String userId, String cvId) async {
    try {
      await _supabase.rpc('apply_to_partnership_job', params: {
        'p_job_id': jobId,
        'p_user_id': userId,
        'p_cv_id': cvId,
      });
    } catch (e) {
      throw Exception('Failed to apply for partnership job: $e');
    }
  }

  Future<bool> hasAppliedToPartnershipJob(String userId, String jobId) async {
    try {
      final response = await _supabase
          .from('school_partnership_jobs')
          .select('applicants')
          .eq('id', jobId)
          .maybeSingle();

      if (response == null) return false;

      final applicants = response['applicants'] as List?;
      if (applicants == null) return false;

      return applicants.any((app) => app['user_id'] == userId);
    } catch (e) {
      return false;
    }
  }

  /// Update application status for partnership jobs
  Future<void> updatePartnershipApplicationStatus(
      String jobId, String userId, String newStatus) async {
    try {
      // 1. Fetch current partnership job to get applicants list
      final response = await _supabase
          .from('school_partnership_jobs')
          .select('applicants')
          .eq('id', jobId)
          .single();
      
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
        await _supabase.from('school_partnership_jobs').update({
          'applicants': applicants.map((e) => e.toJson()).toList(),
        }).eq('id', jobId);
      } else {
        throw Exception('Application not found');
      }
    } catch (e) {
      throw Exception('Failed to update partnership application status: $e');
    }
  }

  /// Delete application from partnership jobs
  Future<void> deletePartnershipApplication(String jobId, String userId) async {
    try {
      // 1. Fetch current partnership job to get applicants list
      final response = await _supabase
          .from('school_partnership_jobs')
          .select('applicants')
          .eq('id', jobId)
          .single();
      
      final List<dynamic> currentApplicantsJson = response['applicants'] ?? [];
      final List<JobApplication> applicants =
          currentApplicantsJson.map((e) => JobApplication.fromJson(e)).toList();

      // 2. Remove the application
      applicants.removeWhere((app) => app.userId == userId);

      // 3. Save back to DB
      await _supabase.from('school_partnership_jobs').update({
        'applicants': applicants.map((e) => e.toJson()).toList(),
      }).eq('id', jobId);
    } catch (e) {
      throw Exception('Failed to delete partnership application: $e');
    }
  }

  /// Get partnership job by ID
  Future<JobModel?> getPartnershipJobById(String jobId) async {
    try {
      final response = await _supabase
          .from('school_partnership_jobs')
          .select()
          .eq('id', jobId)
          .maybeSingle();

      if (response == null) return null;
      
      // Map fields for JobModel compatibility
      final jobData = Map<String, dynamic>.from(response);
      jobData['creator_id'] = response['company_id'];
      jobData['status'] = response['admin_status'] ?? 'pending';
      
      return JobModel.fromJson(jobData);
    } catch (e) {
      throw Exception('Failed to fetch partnership job: $e');
    }
  }

  // --- Admin Features ---

  /// Get all pending jobs for admin approval
  Future<List<JobModel>> getPendingJobs() async {
    try {
      // 1. Fetch pending jobs
      final jobsResponse = await _supabase
          .from('jobs')
          .select()
          .eq('status', 'pending')
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
          .select('id, full_name, avatar_url, metadata, email, phone')
          .filter('id', 'in', creatorIds);
      
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
          jobWithProfile['profiles'] = profile;
        }
        
        return JobModel.fromJson(jobWithProfile);
      }).toList();

    } catch (e) {
      throw Exception('Failed to fetch pending jobs: $e');
    }
  }

  /// Approve a job (Admin only)
  Future<void> approveJob(String jobId) async {
    try {
      await _supabase
          .from('jobs')
          .update({'status': 'approved'})
          .eq('id', jobId);
    } catch (e) {
      throw Exception('Failed to approve job: $e');
    }
  }

  /// Reject a job (Admin only)
  Future<void> rejectJob(String jobId) async {
    try {
      await _supabase
          .from('jobs')
          .update({'status': 'rejected'})
          .eq('id', jobId);
    } catch (e) {
      throw Exception('Failed to reject job: $e');
    }
  }

  /// Get all pending partnership jobs for admin approval
  Future<List<Map<String, dynamic>>> getPendingPartnershipJobs() async {
    try {
      // Fetch pending partnership jobs
      final response = await _supabase
          .from('school_partnership_jobs')
          .select()
          .eq('admin_status', 'pending')
          .order('created_at', ascending: false);

      final jobsList = response as List<dynamic>;
      if (jobsList.isEmpty) return [];

      // Extract school and company IDs
      final schoolIds = jobsList
          .map((job) => job['school_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();
      
      final companyIds = jobsList
          .map((job) => job['company_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      // Fetch profiles for schools and companies
      Map<String, dynamic> profilesMap = {};
      
      final allIds = {...schoolIds, ...companyIds}.toList();
      if (allIds.isNotEmpty) {
        final profilesResponse = await _supabase
            .from('profiles')
            .select('id, full_name, avatar_url, metadata, email, phone, role')
            .filter('id', 'in', allIds);
        
        final profilesList = profilesResponse as List<dynamic>;
        profilesMap = {
          for (var profile in profilesList) 
            profile['id'] as String: profile
        };
      }

      // Merge data
      return jobsList.map((jobData) {
        final job = Map<String, dynamic>.from(jobData);
        
        final schoolId = job['school_id'];
        final companyId = job['company_id'];
        
        if (schoolId != null) {
          job['school_profile'] = profilesMap[schoolId];
        }
        if (companyId != null) {
          job['company_profile'] = profilesMap[companyId];
        }
        
        return job;
      }).toList();

    } catch (e) {
      throw Exception('Failed to fetch pending partnership jobs: $e');
    }
  }

  /// Approve a partnership job (Admin only)
  Future<void> approvePartnershipJob(String jobId) async {
    try {
      await _supabase
          .from('school_partnership_jobs')
          .update({'admin_status': 'approved'})
          .eq('id', jobId);
    } catch (e) {
      throw Exception('Failed to approve partnership job: $e');
    }
  }

  /// Reject a partnership job (Admin only)
  Future<void> rejectPartnershipJob(String jobId) async {
    try {
      await _supabase
          .from('school_partnership_jobs')
          .update({'admin_status': 'rejected'})
          .eq('id', jobId);
    } catch (e) {
      throw Exception('Failed to reject partnership job: $e');
    }
  }
}
