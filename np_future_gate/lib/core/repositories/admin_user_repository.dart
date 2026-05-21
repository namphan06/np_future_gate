import 'package:flutter/foundation.dart';
import 'package:np_future_gate/core/config/supabase_config.dart';
import 'package:np_future_gate/core/models/auth_models.dart';
import 'package:np_future_gate/core/models/profile_model.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin User Repository
/// Quản lý người dùng từ phía Admin
class AdminUserRepository {
  final SupabaseService _supabaseService = SupabaseService.instance;
  SupabaseClient get _client => _supabaseService.client;

  /// Get all users by role
  Future<List<Profile>> getUsersByRole(UserRole role) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('role', role.value)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Profile.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting users by role: $e');
      throw Exception('Failed to get users: $e');
    }
  }

  /// Create user account (auth + profile) without switching current session
  Future<AuthResult> createUserAccount({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
    required bool isActive,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final tempClient = SupabaseClient(
        SupabaseConfig.supabaseUrl,
        SupabaseConfig.supabaseAnonKey,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          pkceAsyncStorage: SharedPreferencesGotrueAsyncStorage(),
          detectSessionInUri: false,
        ),
      );

      final response = await tempClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': role.value,
        },
      );

      if (response.user == null) {
        return AuthResult.failure('Tạo tài khoản thất bại. Vui lòng thử lại.');
      }

      await tempClient.from('profiles').upsert({
        'id': response.user!.id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'role': role.value,
        'metadata': metadata,
        'is_active': isActive,
      }, onConflict: 'id');

      return AuthResult.success(
        message: response.user!.emailConfirmedAt == null
            ? 'Tạo tài khoản thành công. Vui lòng xác thực email.'
            : 'Tạo tài khoản thành công.',
        data: response.user,
      );
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } on PostgrestException catch (e) {
      return AuthResult.failure('Lỗi database: ${e.message}');
    } catch (e) {
      return AuthResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  /// Get user by ID
  Future<Profile?> getUserById(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return Profile.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error getting user by ID: $e');
      return null;
    }
  }

  /// Toggle user active status
  Future<bool> toggleUserActiveStatus(String userId, bool isActive) async {
    try {
      await _client
          .from('profiles')
          .update({'is_active': isActive})
          .eq('id', userId);

      debugPrint('✅ User active status updated: $isActive');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating user active status: $e');
      throw Exception('Failed to update active status: $e');
    }
  }

  /// Update user metadata (for post limits, etc.)
  Future<bool> updateUserMetadata(String userId, Map<String, dynamic> metadata) async {
    try {
      debugPrint('🔍 Updating metadata for user $userId');
      debugPrint('🔍 New metadata: $metadata');
      
      await _client
          .from('profiles')
          .update({'metadata': metadata})
          .eq('id', userId);

      debugPrint('✅ User metadata updated');
      
      // Force a small delay to ensure database commit
      await Future.delayed(const Duration(milliseconds: 100));
      
      return true;
    } catch (e) {
      debugPrint('❌ Error updating user metadata: $e');
      throw Exception('Failed to update metadata: $e');
    }
  }

  /// Set post limit for employer/school
  Future<bool> setPostLimit(String userId, int limit) async {
    try {
      // Get current metadata
      final profile = await getUserById(userId);
      if (profile == null) {
        throw Exception('User not found');
      }

      debugPrint('🔍 Current metadata: ${profile.metadata}');
      
      final updatedMetadata = Map<String, dynamic>.from(profile.metadata);
      updatedMetadata['limit_post'] = limit;
      
      debugPrint('🔍 Updated metadata: $updatedMetadata');

      await updateUserMetadata(userId, updatedMetadata);
      
      // Verify the update
      final verifyProfile = await getUserById(userId);
      debugPrint('✅ Verified metadata after update: ${verifyProfile?.metadata}');
      
      return true;
    } catch (e) {
      debugPrint('❌ Error setting post limit: $e');
      throw Exception('Failed to set post limit: $e');
    }
  }

  /// Delete user account
  Future<bool> deleteUserAccount(String userId) async {
    try {
      // Note: This will cascade delete due to foreign key constraints
      // You may want to add additional cleanup logic here
      
      // Delete from profiles (this triggers cascade delete in other tables)
      await _client
          .from('profiles')
          .delete()
          .eq('id', userId);

      // Also delete from auth.users (requires admin privileges)
      // This may need to be done via a Supabase function or RPC
      try {
        await _client.rpc('delete_user', params: {'user_id': userId});
      } catch (e) {
        debugPrint('⚠️ Could not delete from auth.users: $e');
        // Continue even if auth deletion fails
      }

      debugPrint('✅ User account deleted');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting user account: $e');
      throw Exception('Failed to delete user account: $e');
    }
  }

  /// Get user applications (for candidates)
  Future<List<Map<String, dynamic>>> getUserApplications(String userId) async {
    try {
      final response = await _client
          .from('user_job_activities')
          .select('*, jobs(*)')
          .eq('user_id', userId)
          .eq('is_applied', true)
          .order('applied_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('❌ Error getting user applications: $e');
      return [];
    }
  }

  /// Get user posted jobs (for employers)
  Future<List<Map<String, dynamic>>> getUserPostedJobs(String userId) async {
    try {
      final response = await _client
          .from('jobs')
          .select()
          .eq('creator_id', userId)
          .order('created_at', ascending: false);

      final jobs = List<Map<String, dynamic>>.from(response as List);
      if (jobs.isNotEmpty) {
        debugPrint('🔍 Sample job data: ${jobs.first}');
      }
      return jobs;
    } catch (e) {
      debugPrint('❌ Error getting user posted jobs: $e');
      return [];
    }
  }

  /// Get school partnership jobs (for schools)
  Future<List<Map<String, dynamic>>> getSchoolPartnershipJobs(String userId) async {
    try {
      final response = await _client
          .from('school_partnership_jobs')
          .select()
          .eq('school_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('❌ Error getting school partnership jobs: $e');
      return [];
    }
  }

  /// Get statistics for a user
  Future<Map<String, dynamic>> getUserStatistics(String userId, UserRole role) async {
    try {
      switch (role) {
        case UserRole.candidate:
          final applications = await getUserApplications(userId);
          final pendingApps = applications.where((app) => app['application_status'] == 'pending').length;
          final acceptedApps = applications.where((app) => app['application_status'] == 'accepted').length;
          
          return {
            'total_applications': applications.length,
            'pending_applications': pendingApps,
            'accepted_applications': acceptedApps,
          };

        case UserRole.employer:
          final jobs = await getUserPostedJobs(userId);
          final activeJobs = jobs.where((job) => job['status'] == 'approved').length;
          
          // Count total applications to employer's jobs from applicants JSONB column
          int totalApplicants = 0;
          for (var job in jobs) {
            final applicants = job['applicants'] as List?;
            if (applicants != null) {
              totalApplicants += applicants.length;
            }
          }
          
          return {
            'total_jobs': jobs.length,
            'active_jobs': activeJobs,
            'total_applicants': totalApplicants,
          };

        case UserRole.school:
          // For schools, count both regular jobs and partnership jobs
          final regularJobs = await getUserPostedJobs(userId);
          final partnershipJobs = await getSchoolPartnershipJobs(userId);
          
          final activeRegularJobs = regularJobs.where((job) => job['status'] == 'approved').length;
          
          // Count applicants from partnership jobs
          int totalApplicants = 0;
          for (var job in partnershipJobs) {
            final applicants = job['applicants'] as List?;
            if (applicants != null) {
              totalApplicants += applicants.length;
            }
          }
          
          return {
            'total_jobs': regularJobs.length,
            'total_partnership_jobs': partnershipJobs.length,
            'active_regular_jobs': activeRegularJobs,
            'total_applicants': totalApplicants,
          };

        default:
          return {};
      }
    } catch (e) {
      debugPrint('❌ Error getting user statistics: $e');
      return {};
    }
  }

  /// Search users by email or name
  Future<List<Profile>> searchUsers(String query, UserRole? role) async {
    try {
      var request = _client
          .from('profiles')
          .select()
          .or('email.ilike.%$query%,full_name.ilike.%$query%');

      if (role != null) {
        request = request.eq('role', role.value);
      }

      final response = await request.order('created_at', ascending: false);

      return (response as List)
          .map((json) => Profile.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error searching users: $e');
      return [];
    }
  }
}
