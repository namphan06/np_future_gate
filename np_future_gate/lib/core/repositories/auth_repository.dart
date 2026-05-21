import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:np_future_gate/core/models/auth_models.dart';
import 'package:np_future_gate/core/models/profile_model.dart';
import 'package:np_future_gate/core/repositories/device_token_repository.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth Repository
/// Xử lý tất cả logic liên quan đến authentication
class AuthRepository {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final DeviceTokenRepository _deviceTokenRepository = DeviceTokenRepository();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  SupabaseClient get _client => _supabaseService.client;

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
  }) async {
    try {
      debugPrint('🔵 Bắt đầu đăng ký: $email');
      
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': role.value,
        },
      );

      debugPrint('🔵 Auth response - User: ${response.user?.id}');
      debugPrint('🔵 Auth response - Session: ${response.session != null}');

      if (response.user == null) {
        debugPrint('❌ Đăng ký thất bại: User null');
        return AuthResult.failure('Đăng ký thất bại. Vui lòng thử lại.');
      }

      debugPrint('✅ User đã tạo trong auth.users: ${response.user!.id}');

      // Tạo profile thủ công nếu trigger không hoạt động
      try {
        debugPrint('🔵 Bắt đầu tạo profile...');
        await _client.from('profiles').insert({
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
          'phone': phone,
          'role': role.value,
          'metadata': {},
          'is_active': false, // Mặc định tài khoản chưa kích hoạt
        });
        debugPrint('✅ Profile đã tạo thành công');
      } catch (profileError) {
        // Ignore nếu profile đã tồn tại (trigger đã tạo)
        debugPrint('⚠️ Lỗi tạo profile (có thể trigger đã tạo): $profileError');
      }

      // Kiểm tra xem có cần xác thực email không
      if (response.user!.emailConfirmedAt == null) {
        debugPrint('⚠️ Email chưa được xác thực');
        return AuthResult.success(
          message: 'Vui lòng kiểm tra email để xác thực tài khoản.',
          data: response.user,
        );
      }

      debugPrint('✅ Đăng ký hoàn tất');
      return AuthResult.success(
        message: 'Đăng ký thành công!',
        data: response.user,
      );
    } on AuthException catch (e) {
      debugPrint('❌ AuthException: ${e.statusCode} - ${e.message}');
      return AuthResult.failure(_getAuthErrorMessage(e));
    } on PostgrestException catch (e) {
      debugPrint('❌ PostgrestException: ${e.code} - ${e.message}');
      debugPrint('❌ Details: ${e.details}');
      debugPrint('❌ Hint: ${e.hint}');
      return AuthResult.failure('Lỗi database: ${e.message}');
    } catch (e) {
      debugPrint('❌ Lỗi không xác định: $e');
      return AuthResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔵 Bắt đầu đăng nhập: $email');
      
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        debugPrint('❌ Đăng nhập thất bại: User null');
        return AuthResult.failure('Đăng nhập thất bại. Vui lòng thử lại.');
      }

      debugPrint('✅ Đăng nhập thành công: ${response.user!.id}');
      
      // Check if account is active
      try {
        final profile = await getCurrentUserProfile();
        if (profile != null && !profile.isActive) {
          debugPrint('⚠️ Tài khoản bị ngừng hoạt động: ${response.user!.id}');
          
          // Sign out immediately
          await _client.auth.signOut();
          
          return AuthResult.failure(
            'Tài khoản của bạn đã bị ngừng hoạt động. '
            'Vui lòng liên hệ quản trị viên để được hỗ trợ.'
          );
        }
      } catch (e) {
        debugPrint('⚠️ Không thể kiểm tra trạng thái tài khoản: $e');
        // Allow login to continue if can't check status
      }
      
      return AuthResult.success(
        message: 'Đăng nhập thành công!',
        data: response.user,
      );
    } on AuthException catch (e) {
      debugPrint('❌ AuthException: ${e.statusCode} - ${e.message}');
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      debugPrint('❌ Lỗi đăng nhập: $e');
      return AuthResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      debugPrint('🔵 Bắt đầu đăng nhập Google');
      
      // Đăng xuất trước để chọn tài khoản mới
      await _googleSignIn.signOut();

      // Sign in with Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('⚠️ User hủy đăng nhập Google');
        return AuthResult.failure('Đăng nhập Google bị hủy.');
      }

      debugPrint('🔵 Google user: ${googleUser.email}');

      // Get Google authentication
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        debugPrint('❌ Không lấy được token từ Google');
        return AuthResult.failure('Không thể lấy thông tin xác thực từ Google.');
      }

      debugPrint('🔵 Đang đăng nhập vào Supabase...');
      // Sign in to Supabase with Google credentials
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user == null) {
        debugPrint('❌ Supabase signIn thất bại');
        return AuthResult.failure('Đăng nhập Google thất bại.');
      }

      debugPrint('✅ Đăng nhập Google thành công: ${response.user!.id}');
      
      // Check if account is active
      try {
        final profile = await getCurrentUserProfile();
        if (profile != null && !profile.isActive) {
          debugPrint('⚠️ Tài khoản bị ngừng hoạt động: ${response.user!.id}');
          
          // Sign out immediately
          await _client.auth.signOut();
          await _googleSignIn.signOut();
          
          return AuthResult.failure(
            'Tài khoản của bạn đã bị ngừng hoạt động. '
            'Vui lòng liên hệ quản trị viên để được hỗ trợ.'
          );
        }
      } catch (e) {
        debugPrint('⚠️ Không thể kiểm tra trạng thái tài khoản: $e');
        // Allow login to continue if can't check status
      }
      
      return AuthResult.success(
        message: 'Đăng nhập Google thành công!',
        data: response.user,
      );
    } on AuthException catch (e) {
      debugPrint('❌ AuthException: ${e.statusCode} - ${e.message}');
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      debugPrint('❌ Lỗi Google Sign-in: $e');
      return AuthResult.failure('Đã xảy ra lỗi khi đăng nhập Google: $e');
    }
  }

  /// Sign out
  Future<AuthResult> signOut({String? deviceToken}) async {
    try {
      // Remove device token if provided
      if (deviceToken != null && _supabaseService.currentUserId != null) {
        try {
          await _deviceTokenRepository.removeDeviceToken(
            deviceToken: deviceToken,
            userId: _supabaseService.currentUserId!,
          );
        } catch (e) {
          debugPrint('⚠️ Error removing device token: $e');
        }
      }
      
      await _client.auth.signOut();
      await _googleSignIn.signOut();
      return AuthResult.success(message: 'Đăng xuất thành công!');
    } catch (e) {
      return AuthResult.failure('Đã xảy ra lỗi khi đăng xuất: $e');
    }
  }

  /// Reset password
  Future<AuthResult> resetPassword({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return AuthResult.success(
        message: 'Đã gửi email đặt lại mật khẩu. Vui lòng kiểm tra hộp thư.',
      );
    } on AuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  /// Get current user profile from profiles table
  Future<Profile?> getCurrentUserProfile() async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) return null;

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return Profile.fromJson(response);
    } catch (e) {
      debugPrint('Lỗi khi lấy profile: $e');
      return null;
    }
  }

  /// Update user profile
  Future<AuthResult> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (metadata != null) updates['metadata'] = metadata;

      await _client.from('profiles').update(updates).eq('id', userId);

      // Sync with Auth User Metadata
      final userUpdates = UserAttributes(
        data: {
          if (fullName != null) 'full_name': fullName,
          if (phone != null) 'phone': phone,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          if (metadata != null && metadata.containsKey('company_name')) 'company_name': metadata['company_name'],
        },
      );
      await _client.auth.updateUser(userUpdates);

      return AuthResult.success(message: 'Cập nhật thông tin thành công!');
    } catch (e) {
      return AuthResult.failure('Đã xảy ra lỗi khi cập nhật: $e');
    }
  }

  /// Upload avatar and return URL
  Future<String?> uploadAvatar(File file, String userId) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;

      // Delete old avatar if exists
      try {
        final profile = await getCurrentUserProfile();
        if (profile?.avatarUrl != null) {
           final oldUrl = profile!.avatarUrl!;
           // Check if it's a supabase storage url in the 'profile' bucket
           if (oldUrl.contains('/storage/v1/object/public/profile/')) {
             final oldPath = oldUrl.split('/profile/').last;
             await _client.storage.from('profile').remove([oldPath]);
           }
        }
      } catch (e) {
        debugPrint('Error deleting old avatar: $e');
      }

      await _client.storage.from('profile').upload(
        filePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final imageUrl = _client.storage.from('profile').getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      throw Exception('Upload failed: $e');
    }
  }

  /// Update Password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  /// Get user authentication state stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Check if user is authenticated
  bool get isAuthenticated => _supabaseService.isAuthenticated;

  /// Get current user
  User? get currentUser => _supabaseService.currentUser;

  /// Convert AuthException to Vietnamese message
  String _getAuthErrorMessage(AuthException e) {
    switch (e.statusCode) {
      case '400':
        if (e.message.contains('User already registered')) {
          return 'Email đã được đăng ký.';
        }
        if (e.message.contains('Invalid login credentials')) {
          return 'Email hoặc mật khẩu không đúng.';
        }
        return 'Yêu cầu không hợp lệ.';
      case '422':
        return 'Email hoặc mật khẩu không hợp lệ.';
      case '429':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      default:
        return e.message;
    }
  }

  /// Get profiles by list of IDs
  Future<List<Profile>> getProfilesByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];
      
      final response = await _client
          .from('profiles')
          .select()
          .filter('id', 'in', '(${userIds.map((e) => '"$e"').join(',')})');

      return (response as List).map((e) => Profile.fromJson(e)).toList();
    } catch (e) {
      debugPrint('❌ Lỗi lấy danh sách profiles: $e');
      return [];
    }
  }

  /// Save device token for push notifications
  /// Call this method after successful login/signup
  Future<void> saveDeviceToken({
    required String deviceToken,
    required String userId,
    required String role,
  }) async {
    try {
      await _deviceTokenRepository.saveDeviceToken(
        deviceToken: deviceToken,
        userId: userId,
        role: role,
      );
      debugPrint('✅ Device token saved successfully');
    } catch (e) {
      debugPrint('⚠️ Error saving device token: $e');
      // Don't throw, just log the error
      // Push notification registration shouldn't block user flow
    }
  }

  /// Get device token repository
  DeviceTokenRepository get deviceTokenRepository => _deviceTokenRepository;
}
