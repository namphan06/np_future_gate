import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/profile_model.dart';

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
      print('Error fetching companies: $e');
      return [];
    }
  }

  /// Lấy danh sách ID các công ty mà candidate đang theo dõi
  Future<List<String>> getFollowedCompanyIds(String candidateId) async {
    try {
      final response = await _client
          .from('company_followers')
          .select('employer_id')
          .eq('candidate_id', candidateId);

      return (response as List)
          .map((e) => e['employer_id'] as String)
          .toList();
    } catch (e) {
      print('Error fetching followed company IDs: $e');
      return [];
    }
  }

  /// Theo dõi công ty
  Future<void> followCompany(String candidateId, String employerId) async {
    try {
      await _client.from('company_followers').insert({
        'candidate_id': candidateId,
        'employer_id': employerId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error following company: $e');
      throw e;
    }
  }

  /// Bỏ theo dõi công ty
  Future<void> unfollowCompany(String candidateId, String employerId) async {
    try {
      await _client
          .from('company_followers')
          .delete()
          .eq('candidate_id', candidateId)
          .eq('employer_id', employerId);
    } catch (e) {
      print('Error unfollowing company: $e');
      throw e;
    }
  }
}
