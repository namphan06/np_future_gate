import 'package:flutter/material.dart';

/// Demo Mode Service - Updated for Real Account Switching
/// Manages switching between admin account and test accounts
/// Test accounts are REAL accounts in database with is_test_account flag
/// Admin signs out and signs into test account to preview UI

class DemoModeService {
  factory DemoModeService() => _instance;
  DemoModeService._internal();
  static final DemoModeService _instance = DemoModeService._internal();

  static DemoModeService get instance => _instance;

  // Test account credentials
  static const String testCandidateEmail = 'test-candidate@demo.com';
  static const String testEmployerEmail = 'test-employer@demo.com';
  static const String testSchoolEmail = 'test-school@demo.com';
  static const String testPassword = 'Demo123456!'; // Same password for all test accounts

  // Admin's original credentials (to return later)
  String? _adminEmail;

  String? get adminEmail => _adminEmail;

  /// Store admin credentials before switching to test account
  void storeAdminCredentials(String email, {String? password}) {
    _adminEmail = email;
  }

  /// Clear stored credentials
  void clearAdminCredentials() {
    _adminEmail = null;
  }

  /// Get test account email for a role
  String getTestEmail(String role) {
    switch (role) {
      case 'candidate':
        return testCandidateEmail;
      case 'employer':
        return testEmployerEmail;
      case 'school':
        return testSchoolEmail;
      default:
        return testCandidateEmail;
    }
  }

  /// Check if current user email is a test account
  bool isTestAccount(String? email) {
    if (email == null) return false;
    return email == testCandidateEmail ||
        email == testEmployerEmail ||
        email == testSchoolEmail;
  }

  /// Check if user is test account by metadata flag
  /// This should be called after fetching user profile
  bool isTestAccountByMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) return false;
    return metadata['is_test_account'] == true;
  }

  /// Get role name in Vietnamese
  String getRoleDisplayName(String role) {
    switch (role) {
      case 'candidate':
        return 'Ứng viên';
      case 'employer':
        return 'Nhà tuyển dụng';
      case 'school':
        return 'Nhà trường';
      default:
        return 'Demo';
    }
  }

  /// Show demo mode warning dialog
  void showDemoWarning(BuildContext context, {required String action}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600, size: 28),
            const SizedBox(width: 12),
            const Text('Tài khoản Demo'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bạn đang sử dụng tài khoản demo/test.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Không thể thực hiện: $action',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tài khoản demo chỉ cho phép xem giao diện, không thể thực hiện các thao tác thay đổi dữ liệu.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Check and block if current user is test account
  /// Returns true if blocked (is test account)
  bool checkAndBlock(BuildContext context, {
    required String action,
    String? userEmail,
    Map<String, dynamic>? userMetadata,
  }) {
    // Check by email
    if (userEmail != null && isTestAccount(userEmail)) {
      showDemoWarning(context, action: action);
      return true; // Blocked
    }

    // Check by metadata
    if (isTestAccountByMetadata(userMetadata)) {
      showDemoWarning(context, action: action);
      return true; // Blocked
    }

    return false; // Not blocked
  }
}
