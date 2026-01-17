import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../repositories/device_token_repository.dart';
import '../models/notification_model.dart';
import '../../notification/models/notification_config.dart';
import 'notification/status_notification_service.dart';
import '../../main.dart'; // For navigatorKey

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
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('👉 =================================');
        print('📱 Local notification tapped!');
        print('📱 Payload: ${response.payload}');
        print('📱 Action ID: ${response.actionId}');
        print('📱 Notification ID: ${response.id}');
        print('👉 =================================');
        
        // Parse data từ payload
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            // Parse JSON payload
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            print('📦 Parsed data: $data');
            
            // Lấy context từ navigatorKey
            final context = navigatorKey.currentContext;
            print('🎯 Context available: ${context != null}');
            print('🎯 Context mounted: ${context?.mounted ?? false}');
            
            if (context != null && context.mounted) {
              // Sử dụng NotificationService để handle navigation
              final notificationService = StatusNotificationService();
              print('✅ Creating NotificationModel...');
              
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
              
              print('✅ Calling handleNotificationTap...');
              await notificationService.handleNotificationTap(context, notification);
              print('✅ Navigation completed');
            } else {
              print('❌ Context not available or not mounted');
            }
          } catch (e, stackTrace) {
            print('❌ Error handling notification tap: $e');
            print('❌ Stack trace: $stackTrace');
          }
        } else {
          print('⚠️ Payload is null or empty');
        }
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
    
    print('✅ Local notification displayed');
  }

  /// Handle messages that opened the app
  void _handleMessageOpenedApp(RemoteMessage message) async {
    print('👉 =================================');
    print('📲 Message opened app (from background)!');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');
    print('👉 =================================');
    
    // Lấy context từ navigatorKey
    final context = navigatorKey.currentContext;
    print('🎯 Context available: ${context != null}');
    print('🎯 Context mounted: ${context?.mounted ?? false}');
    
    if (context != null && context.mounted && message.data.isNotEmpty) {
      try {
        final notificationService = StatusNotificationService();
        print('✅ Creating NotificationModel from FCM data...');
        
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
        
        print('✅ Calling handleNotificationTap...');
        // Handle navigation
        await notificationService.handleNotificationTap(context, notification);
        print('✅ Navigation completed');
      } catch (e, stackTrace) {
        print('❌ Error handling message opened app: $e');
        print('❌ Stack trace: $stackTrace');
      }
    } else {
      print('❌ Cannot handle: context=${context != null}, data empty=${message.data.isEmpty}');
    }
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
        print('🚀 ========================================');
        print('🚀 App opened from notification (terminated state)!');
        print('   Title: ${initialMessage.notification?.title}');
        print('   Body: ${initialMessage.notification?.body}');
        print('   Data: ${initialMessage.data}');
        print('🚀 ========================================');
        
        // Đợi một chút để app render xong
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Lấy context từ navigatorKey
        final context = navigatorKey.currentContext;
        print('🎯 Context available: ${context != null}');
        print('🎯 Context mounted: ${context?.mounted ?? false}');
        
        if (context != null && context.mounted && initialMessage.data.isNotEmpty) {
          try {
            final notificationService = StatusNotificationService();
            print('✅ Creating NotificationModel from initial FCM data...');
            
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
            
            print('✅ Calling handleNotificationTap from terminated state...');
            // Handle navigation
            await notificationService.handleNotificationTap(context, notification);
            print('✅ Navigation from terminated state completed');
          } catch (e, stackTrace) {
            print('❌ Error handling initial message: $e');
            print('❌ Stack trace: $stackTrace');
          }
        } else {
          print('⚠️ Cannot handle initial message:');
          print('   Context: ${context != null}');
          print('   Mounted: ${context?.mounted ?? false}');
          print('   Has data: ${initialMessage.data.isNotEmpty}');
        }
      } else {
        print('ℹ️ No initial message (app opened normally)');
      }
    } catch (e) {
      print('❌ Error checking initial message: $e');
    }
  }
  
  /// Parse payload string to Map
  Map<String, dynamic> _parsePayload(String payload) {
    try {
      // Payload format: "{key1: value1, key2: value2}"
      // Simple parsing (not JSON)
      final map = <String, dynamic>{};
      final cleaned = payload.replaceAll('{', '').replaceAll('}', '');
      final pairs = cleaned.split(', ');
      
      for (var pair in pairs) {
        final keyValue = pair.split(': ');
        if (keyValue.length == 2) {
          map[keyValue[0]] = keyValue[1];
        }
      }
      
      return map;
    } catch (e) {
      print('❌ Error parsing payload: $e');
      return {};
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
