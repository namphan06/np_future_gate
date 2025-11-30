/// Auth Result
/// Kết quả trả về từ các thao tác auth
class AuthResult {
  final bool success;
  final String? message;
  final dynamic data;

  AuthResult({
    required this.success,
    this.message,
    this.data,
  });

  factory AuthResult.success({String? message, dynamic data}) {
    return AuthResult(
      success: true,
      message: message,
      data: data,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult(
      success: false,
      message: message,
    );
  }
}

/// User Role Enum
enum UserRole {
  candidate,
  employer,
  school;

  String get value => name;

  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (e) => e.name == role,
      orElse: () => UserRole.candidate,
    );
  }
}
