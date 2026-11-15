import 'dart:math';
import 'package:flutter/material.dart';

class ManaIndicator extends StatelessWidget {
  final int currentMana;
  final int maxMana;

  /// Les [reserveArrows] premiers cristaux, dans l'ordre d'affichage, portent
  /// la flèche de la réserve : ce qui passera au prochain tour.
  final int reserveArrows;

  const ManaIndicator({
    super.key,
    required this.currentMana,
    required this.maxMana,
    this.reserveArrows = 0,
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
        final crystal = _crystal(index, baseSize);
        if (index >= reserveArrows) return crystal;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            crystal,
            Positioned(
              right: 0,
              bottom: 0,
              child: _ReserveArrow(size: baseSize * 0.45),
            ),
          ],
        );
      }),
    );
  }

  Widget _crystal(int index, double baseSize) {
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
  }
}

/// La pastille de la réserve : un disque sombre cerclé de cyan, une flèche.
class _ReserveArrow extends StatelessWidget {
  final double size;

  const _ReserveArrow({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.cyanAccent, width: 1),
      ),
      child: Icon(
        Icons.arrow_forward_rounded,
        color: Colors.white,
        size: size * 0.75,
      ),
    );
  }
}
