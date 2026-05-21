import 'package:flutter/material.dart';
import 'package:np_future_gate/core/theme/app_colors.dart';
import 'package:np_future_gate/core/theme/app_gradients.dart';
import 'package:np_future_gate/core/theme/app_text_styles.dart';

/// Custom Gradient Button với hiệu ứng đẹp mắt
class GradientButton extends StatelessWidget {

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradient,
    this.width,
    this.height = 50,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.icon,
    this.isLoading = false,
  });
  final String text;
  final VoidCallback onPressed;
  final Gradient? gradient;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final TextStyle? textStyle;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradients.primaryBlue,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: AppColors.textWhite, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          text,
                          style: textStyle ?? AppTextStyles.buttonMedium,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined Button với gradient border
class GradientOutlinedButton extends StatelessWidget {

  const GradientOutlinedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradient,
    this.width,
    this.height = 50,
    this.borderRadius,
    this.borderWidth = 2,
    this.textStyle,
    this.icon,
  });
  final String text;
  final VoidCallback onPressed;
  final Gradient? gradient;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final double borderWidth;
  final TextStyle? textStyle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradients.primaryBlue,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(borderWidth),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12 - borderWidth),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return (gradient ?? AppGradients.primaryBlue)
                            .createShader(bounds);
                      },
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return (gradient ?? AppGradients.primaryBlue)
                          .createShader(bounds);
                    },
                    child: Text(
                      text,
                      style: (textStyle ?? AppTextStyles.buttonMedium)
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon Button với gradient background
class GradientIconButton extends StatelessWidget {

  const GradientIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.gradient,
    this.size = 48,
    this.iconSize = 24,
  });
  final IconData icon;
  final VoidCallback onPressed;
  final Gradient? gradient;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradients.primaryBlue,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              icon,
              color: AppColors.textWhite,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}

/// Text Button với gradient text
class GradientTextButton extends StatelessWidget {

  const GradientTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradient,
    this.textStyle,
    this.icon,
  });
  final String text;
  final VoidCallback onPressed;
  final Gradient? gradient;
  final TextStyle? textStyle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            ShaderMask(
              shaderCallback: (bounds) {
                return (gradient ?? AppGradients.primaryBlue)
                    .createShader(bounds);
              },
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          ShaderMask(
            shaderCallback: (bounds) {
              return (gradient ?? AppGradients.primaryBlue).createShader(bounds);
            },
            child: Text(
              text,
              style: (textStyle ?? AppTextStyles.buttonMedium)
                  .copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
