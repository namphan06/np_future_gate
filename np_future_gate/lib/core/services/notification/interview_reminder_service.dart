import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:np_future_gate/core/models/interview_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

/// Service để quản lý thông báo nhắc nhở lịch phỏng vấn
/// Gửi thông báo cho cả employer và candidate trước khi phỏng vấn
class InterviewReminderService {
  factory InterviewReminderService() => _instance;
  InterviewReminderService._internal();
  static final InterviewReminderService _instance = InterviewReminderService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Schedule reminder notifications for an interview
  /// Gửi thông báo trước 1 ngày và 1 giờ
  Future<void> scheduleInterviewReminders({
    required InterviewModel interview,
    required String candidateName,
    required bool isForEmployer,
  }) async {
    try {
      final now = DateTime.now();
      final interviewTime = interview.interviewTime;

      // Không schedule nếu thời gian phỏng vấn đã qua
      if (interviewTime.isBefore(now)) {
        debugPrint('⏰ Interview time is in the past, skipping reminders');
        return;
      }

      // Schedule 1 day before (24 hours)
      final oneDayBefore = interviewTime.subtract(const Duration(days: 1));
      if (oneDayBefore.isAfter(now)) {
        await _scheduleNotification(
          id: _getNotificationId(interview.id, '1day', isForEmployer),
          title: isForEmployer
              ? '📅 Nhắc nhở: Phỏng vấn ngày mai'
              : '📅 Nhắc nhở: Bạn có lịch phỏng vấn ngày mai',
          body: isForEmployer
              ? 'Phỏng vấn $candidateName - ${interview.jobTitle} vào lúc ${_formatTime(interviewTime)}'
              : 'Phỏng vấn vị trí ${interview.jobTitle} vào lúc ${_formatTime(interviewTime)}',
          scheduledTime: oneDayBefore,
          payload: 'interview:${interview.id}',
        );
        debugPrint('✅ Scheduled 1-day reminder for interview ${interview.id}');
      }

      // Schedule 1 hour before
      final oneHourBefore = interviewTime.subtract(const Duration(hours: 1));
      if (oneHourBefore.isAfter(now)) {
        await _scheduleNotification(
          id: _getNotificationId(interview.id, '1hour', isForEmployer),
          title: isForEmployer
              ? '⏰ Nhắc nhở: Phỏng vấn trong 1 giờ nữa'
              : '⏰ Nhắc nhở: Bạn có lịch phỏng vấn trong 1 giờ nữa',
          body: isForEmployer
              ? 'Phỏng vấn $candidateName - ${interview.jobTitle}'
              : 'Phỏng vấn vị trí ${interview.jobTitle}',
          scheduledTime: oneHourBefore,
          payload: 'interview:${interview.id}',
        );
        debugPrint('✅ Scheduled 1-hour reminder for interview ${interview.id}');
      }

      // Schedule notification at interview time
      await _scheduleNotification(
        id: _getNotificationId(interview.id, 'now', isForEmployer),
        title: isForEmployer
            ? '🎯 Phỏng vấn bắt đầu!'
            : '🎯 Lịch phỏng vấn của bạn đã bắt đầu!',
        body: isForEmployer
            ? 'Phỏng vấn $candidateName - ${interview.jobTitle}'
            : 'Phỏng vấn vị trí ${interview.jobTitle}',
        scheduledTime: interviewTime,
        payload: 'interview:${interview.id}',
      );
      debugPrint('✅ Scheduled start-time notification for interview ${interview.id}');

    } catch (e) {
      debugPrint('❌ Error scheduling interview reminders: $e');
    }
  }

  /// Schedule a single notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    try {
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'interview_reminders',
            'Nhắc nhở lịch phỏng vấn',
            channelDescription: 'Thông báo nhắc nhở về lịch phỏng vấn sắp tới',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(body),
            actions: [
              const AndroidNotificationAction(
                'view',
                'Xem chi tiết',
                showsUserInterface: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ Error scheduling notification $id: $e');
      rethrow;
    }
  }

  /// Cancel all reminders for an interview
  Future<void> cancelInterviewReminders(String interviewId, bool isForEmployer) async {
    try {
      await _notifications.cancel(_getNotificationId(interviewId, '1day', isForEmployer));
      await _notifications.cancel(_getNotificationId(interviewId, '1hour', isForEmployer));
      await _notifications.cancel(_getNotificationId(interviewId, 'now', isForEmployer));
      debugPrint('✅ Cancelled all reminders for interview $interviewId');
    } catch (e) {
      debugPrint('❌ Error cancelling interview reminders: $e');
    }
  }

  /// Generate unique notification ID
  /// Format: [interviewId hash][type][user type]
  int _getNotificationId(String interviewId, String type, bool isForEmployer) {
    final hash = interviewId.hashCode.abs() % 100000; // Limit to 5 digits
    final typeCode = type == '1day' ? 1 : (type == '1hour' ? 2 : 3);
    final userCode = isForEmployer ? 1 : 2;
    
    // Example: 12345 + 10 + 1 = 123461
    return hash * 100 + typeCode * 10 + userCode;
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    return '$day/$month - $hour:$minute';
  }

  /// Reschedule reminders when interview time is updated
  Future<void> rescheduleInterviewReminders({
    required InterviewModel interview,
    required String candidateName,
    required bool isForEmployer,
  }) async {
    // Cancel old reminders first
    await cancelInterviewReminders(interview.id, isForEmployer);
    
    // Schedule new reminders
    await scheduleInterviewReminders(
      interview: interview,
      candidateName: candidateName,
      isForEmployer: isForEmployer,
    );
  }

  /// Check and schedule reminders for all upcoming interviews
  /// Được gọi khi app khởi động hoặc định kỳ
  Future<void> syncAllInterviewReminders(String userId, bool isEmployer) async {
    try {
      debugPrint('🔄 Syncing interview reminders for user $userId...');

      final response = await _supabase
          .from('interview_schedules')
          .select('''
            *,
            profiles!interview_schedules_candidate_id_fkey(full_name)
          ''')
          .eq(isEmployer ? 'employer_id' : 'candidate_id', userId)
          .eq('status', 'scheduled')
          .gte('interview_time', DateTime.now().toUtc().toIso8601String());

      if (response.isEmpty) {
        debugPrint('✅ No upcoming interviews found');
        return;
      }

      for (final data in response as List) {
        try {
          final interview = InterviewModel.fromJson(data);
          final candidateName = isEmployer
              ? (data['profiles']?['full_name'] as String?) ?? 'Ứng viên'
              : 'Bạn';

          await scheduleInterviewReminders(
            interview: interview,
            candidateName: candidateName,
            isForEmployer: isEmployer,
          );
        } catch (e) {
          debugPrint('⚠️ Error processing interview ${data['id']}: $e');
        }
      }

      debugPrint('✅ Synced ${response.length} interview reminders');
    } catch (e) {
      debugPrint('❌ Error syncing interview reminders: $e');
    }
  }

  /// Check if notification permissions are granted
  Future<bool> checkPermissions() async {
    if (await _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled() ??
        false) {
      return true;
    }

    if (await _notifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
        false) {
      return true;
    }

    return false;
  }
}
