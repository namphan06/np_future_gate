import 'package:flutter/material.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';

/// Types of snackbar messages.
enum SnackBarType { success, error, info }

/// Shows a styled snackbar with consistent appearance across the app.
///
/// [context] - BuildContext for accessing ScaffoldMessenger.
/// [message] - The text to display in the snackbar.
/// [type] - Determines the color scheme (defaults to [SnackBarType.info]).
/// [action] - Optional callback for the action button.
/// [actionLabel] - Label for the action button (required if [action] is provided).
void showAppSnackBar(
  BuildContext context, {
  required String message,
  SnackBarType type = SnackBarType.info,
  VoidCallback? action,
  String? actionLabel,
}) {
  final color = switch (type) {
    SnackBarType.success => AppMainColors.success,
    SnackBarType.error => AppMainColors.error,
    SnackBarType.info => AppMainColors.info,
  };

  final icon = switch (type) {
    SnackBarType.success => Icons.check_circle_outline,
    SnackBarType.error => Icons.error_outline,
    SnackBarType.info => Icons.info_outline,
  };

  final snackBar = SnackBar(
    content: Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
    backgroundColor: color,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 3),
    action: action != null && actionLabel != null
        ? SnackBarAction(
            label: actionLabel,
            textColor: Colors.white,
            onPressed: action,
          )
        : null,
  );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}
