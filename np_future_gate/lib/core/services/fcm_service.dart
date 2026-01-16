import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../repositories/device_token_repository.dart';

/// Firebase Cloud Messaging Service
/// Xử lý việc nhận và gửi push notifications
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final DeviceTokenRepository _deviceTokenRepo = DeviceTokenRepository();
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  
  // Callback để navigate đến home page khi notification được bấm
  Function(BuildContext)? onNotificationTap;

  /// Initialize FCM and Local Notifications
  Future<void> initialize() async {
    try {
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Request permission for iOS
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('📱 FCM Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        _fcmToken = await _fcm.getToken();
        print('✅ FCM Token: $_fcmToken');

        // Listen for token refresh
        _fcm.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          print('🔄 FCM Token refreshed: $newToken');
        });

        // Setup message handlers
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      }
    } catch (e) {
      print('❌ FCM Initialization error: $e');
    }
  }

  /// Initialize Flutter Local Notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    // Xử lý khi user tap vào local notification
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('📱 Local notification tapped: ${response.payload}');
        // App sẽ tự động mở, không cần xử lý gì thêm
      },
    );
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async {
    print('📬 Foreground message received:');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');
    
    // Show local notification when app is in foreground
    if (message.notification != null) {
      await _showLocalNotification(
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'fcm_channel',
      'FCM Notifications',
      channelDescription: 'Firebase Cloud Messaging notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
    
    print('✅ Local notification displayed');
  }

  /// Handle messages that opened the app
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('📲 Message opened app:');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');
    // App sẽ tự động mở về trang đầu (splash -> home)
    // Không cần navigate thêm
  }

  /// Save FCM token to database
  Future<void> saveToken({
    required String userId,
    required String role,
  }) async {
    if (_fcmToken == null) {
      print('⚠️ No FCM token available');
      return;
    }

    try {
      await _deviceTokenRepo.saveDeviceToken(
        deviceToken: _fcmToken!,
        userId: userId,
        role: role,
      );
      print('✅ FCM token saved to database');
    } catch (e) {
      print('❌ Failed to save FCM token: $e');
      rethrow;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Failed to unsubscribe from topic: $e');
    }
  }
  
  /// Check và xử lý initial message (khi app mở từ terminated state)
  /// Gọi method này trong main.dart sau khi app đã khởi tạo xong
  Future<void> checkInitialMessage() async {
    try {
      // Kiểm tra xem app có được mở từ notification không
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      
      if (initialMessage != null) {
        print('🚀 App opened from notification (terminated state):');
        print('   Title: ${initialMessage.notification?.title}');
        print('   Body: ${initialMessage.notification?.body}');
        print('   Data: ${initialMessage.data}');
        // App sẽ tự động mở về trang đầu
      }
    } catch (e) {
      print('❌ Error checking initial message: $e');
    }
  }
}

/// Background message handler
/// MUST be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📦 Background message received:');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
}
