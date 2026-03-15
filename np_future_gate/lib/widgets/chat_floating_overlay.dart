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
  bool _isVisible = false; 

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _listenAuthChanges();
    
    // Đợi 2.5 giây để splash screen và các data ban đầu load xong
    _startDisplayTimer(2500);
  }

  void _startDisplayTimer(int milliseconds) {
    Future.delayed(Duration(milliseconds: milliseconds), () {
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
      final bool wasLoggedIn = _isLoggedIn;
      
      setState(() {
        _isLoggedIn = session != null;
        
        // Nếu vừa logout, ẩn ngay lập tức
        if (!_isLoggedIn) {
          _isVisible = false;
        } 
        // Nếu vừa login thành công, đợi 2s rồi mới hiện
        else if (!wasLoggedIn) {
          _startDisplayTimer(2000);
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
          // Sử dụng AnimatedOpacity để nút hiện ra mượt mà
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !(_isLoggedIn && _isVisible),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                opacity: (_isLoggedIn && _isVisible) ? 1.0 : 0.0,
                child: DraggableFloatingButton(
                  onChatPressed: () {
                    widget.navigatorKey.currentState?.push(
                      MaterialPageRoute(
                        builder: (context) => const ChatListScreen(),
                      ),
                    );
                  },
                  onChatbotPressed: () {
                    widget.navigatorKey.currentState?.push(
                      MaterialPageRoute(
                        builder: (context) => const ChatbotScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

