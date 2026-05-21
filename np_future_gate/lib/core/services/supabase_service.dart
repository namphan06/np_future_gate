import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:np_future_gate/core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Service
/// Singleton service để khởi tạo và quản lý Supabase client
class SupabaseService {

  SupabaseService._();
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  /// Get singleton instance
  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  /// Get Supabase client
  SupabaseClient get client {
    if (_client == null) {
      throw Exception(
          'Supabase chưa được khởi tạo. Gọi initialize() trong main() trước.');
    }
    return _client!;
  }

  /// Initialize Supabase
  /// Gọi hàm này trong main() trước khi runApp()
  static Future<void> initialize() async {
    try {
      // Load .env file
      await dotenv.load(fileName: '.env');

      // Initialize Supabase
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      _client = Supabase.instance.client;
      debugPrint('✅ Supabase đã khởi tạo thành công');
    } catch (e) {
      debugPrint('❌ Lỗi khởi tạo Supabase: $e');
      rethrow;
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => client.auth.currentUser != null;

  /// Get current user
  User? get currentUser => client.auth.currentUser;

  /// Get current user ID
  String? get currentUserId => client.auth.currentUser?.id;
}
