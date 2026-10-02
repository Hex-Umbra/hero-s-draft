import 'package:flutter/material.dart';
import 'ui_card_helpers.dart';

/// Une prise par rune portée, garnie de son emoji ; aucune vide — la
/// capacité n'existe plus (spec P-43 E2, §4.10).
class CardRuneSockets extends StatelessWidget {
  final List<String> forgeUpgrades;

  const CardRuneSockets({
    super.key,
    required this.forgeUpgrades,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58.0,
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 2.0,
        runSpacing: 2.0,
        children: [
          ...forgeUpgrades.map((upgrade) => Container(
                width: 10.0,
                height: 10.0,
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
                      style: const TextStyle(fontSize: 7.0),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
