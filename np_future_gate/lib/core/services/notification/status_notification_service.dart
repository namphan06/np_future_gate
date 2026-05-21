import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/notification_model.dart';
import 'package:np_future_gate/core/repositories/device_token_repository.dart';
import 'package:np_future_gate/core/repositories/notification_repository.dart';
import 'package:np_future_gate/core/services/push_notification_service.dart';
import 'package:np_future_gate/notification/models/notification_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    debugPrint('🔔 ========== handleNotificationTap START ==========');
    debugPrint('🔔 Notification ID: ${notification.id}');
    debugPrint('🔔 Action Code: ${notification.actionCode}');
    debugPrint('🔔 Action Data: ${notification.actionData}');
    
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
    
    debugPrint('🔔 Action Code Enum: ${actionCode.code}');
    debugPrint('🔔 Config found: ${config != null}');

    if (config == null) {
      // Không có config, show dialog mặc định
      debugPrint('⚠️ No config found, showing dialog');
      // ignore: use_build_context_synchronously
      _showNotificationDialog(context, notification);
      return false;
    }

    // Nếu config yêu cầu show dialog
    if (config.showDialog) {
      debugPrint('💬 Config requires dialog');
      _showNotificationDialog(
        // ignore: use_build_context_synchronously
        context,
        notification,
        dialogTitle: config.dialogTitle,
      );
      return false;
    }

    // Nếu cần navigation
    if (actionCode.requiresNavigation) {
      debugPrint('🧭 Navigation required');
      // Extract route params từ action_data
      final routeParams = config.extractRouteParams?.call(notification.actionData) ?? {};
      debugPrint('🧭 Route params: $routeParams');
      
      // Gọi callback navigate nếu có
      if (onNavigate != null) {
        debugPrint('✅ onNavigate callback is available');
        try {
          // ignore: use_build_context_synchronously
          await onNavigate!(context, actionCode, routeParams);
          debugPrint('✅ Navigation completed successfully');
          return true;
        } catch (e) {
          debugPrint('❌ Error navigating: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể mở trang này')),
            );
          }
        }
      } else {
        debugPrint('⚠️ onNavigate callback is NULL! Navigation not configured.');
        // Fallback: show dialog nếu chưa có callback
        // ignore: use_build_context_synchronously
        _showNotificationDialog(context, notification);
      }
      return false;
    }

    // Default: show dialog
    debugPrint('💬 Default: showing dialog');
    // ignore: use_build_context_synchronously
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
      debugPrint('Error getting current user ID: $e');
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
      debugPrint('📱 Sending push notification to user: $userId');
      
      // Lấy danh sách active device IDs
      final deviceIds = await _deviceTokenRepo.getActiveDeviceIds(
        userId: userId,
        role: role,
      );
      
      if (deviceIds.isEmpty) {
        debugPrint('ℹ️ No active devices found for user: $userId');
        return;
      }
      
      debugPrint('📱 Found ${deviceIds.length} device(s)');
      
      // Gửi notification đến tất cả devices của user
      final success = await PushNotificationService.sendNotificationToMultipleDevices(
        deviceTokens: deviceIds,
        title: title,
        body: body,
        data: data,
      );
      
      if (success) {
        debugPrint('✅ Push notifications sent to ${deviceIds.length} device(s)');
      } else {
        debugPrint('❌ Failed to send push notifications');
      }
    } catch (e) {
      debugPrint('❌ Error sending push notification: $e');
    }
  }

  /// Tạo thông báo khi có đơn ứng tuyển mới
  Future<void> notifyNewApplication({
    required String employerId,
    required String jobId,
    required String jobTitle,
    required String candidateName,
  }) async {
    const title = 'Đơn ứng tuyển mới';
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
    const title = 'Lịch phỏng vấn mới';
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
    const title = 'Công việc được duyệt';
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
    const title = 'Công việc bị từ chối';
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
    const title = 'Yêu cầu liên kết';
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
    const title = 'Nhắc nhở phỏng vấn';
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
