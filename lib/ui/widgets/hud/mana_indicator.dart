import 'dart:math';
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
    final totalIcons = max(currentMana, maxMana);
    double baseSize = 24.0;
    if (totalIcons > 5) {
      baseSize = (24.0 * 5 / totalIcons).clamp(12.0, 24.0);
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4.0,
      runSpacing: 4.0,
      children: List.generate(totalIcons, (index) {
        if (index < maxMana) {
          final isActive = index < currentMana;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Icon(
              Icons.diamond,
              color: isActive ? Colors.cyanAccent : Colors.white24,
              size: baseSize,
              shadows: isActive
                  ? [Shadow(color: Colors.cyanAccent, blurRadius: baseSize / 3)]
                  : null,
            ),
          );
        } else {
          // Mana de relique supplémentaire (index >= maxMana)
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.diamond,
                  color: Colors.black,
                  size: baseSize,
                ),
                Icon(
                  Icons.diamond_outlined,
                  color: Colors.cyanAccent,
                  size: baseSize,
                  shadows: [
                    Shadow(
                      color: Colors.cyanAccent,
                      blurRadius: baseSize / 3,
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      }),
    );
  }
}
