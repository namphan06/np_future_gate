import 'package:flutter/material.dart';
import '../services/demo_mode_service.dart';
import '../services/supabase_service.dart';

/// Test Account Protected Button
/// Automatically checks if user is test account and blocks action
/// Shows warning dialog if test account attempts to perform action
class TestProtectedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final String actionName;
  final ButtonStyle? style;
  final bool isElevatedButton;

  const TestProtectedButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.actionName,
    this.style,
    this.isElevatedButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return isElevatedButton
        ? ElevatedButton(
            onPressed: () => _handlePress(context),
            style: style,
            child: child,
          )
        : TextButton(
            onPressed: () => _handlePress(context),
            style: style,
            child: child,
          );
  }

  void _handlePress(BuildContext context) {
    final currentUser = SupabaseService.instance.currentUser;
    
    // Check if test account
    if (DemoModeService.instance.checkAndBlock(
      context,
      action: actionName,
      userEmail: currentUser?.email,
      userMetadata: currentUser?.userMetadata,
    )) {
      return; // Blocked
    }
    
    // Not blocked, execute action
    onPressed();
  }
}

/// Test Account Protected Icon Button
class TestProtectedIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Icon icon;
  final String actionName;
  final String? tooltip;

  const TestProtectedIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.actionName,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _handlePress(context),
      icon: icon,
      tooltip: tooltip,
    );
  }

  void _handlePress(BuildContext context) {
    final currentUser = SupabaseService.instance.currentUser;
    
    if (DemoModeService.instance.checkAndBlock(
      context,
      action: actionName,
      userEmail: currentUser?.email,
      userMetadata: currentUser?.userMetadata,
    )) {
      return;
    }
    
    onPressed();
  }
}

/// Test Account Protected Floating Action Button
class TestProtectedFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final String actionName;
  final String? tooltip;

  const TestProtectedFAB({
    super.key,
    required this.onPressed,
    required this.child,
    required this.actionName,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _handlePress(context),
      tooltip: tooltip,
      child: child,
    );
  }

  void _handlePress(BuildContext context) {
    final currentUser = SupabaseService.instance.currentUser;
    
    if (DemoModeService.instance.checkAndBlock(
      context,
      action: actionName,
      userEmail: currentUser?.email,
      userMetadata: currentUser?.userMetadata,
    )) {
      return;
    }
    
    onPressed();
  }
}

/// Manual check helper - for use in async functions or complex logic
Future<bool> checkTestAccount(BuildContext context, String action) async {
  final currentUser = SupabaseService.instance.currentUser;
  
  return DemoModeService.instance.checkAndBlock(
    context,
    action: action,
    userEmail: currentUser?.email,
    userMetadata: currentUser?.userMetadata,
  );
}
