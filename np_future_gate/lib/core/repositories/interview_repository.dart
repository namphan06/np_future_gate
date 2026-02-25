import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/interview_model.dart';
import '../services/supabase_service.dart';
import '../services/notification/interview_reminder_service.dart';

class InterviewRepository {
  final SupabaseService _supabaseService = SupabaseService.instance;
  SupabaseClient get _client => _supabaseService.client;
  final InterviewReminderService _reminderService = InterviewReminderService();

  Future<void> createInterview({
    required String candidateId,
    required String jobId,
    required String employerId,
    String? cvId,
    required DateTime interviewTime,
    required String jobTitle,
    bool isPartnershipJob = false, // Keep for future use but not needed now
  }) async {
    try {
      // Simply insert job_id - it can reference either jobs or school_partnership_jobs
      // Foreign key constraint is relaxed to allow this
      // Access control is handled by RLS policies
      final response = await _client.from('interview_schedules').insert({
        'candidate_id': candidateId,
        'job_id': jobId,
        'employer_id': employerId,
        'cv_id': cvId,
        'interview_time': interviewTime.toUtc().toIso8601String(),
        'job_title': jobTitle,
        'status': 'scheduled',
        'evaluation': {},
      }).select().single();

      // Schedule reminders for both employer and candidate
      try {
        final interviewId = response['id'] as String;
        
        // Get candidate name
        final candidateProfile = await _client
            .from('profiles')
            .select('full_name')
            .eq('id', candidateId)
            .maybeSingle();
        
        final candidateName = candidateProfile?['full_name'] ?? 'Ứng viên';

        final interview = InterviewModel(
          id: interviewId,
          candidateId: candidateId,
          jobId: jobId,
          employerId: employerId,
          cvId: cvId,
          interviewTime: interviewTime,
          jobTitle: jobTitle,
          evaluation: {},
          status: 'scheduled',
          createdAt: DateTime.now(),
          isPartnership: isPartnershipJob,
          share: false,
        );

        // Schedule for employer
        await _reminderService.scheduleInterviewReminders(
          interview: interview,
          candidateName: candidateName,
          isForEmployer: true,
        );

        // Schedule for candidate
        await _reminderService.scheduleInterviewReminders(
          interview: interview,
          candidateName: candidateName,
          isForEmployer: false,
        );
        
        print('✅ Scheduled reminders for interview $interviewId');
      } catch (e) {
        print('⚠️ Error scheduling reminders: $e');
        // Don't throw - interview was created successfully
      }
    } catch (e) {
      print('Error creating interview: $e');
      rethrow;
    }
  }

  Future<List<InterviewModel>> getInterviewsByEmployer(String employerId) async {
    try {
      final response = await _client
          .from('interview_schedules')
          .select()
          .eq('employer_id', employerId)
          .order('interview_time', ascending: true);

      // Fetch all job IDs from interviews
      final jobIds = (response as List)
          .map((e) => e['job_id'] as String)
          .toSet()
          .toList();

      // Get partnership job IDs
      final partnershipJobIds = <String>{};
      if (jobIds.isNotEmpty) {
        try {
          final partnershipJobs = await _client
              .from('school_partnership_jobs')
              .select('id')
              .inFilter('id', jobIds);
          
          for (var job in partnershipJobs as List) {
            partnershipJobIds.add(job['id'] as String);
          }
        } catch (e) {
          print('Error fetching partnership job IDs: $e');
          // Continue anyway
        }
      }

      // Map interviews and add isPartnership flag
      return (response as List).map((e) {
        final jobId = e['job_id'] as String;
        final isPartnership = partnershipJobIds.contains(jobId);
        final interviewData = Map<String, dynamic>.from(e as Map);
        interviewData['is_partnership'] = isPartnership;
        return InterviewModel.fromJson(interviewData);
      }).toList();
    } catch (e) {
      print('Error fetching interviews: $e');
      return [];
    }
  }

  Future<List<InterviewModel>> getInterviewsByCandidate(String candidateId) async {
    try {
      final response = await _client
          .from('interview_schedules')
          .select()
          .eq('candidate_id', candidateId)
          .order('interview_time', ascending: true);

      // Fetch all job IDs from interviews
      final jobIds = (response as List)
          .map((e) => e['job_id'] as String)
          .toSet()
          .toList();

      // Get partnership job IDs
      final partnershipJobIds = <String>{};
      if (jobIds.isNotEmpty) {
        try {
          final partnershipJobs = await _client
              .from('school_partnership_jobs')
              .select('id')
              .inFilter('id', jobIds);
          
          for (var job in partnershipJobs as List) {
            partnershipJobIds.add(job['id'] as String);
          }
        } catch (e) {
          print('Error fetching partnership job IDs: $e');
        }
      }

      // Map interviews and add isPartnership flag
      return (response as List).map((e) {
        final jobId = e['job_id'] as String;
        final isPartnership = partnershipJobIds.contains(jobId);
        final interviewData = Map<String, dynamic>.from(e as Map);
        interviewData['is_partnership'] = isPartnership;
        return InterviewModel.fromJson(interviewData);
      }).toList();
    } catch (e) {
      print('Error fetching candidate interviews: $e');
      return [];
    }
  }

