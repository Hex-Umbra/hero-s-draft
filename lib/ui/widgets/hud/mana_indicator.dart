import 'package:flutter/material.dart';

class ManaIndicator extends StatelessWidget {
  final int currentMana;
  final int maxMana;

  const ManaIndicator({
    super.key,
    required this.currentMana,
    required this.maxMana,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxMana, (index) {
        final isActive = index < currentMana;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Icon(
            Icons.diamond,
            color: isActive ? Colors.cyanAccent : Colors.white24,
            size: 24,
            shadows: isActive
                ? [const Shadow(color: Colors.cyanAccent, blurRadius: 8)]
                : null,
          ),
        );
      }),
    );
  }
}
