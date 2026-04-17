import 'package:flutter/material.dart';

class QuizOption extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool? isCorrect;
  final VoidCallback onTap;

  const QuizOption({
    super.key,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color getBackgroundColor() {
      if (isCorrect == true) return Colors.green[50]!;
      if (isCorrect == false) return Colors.red[50]!;
      if (isSelected) return Colors.deepPurple[50]!;
      return Colors.white;
    }

    Color getBorderColor() {
      if (isCorrect == true) return Colors.green;
      if (isCorrect == false) return Colors.red;
      if (isSelected) return Colors.deepPurple;
      return Colors.grey[300]!;
    }

    Color getTextColor() {
      if (isCorrect == true) return Colors.green[800]!;
      if (isCorrect == false) return Colors.red[800]!;
      if (isSelected) return Colors.deepPurple;
      return Colors.black87;
    }

    return GestureDetector(
      onTap: isCorrect == null ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 14.0, left: 4.0, right: 4.0),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        decoration: BoxDecoration(
          color: getBackgroundColor(),
          border: Border.all(color: getBorderColor(), width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.deepPurple.withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 8 : 4,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected || isCorrect != null
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: getTextColor(),
                ),
              ),
            ),
            if (isCorrect == true)
              const Icon(Icons.check_circle, color: Colors.green, size: 24),
            if (isCorrect == false)
              const Icon(Icons.cancel, color: Colors.red, size: 24),
            if (isCorrect == null && isSelected)
              const Icon(Icons.radio_button_checked,
                  color: Colors.deepPurple, size: 24),
            if (isCorrect == null && !isSelected)
              Icon(Icons.radio_button_unchecked,
                  color: Colors.grey[400], size: 24),
          ],
        ),
      ),
    );
  }
}
