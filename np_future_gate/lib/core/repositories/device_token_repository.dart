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
      // Lấy thông tin thiết bị
      final deviceInfo = await _getDeviceInfo();

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
      var query = _supabase
          .from('device_tokens')
          .select('device_id')
          .eq('is_active', true);

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (role != null) {
        query = query.eq('role', role);
      }

      final response = await query;
      
      return (response as List)
          .map((item) => item['device_id'] as String)
          .toList();
    } catch (e) {
      print('Error getting active device IDs: $e');
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
