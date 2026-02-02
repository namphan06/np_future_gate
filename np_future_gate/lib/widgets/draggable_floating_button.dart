import 'package:flutter/material.dart';

class DraggableFloatingButton extends StatefulWidget {
  final VoidCallback onChatPressed;
  final VoidCallback onChatbotPressed;

  const DraggableFloatingButton({
    Key? key,
    required this.onChatPressed,
    required this.onChatbotPressed,
  }) : super(key: key);

  @override
  State<DraggableFloatingButton> createState() =>
      _DraggableFloatingButtonState();
}

class _DraggableFloatingButtonState extends State<DraggableFloatingButton>
    with SingleTickerProviderStateMixin {
  Offset? _position; // null = chưa set, sẽ dùng default bottom-right
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Default position: bottom-right corner (above navbar)
    final defaultPosition = Offset(
      screenWidth - 76, // 60 (button) + 16 (margin)
      screenHeight - bottomPadding - 160, // 60 (button) + 80 (navbar space)
    );

    final currentPosition = _position ?? defaultPosition;

    return Stack(
      children: [
        // Expanded menu - position absolute phía trên button
        if (_isExpanded)
          Positioned(
            right: screenWidth - currentPosition.dx - 65, // Căn phải với button
            bottom: screenHeight - currentPosition.dy + 12, // 12px phía trên button
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.bottomRight,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMenuItem(
                      icon: Icons.smart_toy_rounded,
                      label: 'Chatbot AI',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF4834DF)],
                      ),
                      onTap: () {
                        _toggleExpand();
                        widget.onChatbotPressed();
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.chat_bubble_rounded,
                      label: 'Chat',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                      ),
                      onTap: () {
                        _toggleExpand();
                        widget.onChatPressed();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Main button - position cố định
        Positioned(
          left: currentPosition.dx,
          top: currentPosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _position = Offset(
                  (currentPosition.dx + details.delta.dx)
                      .clamp(0.0, screenWidth - 60.0),
                  (currentPosition.dy + details.delta.dy)
                      .clamp(0.0, screenHeight - 60.0),
                );
              });
            },
            child: GestureDetector(
              onTap: _toggleExpand,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF42A5F5).withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return RotationTransition(
                      turns: Tween<double>(begin: 0.0, end: 0.125)
                          .animate(animation),
                      child: child,
                    );
                  },
                  child: Icon(
                    _isExpanded ? Icons.close_rounded : Icons.add_rounded,
                    key: ValueKey(_isExpanded),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: gradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 24,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
