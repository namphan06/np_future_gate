import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

/// Push Notification Service với FCM V1 API
/// Sử dụng OAuth2 authentication với Service Account
class PushNotificationService {
  static const String _projectId = 'npfuturegate';
  static String get _fcmEndpoint => 
    'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';
  
  static const String _serviceAccountPath = 
    'assets/npfuturegate-firebase-adminsdk-fbsvc-238b19fc92.json';

  /// Get OAuth2 access token from Service Account
  static Future<String> _getAccessToken() async {
    try {
      // Load service account JSON
      final serviceAccountJson = await rootBundle.loadString(_serviceAccountPath);
      final accountCredentials = ServiceAccountCredentials.fromJson(
        json.decode(serviceAccountJson),
      );
      
      // Define FCM scope
      const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      
      // Get authenticated client
      final authClient = await clientViaServiceAccount(
        accountCredentials,
        scopes,
      );
      
      // Get access token
      final accessToken = authClient.credentials.accessToken.data;
      
      // Close client
      authClient.close();
      
      print('✅ OAuth2 access token obtained');
      return accessToken;
    } catch (e) {
      print('❌ Error getting access token: $e');
      rethrow;
    }
  }

  /// Gửi notification đến một device token cụ thể
  static Future<bool> sendNotificationToDevice({
    required String deviceToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('═══════════════════════════════════════');
      print('📱 Sending FCM Notification');
      print('═══════════════════════════════════════');
      print('Token: ${deviceToken.substring(0, min(20, deviceToken.length))}...');
      print('Title: $title');
      print('Body: $body');
      print('───────────────────────────────────────');
      
      // Get OAuth2 token
      final accessToken = await _getAccessToken();
      
      // Convert all data values to strings (FCM requirement)
      final stringData = <String, String>{};
      data?.forEach((key, value) {
        stringData[key] = value.toString();
      });
      
      // Prepare FCM message
      final message = {
        'message': {
          'token': deviceToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': stringData,
          'android': {
            'priority': 'high',
            'notification': {
              'sound': 'default',
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'channel_id': 'fcm_channel',
            },
          },
          'apns': {
            'headers': {
              'apns-priority': '10',
            },
            'payload': {
              'aps': {
                'sound': 'default',
                'category': 'FLUTTER_NOTIFICATION_CLICK',
              },
            },
          },
        }
      };
      
      // Send to FCM
      final response = await http.post(
        Uri.parse(_fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );
      
      if (response.statusCode == 200) {
        print('✅ Notification sent successfully!');
        print('Response: ${response.body}');
        print('═══════════════════════════════════════\n');
        return true;
      } else {
        print('❌ Failed to send notification');
        print('Status: ${response.statusCode}');
        print('Response: ${response.body}');
        print('═══════════════════════════════════════\n');
        return false;
      }
    } catch (e) {
      print('❌ Error sending notification: $e');
      print('═══════════════════════════════════════\n');
      return false;
    }
  }

  /// Gửi notification đến nhiều devices
  static Future<bool> sendNotificationToMultipleDevices({
    required List<String> deviceTokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    print('📱 Sending to ${deviceTokens.length} devices\n');
    
    bool allSuccess = true;
    for (var i = 0; i < deviceTokens.length; i++) {
      print('Device ${i + 1}/${deviceTokens.length}:');
      final success = await sendNotificationToDevice(
        deviceToken: deviceTokens[i],
        title: title,
        body: body,
        data: data,
      );
      if (!success) allSuccess = false;
    }
    
    return allSuccess;
  }

  /// Gửi notification đến một topic
  static Future<bool> sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('═══════════════════════════════════════');
      print('📢 Sending to Topic: $topic');
      print('═══════════════════════════════════════');
      
      final accessToken = await _getAccessToken();
      
      // Convert all data values to strings (FCM requirement)
      final stringData = <String, String>{};
      data?.forEach((key, value) {
        stringData[key] = value.toString();
      });
      
      final message = {
        'message': {
          'topic': topic,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': stringData,
          'android': {
            'priority': 'high',
            'notification': {
              'sound': 'default',
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'channel_id': 'fcm_channel',
            },
          },
          'apns': {
            'headers': {
              'apns-priority': '10',
            },
            'payload': {
              'aps': {
                'sound': 'default',
                'category': 'FLUTTER_NOTIFICATION_CLICK',
              },
            },
          },
        }
      };
      
      final response = await http.post(
        Uri.parse(_fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );
      
      if (response.statusCode == 200) {
        print('✅ Topic notification sent!');
        print('═══════════════════════════════════════\n');
        return true;
      } else {
        print('❌ Failed: ${response.statusCode}');
        print('Response: ${response.body}');
        print('═══════════════════════════════════════\n');
        return false;
      }
    } catch (e) {
      print('❌ Error: $e');
      return false;
    }
  }
}

int min(int a, int b) => a < b ? a : b;
