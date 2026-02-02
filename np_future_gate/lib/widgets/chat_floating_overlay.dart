import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/chatbot/chatbot_screen.dart';
import 'draggable_floating_button.dart';

class ChatFloatingOverlay extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const ChatFloatingOverlay({
    Key? key,
    required this.child,
    required this.navigatorKey,
  }) : super(key: key);

  @override
  State<ChatFloatingOverlay> createState() => _ChatFloatingOverlayState();
}

class _ChatFloatingOverlayState extends State<ChatFloatingOverlay> {
  bool _isLoggedIn = false;
  bool _isVisible = false; // Ẩn mặc định, hiển thị sau vài giây

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _listenAuthChanges();
    
    // Delay hiển thị button 1.5s sau khi vào màn hình (tránh hiện ngay khi login)
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _isLoggedIn) {
        setState(() => _isVisible = true);
      }
    });
  }

  void _checkAuthState() {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      _isLoggedIn = user != null;
    });
  }

  void _listenAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      setState(() {
        _isLoggedIn = session != null;
        // Reset visibility khi logout
        if (!_isLoggedIn) {
          _isVisible = false;
        } else {
          // Delay hiển thị khi login
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) setState(() => _isVisible = true);
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          widget.child,
          // Chỉ hiển thị floating button khi đã login VÀ visible
          if (_isLoggedIn && _isVisible)
            DraggableFloatingButton(
              onChatPressed: () {
                // Navigate to chat list
                widget.navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (context) => const ChatListScreen(),
                  ),
                );
              },
              onChatbotPressed: () {
                // Navigate to chatbot screen
                widget.navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (context) => const ChatbotScreen(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
