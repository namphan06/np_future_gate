class EmployerResponseModel {
  final String? id;
  final String employerId;
  final String candidateId;
  final String? jobId;
  final String responseType; // 'accepted', 'rejected', 'interview', 'other'
  final String message;
  final List<EmailAttachment> attachments;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmployerResponseModel({
    this.id,
    required this.employerId,
    required this.candidateId,
    this.jobId,
    required this.responseType,
    required this.message,
    this.attachments = const [],
    this.metadata = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory EmployerResponseModel.fromJson(Map<String, dynamic> json) {
    return EmployerResponseModel(
      id: json['id'] as String?,
      employerId: json['employer_id'] as String,
      candidateId: json['candidate_id'] as String,
      jobId: json['job_id'] as String?,
      responseType: json['response_type'] as String,
      message: json['message'] as String,
      attachments: (json['attachments'] as List?)
              ?.map((e) => EmailAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'employer_id': employerId,
      'candidate_id': candidateId,
      if (jobId != null) 'job_id': jobId,
      'response_type': responseType,
      'message': message,
      'attachments': attachments.map((e) => e.toJson()).toList(),
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class EmailAttachment {
  final String url;
  final String type;
  final String name;
  final int size;

  EmailAttachment({
    required this.url,
    required this.type,
    required this.name,
    required this.size,
  });

  factory EmailAttachment.fromJson(Map<String, dynamic> json) {
    return EmailAttachment(
      url: json['url'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      size: json['size'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type,
      'name': name,
      'size': size,
    };
  }
}
