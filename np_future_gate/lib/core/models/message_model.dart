class MessageModel {

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderType,
    required this.messageType,
    required this.content,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentSize,
    this.isEdited = false,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.senderName,
    this.senderAvatar,
    this.isSentByMe = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      senderType: json['sender_type'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      content: json['content'] as String,
      attachmentUrl: json['attachment_url'] as String?,
      attachmentName: json['attachment_name'] as String?,
      attachmentSize: json['attachment_size'] as int?,
      isEdited: json['is_edited'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  final String id;
  final String conversationId;
  final String senderId;
  final String senderType;
  final String messageType;
  final String content;
  final String? attachmentUrl;
  final String? attachmentName;
  final int? attachmentSize;
  final bool isEdited;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Thông tin bổ sung để hiển thị
  String? senderName;
  String? senderAvatar;
  bool isSentByMe;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_type': senderType,
      'message_type': messageType,
      'content': content,
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
      'attachment_size': attachmentSize,
      'is_edited': isEdited,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderType,
    String? messageType,
    String? content,
    String? attachmentUrl,
    String? attachmentName,
    int? attachmentSize,
    bool? isEdited,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? senderName,
    String? senderAvatar,
    bool? isSentByMe,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentSize: attachmentSize ?? this.attachmentSize,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      isSentByMe: isSentByMe ?? this.isSentByMe,
    );
  }
}
