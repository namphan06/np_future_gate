class UserJobActivity {

  UserJobActivity({
    required this.id,
    required this.userId,
    required this.jobId,
    this.isSaved = false,
    this.isApplied = false,
    this.cvId,
    this.applicationStatus,
    this.appliedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserJobActivity.fromJson(Map<String, dynamic> json) {
    return UserJobActivity(
      id: json['id'],
      userId: json['user_id'],
      jobId: json['job_id'],
      isSaved: json['is_saved'] ?? false,
      isApplied: json['is_applied'] ?? false,
      cvId: json['cv_id'],
      applicationStatus: json['application_status'],
      appliedAt: json['applied_at'] != null ? DateTime.parse(json['applied_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
  final String id;
  final String userId;
  final String jobId;
  final bool isSaved;
  final bool isApplied;
  final String? cvId;
  final String? applicationStatus;
  final DateTime? appliedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'job_id': jobId,
      'is_saved': isSaved,
      'is_applied': isApplied,
      'cv_id': cvId,
      'application_status': applicationStatus,
      'applied_at': appliedAt?.toIso8601String(),
    };
  }
}
