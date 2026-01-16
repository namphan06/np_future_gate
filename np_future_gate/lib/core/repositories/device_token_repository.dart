import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/device_token_model.dart';
import '../services/supabase_service.dart';

/// Device Token Repository
/// Xử lý tất cả logic liên quan đến device tokens cho push notifications
class DeviceTokenRepository {
  final _supabase = SupabaseService.instance.client;

  /// Lưu hoặc cập nhật device token
  /// Sử dụng function upsert_device_token từ database
  Future<String?> saveDeviceToken({
    required String deviceToken,
    required String userId,
    required String role,
  }) async {
    try {
      // Kiểm tra xem token đã tồn tại chưa (không quan tâm is_active)
      final existing = await _supabase
          .from('device_tokens')
          .select('id')
          .eq('device_id', deviceToken)
          .eq('user_id', userId)
          .eq('role', role)
          .maybeSingle();

      // Nếu đã tồn tại, cập nhật last_login_at và is_active = true
      if (existing != null) {
        await _supabase
            .from('device_tokens')
            .update({
              'last_login_at': DateTime.now().toIso8601String(),
              'is_active': true,
            })
            .eq('id', existing['id']);
        return existing['id'] as String;
      }

      // Nếu chưa tồn tại, tạo mới với notification_settings
      final deviceInfo = await _getDeviceInfo();
      
      final notificationSettings = {
        'enabled': true,
        'sound_enabled': true,
        'job_notifications': true,
        'vibration_enabled': true,
        'notification_types': {
          'info': true,
          'error': true,
          'success': true,
          'warning': true,
          'reminder': true,
          'requirement': true,
          'announcement': true,
        },
        'system_notifications': true,
        'message_notifications': true,
        'interview_notifications': true,
        'application_notifications': true,
        'partnership_notifications': true,
      };

      // Gọi function upsert_device_token trong database
      final response = await _supabase.rpc(
        'upsert_device_token',
        params: {
          'p_device_id': deviceToken,
          'p_user_id': userId,
          'p_role': role,
          'p_device_type': deviceInfo['device_type'],
          'p_device_name': deviceInfo['device_name'],
          'p_app_version': deviceInfo['app_version'],
          'p_notification_settings': notificationSettings,
        },
      );

      return response as String?;
    } catch (e) {
      print('Error saving device token: $e');
      rethrow;
    }
  }

  /// Lấy thông tin thiết bị hiện tại
  Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    String deviceType = '';
    String deviceName = '';
    String appVersion = '';

    try {
      // Lấy app version
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;

      // Lấy device info dựa trên platform
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceType = 'android';
        deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceType = 'ios';
        deviceName = '${iosInfo.name} ${iosInfo.model}';
      }
    } catch (e) {
      print('Error getting device info: $e');
    }

    return {
      'device_type': deviceType,
      'device_name': deviceName,
      'app_version': appVersion,
    };
  }

  /// Lấy tất cả device tokens của user
  Future<List<DeviceTokenModel>> getUserDeviceTokens({
    required String userId,
    String? role,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_user_device_tokens',
        params: {
          'p_user_id': userId,
          'p_role': role,
        },
      ) as List;

      return response
          .map((json) => DeviceTokenModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting user device tokens: $e');
      return [];
    }
  }

  /// Cập nhật notification settings cho device
  Future<bool> updateNotificationSettings({
    required String deviceToken,
    required String userId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      final response = await _supabase.rpc(
        'update_device_notification_settings',
        params: {
          'p_device_id': deviceToken,
          'p_user_id': userId,
          'p_settings': settings,
        },
      );

      return response as bool? ?? false;
    } catch (e) {
      print('Error updating notification settings: $e');
      return false;
    }
  }

  /// Kiểm tra có nên gửi notification cho device không
  Future<bool> shouldSendNotification({
    required String deviceToken,
    required String userId,
    required String category, // 'job', 'application', 'interview', etc.
    String? type, // 'info', 'success', 'warning', etc.
  }) async {
    try {
      final response = await _supabase.rpc(
        'should_send_notification',
        params: {
          'p_device_id': deviceToken,
          'p_user_id': userId,
          'p_notification_category': category,
          'p_notification_type': type,
        },
      );

      return response as bool? ?? false;
    } catch (e) {
      print('Error checking notification permission: $e');
      return false;
    }
  }

  /// Xóa/deactivate device token khi logout
  Future<bool> removeDeviceToken({
    required String deviceToken,
    required String userId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'remove_device_token',
        params: {
          'p_device_id': deviceToken,
          'p_user_id': userId,
        },
      );

      return response as bool? ?? false;
    } catch (e) {
      print('Error removing device token: $e');
      return false;
    }
  }

  /// Lấy active device tokens
  /// - Nếu không có userId và role: lấy TẤT CẢ tokens
  /// - Nếu có userId: lấy tokens của user đó
  /// - Nếu có role: filter theo role
  Future<List<String>> getActiveDeviceIds({
    String? userId,
    String? role,
  }) async {
    try {
      print('🔍 DEBUG Repository Query:');
      print('   userId: $userId');
      print('   role: $role');
      
      var query = _supabase
          .from('device_tokens')
          .select('device_id, user_id, role, is_active')
          .eq('is_active', true);

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (role != null) {
        query = query.eq('role', role);
      }

      final response = await query;
      
      print('📱 DEBUG Raw Response:');
      print('   Type: ${response.runtimeType}');
      print('   Length: ${(response as List).length}');
      print('   Data: $response');
      
      return response
          .map((item) => item['device_id'] as String)
          .toList();
    } catch (e) {
      print('❌ Error getting active device IDs: $e');
      return [];
    }
  }

  /// Deactivate tất cả tokens của một user (khi delete account chẳng hạn)
  Future<bool> deactivateAllUserTokens(String userId) async {
    try {
      await _supabase
          .from('device_tokens')
          .update({'is_active': false})
          .eq('user_id', userId);
      
      return true;
    } catch (e) {
      print('Error deactivating user tokens: $e');
      return false;
    }
  }

  /// Update role cho tất cả device tokens của user
  /// Dùng khi user thay đổi role
  Future<bool> updateUserRole({
    required String userId,
    required String oldRole,
    required String newRole,
  }) async {
    try {
      await _supabase
          .from('device_tokens')
          .update({'role': newRole})
          .eq('user_id', userId)
          .eq('role', oldRole)
          .eq('is_active', true);
      
      return true;
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }
}
