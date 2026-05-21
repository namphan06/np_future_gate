import 'package:flutter/material.dart';
import 'package:np_future_gate/core/theme/app_colors.dart';

/// Text styles cho ứng dụng NP FutureGate
/// Đảm bảo typography nhất quán trong toàn bộ ứng dụng
class AppTextStyles {
  AppTextStyles._();

  // Font family mặc định
  static const String _defaultFontFamily = 'Roboto';

  // ===== HEADING STYLES =====

  /// Heading 1 - Tiêu đề lớn nhất (32px, Bold)
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    fontFamily: _defaultFontFamily,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// Heading 2 - Tiêu đề phụ (28px, Bold)
  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    fontFamily: _defaultFontFamily,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.3,
  );

  /// Heading 3 - Tiêu đề section (24px, SemiBold)
  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    fontFamily: _defaultFontFamily,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// Heading 4 - Tiêu đề nhỏ (20px, SemiBold)
  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    fontFamily: _defaultFontFamily,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// Heading 5 - Tiêu đề card (18px, Medium)
  static const TextStyle h5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    fontFamily: _defaultFontFamily,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// Heading 6 - Tiêu đề nhỏ nhất (16px, Medium)
  static const TextStyle h6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: _defaultFontFamily,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // ===== BODY STYLES =====

  /// Body Large - Văn bản chính lớn (16px, Regular)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    fontFamily: _defaultFontFamily,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Body Medium - Văn bản chính (14px, Regular)
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    fontFamily: _defaultFontFamily,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Body Small - Văn bản phụ (12px, Regular)
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    fontFamily: _defaultFontFamily,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ===== LABEL STYLES =====

  /// Label Large - Nhãn lớn (14px, Medium)
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: _defaultFontFamily,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// Label Medium - Nhãn trung bình (12px, Medium)
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: _defaultFontFamily,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  /// Label Small - Nhãn nhỏ (10px, Medium)
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    fontFamily: _defaultFontFamily,
    color: AppColors.textSecondary,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // ===== BUTTON STYLES =====

  /// Button Large - Text cho button lớn (16px, SemiBold)
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: _defaultFontFamily,
    color: AppColors.textWhite,
    height: 1.2,
    letterSpacing: 0.5,
  );

  /// Button Medium - Text cho button trung bình (14px, SemiBold)
  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: _defaultFontFamily,
    color: AppColors.textWhite,
    height: 1.2,
    letterSpacing: 0.5,
  );

  /// Button Small - Text cho button nhỏ (12px, SemiBold)
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    fontFamily: _defaultFontFamily,
    color: AppColors.textWhite,
    height: 1.2,
    letterSpacing: 0.5,
  );

  // ===== SPECIAL STYLES =====

  /// Caption - Chú thích (12px, Regular)
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    fontFamily: _defaultFontFamily,
    color: AppColors.textHint,
    height: 1.3,
  );

  /// Overline - Text trên cùng (10px, Medium, Uppercase)
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    fontFamily: _defaultFontFamily,
    color: AppColors.textSecondary,
    height: 1.3,
    letterSpacing: 1.5,
  );

  /// Link - Text liên kết (14px, Medium, Blue)
  static const TextStyle link = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: _defaultFontFamily,
    color: AppColors.primaryBlue,
    height: 1.5,
    decoration: TextDecoration.underline,
  );

  /// Error - Text lỗi (12px, Regular, Red)
  static const TextStyle error = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    fontFamily: _defaultFontFamily,
    color: AppColors.error,
    height: 1.3,
  );

  /// Success - Text thành công (12px, Regular, Green)
  static const TextStyle success = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    fontFamily: _defaultFontFamily,
    color: AppColors.success,
    height: 1.3,
  );

  // ===== DISPLAY STYLES (for special cases) =====

  /// Display Large - Số lớn hoặc text nổi bật (48px, Bold)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    fontFamily: _defaultFontFamily,
    color: AppColors.textPrimary,
    height: 1.1,
    letterSpacing: -1,
  );

  /// Display Medium - Số hoặc text nổi bật (40px, Bold)
  static const TextStyle displayMedium = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.bold,
    fontFamily: _defaultFontFamily,
    color: AppColors.textPrimary,
    height: 1.1,
    letterSpacing: -0.5,
  );
}
