import 'package:flutter/foundation.dart';
import 'package:np_future_gate/core/models/ai_intent_model.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository để lấy dữ liệu từ Supabase dựa trên Intent
class AIDataRepository {
  final SupabaseService _supabaseService = SupabaseService.instance;
  SupabaseClient get _client => _supabaseService.client;

  /// Lấy dữ liệu dựa trên Intent và Parameters
  Future<List<Map<String, dynamic>>> fetchDataByIntent(
    AIIntent intent,
    Map<String, dynamic> params,
    String userId,
  ) async {
    final config = intent.queryConfig;
    if (config == null) return [];

    // ignore: unused_local_variable
    final table = config['table'] as String;

    try {
      switch (intent.id) {
        // ============= EMPLOYER =============
        case 'employer_applications_today':
          return await _getEmployerApplicationsToday(userId);

        case 'employer_job_status':
          return await _getEmployerJobsByStatus(userId, params);

        case 'employer_expired_jobs':
          return await _getEmployerExpiredJobs(userId);

        case 'employer_active_jobs':
          return await _getEmployerActiveJobs(userId);

        case 'employer_interviews':
          return await _getEmployerInterviews(userId, params);

        case 'employer_upcoming_interviews':
          return await _getEmployerUpcomingInterviews(userId);

        case 'employer_partnership_requests':
          return await _getEmployerPartnershipRequests(userId);

        // ============= STUDENT =============
        case 'student_applied_jobs':
          return await _getStudentAppliedJobs(userId);

        case 'student_interviews':
          return await _getStudentInterviews(userId, params);

        case 'student_recommended_jobs':
          return await _getStudentRecommendedJobs(userId);

        // ============= SCHOOL =============
        case 'school_partners':
          return await _getSchoolPartners(userId);

        case 'school_partnership_jobs':
          return await _getSchoolPartnershipJobs(userId);

        default:
          return [];
      }
    } catch (e) {
      debugPrint('Error fetching data for intent ${intent.id}: $e');
      return [];
    }
  }

  // ==================== EMPLOYER QUERIES ====================

  Future<List<Map<String, dynamic>>> _getEmployerApplicationsToday(
      String employerId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final response = await _client
        .from('applications')
        .select('''
          *,
          profiles:student_id (id, full_name, email, avatar_url, skills),
          jobs:job_id (id, title, location)
        ''')
        .eq('employer_id', employerId)
        .gte('created_at', startOfDay.toIso8601String())
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _getEmployerJobsByStatus(
      String employerId, Map<String, dynamic> params) async {
    var query = _client
        .from('jobs')
        .select('id, title, location, salary, created_at, status, applications_count:applications(count)')
        .eq('employer_id', employerId);

    if (params.containsKey('status')) {
      query = query.eq('status', params['status']);
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _getEmployerExpiredJobs(
      String employerId) async {
    final now = DateTime.now();

    final response = await _client
        .from('jobs')
        .select('id, title, location, deadline, applications_count:applications(count)')
        .eq('employer_id', employerId)
        .lt('deadline', now.toIso8601String())
        .order('deadline', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _getEmployerActiveJobs(
      String employerId) async {
    final now = DateTime.now();

    final response = await _client
        .from('jobs')
        .select('id, title, location, deadline, applications_count:applications(count)')
        .eq('employer_id', employerId)
        .eq('status', 'approved')
        .gte('deadline', now.toIso8601String())
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _getEmployerInterviews(
      String employerId, Map<String, dynamic> params) async {
    var query = _client
        .from('interview_schedules')
        .select('''
          *,
          profiles:candidate_id (id, full_name, avatar_url),
          jobs:job_id (id, title)
        ''')
        .eq('employer_id', employerId);

    if (params['upcoming'] == true) {
      query = query.gte('interview_time', DateTime.now().toIso8601String());
    }

    final response = await query.order('interview_time', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _getEmployerUpcomingInterviews(
      String employerId) async {
    final now = DateTime.now();
    final next7Days = now.add(const Duration(days: 7));

    final response = await _client
        .from('interview_schedules')
        .select('''
          *,
          profiles:candidate_id (id, full_name, avatar_url, email, phone),
          jobs:job_id (id, title)
        ''')
        .eq('employer_id', employerId)
        .gte('interview_time', now.toIso8601String())
        .lte('interview_time', next7Days.toIso8601String())
        .order('interview_time', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _getEmployerPartnershipRequests(
      String employerId) async {
    final response = await _client
        .from('school_partnership_requests')
        .select('''
          *,
          schools:school_id (id, name, logo_url, location)
        ''')
        .eq('employer_id', employerId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ==================== STUDENT QUERIES ====================

  Future<List<Map<String, dynamic>>> _getStudentAppliedJobs(
      String studentId) async {
    final response = await _client
        .from('applications')
        .select('''
          *,
          jobs:job_id (
            id, title, location, salary, description,
            employers:employer_id (company_name, logo_url)
          )
        ''')
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _getStudentInterviews(
      String studentId, Map<String, dynamic> params) async {
    var query = _client
        .from('interview_schedules')
        .select('''
          *,
          jobs:job_id (id, title, location),
          employers:employer_id (company_name, logo_url, email, phone)
        ''')
        .eq('candidate_id', studentId);

    if (params['upcoming'] == true) {
      query = query.gte('interview_time', DateTime.now().toIso8601String());
    }

    final response = await query.order('interview_time', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _getStudentRecommendedJobs(
      String studentId) async {
    // TODO: Implement recommendation algorithm
    // For now, return recent approved jobs
    final response = await _client
        .from('jobs')
        .select('''
          id, title, location, salary, description, deadline,
          employers:employer_id (id, company_name, logo_url)
        ''')
        .eq('status', 'approved')
        .gte('deadline', DateTime.now().toIso8601String())
        .order('created_at', ascending: false)
        .limit(10);

    return List<Map<String, dynamic>>.from(response);
  }

  // ==================== SCHOOL QUERIES ====================

  Future<List<Map<String, dynamic>>> _getSchoolPartners(
      String schoolId) async {
    final response = await _client
        .from('school_partnerships')
        .select('''
          *,
          employers:employer_id (id, company_name, logo_url, location, email)
        ''')
        .eq('school_id', schoolId)
        .eq('status', 'approved')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _getSchoolPartnershipJobs(
      String schoolId) async {
    final response = await _client
        .from('school_partnership_jobs')
        .select('''
          *,
          employers:employer_id (id, company_name, logo_url)
        ''')
        .eq('school_id', schoolId)
        .eq('status', 'active')
        .gte('deadline', DateTime.now().toIso8601String())
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
