class InterviewModel {

  InterviewModel({
    required this.id,
    required this.candidateId,
    required this.jobId,
    required this.employerId,
    this.cvId,
    required this.interviewTime,
    required this.jobTitle,
    required this.evaluation,
    required this.status,
    required this.createdAt,
    this.isPartnership = false,
    this.share = false,
  });

  factory InterviewModel.fromJson(Map<String, dynamic> json) {
    return InterviewModel(
      id: json['id'],
      candidateId: json['candidate_id'],
      jobId: json['job_id'],
      employerId: json['employer_id'],
      cvId: json['cv_id'],
      interviewTime: DateTime.parse(json['interview_time']).toLocal(),
      jobTitle: json['job_title'],
      evaluation: json['evaluation'] ?? {},
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      isPartnership: json['is_partnership'] ?? false,
      share: json['share'] ?? false,
    );
  }
  final String id;
  final String candidateId;
  final String jobId;
  final String employerId;
  final String? cvId;
  final DateTime interviewTime;
  final String jobTitle;
  final Map<String, dynamic> evaluation;
  final String status;
  final DateTime createdAt;
  final bool isPartnership;
  final bool share;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'candidate_id': candidateId,
      'job_id': jobId,
      'employer_id': employerId,
      'cv_id': cvId,
      'interview_time': interviewTime.toIso8601String(),
      'job_title': jobTitle,
      'evaluation': evaluation,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'is_partnership': isPartnership,
      'share': share,
    };
  }

  InterviewModel copyWith({
    String? id,
    String? candidateId,
    String? jobId,
    String? employerId,
    String? cvId,
    DateTime? interviewTime,
    String? jobTitle,
    Map<String, dynamic>? evaluation,
    String? status,
    DateTime? createdAt,
    bool? isPartnership,
    bool? share,
  }) {
    return InterviewModel(
      id: id ?? this.id,
      candidateId: candidateId ?? this.candidateId,
      jobId: jobId ?? this.jobId,
      employerId: employerId ?? this.employerId,
      cvId: cvId ?? this.cvId,
      interviewTime: interviewTime ?? this.interviewTime,
      jobTitle: jobTitle ?? this.jobTitle,
      evaluation: evaluation ?? this.evaluation,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isPartnership: isPartnership ?? this.isPartnership,
      share: share ?? this.share,
    );
  }
}
