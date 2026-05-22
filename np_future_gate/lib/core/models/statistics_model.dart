/// Model representing aggregated statistics data for admin reports.
///
/// Contains counts for users, jobs, applications, interviews,
/// period-specific metrics, and breakdowns by role/status.
class StatisticsModel {
  StatisticsModel({
    required this.totalUsers,
    required this.totalJobs,
    required this.totalApplications,
    required this.totalInterviews,
    required this.newUsersInPeriod,
    required this.newJobsInPeriod,
    required this.newApplicationsInPeriod,
    required this.applicationSuccessRate,
    required this.usersByRole,
    required this.jobsByStatus,
  });

  /// Creates a [StatisticsModel] from a JSON map.
  ///
  /// Throws [ArgumentError] if any required field is missing from [json].
  factory StatisticsModel.fromJson(Map<String, dynamic> json) {
    const requiredFields = [
      'total_users',
      'total_jobs',
      'total_applications',
      'total_interviews',
      'new_users_in_period',
      'new_jobs_in_period',
      'new_applications_in_period',
      'application_success_rate',
      'users_by_role',
      'jobs_by_status',
    ];

    for (final field in requiredFields) {
      if (!json.containsKey(field)) {
        throw ArgumentError(
          'Missing required field "$field" in StatisticsModel.fromJson',
        );
      }
    }

    return StatisticsModel(
      totalUsers: json['total_users'] as int,
      totalJobs: json['total_jobs'] as int,
      totalApplications: json['total_applications'] as int,
      totalInterviews: json['total_interviews'] as int,
      newUsersInPeriod: json['new_users_in_period'] as int,
      newJobsInPeriod: json['new_jobs_in_period'] as int,
      newApplicationsInPeriod: json['new_applications_in_period'] as int,
      applicationSuccessRate:
          (json['application_success_rate'] as num).toDouble(),
      usersByRole: Map<String, int>.from(json['users_by_role'] as Map),
      jobsByStatus: Map<String, int>.from(json['jobs_by_status'] as Map),
    );
  }

  final int totalUsers;
  final int totalJobs;
  final int totalApplications;
  final int totalInterviews;
  final int newUsersInPeriod;
  final int newJobsInPeriod;
  final int newApplicationsInPeriod;
  final double applicationSuccessRate;
  final Map<String, int> usersByRole;
  final Map<String, int> jobsByStatus;

  /// Converts this model to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'total_users': totalUsers,
      'total_jobs': totalJobs,
      'total_applications': totalApplications,
      'total_interviews': totalInterviews,
      'new_users_in_period': newUsersInPeriod,
      'new_jobs_in_period': newJobsInPeriod,
      'new_applications_in_period': newApplicationsInPeriod,
      'application_success_rate': applicationSuccessRate,
      'users_by_role': usersByRole,
      'jobs_by_status': jobsByStatus,
    };
  }

  /// Creates a copy of this model with the given fields replaced.
  StatisticsModel copyWith({
    int? totalUsers,
    int? totalJobs,
    int? totalApplications,
    int? totalInterviews,
    int? newUsersInPeriod,
    int? newJobsInPeriod,
    int? newApplicationsInPeriod,
    double? applicationSuccessRate,
    Map<String, int>? usersByRole,
    Map<String, int>? jobsByStatus,
  }) {
    return StatisticsModel(
      totalUsers: totalUsers ?? this.totalUsers,
      totalJobs: totalJobs ?? this.totalJobs,
      totalApplications: totalApplications ?? this.totalApplications,
      totalInterviews: totalInterviews ?? this.totalInterviews,
      newUsersInPeriod: newUsersInPeriod ?? this.newUsersInPeriod,
      newJobsInPeriod: newJobsInPeriod ?? this.newJobsInPeriod,
      newApplicationsInPeriod:
          newApplicationsInPeriod ?? this.newApplicationsInPeriod,
      applicationSuccessRate:
          applicationSuccessRate ?? this.applicationSuccessRate,
      usersByRole: usersByRole ?? this.usersByRole,
      jobsByStatus: jobsByStatus ?? this.jobsByStatus,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StatisticsModel) return false;
    return totalUsers == other.totalUsers &&
        totalJobs == other.totalJobs &&
        totalApplications == other.totalApplications &&
        totalInterviews == other.totalInterviews &&
        newUsersInPeriod == other.newUsersInPeriod &&
        newJobsInPeriod == other.newJobsInPeriod &&
        newApplicationsInPeriod == other.newApplicationsInPeriod &&
        applicationSuccessRate == other.applicationSuccessRate &&
        _mapsEqual(usersByRole, other.usersByRole) &&
        _mapsEqual(jobsByStatus, other.jobsByStatus);
  }

  @override
  int get hashCode {
    return Object.hash(
      totalUsers,
      totalJobs,
      totalApplications,
      totalInterviews,
      newUsersInPeriod,
      newJobsInPeriod,
      newApplicationsInPeriod,
      applicationSuccessRate,
      Object.hashAll(usersByRole.entries.map((e) => Object.hash(e.key, e.value))),
      Object.hashAll(jobsByStatus.entries.map((e) => Object.hash(e.key, e.value))),
    );
  }

  static bool _mapsEqual(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'StatisticsModel('
        'totalUsers: $totalUsers, '
        'totalJobs: $totalJobs, '
        'totalApplications: $totalApplications, '
        'totalInterviews: $totalInterviews, '
        'newUsersInPeriod: $newUsersInPeriod, '
        'newJobsInPeriod: $newJobsInPeriod, '
        'newApplicationsInPeriod: $newApplicationsInPeriod, '
        'applicationSuccessRate: $applicationSuccessRate, '
        'usersByRole: $usersByRole, '
        'jobsByStatus: $jobsByStatus)';
  }
}
