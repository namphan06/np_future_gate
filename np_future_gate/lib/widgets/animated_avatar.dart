import 'dart:math' as math;

import 'package:flutter/material.dart';

/// AnimatedAvatar
/// Shows a placeholder icon while loading a network image and
/// smoothly transitions to the loaded image with a cross-fade
/// or an optional Y-axis flip.
class AnimatedAvatar extends StatefulWidget {
  final String? avatarUrl;
  final double width;
  final double height;
  final double borderRadius;
  final bool flipOnLoad;
  final Color placeholderColor;
  final IconData placeholderIcon;

  const AnimatedAvatar({
    super.key,
    required this.avatarUrl,
    this.width = 50,
    this.height = 50,
    this.borderRadius = 12,
    this.flipOnLoad = false,
    this.placeholderColor = const Color(0xFFF1F5F9),
    this.placeholderIcon = Icons.person_rounded,
  });

  @override
  State<AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<AnimatedAvatar> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loaded = false;
  }

  @override
  void didUpdateWidget(covariant AnimatedAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarUrl != widget.avatarUrl) {
      _loaded = false;
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: widget.placeholderColor,
      child: Center(
        child: Icon(widget.placeholderIcon, size: math.min(widget.width, widget.height) * 0.5, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.avatarUrl == null) return const SizedBox.shrink();

    final image = Image.network(
      widget.avatarUrl!,
      fit: BoxFit.cover,
      width: widget.width,
      height: widget.height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          if (!_loaded) {
            // mark loaded
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _loaded = true);
            });
          }
          return child;
        }
        return const SizedBox.shrink();
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder();
      },
    );

    if (widget.flipOnLoad) {
      // If flip is requested, when loaded animate rotation Y from pi/2 -> 0
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        transitionBuilder: (child, animation) {
          return AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, child) {
              final value = (1.0 - animation.value) * (math.pi / 2);
              return Transform(
                transform: Matrix4.rotationY(value),
                alignment: Alignment.center,
                child: child,
              );
            },
          );
        },
        child: _loaded ? image : const SizedBox.shrink(),
      );
    }

    // Default: cross-fade via AnimatedOpacity
    return AnimatedOpacity(
      opacity: _loaded ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: image,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Placeholder is visible until image is fully loaded
            AnimatedOpacity(
              opacity: _loaded ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _buildPlaceholder(),
            ),
            // Image (may be invisible until loaded)
            _buildImage(),
          ],
        ),
      ),
    );
  }
}
