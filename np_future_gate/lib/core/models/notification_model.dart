import 'package:np_future_gate/notification/models/notification_config.dart';

/// Model đại diện cho một thông báo
class NotificationModel { // Thời gian đọc

  NotificationModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.recipientIds,
    required this.title,
    required this.content,
    this.actionCode,
    this.actionData,
    required this.isActive,
    required this.type,
    this.senderId,
    this.expiresAt,
    this.isRead = false,
    this.readAt,
  });

  /// Tạo NotificationModel từ JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      recipientIds: json['recipient_ids'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      actionCode: json['action_code'] as String?,
      actionData: json['action_data'] != null
          ? Map<String, dynamic>.from(json['action_data'])
          : null,
      isActive: json['is_active'] as bool? ?? true,
      type: _parseType(json['type'] as String?),
      senderId: json['sender_id'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
    );
  }
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String recipientIds;
  final String title;
  final String content;
  final String? actionCode;
  final Map<String, dynamic>? actionData;
  final bool isActive;
  final NotificationType type;
  final String? senderId;
  final DateTime? expiresAt;
  final bool isRead; // Trạng thái đã đọc (từ notification_reads)
  final DateTime? readAt;

  /// Chuyển NotificationModel sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'recipient_ids': recipientIds,
      'title': title,
      'content': content,
      'action_code': actionCode,
      'action_data': actionData,
      'is_active': isActive,
      'type': type.name,
      'sender_id': senderId,
      'expires_at': expiresAt?.toIso8601String(),
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
    };
  }

  /// Parse type từ string
  static NotificationType _parseType(String? typeStr) {
    if (typeStr == null) return NotificationType.info;
    try {
      return NotificationType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => NotificationType.info,
      );
    } catch (e) {
      return NotificationType.info;
    }
  }

  /// Lấy NotificationActionCode
  NotificationActionCode get actionCodeEnum {
    return NotificationActionCode.fromString(actionCode);
  }

  /// Kiểm tra có cần navigation không
  bool get requiresNavigation {
    return actionCodeEnum.requiresNavigation;
  }

  /// Kiểm tra có hết hạn không
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Lấy thời gian tương đối (VD: "2 giờ trước")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years năm trước';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months tháng trước';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  /// Copy với thông tin đã đọc
  NotificationModel copyWithRead({
    required bool isRead,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      recipientIds: recipientIds,
      title: title,
      content: content,
      actionCode: actionCode,
      actionData: actionData,
      isActive: isActive,
      type: type,
      senderId: senderId,
      expiresAt: expiresAt,
      isRead: isRead,
      readAt: readAt ?? this.readAt,
    );
  }

  /// Copy với các field khác
  NotificationModel copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? recipientIds,
    String? title,
    String? content,
    String? actionCode,
    Map<String, dynamic>? actionData,
    bool? isActive,
    NotificationType? type,
    String? senderId,
    DateTime? expiresAt,
    bool? isRead,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      recipientIds: recipientIds ?? this.recipientIds,
      title: title ?? this.title,
      content: content ?? this.content,
      actionCode: actionCode ?? this.actionCode,
      actionData: actionData ?? this.actionData,
      isActive: isActive ?? this.isActive,
      type: type ?? this.type,
      senderId: senderId ?? this.senderId,
      expiresAt: expiresAt ?? this.expiresAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }
}

/// Model để tạo notification mới
class CreateNotificationRequest {

  CreateNotificationRequest({
    required this.recipientIds,
    required this.title,
    required this.content,
    this.actionCode,
    this.actionData,
    this.type = NotificationType.info,
    this.senderId,
    this.expiresAt,
  });
  final String recipientIds; // 'all', uuid, hoặc JSON array
  final String title;
  final String content;
  final NotificationActionCode? actionCode;
  final Map<String, dynamic>? actionData;
  final NotificationType type;
  final String? senderId;
  final DateTime? expiresAt;

  Map<String, dynamic> toJson() {
    return {
      'recipient_ids': recipientIds,
      'title': title,
      'content': content,
      'action_code': actionCode?.code,
      'action_data': actionData,
      'type': type.name,
      'sender_id': senderId,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}
