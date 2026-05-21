import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:np_future_gate/core/theme/app_colors.dart';

class DraggableFloatingButton extends StatefulWidget {

  const DraggableFloatingButton({
    super.key,
    required this.onChatPressed,
    required this.onChatbotPressed,
  });
  final VoidCallback onChatPressed;
  final VoidCallback onChatbotPressed;

  @override
  State<DraggableFloatingButton> createState() =>
      _DraggableFloatingButtonState();
}

class _DraggableFloatingButtonState extends State<DraggableFloatingButton>
    with TickerProviderStateMixin {
  Offset? _position;
  bool _isExpanded = false;
  bool _isDragging = false;
  
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  void _snapToEdge(Size screenSize, double bottomPadding) {
    if (_position == null) return;

    double x = _position!.dx;
    double y = _position!.dy;

    // Magnet to edges
    if (x < screenSize.width / 2) {
      x = 16.0; // Left margin
    } else {
      x = screenSize.width - 76.0; // Right margin (60 button + 16 margin)
    }

    // Keep within vertical bounds
    y = y.clamp(80.0, screenSize.height - bottomPadding - 100.0);

    setState(() {
      _position = Offset(x, y);
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Default position: bottom-right
    final defaultPosition = Offset(
      screenSize.width - 76,
      screenSize.height - bottomPadding - 140,
    );

    final currentPosition = _position ?? defaultPosition;
    final isAtLeft = currentPosition.dx < screenSize.width / 2;

    return Stack(
      children: [
        // Overlay background when expanded
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleExpand,
              child: Container(color: Colors.transparent),
            ),
          ),

        // Menu items
        Positioned(
          left: isAtLeft ? currentPosition.dx + 70 : null,
          right: !isAtLeft ? (screenSize.width - currentPosition.dx) : null,
          top: currentPosition.dy - 10,
          child: FadeTransition(
            opacity: _expandAnimation,
            child: ScaleTransition(
              scale: _expandAnimation,
              alignment: isAtLeft ? Alignment.centerLeft : Alignment.centerRight,
              child: _buildExpandedMenu(isAtLeft),
            ),
          ),
        ),

        // Main Button
        AnimatedPositioned(
          duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          left: currentPosition.dx,
          top: currentPosition.dy,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onPanStart: (_) => setState(() => _isDragging = true),
              onPanUpdate: (details) {
                setState(() {
                  _position = Offset(
                    (currentPosition.dx + details.delta.dx).clamp(0.0, screenSize.width - 60.0),
                    (currentPosition.dy + details.delta.dy).clamp(0.0, screenSize.height - 60.0),
                  );
                });
              },
              onPanEnd: (_) => _snapToEdge(screenSize, bottomPadding),
              onTap: _toggleExpand,
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: _buildMainButton(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainButton() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating ring effect
              RotationTransition(
                turns: _pulseController,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _isExpanded ? Icons.close_rounded : Icons.auto_awesome,
                  key: ValueKey(_isExpanded),
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedMenu(bool isAtLeft) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuItem(
            icon: Icons.smart_toy_rounded,
            label: 'AI Assistant',
            color: AppColors.primaryPurple,
            onTap: () {
              _toggleExpand();
              widget.onChatbotPressed();
            },
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 30,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 8),
          _buildMenuItem(
            icon: Icons.chat_bubble_rounded,
            label: 'Support Chat',
            color: AppColors.primaryBlue,
            onTap: () {
              _toggleExpand();
              widget.onChatPressed();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

