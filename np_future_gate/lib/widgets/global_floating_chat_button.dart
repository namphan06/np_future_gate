import 'package:flutter/material.dart';

class GlobalFloatingChatButton extends StatefulWidget {
  final Widget child;

  const GlobalFloatingChatButton({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<GlobalFloatingChatButton> createState() => GlobalFloatingChatButtonState();

  static GlobalFloatingChatButtonState? of(BuildContext context) {
    return context.findAncestorStateOfType<GlobalFloatingChatButtonState>();
  }
}

class GlobalFloatingChatButtonState extends State<GlobalFloatingChatButton> {
  bool _isVisible = true;

  void toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  void show() {
    setState(() {
      _isVisible = true;
    });
  }

  void hide() {
    setState(() {
      _isVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isVisible)
          const Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: SizedBox.shrink(),
            ),
          ),
      ],
    );
  }
}
