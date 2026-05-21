import 'package:flutter/foundation.dart';
import 'package:np_future_gate/core/models/profile_model.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyRepository {
  final SupabaseService _supabaseService = SupabaseService.instance;
  SupabaseClient get _client => _supabaseService.client;

  /// Lấy danh sách tất cả các công ty (Employer)
  Future<List<Profile>> getAllCompanies() async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('role', 'employer');

      return (response as List).map((e) => Profile.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching companies: $e');
      return [];
    }
  }

  /// Lấy danh sách ID các công ty mà user đang theo dõi (flexible cho cả candidate và school)
  Future<List<String>> getFollowedCompanyIds(String userId, {String userRole = 'candidate'}) async {
    try {
      final response = await _client
          .from('company_followers')
          .select('employer_id')
          .eq('candidate_id', userId)
          .eq('followed_by', userRole);

      return (response as List)
          .map((e) => e['employer_id'] as String)
          .toList();
    } catch (e) {
      debugPrint('Error fetching followed company IDs: $e');
      return [];
    }
  }

  /// Theo dõi công ty (flexible cho cả candidate và school)
  Future<void> followCompany(String userId, String employerId, {String userRole = 'candidate'}) async {
    try {
      await _client.from('company_followers').insert({
        'candidate_id': userId,
        'employer_id': employerId,
        'followed_by': userRole,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error following company: $e');
      rethrow;
    }
  }

  /// Bỏ theo dõi công ty (flexible cho cả candidate và school)
  Future<void> unfollowCompany(String userId, String employerId, {String userRole = 'candidate'}) async {
    try {
      await _client
          .from('company_followers')
          .delete()
          .eq('candidate_id', userId)
          .eq('employer_id', employerId)
          .eq('followed_by', userRole);
    } catch (e) {
      debugPrint('Error unfollowing company: $e');
      rethrow;
    }
  }

  /// Stream danh sách tất cả các công ty (Realtime)
  Stream<List<Profile>> get companiesStream {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('role', 'employer')
        .map((event) => event.map((e) => Profile.fromJson(e)).toList());
  }
}
