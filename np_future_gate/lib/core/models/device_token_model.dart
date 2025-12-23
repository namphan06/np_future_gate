/// Device Token Model
/// Model để lưu thông tin device token cho push notifications
class DeviceTokenModel {
  final String? id;
  final String deviceId; // FCM token hoặc APNS token
  final String userId;
  final String role;
  final String? deviceType; // 'ios' hoặc 'android'
  final String? deviceName;
  final String? appVersion;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DeviceTokenModel({
    this.id,
    required this.deviceId,
    required this.userId,
    required this.role,
    this.deviceType,
    this.deviceName,
    this.appVersion,
    this.isActive = true,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from JSON
  factory DeviceTokenModel.fromJson(Map<String, dynamic> json) {
    return DeviceTokenModel(
      id: json['id'] as String?,
      deviceId: json['device_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      deviceType: json['device_type'] as String?,
      deviceName: json['device_name'] as String?,
      appVersion: json['app_version'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'device_id': deviceId,
      'user_id': userId,
      'role': role,
      if (deviceType != null) 'device_type': deviceType,
      if (deviceName != null) 'device_name': deviceName,
      if (appVersion != null) 'app_version': appVersion,
      'is_active': isActive,
      if (lastLoginAt != null) 'last_login_at': lastLoginAt!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Copy with
  DeviceTokenModel copyWith({
    String? id,
    String? deviceId,
    String? userId,
    String? role,
    String? deviceType,
    String? deviceName,
    String? appVersion,
    bool? isActive,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeviceTokenModel(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      deviceType: deviceType ?? this.deviceType,
      deviceName: deviceName ?? this.deviceName,
      appVersion: appVersion ?? this.appVersion,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'DeviceTokenModel(id: $id, deviceId: $deviceId, userId: $userId, role: $role, deviceType: $deviceType, isActive: $isActive)';
  }
}
