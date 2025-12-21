import 'package:flutter/material.dart';

enum FloatingButtonMode {
  chat,
  chatbot,
}

enum FloatingButtonState {
  expanded,   // Hiển thị đầy đủ
  normal,     // Nút tròn bình thường
  minimized,  // Thu nhỏ thành thanh dọc
}

class DraggableFloatingButton extends StatefulWidget {
  final VoidCallback onChatPressed;
  final VoidCallback onChatbotPressed;
  final VoidCallback? onHide;
  final bool initiallyVisible;

  const DraggableFloatingButton({
    Key? key,
    required this.onChatPressed,
    required this.onChatbotPressed,
    this.onHide,
    this.initiallyVisible = true,
  }) : super(key: key);

  @override
  State<DraggableFloatingButton> createState() =>
      _DraggableFloatingButtonState();
}

class _DraggableFloatingButtonState extends State<DraggableFloatingButton>
    with SingleTickerProviderStateMixin {
  Offset _position = const Offset(20, 100);
  FloatingButtonState _buttonState = FloatingButtonState.normal;
  FloatingButtonMode _currentMode = FloatingButtonMode.chat;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    // Bắt đầu ở trạng thái minimized (rút gọn)
    _buttonState = FloatingButtonState.minimized;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      if (_buttonState == FloatingButtonState.minimized) {
        _buttonState = FloatingButtonState.normal;
      } else if (_buttonState == FloatingButtonState.normal) {
        _buttonState = FloatingButtonState.expanded;
        _animationController.forward();
      } else {
        _buttonState = FloatingButtonState.normal;
        _animationController.reverse();
      }
    });
  }

  void _toggleMinimize() {
    setState(() {
      if (_buttonState == FloatingButtonState.minimized) {
        _buttonState = FloatingButtonState.normal;
      } else {
        _buttonState = FloatingButtonState.minimized;
        _animationController.reverse();
      }
    });
  }

  void _switchMode(FloatingButtonMode mode) {
    setState(() {
      _currentMode = mode;
      _buttonState = FloatingButtonState.normal;
      _animationController.reverse();
    });

    if (mode == FloatingButtonMode.chat) {
      widget.onChatPressed();
    } else {
      widget.onChatbotPressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx)
                  .clamp(0, screenWidth - (_buttonState == FloatingButtonState.minimized ? 20 : 60)),
              (_position.dy + details.delta.dy)
                  .clamp(0, screenHeight - (_buttonState == FloatingButtonState.minimized ? 120 : 60)),
            );
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _buttonState == FloatingButtonState.minimized
              ? _buildMinimizedButton()
              : _buildNormalButton(),
        ),
      ),
    );
  }

  Widget _buildMinimizedButton() {
    return GestureDetector(
      onTap: _toggleMinimize,
      child: Container(
        width: 6,
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _currentMode == FloatingButtonMode.chat
                ? [Colors.blue.shade400, Colors.blue.shade600]
                : [Colors.purple.shade400, Colors.purple.shade600],
          ),
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: (_currentMode == FloatingButtonMode.chat
                      ? Colors.blue
                      : Colors.purple)
                  .withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Menu options
        if (_buttonState == FloatingButtonState.expanded)
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.chat,
                    label: 'Chat',
                    isSelected: _currentMode == FloatingButtonMode.chat,
                    onTap: () => _switchMode(FloatingButtonMode.chat),
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                      ],
                    ),
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: Colors.grey.shade200,
                  ),
                  _buildMenuItem(
                    icon: Icons.smart_toy,
                    label: 'Chatbot AI',
                    isSelected: _currentMode == FloatingButtonMode.chatbot,
                    onTap: () => _switchMode(FloatingButtonMode.chatbot),
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.shade400,
                        Colors.purple.shade600,
                      ],
                    ),
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: Colors.grey.shade200,
                  ),
                  _buildMenuItem(
                    icon: Icons.horizontal_rule,
                    label: 'Thu nhỏ',
                    isSelected: false,
                    onTap: _toggleMinimize,
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.shade400,
                        Colors.grey.shade600,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Main button
        GestureDetector(
          onTap: _toggleExpand,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _currentMode == FloatingButtonMode.chat
                    ? [Colors.blue.shade400, Colors.blue.shade600]
                    : [Colors.purple.shade400, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_currentMode == FloatingButtonMode.chat
                          ? Colors.blue
                          : Colors.purple)
                      .withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _buttonState == FloatingButtonState.expanded
                    ? Icons.close
                    : _currentMode == FloatingButtonMode.chat
                        ? Icons.chat_bubble
                        : Icons.smart_toy,
                key: ValueKey(_buttonState == FloatingButtonState.expanded 
                    ? 'close' 
                    : _currentMode.toString()),
                color: Colors.white,
                size: 28,
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
    required bool isSelected,
    required VoidCallback onTap,
    required Gradient gradient,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: isSelected ? gradient : null,
                color: isSelected ? null : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
