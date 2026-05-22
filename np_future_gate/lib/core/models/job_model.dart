import 'package:np_future_gate/core/models/application_model.dart';

class JobModel { // Full profile data for admin


  JobModel({
    this.id,
    required this.creatorId,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.deadline,
    required this.metadata,
    this.applicants = const [],
    this.viewCount = 0,
    this.status = 'pending',
    this.creatorName,
    this.creatorAvatarUrl,
    this.creatorProfile,
   
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    final profileData = json['profiles'];
    Map<String, dynamic>? profile;

    if (profileData is List) {
      if (profileData.isNotEmpty) {
        profile = profileData.first as Map<String, dynamic>;
      }
    } else if (profileData is Map) {
      profile = Map<String, dynamic>.from(profileData);
    }

    return JobModel(
      id: json['id'],
      creatorId: json['creator_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      isActive: json['is_active'] ?? true,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      metadata: JobMetadata.fromJson(json['metadata'] ?? {}),
      applicants: (json['applicants'] as List<dynamic>?)
              ?.map((e) => JobApplication.fromJson(e))
              .toList() ??
          [],
      viewCount: json['view_count'] ?? 0,
      status: json['status'] ?? 'pending',
      creatorName: profile?['full_name'],
      creatorAvatarUrl: profile?['avatar_url'],
      creatorProfile: profile, // Store full profile
      
    );
  }
  final String? id;
  final String creatorId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final DateTime? deadline;
  final JobMetadata metadata;
  final List<JobApplication> applicants;
  final int viewCount;
  final String status; // 'pending', 'approved', 'rejected', 'closed'
  final String? creatorName;
  final String? creatorAvatarUrl;
  final Map<String, dynamic>? creatorProfile;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'creator_id': creatorId,
      'is_active': isActive,
      if (deadline != null) 'deadline': deadline!.toIso8601String(),
      'metadata': metadata.toJson(),
      'applicants': applicants.map((e) => e.toJson()).toList(),
      'view_count': viewCount,
      'status': status,
    };
  }

  JobModel copyWith({
    String? id,
    String? creatorId,
    bool? isActive,
    DateTime? deadline,
    JobMetadata? metadata,
    List<JobApplication>? applicants,
    String? status,
  }) {
    return JobModel(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive ?? this.isActive,
      deadline: deadline ?? this.deadline,
      metadata: metadata ?? this.metadata,
      applicants: applicants ?? this.applicants,
      viewCount: viewCount,
      status: status ?? this.status,
    );
  }
}

class JobMetadata {

  JobMetadata({
    required this.title,
    this.workingRegions = const [],
    this.experienceRequired = '',
    this.fields = const [],
    this.requirementsTags = const [],
    required this.salary,
    this.employmentTypes = const [],
    this.workLocations = const [],
    this.jobDescription = const [],
    this.candidateRequirements = const [],
    this.benefits = const [],
    this.isIntern = false,
  });

  factory JobMetadata.fromJson(Map<String, dynamic> json) {
    return JobMetadata(
      title: json['title'] ?? '',
      workingRegions: List<String>.from(json['working_regions'] ?? []),
      experienceRequired: json['experience_required'] ?? '',
      fields: List<String>.from(json['fields'] ?? []),
      requirementsTags: List<String>.from(json['requirements_tags'] ?? []),
      salary: JobSalary.fromJson(json['salary'] ?? {}),
      employmentTypes: List<String>.from(json['employment_types'] ?? []),
      workLocations: List<String>.from(json['work_locations'] ?? []),
      jobDescription: List<String>.from(json['job_description'] ?? []),
      candidateRequirements: List<String>.from(json['candidate_requirements'] ?? []),
      benefits: List<String>.from(json['benefits'] ?? []),
      isIntern: json['is_intern'] ?? false,
    );
  }
  final String title;
  final List<String> workingRegions;
  final String experienceRequired;
  final List<String> fields;
  final List<String> requirementsTags;
  final JobSalary salary;
  final List<String> employmentTypes;
  final List<String> workLocations;
  final List<String> jobDescription;
  final List<String> candidateRequirements;
  final List<String> benefits;
  final bool isIntern;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'working_regions': workingRegions,
      'experience_required': experienceRequired,
      'fields': fields,
      'requirements_tags': requirementsTags,
      'salary': salary.toJson(),
      'employment_types': employmentTypes,
      'work_locations': workLocations,
      'job_description': jobDescription,
      'candidate_requirements': candidateRequirements,
      'benefits': benefits,
      'is_intern': isIntern,
    };
  }
}

class JobSalary { // 'monthly', 'hourly', 'yearly'

  JobSalary({
    this.min,
    this.max,
    this.currency = 'VND',
    this.isNegotiable = false,
    this.type = 'monthly',
  });

  factory JobSalary.fromJson(Map<String, dynamic> json) {
    return JobSalary(
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      currency: json['currency'] ?? 'VND',
      isNegotiable: json['is_negotiable'] ?? false,
      type: json['type'] ?? 'monthly',
    );
  }
  final double? min;
  final double? max;
  final String currency;
  final bool isNegotiable;
  final String type;

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
      'currency': currency,
      'is_negotiable': isNegotiable,
      'type': type,
    };
  }
}

class JobApplication { // Additional recruitment tracking

  JobApplication({
    required this.userId,
    required this.cvId,
    required this.appliedAt,
    this.status = 'pending',
    this.recruitmentStatus,
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
      userId: json['user_id'],
      cvId: json['cv_id'],
      appliedAt: DateTime.parse(json['applied_at']),
      status: json['status'] ?? 'pending',
      recruitmentStatus: json['recruitment_status'],
    );
  }
  final String userId;
  final String cvId;
  final DateTime appliedAt;
  final String status; // 'pending', 'accepted', 'rejected'
  final String? recruitmentStatus;

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'cv_id': cvId,
      'applied_at': appliedAt.toIso8601String(),
      'status': status,
      if (recruitmentStatus != null) 'recruitment_status': recruitmentStatus,
    };
  }

  /// Converts this [JobApplication] to an [ApplicationModel] instance.
  ///
  /// Requires [jobId] since JobApplication does not store it directly
  /// (it's typically inferred from the parent JobModel).
  ApplicationModel toApplicationModel({required String jobId}) {
    return ApplicationModel(
      userId: userId,
      cvId: cvId,
      jobId: jobId,
      appliedAt: appliedAt,
      status: status,
      recruitmentStatus: recruitmentStatus,
    );
  }
}
