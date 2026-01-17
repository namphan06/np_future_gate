import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/notification_model.dart';
import '../../../notification/models/notification_config.dart';
import '../../repositories/notification_repository.dart';
import '../../repositories/device_token_repository.dart';
import '../push_notification_service.dart';

/// Service xử lý logic navigation và hiển thị thông báo
class StatusNotificationService {
  final NotificationRepository _repository = NotificationRepository();
  final DeviceTokenRepository _deviceTokenRepo = DeviceTokenRepository();

  // Callback để navigate đến các screen
  // Set từ bên ngoài khi khởi tạo app
  static Future<void> Function(BuildContext, NotificationActionCode, Map<String, dynamic>)? onNavigate;

  /// Xử lý khi user tap vào notification
  /// 
  /// Trả về true nếu cần navigate, false nếu chỉ show dialog
  Future<bool> handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
  ) async {
    print('🔔 ========== handleNotificationTap START ==========');
    print('🔔 Notification ID: ${notification.id}');
    print('🔔 Action Code: ${notification.actionCode}');
    print('🔔 Action Data: ${notification.actionData}');
    
    // Đánh dấu đã đọc
    final userId = await _getCurrentUserId();
    if (userId != null && !notification.isRead) {
      await _repository.markAsRead(
        notificationId: notification.id,
        userId: userId,
      );
    }

    // Lấy config từ action code
    final actionCode = notification.actionCodeEnum;
    final config = NotificationConfigs.getConfig(actionCode);
    
    print('🔔 Action Code Enum: ${actionCode.code}');
    print('🔔 Config found: ${config != null}');

    if (config == null) {
      // Không có config, show dialog mặc định
      print('⚠️ No config found, showing dialog');
      _showNotificationDialog(context, notification);
      return false;
    }

    // Nếu config yêu cầu show dialog
    if (config.showDialog) {
      print('💬 Config requires dialog');
      _showNotificationDialog(
        context,
        notification,
        dialogTitle: config.dialogTitle,
      );
      return false;
    }

    // Nếu cần navigation
    if (actionCode.requiresNavigation) {
      print('🧭 Navigation required');
      // Extract route params từ action_data
      final routeParams = config.extractRouteParams?.call(notification.actionData) ?? {};
      print('🧭 Route params: $routeParams');
      
      // Gọi callback navigate nếu có
      if (onNavigate != null) {
        print('✅ onNavigate callback is available');
        try {
          await onNavigate!(context, actionCode, routeParams);
          print('✅ Navigation completed successfully');
          return true;
        } catch (e) {
          print('❌ Error navigating: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể mở trang này')),
            );
          }
        }
      } else {
        print('⚠️ onNavigate callback is NULL! Navigation not configured.');
        // Fallback: show dialog nếu chưa có callback
        _showNotificationDialog(context, notification);
      }
      return false;
    }

    // Default: show dialog
    print('💬 Default: showing dialog');
    _showNotificationDialog(context, notification);
    return false;
  }

  /// Hiển thị dialog với nội dung thông báo
  void _showNotificationDialog(
    BuildContext context,
    NotificationModel notification, {
    String? dialogTitle,
  }) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogTitle ?? notification.title),
        content: SingleChildScrollView(
          child: Text(notification.content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Lấy user ID hiện tại
  Future<String?> _getCurrentUserId() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      return user?.id;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  /// Gửi push notification đến thiết bị của user
  Future<void> _sendPushNotificationToUser({
    required String userId,
    required String title,
    required String body,
    String? role,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('📱 Sending push notification to user: $userId');
      
      // Lấy danh sách active device IDs
      final deviceIds = await _deviceTokenRepo.getActiveDeviceIds(
        userId: userId,
        role: role,
      );
      
      if (deviceIds.isEmpty) {
        print('ℹ️ No active devices found for user: $userId');
        return;
      }
      
      print('📱 Found ${deviceIds.length} device(s)');
      
      // Gửi notification đến tất cả devices của user
      final success = await PushNotificationService.sendNotificationToMultipleDevices(
        deviceTokens: deviceIds,
        title: title,
        body: body,
        data: data,
      );
      
      if (success) {
        print('✅ Push notifications sent to ${deviceIds.length} device(s)');
      } else {
        print('❌ Failed to send push notifications');
      }
    } catch (e) {
      print('❌ Error sending push notification: $e');
    }
  }

  /// Tạo thông báo khi có đơn ứng tuyển mới
  Future<void> notifyNewApplication({
    required String employerId,
    required String jobId,
    required String jobTitle,
    required String candidateName,
  }) async {
    final title = 'Đơn ứng tuyển mới';
    final content = '$candidateName đã ứng tuyển vào vị trí $jobTitle';
    
    // Tạo thông báo trong database
    await _repository.createNotificationToUser(
      userId: employerId,
      title: title,
      content: content,
      actionCode: NotificationActionCode.applicationReceived,
      actionData: {'job_id': jobId},
      type: NotificationType.info,
    );
    
    // Gửi push notification đến thiết bị
    await _sendPushNotificationToUser(
      userId: employerId,
      title: title,
      body: content,
      role: 'employer',
      data: {
        'type': 'application_received',
        'action_code': NotificationActionCode.applicationReceived.code,
        'jobId': jobId,
      },
    );
  }

  /// Tạo thông báo khi có lịch phỏng vấn
  Future<void> notifyInterviewScheduled({
    required String candidateId,
    required String interviewId,
    required String jobId,
    required String jobTitle,
    required DateTime interviewTime,
  }) async {
    final title = 'Lịch phỏng vấn mới';
    final content = 'Bạn có lịch phỏng vấn cho vị trí $jobTitle vào ${_formatDateTime(interviewTime)}';
    
    // Tạo thông báo trong database
    await _repository.createNotificationToUser(
      userId: candidateId,
      title: title,
      content: content,
      actionCode: NotificationActionCode.interviewScheduled,
      actionData: {
        'interview_id': interviewId,
        'job_id': jobId,
      },
      type: NotificationType.requirement,
    );
    
    // Gửi push notification đến thiết bị
    await _sendPushNotificationToUser(
      userId: candidateId,
      title: title,
      body: content,
      role: 'candidate',
      data: {
        'type': 'interview_scheduled',
        'action_code': NotificationActionCode.interviewScheduled.code,
        'interviewId': interviewId,
        'jobId': jobId,
      },
    );
  }

  /// Tạo thông báo khi công việc được duyệt
  Future<void> notifyJobApproved({
    required String employerId,
    required String jobId,
    required String jobTitle,
  }) async {
    final title = 'Công việc được duyệt';
    final content = 'Tin tuyển dụng "$jobTitle" đã được phê duyệt';
    
    // Tạo thông báo trong database
    await _repository.createNotificationToUser(
      userId: employerId,
      title: title,
      content: content,
      actionCode: NotificationActionCode.jobApproved,
      actionData: {'job_id': jobId},
      type: NotificationType.success,
    );
    
    // Gửi push notification đến thiết bị
    await _sendPushNotificationToUser(
      userId: employerId,
      title: title,
      body: content,
      role: 'employer',
      data: {
        'type': 'job_approved',
        'action_code': NotificationActionCode.jobApproved.code,
        'jobId': jobId,
      },
    );
  }

  /// Tạo thông báo khi công việc bị từ chối
  Future<void> notifyJobRejected({
    required String employerId,
    required String jobId,
    required String jobTitle,
    required String reason,
  }) async {
    final title = 'Công việc bị từ chối';
    final content = 'Tin tuyển dụng "$jobTitle" đã bị từ chối. Lý do: $reason';
    
    // Tạo thông báo trong database
    await _repository.createNotificationToUser(
      userId: employerId,
      title: title,
      content: content,
      actionCode: NotificationActionCode.jobRejected,
      actionData: {'job_id': jobId},
      type: NotificationType.error,
    );
    
    // Gửi push notification đến thiết bị
    await _sendPushNotificationToUser(
      userId: employerId,
      title: title,
      body: content,
      role: 'employer',
      data: {
        'type': 'job_rejected',
        'action_code': NotificationActionCode.jobRejected.code,
        'jobId': jobId,
        'reason': reason,
      },
    );
  }

  /// Tạo thông báo liên kết trường - doanh nghiệp
  Future<void> notifyPartnershipRequest({
    required String companyId,
    required String schoolName,
    required String partnershipId,
  }) async {
    final title = 'Yêu cầu liên kết';
    final content = '$schoolName muốn liên kết với doanh nghiệp của bạn';
    
    // Tạo thông báo trong database
    await _repository.createNotificationToUser(
      userId: companyId,
      title: title,
      content: content,
      actionCode: NotificationActionCode.partnershipRequest,
      actionData: {'partnership_id': partnershipId},
      type: NotificationType.requirement,
    );
    
    // Gửi push notification đến thiết bị
    await _sendPushNotificationToUser(
      userId: companyId,
      title: title,
      body: content,
      role: 'employer',
      data: {
        'type': 'partnership_request',
        'action_code': NotificationActionCode.partnershipRequest.code,
        'partnershipId': partnershipId,
      },
    );
  }

  /// Tạo thông báo hệ thống cho tất cả
  Future<void> notifySystemUpdate({
    required String title,
    required String content,
  }) async {
    await _repository.createNotificationToAll(
      title: title,
      content: content,
      actionCode: NotificationActionCode.systemUpdate,
      type: NotificationType.announcement,
    );
  }

  /// Tạo thông báo nhắc phỏng vấn (trước 1 ngày)
  Future<void> notifyInterviewReminder({
    required String candidateId,
    required String interviewId,
    required String jobTitle,
    required DateTime interviewTime,
  }) async {
    final title = 'Nhắc nhở phỏng vấn';
    final content = 'Bạn có lịch phỏng vấn cho vị trí $jobTitle vào ngày mai lúc ${_formatDateTime(interviewTime)}';
    
    // Tạo thông báo trong database
    await _repository.createNotificationToUser(
      userId: candidateId,
      title: title,
      content: content,
      actionCode: NotificationActionCode.interviewReminder,
      actionData: {'interview_id': interviewId},
      type: NotificationType.reminder,
    );
    
    // Gửi push notification đến thiết bị
    await _sendPushNotificationToUser(
      userId: candidateId,
      title: title,
      body: content,
      role: 'candidate',
      data: {
        'type': 'interview_reminder',
        'action_code': NotificationActionCode.interviewReminder.code,
        'interviewId': interviewId,
      },
    );
  }

  /// Format DateTime sang dạng dễ đọc
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} lúc ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
