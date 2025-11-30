import 'package:flutter/material.dart';

/// Màu sắc chính của ứng dụng NP FutureGate
/// Lấy cảm hứng từ logo với tông màu sáng, hiện đại hướng về tương lai
class AppColors {
  // Private constructor để ngăn khởi tạo
  AppColors._();

  // ===== MÀU CHÍNH (Primary Colors) =====
  // Màu xanh dương công nghệ - từ logo
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryBlueDark = Color(0xFF1976D2);
  static const Color primaryBlueLight = Color(0xFF64B5F6);
  
  // Màu xanh lá tương lai - năng lượng, phát triển
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryGreenDark = Color(0xFF388E3C);
  static const Color primaryGreenLight = Color(0xFF81C784);
  
  // Màu tím công nghệ - sáng tạo, đổi mới
  static const Color primaryPurple = Color(0xFF9C27B0);
  static const Color primaryPurpleDark = Color(0xFF7B1FA2);
  static const Color primaryPurpleLight = Color(0xFFBA68C8);

  // ===== MÀU PHỤ (Secondary Colors) =====
  // Màu cam năng động - nhiệt huyết
  static const Color secondaryOrange = Color(0xFFFF9800);
  static const Color secondaryOrangeLight = Color(0xFFFFB74D);
  
  // Màu xanh ngọc - thanh lịch, hiện đại
  static const Color secondaryCyan = Color(0xFF00BCD4);
  static const Color secondaryCyanLight = Color(0xFF4DD0E1);
  
  // Màu hồng - friendly, approachable
  static const Color secondaryPink = Color(0xFFE91E63);
  static const Color secondaryPinkLight = Color(0xFFF06292);

  // ===== MÀU NỀN (Background Colors) =====
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color backgroundGrey = Color(0xFFECEFF1);
  static const Color backgroundDark = Color(0xFF263238);
  
  // ===== MÀU VĂN BẢN (Text Colors) =====
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textDisabled = Color(0xFF9E9E9E);

  // ===== MÀU TRẠNG THÁI (Status Colors) =====
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // ===== MÀU VIỀN & DIVIDER =====
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFBDBDBD);
  static const Color shadow = Color(0x1A000000);

  // ===== MÀU ĐẶC BIỆT (Special Colors) =====
  // Màu highlight cho các phần tử nổi bật
  static const Color highlight = Color(0xFFFFEB3B);
  // Màu cho glass morphism effect
  static const Color glassWhite = Color(0x80FFFFFF);
  static const Color glassDark = Color(0x40000000);
}
