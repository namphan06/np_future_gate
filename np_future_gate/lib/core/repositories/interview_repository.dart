import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/interview_model.dart';
import '../services/supabase_service.dart';

class InterviewRepository {
  final SupabaseService _supabaseService = SupabaseService.instance;
  SupabaseClient get _client => _supabaseService.client;

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
      await _client.from('interview_schedules').insert({
        'candidate_id': candidateId,
        'job_id': jobId,
        'employer_id': employerId,
        'cv_id': cvId,
        'interview_time': interviewTime.toUtc().toIso8601String(),
        'job_title': jobTitle,
        'status': 'scheduled',
        'evaluation': {},
      });
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

      return (response as List).map((e) => InterviewModel.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching interviews: $e');
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

  Future<void> updateStatus(String id, String status) async {
    try {
      await _client.from('interview_schedules').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      print('Error updating status: $e');
      rethrow;
    }
  }

  Future<void> deleteInterview(String id) async {
    try {
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
}
