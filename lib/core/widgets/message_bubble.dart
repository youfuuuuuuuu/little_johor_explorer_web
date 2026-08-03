import 'package:flutter/material.dart';

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
    return Text.rich(
      TextSpan(
        children: _parseMarkdownToSpans(message),
      ),
      style: TextStyle(
        fontSize: 14,
        height: 1.5,
        color: isUser ? Colors.white : const Color(0xFF2D2D2D),
      ),
    );
  }

  List<InlineSpan> _parseMarkdownToSpans(String rawText) {
    List<InlineSpan> spans = [];
    List<String> lines = rawText.split('\n');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      bool isHeader = false;
      bool isBullet = false;

      if (line.trim().startsWith('###')) {
        isHeader = true;
        line = line.replaceFirst('###', '').trim();
      } else if (line.trim().startsWith('-')) {
        isBullet = true;
        line = line.replaceFirst('-', '').trim();
      }

      List<TextSpan> inlineSpans = [];
      final RegExp exp = RegExp(r'\*\*(.*?)\*\*|\*(.*?)\*');

      line.splitMapJoin(
        exp,
        onMatch: (Match match) {
          if (match.group(1) != null) {
            inlineSpans.add(TextSpan(
              text: match.group(1),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isUser ? Colors.white : const Color(0xFF0A0A0A),
              ),
            ));
          } else if (match.group(2) != null) {
            inlineSpans.add(TextSpan(
              text: match.group(2),
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: isUser ? Colors.white70 : const Color(0xFF1D4ED8),
              ),
            ));
          }
          return '';
        },
        onNonMatch: (String nonMatch) {
          inlineSpans.add(TextSpan(text: nonMatch));
          return '';
        },
      );

      if (isHeader) {
        spans.add(TextSpan(
          children: inlineSpans,
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w900,
            color: isUser ? Colors.white : const Color(0xFF0A0A0A),
            height: 2.0,
          ),
        ));
      } else if (isBullet) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(left: 4, right: 8),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isUser ? Colors.white70 : Colors.purple.shade700,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
        spans.add(TextSpan(children: inlineSpans));
      } else {
        spans.add(TextSpan(children: inlineSpans));
      }
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans;
  }
}
