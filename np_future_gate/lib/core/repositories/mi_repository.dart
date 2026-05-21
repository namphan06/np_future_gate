import 'package:flutter/foundation.dart';
import 'package:np_future_gate/core/models/mi_model.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MIRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  Future<List<MIQuestion>> getActiveQuestions() async {
    try {
      final response = await _client
          .from('mi_questions')
          .select()
          .eq('is_active', true)
          .order('order', ascending: true);

      return (response as List).map((e) => MIQuestion.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching MI questions: $e');
      return [];
    }
  }
}
