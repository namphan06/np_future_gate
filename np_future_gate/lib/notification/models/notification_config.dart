import 'package:flutter/material.dart';

/// Enum định nghĩa các loại thông báo
enum NotificationType {
  info,
  success,
  warning,
  error,
  announcement,
  requirement,
  reminder;

  String get displayName {
    switch (this) {
      case NotificationType.info:
        return 'Thông tin';
      case NotificationType.success:
        return 'Thành công';
      case NotificationType.warning:
        return 'Cảnh báo';
      case NotificationType.error:
        return 'Lỗi';
      case NotificationType.announcement:
        return 'Thông báo';
      case NotificationType.requirement:
        return 'Yêu cầu';
      case NotificationType.reminder:
        return 'Nhắc nhở';
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.success:
        return Colors.green;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.announcement:
        return Colors.purple;
      case NotificationType.requirement:
        return Colors.amber;
      case NotificationType.reminder:
        return Colors.teal;
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.info:
        return Icons.info_outline;
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.warning:
        return Icons.warning_amber;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.announcement:
        return Icons.campaign;
      case NotificationType.requirement:
        return Icons.assignment_outlined;
      case NotificationType.reminder:
        return Icons.notifications_active;
    }
  }
}

/// Enum định nghĩa các action code (mã hành động)
enum NotificationActionCode {
  // === JOB RELATED ===
  jobDetail('job_detail', 'Chi tiết công việc', requiresNavigation: true),
  jobApproved('job_approved', 'Công việc được duyệt', requiresNavigation: true),
  jobRejected('job_rejected', 'Công việc bị từ chối', requiresNavigation: true),
  newJobPosted('new_job_posted', 'Công việc mới', requiresNavigation: true),
  jobExpiring('job_expiring', 'Công việc sắp hết hạn', requiresNavigation: true),



  // === APPLICATION RELATED ===
  applicationReceived('application_received', 'Nhận đơn ứng tuyển', requiresNavigation: true),
  applicationApproved('application_approved', 'Đơn được chấp nhận', requiresNavigation: true),
  applicationRejected('application_rejected', 'Đơn bị từ chối', requiresNavigation: true),
  applicationViewed('application_viewed', 'Đơn được xem', requiresNavigation: true),

  // === INTERVIEW RELATED ===
  interviewScheduled('interview_schedule', 'Lịch phỏng vấn', requiresNavigation: true),
  interviewUpdated('interview_updated', 'Cập nhật lịch phỏng vấn', requiresNavigation: true),
  interviewCanceled('interview_canceled', 'Hủy phỏng vấn', requiresNavigation: true),
  interviewReminder('interview_reminder', 'Nhắc phỏng vấn', requiresNavigation: true),
  interviewEvaluated('interview_evaluated', 'Đánh giá phỏng vấn', requiresNavigation: true),

  // === PARTNERSHIP RELATED ===
  partnershipRequest('partnership_request', 'Yêu cầu liên kết', requiresNavigation: true),
  partnershipApproved('partnership_approved', 'Liên kết được duyệt', requiresNavigation: true),
  partnershipRejected('partnership_rejected', 'Liên kết bị từ chối', requiresNavigation: true),
  partnershipJobPosted('partnership_job_posted', 'Công việc liên kết mới', requiresNavigation: true),

  // === PROFILE RELATED ===
  profileViewed('profile_viewed', 'Hồ sơ được xem', requiresNavigation: true),
  profileFollowed('profile_followed', 'Người theo dõi mới', requiresNavigation: true),
  profileUpdated('profile_updated', 'Cập nhật hồ sơ', requiresNavigation: false),

  // === MESSAGE/CHAT RELATED ===
  newMessage('new_message', 'Tin nhắn mới', requiresNavigation: true),
  messageReply('message_reply', 'Trả lời tin nhắn', requiresNavigation: true),

