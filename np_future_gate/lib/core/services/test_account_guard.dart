import 'package:flutter/material.dart';

/// Test Account Guard Service
/// Automatically detects test accounts after login
/// Blocks all CUD operations at repository level
class TestAccountGuard {
  static final TestAccountGuard _instance = TestAccountGuard._internal();
  factory TestAccountGuard() => _instance;
  TestAccountGuard._internal();

  static TestAccountGuard get instance => _instance;

  // Test account emails
  static const Set<String> testEmails = {
    'test-candidate@demo.com',
    'test-employer@demo.com',
    'test-school@demo.com',
  };

  // Current user state
  bool _isTestAccount = false;
  String? _currentUserEmail;

  /// Check if current session is test account
  bool get isTestAccount => _isTestAccount;
  
  /// Get current user email
  String? get currentUserEmail => _currentUserEmail;

  /// Initialize guard after login
  /// Call this in signInWithEmail after successful login
  void initialize(String? email, Map<String, dynamic>? metadata) {
    _currentUserEmail = email;
    
    // Check by email
    if (email != null && testEmails.contains(email.toLowerCase())) {
      _isTestAccount = true;
      debugPrint('🔒 Test Account detected: $email');
      return;
    }
    
    // Check by metadata flag
    if (metadata != null && metadata['is_test_account'] == true) {
      _isTestAccount = true;
      debugPrint('🔒 Test Account detected via metadata: $email');
      return;
    }
    
    _isTestAccount = false;
    debugPrint('✅ Normal account: $email');
  }

  /// Clear guard state (call on logout)
  void clear() {
    _isTestAccount = false;
    _currentUserEmail = null;
    debugPrint('🔓 Guard cleared');
  }

  /// Check and throw if test account attempts CUD operation
  /// Call this at the START of every Create/Update/Delete method
  void checkAndThrow(String operation) {
    if (_isTestAccount) {
      throw TestAccountException(
        'Tài khoản demo không thể thực hiện thao tác: $operation',
        operation: operation,
      );
    }
  }

  /// Check without throwing - returns true if blocked
  bool checkBlocked(String operation) {
    if (_isTestAccount) {
      debugPrint('❌ Blocked: $operation (Test Account: $_currentUserEmail)');
      return true;
    }
    return false;
  }
}

/// Custom exception for test account blocking
class TestAccountException implements Exception {
  final String message;
  final String operation;

  TestAccountException(this.message, {required this.operation});

  @override
  String toString() => message;
}
