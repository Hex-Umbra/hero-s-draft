import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'ui_card_helpers.dart';

class CardRuneSockets extends StatelessWidget {
  final List<String> forgeUpgrades;
  final int baseMaxForgeUpgrades;
  final int rarityIndex;

  const CardRuneSockets({
    super.key,
    required this.forgeUpgrades,
    required this.baseMaxForgeUpgrades,
    required this.rarityIndex,
  });

  @override
  Widget build(BuildContext context) {
    final totalSlots = baseMaxForgeUpgrades + rarityIndex;
    final filledSlots = forgeUpgrades.length;
    final emptySlots = max(0, totalSlots - filledSlots);

    return SizedBox(
      width: 45.0,
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 2.0,
        runSpacing: 2.0,
        children: [
          ...forgeUpgrades.map((upgrade) => Container(
                width: 7.0,
                height: 7.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black45,
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.8),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.3),
                      blurRadius: 1.5,
                      spreadRadius: 0.25,
                    ),
                  ],
                ),
                child: Center(
                  child: FittedBox(
                    child: Text(
                      getRuneEmoji(upgrade),
                      style: const TextStyle(fontSize: 4.5),
                    ),
                  ),
                ),
              )),
          ...List.generate(
            emptySlots,
            (index) => Container(
              width: 7.0,
              height: 7.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: Colors.white24,
                  width: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
