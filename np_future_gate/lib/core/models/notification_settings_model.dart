/// Model cho notification settings
class NotificationSettingsModel {

  NotificationSettingsModel({
    this.enabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.jobNotifications = true,
    this.systemNotifications = true,
    this.messageNotifications = true,
    this.interviewNotifications = true,
    this.applicationNotifications = true,
    this.partnershipNotifications = true,
    NotificationTypesSettings? notificationTypes,
  }) : notificationTypes = notificationTypes ?? NotificationTypesSettings();

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      enabled: json['enabled'] as bool? ?? true,
      soundEnabled: json['sound_enabled'] as bool? ?? true,
      vibrationEnabled: json['vibration_enabled'] as bool? ?? true,
      jobNotifications: json['job_notifications'] as bool? ?? true,
      systemNotifications: json['system_notifications'] as bool? ?? true,
      messageNotifications: json['message_notifications'] as bool? ?? true,
      interviewNotifications: json['interview_notifications'] as bool? ?? true,
      applicationNotifications: json['application_notifications'] as bool? ?? true,
      partnershipNotifications: json['partnership_notifications'] as bool? ?? true,
      notificationTypes: json['notification_types'] != null
          ? NotificationTypesSettings.fromJson(json['notification_types'] as Map<String, dynamic>)
          : NotificationTypesSettings(),
    );
  }
  final bool enabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool jobNotifications;
  final bool systemNotifications;
  final bool messageNotifications;
  final bool interviewNotifications;
  final bool applicationNotifications;
  final bool partnershipNotifications;
  final NotificationTypesSettings notificationTypes;

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'sound_enabled': soundEnabled,
      'vibration_enabled': vibrationEnabled,
      'job_notifications': jobNotifications,
      'system_notifications': systemNotifications,
      'message_notifications': messageNotifications,
      'interview_notifications': interviewNotifications,
      'application_notifications': applicationNotifications,
      'partnership_notifications': partnershipNotifications,
      'notification_types': notificationTypes.toJson(),
    };
  }

  NotificationSettingsModel copyWith({
    bool? enabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? jobNotifications,
    bool? systemNotifications,
    bool? messageNotifications,
    bool? interviewNotifications,
    bool? applicationNotifications,
    bool? partnershipNotifications,
    NotificationTypesSettings? notificationTypes,
  }) {
    return NotificationSettingsModel(
      enabled: enabled ?? this.enabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      jobNotifications: jobNotifications ?? this.jobNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      interviewNotifications: interviewNotifications ?? this.interviewNotifications,
      applicationNotifications: applicationNotifications ?? this.applicationNotifications,
      partnershipNotifications: partnershipNotifications ?? this.partnershipNotifications,
      notificationTypes: notificationTypes ?? this.notificationTypes,
    );
  }
}

/// Model cho notification types settings
class NotificationTypesSettings {

  NotificationTypesSettings({
    this.info = true,
    this.error = true,
    this.success = true,
    this.warning = true,
    this.reminder = true,
    this.requirement = true,
    this.announcement = true,
  });

  factory NotificationTypesSettings.fromJson(Map<String, dynamic> json) {
    return NotificationTypesSettings(
      info: json['info'] as bool? ?? true,
      error: json['error'] as bool? ?? true,
      success: json['success'] as bool? ?? true,
      warning: json['warning'] as bool? ?? true,
      reminder: json['reminder'] as bool? ?? true,
      requirement: json['requirement'] as bool? ?? true,
      announcement: json['announcement'] as bool? ?? true,
    );
  }
  final bool info;
  final bool error;
  final bool success;
  final bool warning;
  final bool reminder;
  final bool requirement;
  final bool announcement;

  Map<String, dynamic> toJson() {
    return {
      'info': info,
      'error': error,
      'success': success,
      'warning': warning,
      'reminder': reminder,
      'requirement': requirement,
      'announcement': announcement,
    };
  }

  NotificationTypesSettings copyWith({
    bool? info,
    bool? error,
    bool? success,
    bool? warning,
    bool? reminder,
    bool? requirement,
    bool? announcement,
  }) {
    return NotificationTypesSettings(
      info: info ?? this.info,
      error: error ?? this.error,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      reminder: reminder ?? this.reminder,
      requirement: requirement ?? this.requirement,
      announcement: announcement ?? this.announcement,
    );
  }
}
