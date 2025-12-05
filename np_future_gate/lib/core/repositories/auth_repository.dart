import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/supabase_service.dart';
import '../models/auth_models.dart';
import '../models/profile_model.dart';

/// Auth Repository
/// Xử lý tất cả logic liên quan đến authentication
class AuthRepository {
  final SupabaseService _supabaseService = SupabaseService.instance;
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
      print('🔵 Bắt đầu đăng ký: $email');
      
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': role.value,
        },
      );

      print('🔵 Auth response - User: ${response.user?.id}');
      print('🔵 Auth response - Session: ${response.session != null}');

      if (response.user == null) {
        print('❌ Đăng ký thất bại: User null');
        return AuthResult.failure('Đăng ký thất bại. Vui lòng thử lại.');
      }

      print('✅ User đã tạo trong auth.users: ${response.user!.id}');

      // Tạo profile thủ công nếu trigger không hoạt động
      try {
        print('🔵 Bắt đầu tạo profile...');
        await _client.from('profiles').insert({
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
          'phone': phone,
          'role': role.value,
          'metadata': {},
        });
        print('✅ Profile đã tạo thành công');
      } catch (profileError) {
        // Ignore nếu profile đã tồn tại (trigger đã tạo)
        print('⚠️ Lỗi tạo profile (có thể trigger đã tạo): $profileError');
      }

      // Kiểm tra xem có cần xác thực email không
      if (response.user!.emailConfirmedAt == null) {
        print('⚠️ Email chưa được xác thực');
        return AuthResult.success(
          message: 'Vui lòng kiểm tra email để xác thực tài khoản.',
          data: response.user,
        );
      }

      print('✅ Đăng ký hoàn tất');
      return AuthResult.success(
        message: 'Đăng ký thành công!',
        data: response.user,
      );
    } on AuthException catch (e) {
      print('❌ AuthException: ${e.statusCode} - ${e.message}');
      return AuthResult.failure(_getAuthErrorMessage(e));
    } on PostgrestException catch (e) {
      print('❌ PostgrestException: ${e.code} - ${e.message}');
      print('❌ Details: ${e.details}');
      print('❌ Hint: ${e.hint}');
      return AuthResult.failure('Lỗi database: ${e.message}');
    } catch (e) {
      print('❌ Lỗi không xác định: $e');
      return AuthResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 Bắt đầu đăng nhập: $email');
      
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        print('❌ Đăng nhập thất bại: User null');
        return AuthResult.failure('Đăng nhập thất bại. Vui lòng thử lại.');
      }

      print('✅ Đăng nhập thành công: ${response.user!.id}');
      return AuthResult.success(
        message: 'Đăng nhập thành công!',
        data: response.user,
      );
    } on AuthException catch (e) {
      print('❌ AuthException: ${e.statusCode} - ${e.message}');
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      print('❌ Lỗi đăng nhập: $e');
      return AuthResult.failure('Đã xảy ra lỗi: $e');
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      print('🔵 Bắt đầu đăng nhập Google');
      
      // Đăng xuất trước để chọn tài khoản mới
      await _googleSignIn.signOut();

      // Sign in with Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('⚠️ User hủy đăng nhập Google');
        return AuthResult.failure('Đăng nhập Google bị hủy.');
      }

      print('🔵 Google user: ${googleUser.email}');

      // Get Google authentication
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        print('❌ Không lấy được token từ Google');
        return AuthResult.failure('Không thể lấy thông tin xác thực từ Google.');
      }

      print('🔵 Đang đăng nhập vào Supabase...');
      // Sign in to Supabase with Google credentials
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user == null) {
        print('❌ Supabase signIn thất bại');
        return AuthResult.failure('Đăng nhập Google thất bại.');
      }

      print('✅ Đăng nhập Google thành công: ${response.user!.id}');
      return AuthResult.success(
        message: 'Đăng nhập Google thành công!',
        data: response.user,
      );
    } on AuthException catch (e) {
      print('❌ AuthException: ${e.statusCode} - ${e.message}');
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      print('❌ Lỗi Google Sign-in: $e');
      return AuthResult.failure('Đã xảy ra lỗi khi đăng nhập Google: $e');
    }
  }

  /// Sign out
  Future<AuthResult> signOut() async {
    try {
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
      print('Lỗi khi lấy profile: $e');
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
          // We don't sync all metadata to auth user to keep it light, 
          // but basic info is good.
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
        print('Error deleting old avatar: $e');
      }

      await _client.storage.from('profile').upload(
        filePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final imageUrl = _client.storage.from('profile').getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      print('Error uploading avatar: $e');
      throw Exception('Upload failed: $e');
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
      print('❌ Lỗi lấy danh sách profiles: $e');
      return [];
    }
  }
}
