import 'package:flutter/material.dart' hide Badge;
import 'package:little_johor_explorer/data/models/badge.dart';

class BadgeWidget extends StatelessWidget {
  final Badge badge;

  const BadgeWidget({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Image.asset(
            badge.iconPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.broken_image, color: Colors.grey);
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          badge.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
