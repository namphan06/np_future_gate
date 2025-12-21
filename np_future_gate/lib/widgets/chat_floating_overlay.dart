import 'package:flutter/material.dart';
import '../screens/chat/chat_list_screen.dart';
import 'draggable_floating_button.dart';

class ChatFloatingOverlay extends StatelessWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const ChatFloatingOverlay({
    Key? key,
    required this.child,
    required this.navigatorKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          child,
          // Floating chat button hiển thị trên mọi màn hình
          DraggableFloatingButton(
            onChatPressed: () {
              // Sử dụng navigatorKey để access navigator
              navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => const ChatListScreen(),
                ),
              );
            },
            onChatbotPressed: () {
              // Sử dụng navigatorKey để access ScaffoldMessenger
              final context = navigatorKey.currentContext;
              if (context != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chatbot AI sẽ được triển khai sau'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
