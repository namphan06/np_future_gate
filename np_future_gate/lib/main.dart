import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:np_future_gate/core/repositories/auth_repository.dart';
import 'package:np_future_gate/core/services/fcm_service.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:np_future_gate/core/theme/app_theme.dart';
import 'package:np_future_gate/firebase_options.dart';
import 'package:np_future_gate/features/notification/notification_navigation_setup.dart';
import 'package:np_future_gate/screens/splash/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;

// Global navigator key để access navigator từ bất kỳ đâu
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global notification plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('🚀 Initializing app...');
  
  // Initialize timezone
  tz.initializeTimeZones();
  debugPrint('✅ Timezone initialized');
  
  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ Environment variables loaded');
  } catch (e) {
    debugPrint('⚠️ Error loading .env file: $e');
  }
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }
  
  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize date formatting
  await initializeDateFormatting('vi', null);
  
  // Initialize local notifications
  await _initializeLocalNotifications();
  debugPrint('✅ Local notifications initialized');
  
  // Initialize FCM
  try {
    await FCMService().initialize();
    debugPrint('✅ FCM Service initialized');
  } catch (e) {
    debugPrint('⚠️ FCM initialization error: $e');
  }
  
  // Setup notification navigation
  setupNotificationNavigation();
  debugPrint('✅ Notification navigation setup completed');
  
  // Debug: Check current auth session
  final session = Supabase.instance.client.auth.currentSession;
  final user = Supabase.instance.client.auth.currentUser;
  debugPrint('🔐 Auth Debug: Session=${session != null ? "Active" : "None"}, User=${user?.id}');
  
  // Nếu user đã đăng nhập, lưu device token
  if (user != null) {
    _saveDeviceTokenForCurrentUser();
  }
  
  runApp(const MyApp());
}

Future<void> _initializeLocalNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
  
  const InitializationSettings settings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  
  await flutterLocalNotificationsPlugin.initialize(
    settings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null) {
        _handleNotificationTap(response.payload!);
      }
    },
  );
  
  // Request permissions for Android 13+
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

void _handleNotificationTap(String payload) {
  // Handle interview reminder notification tap
  if (payload.startsWith('interview:')) {
    final interviewId = payload.split(':')[1];
    debugPrint('📅 Navigate to interview: $interviewId');
    // TODO: Navigate to interview detail screen
  }
}

/// Lưu device token cho user hiện tại (nếu đã đăng nhập)
Future<void> _saveDeviceTokenForCurrentUser() async {
  try {
    final authRepo = AuthRepository();
    final profile = await authRepo.getCurrentUserProfile();
    final fcmToken = FCMService().fcmToken;
    
    if (profile != null && fcmToken != null) {
      debugPrint('💾 Saving device token for existing session...');
      await authRepo.saveDeviceToken(
        deviceToken: fcmToken,
        userId: profile.id,
        role: profile.role.value,
      );
      debugPrint('✅ Device token saved on app startup');
    } else {
      if (fcmToken == null) {
        debugPrint('⚠️ FCM token not available yet');
      }
    }
  } catch (e) {
    debugPrint('⚠️ Error saving device token on startup: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Check initial message sau khi widget tree đã build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialNotification();
    });
  }

  Future<void> _checkInitialNotification() async {
    // Đợi thêm một chút để đảm bảo navigation đã sẵn sàng
    await Future.delayed(const Duration(milliseconds: 1000));
    debugPrint('🔍 Checking for initial notification...');
    await FCMService().checkInitialMessage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'NP FutureGate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
