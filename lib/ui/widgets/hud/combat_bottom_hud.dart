import 'package:flutter/material.dart';
import 'mana_indicator.dart';
import 'player_health_bar.dart';

/// Cristaux de mana + barre de vie du joueur, ancrés en bas de l'écran de combat.
class CombatBottomHud extends StatelessWidget {
  final double hudHeight;
  final double hudWidth;
  final int currentMana;
  final int maxMana;
  final int currentPv;
  final int maxPv;
  final int armure;
  final int effectiveAttaque;

  const CombatBottomHud({
    super.key,
    required this.hudHeight,
    required this.hudWidth,
    required this.currentMana,
    required this.maxMana,
    required this.currentPv,
    required this.maxPv,
    required this.armure,
    required this.effectiveAttaque,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: hudHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: hudWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cristaux de Mana
                  ManaIndicator(currentMana: currentMana, maxMana: maxMana),
                  const SizedBox(height: 4),
                  PlayerHealthBar(
                    currentPv: currentPv,
                    maxPv: maxPv,
                    armure: armure,
                    effectiveAttaque: effectiveAttaque,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
