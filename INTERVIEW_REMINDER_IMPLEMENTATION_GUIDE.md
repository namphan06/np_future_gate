# 🔔 Hướng dẫn Implement Interview Reminder Notifications

## Tổng quan
Hệ thống thông báo tự động gửi nhắc nhở lịch phỏng vấn cho cả **Employer** và **Candidate** trước 1 ngày và 1 giờ.

---

## 📦 Bước 1: Thêm Dependencies

Thêm vào `pubspec.yaml`:

```yaml
dependencies:
  flutter_local_notifications: ^17.0.0
  timezone: ^0.9.0
  permission_handler: ^11.0.0
```

Chạy:
```bash
flutter pub get
```

---

## 🔧 Bước 2: Cấu hình Android

### File: `android/app/src/main/AndroidManifest.xml`

Thêm permissions:
```xml
<manifest>
    <!-- Existing code -->
    
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    
    <application>
        <!-- Existing code -->
        
        <!-- Add receiver for boot completed -->
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
            </intent-filter>
        </receiver>
        
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
            android:exported="false" />
    </application>
</manifest>
```

---

## 🍎 Bước 3: Cấu hình iOS

### File: `ios/Runner/AppDelegate.swift`

```swift
import UIKit
import Flutter
import flutter_local_notifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Request notification permissions
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
        GeneratedPluginRegistrant.register(with: registry)
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### File: `ios/Runner/Info.plist`

Thêm:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

---

## 🚀 Bước 4: Initialize Notification Service

### File: `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'core/services/notification/interview_reminder_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone
  tz.initializeTimeZones();
  
  // Initialize notifications
  await _initializeNotifications();
  
  // ... existing Supabase init ...
  
  runApp(const MyApp());
}

Future<void> _initializeNotifications() async {
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
      // Handle notification tap
      if (response.payload != null) {
        _handleNotificationTap(response.payload!);
      }
    },
  );
  
  // Request permissions
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

void _handleNotificationTap(String payload) {
  // Navigate to interview detail
  if (payload.startsWith('interview:')) {
    final interviewId = payload.split(':')[1];
    // TODO: Navigate to interview detail screen
    print('Navigate to interview: $interviewId');
  }
}
```

---

## 🔄 Bước 5: Tích hợp vào InterviewRepository

### Update `lib/core/repositories/interview_repository.dart`

```dart
import '../services/notification/interview_reminder_service.dart';

class InterviewRepository {
  final InterviewReminderService _reminderService = InterviewReminderService();
  
  // ... existing code ...

  Future<void> createInterview({
    required String candidateId,
    required String jobId,
    required String employerId,
    String? cvId,
    required DateTime interviewTime,
    required String jobTitle,
    bool isPartnershipJob = false,
  }) async {
    try {
      await _client.from('interview_schedules').insert({
        'candidate_id': candidateId,
        'job_id': jobId,
        'employer_id': employerId,
        'cv_id': cvId,
        'interview_time': interviewTime.toUtc().toIso8601String(),
        'job_title': jobTitle,
        'status': 'scheduled',
        'evaluation': {},
      });

      // ✨ NEW: Schedule reminders for both employer and candidate
      final interview = InterviewModel(
        id: '', // Will be fetched from DB
        candidateId: candidateId,
        jobId: jobId,
        employerId: employerId,
        cvId: cvId,
        interviewTime: interviewTime,
        jobTitle: jobTitle,
        evaluation: {},
        status: 'scheduled',
        createdAt: DateTime.now(),
        isPartnership: isPartnershipJob,
        share: false,
      );

      // Get candidate name
      final candidateProfile = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', candidateId)
          .single();
      
      final candidateName = candidateProfile['full_name'] ?? 'Ứng viên';

      // Schedule for employer
      await _reminderService.scheduleInterviewReminders(
        interview: interview,
        candidateName: candidateName,
        isForEmployer: true,
      );

      // Schedule for candidate
      await _reminderService.scheduleInterviewReminders(
        interview: interview,
        candidateName: candidateName,
        isForEmployer: false,
      );

    } catch (e) {
      print('Error creating interview: $e');
      rethrow;
    }
  }

