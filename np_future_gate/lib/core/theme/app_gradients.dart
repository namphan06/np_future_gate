import 'package:flutter/material.dart';
import 'package:np_future_gate/core/theme/app_colors.dart';

/// Các gradient màu cho ứng dụng NP FutureGate
/// Tạo hiệu ứng hiện đại, hướng về tương lai
class AppGradients {
  AppGradients._();

  // ===== GRADIENT CHÍNH =====
  
  /// Gradient xanh dương công nghệ - từ đậm đến nhạt
  static const LinearGradient primaryBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryBlueDark,
      AppColors.primaryBlue,
      AppColors.primaryBlueLight,
    ],
  );

  /// Gradient xanh lá năng lượng tương lai
  static const LinearGradient primaryGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryGreenDark,
      AppColors.primaryGreen,
      AppColors.primaryGreenLight,
    ],
  );

  /// Gradient tím sáng tạo
  static const LinearGradient primaryPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryPurpleDark,
      AppColors.primaryPurple,
      AppColors.primaryPurpleLight,
    ],
  );

  // ===== GRADIENT KẾT HỢP =====

  /// Gradient xanh dương -> xanh lá (công nghệ + tự nhiên)
  static const LinearGradient blueToGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryBlue,
      AppColors.secondaryCyan,
      AppColors.primaryGreen,
    ],
  );

  /// Gradient tím -> xanh dương (sáng tạo + công nghệ)
  static const LinearGradient purpleToBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryPurple,
      AppColors.primaryBlue,
      AppColors.primaryBlueLight,
    ],
  );

  /// Gradient xanh ngọc -> xanh lá (tươi mới)
  static const LinearGradient cyanToGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.secondaryCyan,
      AppColors.secondaryCyanLight,
      AppColors.primaryGreen,
    ],
  );

  /// Gradient cam -> hồng (năng động, nhiệt huyết)
  static const LinearGradient orangeToPink = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.secondaryOrange,
      AppColors.secondaryOrangeLight,
      AppColors.secondaryPink,
    ],
  );

  // ===== GRADIENT NỀN =====

  /// Gradient nền sáng cho toàn ứng dụng
  static const LinearGradient backgroundLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF5F7FA),
      Color(0xFFFFFFFF),
      Color(0xFFF5F7FA),
    ],
  );

  /// Gradient nền tối (dark mode)
  static const LinearGradient backgroundDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A237E),
      Color(0xFF263238),
      Color(0xFF1A237E),
    ],
  );

  /// Gradient cho card/surface
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF5F7FA),
    ],
  );

  // ===== GRADIENT ĐẶC BIỆT =====

  /// Gradient sunrise - bình minh tương lai
  static const LinearGradient sunrise = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFF6B6B),
      Color(0xFFFFD93D),
      Color(0xFF6BCB77),
      Color(0xFF4D96FF),
    ],
  );

  /// Gradient ocean - đại dương công nghệ
  static const LinearGradient ocean = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF667EEA),
      Color(0xFF64B6F7),
      Color(0xFF00D4FF),
    ],
  );

  /// Gradient neon - công nghệ tương lai
  static const LinearGradient neon = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00F5FF),
      Color(0xFF0080FF),
      Color(0xFF8000FF),
    ],
  );

  /// Gradient shimmer cho loading effect
  static const LinearGradient shimmer = LinearGradient(
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    colors: [
      Color(0xFFE0E0E0),
      Color(0xFFF5F5F5),
      Color(0xFFE0E0E0),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ===== GRADIENT OVERLAY =====

  /// Overlay tối cho ảnh nền
  static const LinearGradient darkOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00000000),
      Color(0x80000000),
    ],
  );

  /// Overlay sáng cho glass effect
  static const LinearGradient glassOverlay = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x40FFFFFF),
      Color(0x20FFFFFF),
    ],
  );
}
