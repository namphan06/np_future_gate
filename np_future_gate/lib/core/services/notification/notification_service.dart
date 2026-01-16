import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/notification_model.dart';
import '../../../notification/models/notification_config.dart';
import '../../repositories/notification_repository.dart';

/// Service xử lý logic navigation và hiển thị thông báo
class NotificationService {
  final NotificationRepository _repository = NotificationRepository();

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

    if (config == null) {
      // Không có config, show dialog mặc định
      _showNotificationDialog(context, notification);
      return false;
    }

    // Nếu config yêu cầu show dialog
    if (config.showDialog) {
      _showNotificationDialog(
        context,
        notification,
        dialogTitle: config.dialogTitle,
      );
      return false;
    }

    // Nếu cần navigation
    if (actionCode.requiresNavigation) {
      // Extract route params từ action_data
      final routeParams = config.extractRouteParams?.call(notification.actionData) ?? {};
      
      // Gọi callback navigate nếu có
      if (onNavigate != null) {
        try {
          await onNavigate!(context, actionCode, routeParams);
          return true;
        } catch (e) {
          print('Error navigating: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể mở trang này')),
            );
          }
        }
      } else {
        // Fallback: show dialog nếu chưa có callback
        _showNotificationDialog(context, notification);
      }
      return false;
    }

    // Default: show dialog
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

  /// Tạo thông báo khi có đơn ứng tuyển mới
  Future<void> notifyNewApplication({
    required String employerId,
    required String jobId,
    required String jobTitle,
    required String candidateName,
  }) async {
    await _repository.createNotificationToUser(
      userId: employerId,
      title: 'Đơn ứng tuyển mới',
      content: '$candidateName đã ứng tuyển vào vị trí $jobTitle',
      actionCode: NotificationActionCode.applicationReceived,
      actionData: {'job_id': jobId},
      type: NotificationType.info,
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
    await _repository.createNotificationToUser(
      userId: candidateId,
      title: 'Lịch phỏng vấn mới',
      content: 'Bạn có lịch phỏng vấn cho vị trí $jobTitle vào ${_formatDateTime(interviewTime)}',
      actionCode: NotificationActionCode.interviewScheduled,
      actionData: {
        'interview_id': interviewId,
        'job_id': jobId,
      },
      type: NotificationType.requirement,
    );
  }

  /// Tạo thông báo khi công việc được duyệt
  Future<void> notifyJobApproved({
    required String employerId,
    required String jobId,
    required String jobTitle,
  }) async {
    await _repository.createNotificationToUser(
      userId: employerId,
      title: 'Công việc được duyệt',
      content: 'Tin tuyển dụng "$jobTitle" đã được phê duyệt',
      actionCode: NotificationActionCode.jobApproved,
      actionData: {'job_id': jobId},
      type: NotificationType.success,
    );
  }

  /// Tạo thông báo khi công việc bị từ chối
  Future<void> notifyJobRejected({
    required String employerId,
    required String jobId,
    required String jobTitle,
    required String reason,
  }) async {
    await _repository.createNotificationToUser(
      userId: employerId,
      title: 'Công việc bị từ chối',
      content: 'Tin tuyển dụng "$jobTitle" đã bị từ chối. Lý do: $reason',
      actionCode: NotificationActionCode.jobRejected,
      actionData: {'job_id': jobId},
      type: NotificationType.error,
    );
  }

  /// Tạo thông báo liên kết trường - doanh nghiệp
  Future<void> notifyPartnershipRequest({
    required String companyId,
    required String schoolName,
    required String partnershipId,
  }) async {
    await _repository.createNotificationToUser(
      userId: companyId,
      title: 'Yêu cầu liên kết',
      content: '$schoolName muốn liên kết với doanh nghiệp của bạn',
      actionCode: NotificationActionCode.partnershipRequest,
      actionData: {'partnership_id': partnershipId},
      type: NotificationType.requirement,
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
    await _repository.createNotificationToUser(
      userId: candidateId,
      title: 'Nhắc nhở phỏng vấn',
      content: 'Bạn có lịch phỏng vấn cho vị trí $jobTitle vào ngày mai lúc ${_formatDateTime(interviewTime)}',
      actionCode: NotificationActionCode.interviewReminder,
      actionData: {'interview_id': interviewId},
      type: NotificationType.reminder,
    );
  }

  /// Format DateTime sang dạng dễ đọc
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} lúc ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
