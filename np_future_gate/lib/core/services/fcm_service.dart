import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:np_future_gate/core/models/notification_model.dart';
import 'package:np_future_gate/core/repositories/auth_repository.dart';
import 'package:np_future_gate/core/repositories/device_token_repository.dart';
import 'package:np_future_gate/core/services/notification/status_notification_service.dart';
import 'package:np_future_gate/main.dart'; // For navigatorKey
import 'package:np_future_gate/notification/models/notification_config.dart';

/// Firebase Cloud Messaging Service
/// Xử lý việc nhận và gửi push notifications
class FCMService {
  factory FCMService() => _instance;
  FCMService._internal();
  static final FCMService _instance = FCMService._internal();

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
      final NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('📱 FCM Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        _fcmToken = await _fcm.getToken();
        debugPrint('✅ FCM Token: $_fcmToken');

        if (_fcmToken != null) {
          await _saveTokenForCurrentUser(_fcmToken!);
        }

        // Listen for token refresh
        _fcm.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          debugPrint('🔄 FCM Token refreshed: $newToken');
          _saveTokenForCurrentUser(newToken);
        });

        // Setup message handlers
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      }
    } catch (e) {
      debugPrint('❌ FCM Initialization error: $e');
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
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint('👉 =================================');
        debugPrint('📱 Local notification tapped!');
        debugPrint('📱 Payload: ${response.payload}');
        debugPrint('📱 Action ID: ${response.actionId}');
        debugPrint('📱 Notification ID: ${response.id}');
        debugPrint('👉 =================================');
        
        // Parse data từ payload
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            // Parse JSON payload
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            debugPrint('📦 Parsed data: $data');
            
            // Lấy context từ navigatorKey
            final context = navigatorKey.currentContext;
            debugPrint('🎯 Context available: ${context != null}');
            debugPrint('🎯 Context mounted: ${context?.mounted ?? false}');
            
            if (context != null && context.mounted) {
              // Sử dụng NotificationService để handle navigation
              final notificationService = StatusNotificationService();
              debugPrint('✅ Creating NotificationModel...');
              
              // Tạo notification model tạm từ data
              final notification = NotificationModel(
                id: data['notificationId'] as String? ?? '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                recipientIds: '', // Không cần thiết cho navigation
                title: data['title'] as String? ?? 'Thông báo',
                content: data['body'] as String? ?? '',
                actionCode: data['type'] as String? ?? '',
                actionData: data,
                isActive: true,
                type: NotificationType.info,
                isRead: false,
              );
              
              debugPrint('✅ Calling handleNotificationTap...');
              await notificationService.handleNotificationTap(context, notification);
              debugPrint('✅ Navigation completed');
            } else {
              debugPrint('❌ Context not available or not mounted');
            }
          } catch (e, stackTrace) {
            debugPrint('❌ Error handling notification tap: $e');
            debugPrint('❌ Stack trace: $stackTrace');
          }
        } else {
          debugPrint('⚠️ Payload is null or empty');
        }
      },
    );
  }

  Future<void> _saveTokenForCurrentUser(String token) async {
    try {
      final authRepo = AuthRepository();
      final profile = await authRepo.getCurrentUserProfile();

      if (profile == null) return;

      await authRepo.saveDeviceToken(
        deviceToken: token,
        userId: profile.id,
        role: profile.role.value,
      );
    } catch (e) {
      debugPrint('⚠️ Error saving device token from FCMService: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📬 Foreground message received:');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');
    
    // Show local notification when app is in foreground
    if (message.notification != null) {
      await _showLocalNotification(
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        payload: jsonEncode(message.data), // Convert to JSON string
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
    
    debugPrint('✅ Local notification displayed');
  }

  /// Handle messages that opened the app
  void _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('👉 =================================');
    debugPrint('📲 Message opened app (from background)!');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');
    debugPrint('👉 =================================');
    
    // Lấy context từ navigatorKey
    final context = navigatorKey.currentContext;
    debugPrint('🎯 Context available: ${context != null}');
    debugPrint('🎯 Context mounted: ${context?.mounted ?? false}');
    
    if (context != null && context.mounted && message.data.isNotEmpty) {
      try {
        final notificationService = StatusNotificationService();
        debugPrint('✅ Creating NotificationModel from FCM data...');
        
        // Tạo notification model từ FCM data
        final notification = NotificationModel(
          id: message.data['notificationId'] as String? ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          recipientIds: '',
          title: message.notification?.title ?? 'Thông báo',
          content: message.notification?.body ?? '',
          actionCode: message.data['type'] as String? ?? '',
          actionData: message.data,
          isActive: true,
          type: NotificationType.info,
          isRead: false,
        );
        
        debugPrint('✅ Calling handleNotificationTap...');
        // Handle navigation
        await notificationService.handleNotificationTap(context, notification);
        debugPrint('✅ Navigation completed');
      } catch (e, stackTrace) {
        debugPrint('❌ Error handling message opened app: $e');
        debugPrint('❌ Stack trace: $stackTrace');
      }
    } else {
      debugPrint('❌ Cannot handle: context=${context != null}, data empty=${message.data.isEmpty}');
    }
  }

  /// Save FCM token to database
  Future<void> saveToken({
    required String userId,
    required String role,
  }) async {
    if (_fcmToken == null) {
      debugPrint('⚠️ No FCM token available');
      return;
    }

    try {
      await _deviceTokenRepo.saveDeviceToken(
        deviceToken: _fcmToken!,
        userId: userId,
        role: role,
      );
      debugPrint('✅ FCM token saved to database');
    } catch (e) {
      debugPrint('❌ Failed to save FCM token: $e');
      rethrow;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from topic: $e');
    }
  }
  
  /// Check và xử lý initial message (khi app mở từ terminated state)
  /// Gọi method này trong main.dart sau khi app đã khởi tạo xong
  Future<void> checkInitialMessage() async {
    try {
      // Kiểm tra xem app có được mở từ notification không
      final RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      
      if (initialMessage != null) {
        debugPrint('🚀 ========================================');
        debugPrint('🚀 App opened from notification (terminated state)!');
        debugPrint('   Title: ${initialMessage.notification?.title}');
        debugPrint('   Body: ${initialMessage.notification?.body}');
        debugPrint('   Data: ${initialMessage.data}');
        debugPrint('🚀 ========================================');
        
        // Đợi một chút để app render xong
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Lấy context từ navigatorKey
        final context = navigatorKey.currentContext;
        debugPrint('🎯 Context available: ${context != null}');
        debugPrint('🎯 Context mounted: ${context?.mounted ?? false}');
        
        if (context != null && context.mounted && initialMessage.data.isNotEmpty) {
          try {
            final notificationService = StatusNotificationService();
            debugPrint('✅ Creating NotificationModel from initial FCM data...');
            
            // Tạo notification model từ FCM data
            final notification = NotificationModel(
              id: initialMessage.data['notificationId'] as String? ?? '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              recipientIds: '',
              title: initialMessage.notification?.title ?? 'Thông báo',
              content: initialMessage.notification?.body ?? '',
              actionCode: initialMessage.data['type'] as String? ?? '',
              actionData: initialMessage.data,
              isActive: true,
              type: NotificationType.info,
              isRead: false,
            );
            
            debugPrint('✅ Calling handleNotificationTap from terminated state...');
            // Handle navigation
            await notificationService.handleNotificationTap(context, notification);
            debugPrint('✅ Navigation from terminated state completed');
          } catch (e, stackTrace) {
            debugPrint('❌ Error handling initial message: $e');
            debugPrint('❌ Stack trace: $stackTrace');
          }
        } else {
          debugPrint('⚠️ Cannot handle initial message:');
          debugPrint('   Context: ${context != null}');
          debugPrint('   Mounted: ${context?.mounted ?? false}');
          debugPrint('   Has data: ${initialMessage.data.isNotEmpty}');
        }
      } else {
        debugPrint('ℹ️ No initial message (app opened normally)');
      }
    } catch (e) {
      debugPrint('❌ Error checking initial message: $e');
    }
  }
  
  /// Parse payload string to Map
}

/// Background message handler
/// MUST be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📦 Background message received:');
  debugPrint('   Title: ${message.notification?.title}');
  debugPrint('   Body: ${message.notification?.body}');
}
