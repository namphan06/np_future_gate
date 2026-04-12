import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/mbti_model.dart';
import '../services/supabase_service.dart';

class MBTIRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  Future<List<MBTIQuestion>> getActiveQuestionsWithOptions() async {
    try {
      final questionsResponse = await _client
          .from('mbti_questions')
          .select()
          .eq('is_active', true)
          .order('order', ascending: true);

      final questions = (questionsResponse as List)
          .map((row) => MBTIQuestion.fromJson(row as Map<String, dynamic>))
          .toList();

      if (questions.isEmpty) {
        return [];
      }

      final questionIds = questions.map((question) => question.id).toList();
      final optionsResponse = await _client
          .from('mbti_question_options')
          .select()
          .inFilter('question_id', questionIds)
          .eq('is_active', true)
          .order('order', ascending: true);

      final options = (optionsResponse as List)
          .map(
            (row) => MBTIQuestionOption.fromJson(row as Map<String, dynamic>),
          )
          .toList();

      final optionsByQuestion = <String, List<MBTIQuestionOption>>{};
      for (final option in options) {
        optionsByQuestion.putIfAbsent(option.questionId, () => []).add(option);
      }

      return questions
          .map(
            (question) => question.copyWith(
              options: optionsByQuestion[question.id] ?? const [],
            ),
          )
          .toList();
    } catch (error) {
      debugPrint('Error fetching MBTI questions/options: $error');
      return [];
    }
  }

  Future<List<MBTIType>> getActiveTypes() async {
    try {
      final typesResponse = await _client
          .from('mbti_types')
          .select()
          .eq('is_active', true)
          .order('code', ascending: true);

      final types = (typesResponse as List)
          .map((row) => MBTIType.fromJson(row as Map<String, dynamic>))
          .toList();

      if (types.isEmpty) {
        return [];
      }

      final typeIds = types.map((type) => type.id).toList();
      final sectionsResponse = await _client
          .from('mbti_type_sections')
          .select()
          .inFilter('mbti_type_id', typeIds)
          .eq('is_active', true)
          .order('order', ascending: true);

      final sections = (sectionsResponse as List)
          .map((row) => MBTITypeSection.fromJson(row as Map<String, dynamic>))
          .toList();

      final sectionsByType = <String, List<MBTITypeSection>>{};
      for (final section in sections) {
        sectionsByType.putIfAbsent(section.mbtiTypeId, () => []).add(section);
      }

      return types
          .map(
            (type) =>
                type.copyWith(sections: sectionsByType[type.id] ?? const []),
          )
          .toList();
    } catch (error) {
      debugPrint('Error fetching MBTI types/sections: $error');
      return [];
    }
  }

  Future<MBTIType?> getTypeByCode(String code) async {
    final normalizedCode = code.toUpperCase();
    final types = await getActiveTypes();
    for (final type in types) {
      if (type.code.toUpperCase() == normalizedCode) {
        return type;
      }
    }
    return null;
  }

  Future<MBTIType?> getTypeDetailById(String typeId) async {
    try {
      final typeRow = await _client
          .from('mbti_types')
          .select()
          .eq('id', typeId)
          .eq('is_active', true)
          .maybeSingle();

      if (typeRow == null) {
        return null;
      }

      final type = MBTIType.fromJson(typeRow);

      final sectionsResponse = await _client
          .from('mbti_type_sections')
          .select()
          .eq('mbti_type_id', type.id)
          .eq('is_active', true)
          .order('order', ascending: true);

      final sections = (sectionsResponse as List)
          .map((row) => MBTITypeSection.fromJson(row as Map<String, dynamic>))
          .toList();

      return type.copyWith(sections: sections);
    } catch (error) {
      debugPrint('Error fetching MBTI type detail: $error');
      return null;
    }
  }

  Future<void> saveTestResult({
    required String userId,
    required String resultCode,
    required List<MBTIAnsweredQuestion> answeredQuestions,
  }) async {
    if (answeredQuestions.isEmpty) {
      return;
    }

    try {
      final sessionRow = await _client
          .from('mbti_test_sessions')
          .insert({'user_id': userId, 'result_code': resultCode})
          .select('id')
          .single();

      final sessionId = (sessionRow['id'] ?? '').toString();
      if (sessionId.isEmpty) {
        return;
      }

      final answersPayload = answeredQuestions
          .map(
            (item) => {
              'session_id': sessionId,
              'question_id': item.question.id,
              'answer_text': item.selectedOption.optionText,
            },
          )
          .toList();

      await _client.from('mbti_test_answers').insert(answersPayload);
    } catch (error) {
      debugPrint('Error saving MBTI test session/answers: $error');
    }
  }
}