  // === SYSTEM RELATED ===
  systemUpdate('system_update', 'Cập nhật hệ thống', requiresNavigation: false),
  systemMaintenance('system_maintenance', 'Bảo trì hệ thống', requiresNavigation: false),
  announcement('announcement', 'Thông báo chung', requiresNavigation: false),

  // === ADMIN RELATED ===
  adminReview('admin_review', 'Chờ duyệt', requiresNavigation: true),
  adminApproved('admin_approved', 'Admin phê duyệt', requiresNavigation: true),
  adminRejected('admin_rejected', 'Admin từ chối', requiresNavigation: true),

  // === PAYMENT/SUBSCRIPTION (future) ===
  paymentSuccess('payment_success', 'Thanh toán thành công', requiresNavigation: false),
  paymentFailed('payment_failed', 'Thanh toán thất bại', requiresNavigation: false),
  subscriptionExpiring('subscription_expiring', 'Gói dịch vụ sắp hết hạn', requiresNavigation: true),

  // === DEFAULT ===
  none('none', 'Không hành động', requiresNavigation: false);

  final String code;
  final String displayName;
  final bool requiresNavigation;

  // ignore: sort_constructors_first
  const NotificationActionCode(
    this.code,
    this.displayName, {
    required this.requiresNavigation,
  });

  /// Tìm action code từ string
  static NotificationActionCode fromString(String? code) {
    if (code == null) return NotificationActionCode.none;
    return NotificationActionCode.values.firstWhere(
      (e) => e.code == code,
      orElse: () => NotificationActionCode.none,
    );
  }

  /// Lấy icon phù hợp với action
  IconData get icon {
    if (code.contains('job')) return Icons.work_outline;
    if (code.contains('application')) return Icons.assignment_outlined;
    if (code.contains('interview')) return Icons.event;
    if (code.contains('partnership')) return Icons.handshake_outlined;
    if (code.contains('profile')) return Icons.person_outline;
    if (code.contains('message')) return Icons.message_outlined;
    if (code.contains('admin')) return Icons.admin_panel_settings_outlined;
    if (code.contains('payment') || code.contains('subscription')) {
      return Icons.payment;
    }
    if (code.contains('system') || code.contains('announcement')) {
      return Icons.info_outline;
    }
    return Icons.notifications_outlined;
  }
}

/// Config class chứa thông tin navigation cho mỗi action code
class NotificationActionConfig {

  const NotificationActionConfig({
    required this.actionCode,
    required this.routeName,
    this.extractRouteParams,
    this.showDialog = false,
    this.dialogTitle,
  });
  final NotificationActionCode actionCode;
  final String routeName;
  final Map<String, dynamic> Function(Map<String, dynamic>? actionData)?
      extractRouteParams;
  final bool showDialog;
  final String? dialogTitle;
}

