import 'package:flutter/material.dart';

class ThinkingDots extends StatefulWidget {
  const ThinkingDots({super.key});

  @override
  State<ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<ThinkingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(0),
        _buildDot(300),
        _buildDot(600),
      ],
    );
  }

  Widget _buildDot(int delay) {
    return FadeTransition(
      opacity: TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.0), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.2), weight: 1),
      ]).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(delay / 1200, (delay + 600) / 1200,
              curve: Curves.easeInOut),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
