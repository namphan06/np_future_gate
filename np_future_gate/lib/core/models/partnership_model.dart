/// Model representing a partnership between a school and a company.
class PartnershipModel {
  PartnershipModel({
    required this.id,
    required this.schoolId,
    required this.companyId,
    required this.status,
    required this.postLimitCount,
    required this.postLimitPeriod,
    this.createdAt,
    this.updatedAt,
  })  : assert(
          status == 'pending' || status == 'approved' || status == 'rejected',
          'status must be one of: pending, approved, rejected',
        ),
        assert(
          postLimitPeriod == 'month' || postLimitPeriod == 'year',
          'postLimitPeriod must be one of: month, year',
        );

  factory PartnershipModel.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('id')) {
      throw ArgumentError('Missing required field: id');
    }
    if (!json.containsKey('school_id')) {
      throw ArgumentError('Missing required field: school_id');
    }
    if (!json.containsKey('company_id')) {
      throw ArgumentError('Missing required field: company_id');
    }
    if (!json.containsKey('status')) {
      throw ArgumentError('Missing required field: status');
    }
    if (!json.containsKey('post_limit_count')) {
      throw ArgumentError('Missing required field: post_limit_count');
    }
    if (!json.containsKey('post_limit_period')) {
      throw ArgumentError('Missing required field: post_limit_period');
    }

    final status = json['status'] as String;
    if (status != 'pending' && status != 'approved' && status != 'rejected') {
      throw ArgumentError(
        'Invalid status value: $status. Must be one of: pending, approved, rejected',
      );
    }

    final postLimitPeriod = json['post_limit_period'] as String;
    if (postLimitPeriod != 'month' && postLimitPeriod != 'year') {
      throw ArgumentError(
        'Invalid post_limit_period value: $postLimitPeriod. Must be one of: month, year',
      );
    }

    return PartnershipModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      companyId: json['company_id'] as String,
      status: status,
      postLimitCount: json['post_limit_count'] as int,
      postLimitPeriod: postLimitPeriod,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  final String id;
  final String schoolId;
  final String companyId;
  final String status; // 'pending', 'approved', 'rejected'
  final int postLimitCount;
  final String postLimitPeriod; // 'month', 'year'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'company_id': companyId,
      'status': status,
      'post_limit_count': postLimitCount,
      'post_limit_period': postLimitPeriod,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  PartnershipModel copyWith({
    String? id,
    String? schoolId,
    String? companyId,
    String? status,
    int? postLimitCount,
    String? postLimitPeriod,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PartnershipModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      companyId: companyId ?? this.companyId,
      status: status ?? this.status,
      postLimitCount: postLimitCount ?? this.postLimitCount,
      postLimitPeriod: postLimitPeriod ?? this.postLimitPeriod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PartnershipModel &&
        other.id == id &&
        other.schoolId == schoolId &&
        other.companyId == companyId &&
        other.status == status &&
        other.postLimitCount == postLimitCount &&
        other.postLimitPeriod == postLimitPeriod &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      schoolId,
      companyId,
      status,
      postLimitCount,
      postLimitPeriod,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'PartnershipModel(id: $id, schoolId: $schoolId, companyId: $companyId, '
        'status: $status, postLimitCount: $postLimitCount, '
        'postLimitPeriod: $postLimitPeriod, createdAt: $createdAt, '
        'updatedAt: $updatedAt)';
  }
}