/// Danh sách cấu hình navigation cho từng action code
class NotificationConfigs {
  static final Map<NotificationActionCode, NotificationActionConfig> configs = {
    // JOB RELATED
    NotificationActionCode.jobDetail: NotificationActionConfig(
      actionCode: NotificationActionCode.jobDetail,
      routeName: '/job-detail',
      extractRouteParams: (actionData) => {
        'jobId': actionData?['job_id'],
      },
    ),
    NotificationActionCode.jobApproved: NotificationActionConfig(
      actionCode: NotificationActionCode.jobApproved,
      routeName: '/job-detail',
      extractRouteParams: (actionData) => {
        'jobId': actionData?['job_id'],
      },
    ),
    NotificationActionCode.jobRejected: NotificationActionConfig(
      actionCode: NotificationActionCode.jobRejected,
      routeName: '/job-detail',
      extractRouteParams: (actionData) => {
        'jobId': actionData?['job_id'],
      },
    ),
    NotificationActionCode.newJobPosted: NotificationActionConfig(
      actionCode: NotificationActionCode.newJobPosted,
      routeName: '/job-detail',
      extractRouteParams: (actionData) => {
        'jobId': actionData?['job_id'],
      },
    ),

    // APPLICATION RELATED
    NotificationActionCode.applicationReceived: NotificationActionConfig(
      actionCode: NotificationActionCode.applicationReceived,
      routeName: '/job-applicants',
      extractRouteParams: (actionData) => {
        'jobId': actionData?['jobId'] ?? actionData?['job_id'], // Support both formats
        'userId': actionData?['userId'] ?? actionData?['user_id'],
        'candidateId': actionData?['userId'] ?? actionData?['candidateId'],
      },
    ),
    NotificationActionCode.applicationApproved: NotificationActionConfig(
      actionCode: NotificationActionCode.applicationApproved,
      routeName: '/job-detail',
      extractRouteParams: (actionData) => {
        'jobId': actionData?['jobId'] ?? actionData?['job_id'],
        'userId': actionData?['userId'] ?? actionData?['user_id'],
        'isApproved': true,
      },
    ),
    NotificationActionCode.applicationRejected: NotificationActionConfig(
      actionCode: NotificationActionCode.applicationRejected,
      routeName: '/job-detail',
      extractRouteParams: (actionData) => {
        'jobId': actionData?['jobId'] ?? actionData?['job_id'],
        'userId': actionData?['userId'] ?? actionData?['user_id'],
        'isApproved': false,
      },
    ),

    // INTERVIEW RELATED
    NotificationActionCode.interviewScheduled: NotificationActionConfig(
      actionCode: NotificationActionCode.interviewScheduled,
      routeName: '/interview-detail',
      extractRouteParams: (actionData) => {
        'interviewId': actionData?['interview_id'],
        'jobId': actionData?['job_id'],
      },
    ),
    NotificationActionCode.interviewReminder: NotificationActionConfig(
      actionCode: NotificationActionCode.interviewReminder,
      routeName: '/interview-detail',
      extractRouteParams: (actionData) => {
        'interviewId': actionData?['interview_id'],
      },
    ),

    // PARTNERSHIP RELATED
    NotificationActionCode.partnershipRequest: NotificationActionConfig(
      actionCode: NotificationActionCode.partnershipRequest,
      routeName: '/partnership-detail',
      extractRouteParams: (actionData) => {
        'partnershipId': actionData?['partnership_id'],
      },
    ),

    // PROFILE RELATED
    NotificationActionCode.profileViewed: NotificationActionConfig(
      actionCode: NotificationActionCode.profileViewed,
      routeName: '/profile',
      extractRouteParams: (actionData) => {
        'userId': actionData?['viewer_id'],
      },
    ),

    // MESSAGE RELATED
    NotificationActionCode.newMessage: NotificationActionConfig(
      actionCode: NotificationActionCode.newMessage,
      routeName: '/chat',
      extractRouteParams: (actionData) => {
        'chatId': actionData?['chat_id'],
        'userId': actionData?['sender_id'],
      },
    ),

    // SYSTEM - Show Dialog Only
    NotificationActionCode.systemUpdate: const NotificationActionConfig(
      actionCode: NotificationActionCode.systemUpdate,
      routeName: '',
      showDialog: true,
      dialogTitle: 'Cập nhật hệ thống',
    ),
    NotificationActionCode.announcement: const NotificationActionConfig(
      actionCode: NotificationActionCode.announcement,
      routeName: '',
      showDialog: true,
      dialogTitle: 'Thông báo',
    ),

    // DEFAULT
    NotificationActionCode.none: const NotificationActionConfig(
      actionCode: NotificationActionCode.none,
      routeName: '',
      showDialog: true,
    ),
  };

  /// Lấy config từ action code
  static NotificationActionConfig? getConfig(NotificationActionCode actionCode) {
    return configs[actionCode];
  }

  /// Lấy config từ action code string
  static NotificationActionConfig? getConfigFromString(String? actionCode) {
    if (actionCode == null) return null;
    final code = NotificationActionCode.fromString(actionCode);
    return getConfig(code);
  }
}
