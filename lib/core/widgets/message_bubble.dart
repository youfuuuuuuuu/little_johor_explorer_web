import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.purple.shade400 : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: MarkdownBody(
          data: message,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: isUser ? Colors.white : Colors.black87,
              fontSize: 15,
              height: 1.5,
            ),
            strong: TextStyle(
              color: isUser ? Colors.white : Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            em: TextStyle(
              color: isUser ? Colors.white70 : Colors.black54,
              fontSize: 15,
              fontStyle: FontStyle.italic,
            ),
            listBullet: TextStyle(
              color: isUser ? Colors.white : Colors.purple.shade700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
