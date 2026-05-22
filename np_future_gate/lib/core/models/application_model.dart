/// Standalone model representing a job application.
///
/// Extracted from [JobApplication] in job_model.dart to provide an independent
/// model with full serialization support and the additional [jobId] field
/// for standalone usage outside of a JobModel context.
class ApplicationModel {
  const ApplicationModel({
    required this.userId,
    required this.cvId,
    required this.jobId,
    required this.appliedAt,
    this.status = 'pending',
    this.recruitmentStatus,
  });

  /// Creates an [ApplicationModel] from a JSON map.
  ///
  /// Throws [ArgumentError] with a descriptive message if a required field
  /// is missing from the JSON map.
  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('user_id')) {
      throw ArgumentError('Missing required field "user_id" in ApplicationModel.fromJson');
    }
    if (!json.containsKey('cv_id')) {
      throw ArgumentError('Missing required field "cv_id" in ApplicationModel.fromJson');
    }
    if (!json.containsKey('job_id')) {
      throw ArgumentError('Missing required field "job_id" in ApplicationModel.fromJson');
    }
    if (!json.containsKey('applied_at')) {
      throw ArgumentError('Missing required field "applied_at" in ApplicationModel.fromJson');
    }

    return ApplicationModel(
      userId: json['user_id'] as String,
      cvId: json['cv_id'] as String,
      jobId: json['job_id'] as String,
      appliedAt: DateTime.parse(json['applied_at'] as String),
      status: (json['status'] as String?) ?? 'pending',
      recruitmentStatus: json['recruitment_status'] as String?,
    );
  }

  final String userId;
  final String cvId;
  final String jobId;
  final DateTime appliedAt;
  final String status; // 'pending', 'accepted', 'rejected'
  final String? recruitmentStatus;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'cv_id': cvId,
      'job_id': jobId,
      'applied_at': appliedAt.toIso8601String(),
      'status': status,
      if (recruitmentStatus != null) 'recruitment_status': recruitmentStatus,
    };
  }

  /// Creates a copy of this model with the given fields replaced.
  ApplicationModel copyWith({
    String? userId,
    String? cvId,
    String? jobId,
    DateTime? appliedAt,
    String? status,
    String? recruitmentStatus,
  }) {
    return ApplicationModel(
      userId: userId ?? this.userId,
      cvId: cvId ?? this.cvId,
      jobId: jobId ?? this.jobId,
      appliedAt: appliedAt ?? this.appliedAt,
      status: status ?? this.status,
      recruitmentStatus: recruitmentStatus ?? this.recruitmentStatus,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApplicationModel &&
        other.userId == userId &&
        other.cvId == cvId &&
        other.jobId == jobId &&
        other.appliedAt == appliedAt &&
        other.status == status &&
        other.recruitmentStatus == recruitmentStatus;
  }

  @override
  int get hashCode {
    return Object.hash(userId, cvId, jobId, appliedAt, status, recruitmentStatus);
  }

  @override
  String toString() {
    return 'ApplicationModel(userId: $userId, cvId: $cvId, jobId: $jobId, '
        'appliedAt: $appliedAt, status: $status, '
        'recruitmentStatus: $recruitmentStatus)';
  }
}
