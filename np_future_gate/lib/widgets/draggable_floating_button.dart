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
                  .clamp(0, screenWidth - (_buttonState == FloatingButtonState.minimized ? 16 : 48)),
              (_position.dy + details.delta.dy)
                  .clamp(0, screenHeight - (_buttonState == FloatingButtonState.minimized ? 80 : 48)),
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
        width: 4,  // Giảm từ 6 → 4
        height: 60,// Giảm từ 100 → 80
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade300, Colors.blue.shade500], // Màu nhẹ hơn
          ),
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 6,
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
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat',
                    isSelected: _currentMode == FloatingButtonMode.chat,
                    onTap: () => _switchMode(FloatingButtonMode.chat),
                    color: Colors.blue,
                  ),
                  Divider(height: 1, color: Colors.grey.shade200),
                  _buildMenuItem(
                    icon: Icons.smart_toy_outlined,
                    label: 'Chatbot AI',
                    isSelected: _currentMode == FloatingButtonMode.chatbot,
                    onTap: () => _switchMode(FloatingButtonMode.chatbot),
                    color: Colors.purple,
                  ),
                  Divider(height: 1, color: Colors.grey.shade200),
                  _buildMenuItem(
                    icon: Icons.remove,
                    label: 'Thu nhỏ',
                    isSelected: false,
                    onTap: _toggleMinimize,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        
        // Main button - Nhỏ gọn hơn
        GestureDetector(
          onTap: _toggleExpand,
          child: Container(
            width: 48,  // Giảm từ 60 → 48
            height: 48, // Giảm từ 60 → 48
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _buttonState == FloatingButtonState.expanded
                    ? Icons.close
                    : Icons.forum, // Icon chung cho cả chat & chatbot
                key: ValueKey(_buttonState == FloatingButtonState.expanded),
                color: Colors.white,
                size: 24, // Giảm từ 28 → 24
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
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: isSelected 
                    ? Border.all(color: color, width: 2)
                    : null,
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}
