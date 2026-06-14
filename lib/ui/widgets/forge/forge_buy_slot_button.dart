import 'package:flutter/material.dart';

class ForgeBuySlotButton extends StatelessWidget {
  final bool isEnabled;
  final String text;
  final VoidCallback onPressed;

  const ForgeBuySlotButton({
    super.key,
    required this.isEnabled,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEnabled ? onPressed : null,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isEnabled
              ? Colors.amber.withAlpha(25)
              : Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled
                ? Colors.amber.withAlpha(150)
                : Colors.white12,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: isEnabled ? Colors.amber : Colors.white30,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.white30,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
