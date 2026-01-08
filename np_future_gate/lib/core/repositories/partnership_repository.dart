import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class PartnershipRepository {
  final SupabaseService _supabaseService = SupabaseService.instance;
  SupabaseClient get _client => _supabaseService.client;

  /// Check if a partnership entry exists between school and company
  Future<Map<String, dynamic>?> checkExistingPartnership({
    required String schoolId, 
    required String companyId
  }) async {
    try {
      final response = await _client
          .from('school_company_partnerships')
          .select()
          .eq('school_id', schoolId)
          .eq('company_id', companyId)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Error checking partnership: $e');
    }
  }

  /// Create a new partnership request
  Future<void> sendPartnershipRequest({
    required String schoolId,
    required String companyId,
  }) async {
    try {
      await _client.from('school_company_partnerships').insert({
        'school_id': schoolId,
        'company_id': companyId,
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Error sending partnership request: $e');
    }
  }
}