  Future<void> rescheduleInterview(String id, DateTime newTime) async {
    try {
      await _client.from('interview_schedules').update({
        'interview_time': newTime.toUtc().toIso8601String(),
        'status': 'scheduled',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);

      // ✨ NEW: Reschedule reminders
      final interviewData = await _client
          .from('interview_schedules')
          .select('''
            *,
            profiles!interview_schedules_candidate_id_fkey(full_name)
          ''')
          .eq('id', id)
          .single();

      final interview = InterviewModel.fromJson(interviewData);
      final candidateName = interviewData['profiles']['full_name'] ?? 'Ứng viên';

      // Reschedule for employer
      await _reminderService.rescheduleInterviewReminders(
        interview: interview,
        candidateName: candidateName,
        isForEmployer: true,
      );

      // Reschedule for candidate
      await _reminderService.rescheduleInterviewReminders(
        interview: interview,
        candidateName: candidateName,
        isForEmployer: false,
      );

    } catch (e) {
      print('Error rescheduling interview: $e');
      rethrow;
    }
  }

  Future<void> deleteInterview(String id) async {
    try {
      // ✨ NEW: Cancel reminders before deleting
      await _reminderService.cancelInterviewReminders(id, true);  // employer
      await _reminderService.cancelInterviewReminders(id, false); // candidate
      
      await _client.from('interview_schedules').delete().eq('id', id);
    } catch (e) {
      print('Error deleting interview: $e');
      rethrow;
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      await _client.from('interview_schedules').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);

      // ✨ NEW: Cancel reminders if status changed to completed/cancelled
      if (status == 'completed' || status == 'cancelled') {
        await _reminderService.cancelInterviewReminders(id, true);
        await _reminderService.cancelInterviewReminders(id, false);
      }
    } catch (e) {
      print('Error updating status: $e');
      rethrow;
    }
  }
}
```

---

## 📱 Bước 6: Sync Reminders khi App khởi động

### Update `lib/main.dart` hoặc home screen

```dart
class _HomeScreenState extends State<HomeScreen> {
  final InterviewReminderService _reminderService = InterviewReminderService();
  
  @override
  void initState() {
    super.initState();
    _syncReminders();
  }

  Future<void> _syncReminders() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Check if user is employer or candidate based on role
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();
    
    final isEmployer = profile['role'] == 'employer';

    // Sync all upcoming interview reminders
    await _reminderService.syncAllInterviewReminders(userId, isEmployer);
  }
}
```

---

## ✅ Tính năng đã có

1. ✅ **Thông báo trước 1 ngày** - Nhắc nhở chi tiết về lịch phỏng vấn
2. ✅ **Thông báo trước 1 giờ** - Nhắc nhở sắp bắt đầu
3. ✅ **Thông báo khi bắt đầu** - Thông báo đúng giờ phỏng vấn
4. ✅ **Cho cả Employer và Candidate** - Nội dung khác nhau cho từng vai trò
5. ✅ **Auto-sync khi app khởi động** - Đồng bộ lại tất cả lịch sắp tới
6. ✅ **Cancel khi xóa/hoàn thành** - Tự động hủy thông báo không cần thiết
7. ✅ **Reschedule khi đổi giờ** - Cập nhật thông báo theo lịch mới
8. ✅ **Work offline** - Notifications được schedule local, không cần internet

---

## 🧪 Testing

```dart
// Test manual
final testInterview = InterviewModel(
  id: 'test123',
  candidateId: 'candidate_id',
  jobId: 'job_id',
  employerId: 'employer_id',
  interviewTime: DateTime.now().add(Duration(minutes: 65)), // 1h5m từ bây giờ
  jobTitle: 'Flutter Developer',
  evaluation: {},
  status: 'scheduled',
  createdAt: DateTime.now(),
  isPartnership: false,
  share: false,
);

await InterviewReminderService().scheduleInterviewReminders(
  interview: testInterview,
  candidateName: 'Nguyễn Văn A',
  isForEmployer: true,
);
```

---

## 📊 Notification ID Format

- Format: `[interview_hash][type][user]`
- Example: `123461` = interview hash `12345` + type `1day` (1) + employer (1)
- Đảm bảo unique cho mỗi notification

---

## ⚠️ Lưu ý

1. **Android 13+**: Cần request runtime permission cho notifications
2. **iOS**: Cần user consent cho notifications
3. **Battery optimization**: Một số thiết bị có thể block exact alarms
4. **Timezone**: Đảm bảo timezone được init đúng
5. **Background restrictions**: Test trên real device

---

## 🔍 Troubleshooting

### Notification không hiện?
1. Check permissions: `Settings > Apps > Your App > Notifications`
2. Check battery optimization: Disable for your app
3. Check logs: `flutter logs | grep -i notification`

### Notification delay?
- Android có thể delay exact alarms nếu device ở battery saver mode
- Use `AndroidScheduleMode.exactAllowWhileIdle`

### Notification sau khi restart device?
- Android: Notifications bị clear, cần re-sync khi app mở
- iOS: Notifications được persist

---

## 📝 TODO (Optional enhancements)

- [ ] Add custom notification sound
- [ ] Add notification actions (Accept/Decline)
- [ ] Add notification grouping
- [ ] Add notification history
- [ ] Add snooze functionality
- [ ] Add notification settings UI

---

Đã hoàn tất! 🎉
