import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/profile_model.dart';

class CandidateRepository {
  final SupabaseService _supabaseService = SupabaseService.instance;
  SupabaseClient get _client => _supabaseService.client;

  /// Lấy danh sách ID các ứng viên mà công ty đang theo dõi
  Future<List<String>> getFollowedCandidateIds(String employerId) async {
    try {
      final response = await _client
          .from('company_followers')
          .select('candidate_id')
          .eq('employer_id', employerId)
          .eq('followed_by', 'employer');

      return (response as List)
          .map((e) => e['candidate_id'] as String)
          .toList();
    } catch (e) {
      print('Error fetching followed candidate IDs: $e');
      return [];
    }
  }

  /// Theo dõi ứng viên
  Future<void> followCandidate(String employerId, String candidateId) async {
    try {
      await _client.from('company_followers').insert({
        'employer_id': employerId,
        'candidate_id': candidateId,
        'followed_by': 'employer',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error following candidate: $e');
      rethrow;
    }
  }

  /// Bỏ theo dõi ứng viên
  Future<void> unfollowCandidate(String employerId, String candidateId) async {
    try {
      await _client
          .from('company_followers')
          .delete()
          .eq('employer_id', employerId)
          .eq('candidate_id', candidateId)
          .eq('followed_by', 'employer');
    } catch (e) {
      print('Error unfollowing candidate: $e');
      rethrow;
    }
  }

  /// Lấy danh sách ứng viên mới nhất
  Future<List<Profile>> getRecentCandidates({int limit = 3}) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('role', 'candidate')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((e) => Profile.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching recent candidates: $e');
      return [];
    }
  }

  /// Lấy thông tin profile theo ID
  Future<Profile?> getProfileById(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      
      return Profile.fromJson(response);
    } catch (e) {
      print('Error fetching profile by ID: $e');
      return null;
    }
  }
}
