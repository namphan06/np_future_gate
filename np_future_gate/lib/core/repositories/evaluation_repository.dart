import 'package:supabase_flutter/supabase_flutter.dart';

class EvaluationRepository {
  final SupabaseClient _supabase;

  EvaluationRepository(this._supabase);

  /// Fetch all student work progress records for a specific company
  /// Returns a list of records including student and school profiles
  Future<List<Map<String, dynamic>>> getStudentWorkProgressForCompany(String companyId) async {
    try {
      final response = await _supabase
          .from('student_work_progress')
          .select('''
            *,
            student:user_id (
              id,
              full_name,
              email,
              avatar_url
            ),
            school:school_id (
              id,
              full_name,
              email,
              avatar_url
            )
          ''')
          .eq('company_id', companyId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch student progress: $e');
    }
  }

  /// Fetch all student work progress records for a specific school
  /// Returns a list of records including student and company profiles
  Future<List<Map<String, dynamic>>> getStudentWorkProgressForSchool(String schoolId) async {
    try {
      final response = await _supabase
          .from('student_work_progress')
          .select('''
            *,
            student:user_id (
              id,
              full_name,
              email,
              avatar_url
            ),
            company:company_id (
              id,
              full_name,
              email,
              avatar_url
            )
          ''')
          .eq('school_id', schoolId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch student progress for school: $e');
    }
  }

  /// Fetch student work progress record for the current student
  Future<Map<String, dynamic>?> getStudentWorkProgressForStudent(String userId) async {
    try {
      final response = await _supabase
          .from('student_work_progress')
          .select('''
            *,
            company:company_id (
              id,
              full_name,
              email,
              avatar_url
            ),
            school:school_id (
              id,
              full_name,
              email,
              avatar_url
            )
          ''')
          .eq('user_id', userId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      throw Exception('Failed to fetch student progress: $e');
    }
  }

  /// Update full student work progress record
  Future<void> updateStudentProgress(String progressId, {
    List<Map<String, dynamic>>? evaluations,
    List<Map<String, dynamic>>? workRoadmap,
    String? evaluatorName,
    String? workDuration,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (evaluations != null) updates['evaluations'] = evaluations;
      if (workRoadmap != null) updates['work_roadmap'] = workRoadmap;
      if (evaluatorName != null) updates['evaluator_name'] = evaluatorName;
      if (workDuration != null) updates['work_duration'] = workDuration;
      
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('student_work_progress')
          .update(updates)
          .eq('id', progressId);
    } catch (e) {
      throw Exception('Failed to update progress: $e');
    }
  }
}
