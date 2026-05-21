import 'package:flutter/material.dart';
import 'package:np_future_gate/core/theme/app_colors.dart';
import 'package:np_future_gate/core/theme/app_gradients.dart';
import 'package:np_future_gate/core/theme/app_text_styles.dart';

/// Custom Card với gradient background
class GradientCard extends StatelessWidget {

  const GradientCard({
    super.key,
    required this.child,
    this.gradient,
    this.padding,
    this.borderRadius,
    this.width,
    this.height,
  });
  final Widget child;
  final Gradient? gradient;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradients.cardGradient,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

/// Glass Morphism Card - hiệu ứng kính mờ hiện đại
class GlassCard extends StatelessWidget {

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.width,
    this.height,
    this.blur = 10,
    this.opacity = 0.2,
  });
  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final double blur;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: opacity),
              Colors.white.withValues(alpha: opacity * 0.5),
            ],
          ),
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

/// Info Card với icon và gradient
class InfoCard extends StatelessWidget {

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.gradient,
  });
  final IconData icon;
  final String title;
  final String value;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradient: gradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: gradient ?? AppGradients.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.textWhite,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.h4,
          ),
        ],
      ),
    );
  }
}