  Future<void> updateEvaluation(String id, Map<String, dynamic> evaluation) async {
    try {
      await _client.from('interview_schedules').update({
        'evaluation': evaluation,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      print('Error updating evaluation: $e');
      rethrow;
    }
  }

  Future<void> updateShare(String id, bool share) async {
    try {
      await _client.from('interview_schedules').update({
        'share': share,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      print('Error updating share status: $e');
      rethrow;
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      await _client.from('interview_schedules').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);

      // Cancel reminders if status changed to completed/cancelled
      if (status == 'completed' || status == 'cancelled') {
        try {
          await _reminderService.cancelInterviewReminders(id, true);  // employer
          await _reminderService.cancelInterviewReminders(id, false); // candidate
          print('✅ Cancelled reminders for interview $id');
        } catch (e) {
          print('⚠️ Error cancelling reminders: $e');
        }
      }
    } catch (e) {
      print('Error updating status: $e');
      rethrow;
    }
  }

  Future<void> deleteInterview(String id) async {
    try {
      // Cancel reminders before deleting
      try {
        await _reminderService.cancelInterviewReminders(id, true);  // employer
        await _reminderService.cancelInterviewReminders(id, false); // candidate
        print('✅ Cancelled reminders for deleted interview $id');
      } catch (e) {
        print('⚠️ Error cancelling reminders: $e');
      }

      await _client.from('interview_schedules').delete().eq('id', id);
    } catch (e) {
      print('Error deleting interview: $e');
      rethrow;
    }
  }

  Future<void> rescheduleInterview(String id, DateTime newTime) async {
    try {
      await _client.from('interview_schedules').update({
        'interview_time': newTime.toUtc().toIso8601String(),
        'status': 'scheduled',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);

      // Reschedule reminders with new time
      try {
        final interviewData = await _client
            .from('interview_schedules')
            .select('''
              *,
              profiles!interview_schedules_candidate_id_fkey(full_name)
            ''')
            .eq('id', id)
            .single();

        final interview = InterviewModel.fromJson(interviewData);
        final candidateName = interviewData['profiles']['full_name'] ?? 'Ứng viên';

        // Reschedule for employer
        await _reminderService.rescheduleInterviewReminders(
          interview: interview,
          candidateName: candidateName,
          isForEmployer: true,
        );

        // Reschedule for candidate
        await _reminderService.rescheduleInterviewReminders(
          interview: interview,
          candidateName: candidateName,
          isForEmployer: false,
        );
        
        print('✅ Rescheduled reminders for interview $id');
      } catch (e) {
        print('⚠️ Error rescheduling reminders: $e');
      }
    } catch (e) {
      print('Error rescheduling interview: $e');
      rethrow;
    }
  }

  /// Check if there's a conflicting interview at the same time
  Future<InterviewModel?> checkInterviewConflict(String employerId, DateTime interviewTime) async {
    try {
      // Check for interviews within a 1-hour window of the proposed time
      final startWindow = interviewTime.subtract(const Duration(minutes: 30));
      final endWindow = interviewTime.add(const Duration(minutes: 30));
      
      final response = await _client
          .from('interview_schedules')
          .select()
          .eq('employer_id', employerId)
          .gte('interview_time', startWindow.toUtc().toIso8601String())
          .lte('interview_time', endWindow.toUtc().toIso8601String())
          .neq('status', 'cancelled') // Ignore cancelled interviews
          .maybeSingle();

      if (response != null) {
        return InterviewModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error checking interview conflict: $e');
      return null;
    }
  }

  /// Get evaluation for a candidate in a specific job
  /// Returns null if no interview found or evaluation not shared
  Future<Map<String, dynamic>?> getEvaluationForCandidate({
    required String candidateId,
    required String jobId,
  }) async {
    try {
      final response = await _client
          .from('interview_schedules')
          .select()
          .eq('candidate_id', candidateId)
          .eq('job_id', jobId)
          .order('interview_time', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      final evaluation = response['evaluation'] as Map<String, dynamic>? ?? {};
      final share = response['share'] as bool? ?? false; // Read from share column
      
      // Return complete interview data including evaluation and share status
      return {
        'evaluation': evaluation,
        'interview_time': response['interview_time'],
        'is_shared': share, // Use share column value
      };
    } catch (e) {
      print('Error getting evaluation: $e');
      return null;
    }
  }
}
