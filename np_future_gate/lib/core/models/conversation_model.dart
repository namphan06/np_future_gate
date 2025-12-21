class ConversationModel {
  final String id;
  final String participant1Id;
  final String participant1Type;
  final String participant2Id;
  final String participant2Type;
  final String? jobId;
  final String? applicationId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Thông tin bổ sung để hiển thị
  String? otherUserName;
  String? otherUserAvatar;
  int unreadCount;

  ConversationModel({
    required this.id,
    required this.participant1Id,
    required this.participant1Type,
    required this.participant2Id,
    required this.participant2Type,
    this.jobId,
    this.applicationId,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.otherUserName,
    this.otherUserAvatar,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      participant1Id: json['participant1_id'] as String,
      participant1Type: json['participant1_type'] as String,
      participant2Id: json['participant2_id'] as String,
      participant2Type: json['participant2_type'] as String,
      jobId: json['job_id'] as String?,
      applicationId: json['application_id'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      lastMessageSenderId: json['last_message_sender_id'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participant1_id': participant1Id,
      'participant1_type': participant1Type,
      'participant2_id': participant2Id,
      'participant2_type': participant2Type,
      'job_id': jobId,
      'application_id': applicationId,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'last_message_sender_id': lastMessageSenderId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ConversationModel copyWith({
    String? id,
    String? participant1Id,
    String? participant1Type,
    String? participant2Id,
    String? participant2Type,
    String? jobId,
    String? applicationId,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageSenderId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? otherUserName,
    String? otherUserAvatar,
    int? unreadCount,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      participant1Id: participant1Id ?? this.participant1Id,
      participant1Type: participant1Type ?? this.participant1Type,
      participant2Id: participant2Id ?? this.participant2Id,
      participant2Type: participant2Type ?? this.participant2Type,
      jobId: jobId ?? this.jobId,
      applicationId: applicationId ?? this.applicationId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
