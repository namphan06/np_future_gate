import 'package:flutter/material.dart';

/// App Colors - Tông màu chủ đạo xanh dương (Blue)
class AppMainColors {
  AppMainColors._();

  // Primary Blue Shades - Tông màu chủ đạo
  static const Color primary = Color(0xFF2196F3); // Material Blue 500
  static const Color primaryLight = Color(0xFF64B5F6); // Material Blue 300
  static const Color primaryDark = Color(0xFF1976D2); // Material Blue 700
  
  // Background Gradients - Các gradient nền
  static const Color backgroundStart = Color(0xFFE3F2FD); // Blue 50
  static const Color backgroundEnd = Color(0xFFBBDEFB); // Blue 100
  
  static const Color backgroundLightStart = Color(0xFFF5F9FF); // Very Light Blue
  static const Color backgroundLightEnd = Color(0xFFE8F4FD); // Light Blue
  
  // Surface Colors
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F9FF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Colors.white;
  
  // Accent Colors (vẫn trong tông xanh)
  static const Color accent = Color(0xFF0D47A1); // Blue 900
  static const Color accentLight = Color(0xFF42A5F5); // Blue 400
  
  // Status Colors (dùng tông xanh cho success)
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF03A9F4);
  
  // Shadow
  static Color shadow = Colors.black.withValues(alpha: 0.1);
  static Color shadowLight = Colors.black.withValues(alpha: 0.05);
  
  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundStart, backgroundEnd],
  );
  
  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundLightStart, backgroundLightEnd],
  );
}
