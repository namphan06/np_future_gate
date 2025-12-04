import 'auth_models.dart';

/// Profile Model
/// Đại diện cho thông tin user trong bảng profiles
class Profile {
  final String id;
  final String? email;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final UserRole role;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    this.email,
    this.fullName,
    this.avatarUrl,
    this.phone,
    required this.role,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Profile from JSON (Supabase response)
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'candidate'),
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert Profile to JSON (for Supabase update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'phone': phone,
      'role': role.value,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Profile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? phone,
    UserRole? role,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters for metadata fields
  DateTime? get dateOfBirth {
    final dob = metadata['date_of_birth'] as String?;
    return dob != null ? DateTime.tryParse(dob) : null;
  }

  String? get address => metadata['address'] as String?;
  
  List<String> get workLocations => 
      (metadata['work_locations'] as List?)?.map((e) => e.toString()).toList() ?? [];
      
  String? get education => metadata['education'] as String?;
  
  String? get bio => metadata['bio'] as String?; // Reason to hire
  
  List<String> get interestedFields => 
      (metadata['interested_fields'] as List?)?.map((e) => e.toString()).toList() ?? [];
      
  List<String> get workTypes => 
      (metadata['work_types'] as List?)?.map((e) => e.toString()).toList() ?? [];
      
  List<String> get cvIds => 
      (metadata['cv_ids'] as List?)?.map((e) => e.toString()).toList() ?? [];
      
  List<Map<String, dynamic>> get experience => 
      (metadata['experience'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
      
  bool get security => metadata['security'] as bool? ?? false;

  @override
  String toString() {
    return 'Profile(id: $id, email: $email, fullName: $fullName, role: ${role.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Profile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
