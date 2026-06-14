import 'dart:math';
import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../models/card_instance.dart';
import '../ui_card.dart';

class ForgeCardPreview extends StatelessWidget {
  final CardInstance card;
  final int totalMaxForgeUpgrades;
  final String locale;
  final AppLocalizations l10n;

  const ForgeCardPreview({
    super.key,
    required this.card,
    required this.totalMaxForgeUpgrades,
    required this.locale,
    required this.l10n,
  });

  String _getRuneEmoji(String upgrade) {
    final id = upgrade.split(':')[0];
    switch (id) {
      case 'sharp':
        return '⚔️';
      case 'hardened':
        return '🛡️';
      case 'quick':
        return '🪶';
      case 'eco':
        return '💎';
      case 'burning':
        return '🔥';
      case 'freezing':
        return '❄️';
      case 'shocking':
        return '⚡';
      case 'enduring':
        return '⏳';
      default:
        return '🔮';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 170,
          child: UiCard.fromInstance(
            card: card,
            locale: locale,
            l10n: l10n,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          locale == 'fr' ? 'CAPACITÉ' : 'CAPACITY',
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 120.0,
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 6.0,
            runSpacing: 6.0,
            children: [
              ...card.forgeUpgrades.map((upgrade) => Container(
                    width: 18.0,
                    height: 18.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black45,
                      border: Border.all(
                        color: Colors.cyanAccent,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.4),
                          blurRadius: 3.0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: FittedBox(
                        child: Text(
                          _getRuneEmoji(upgrade),
                          style: const TextStyle(fontSize: 11.0),
                        ),
                      ),
                    ),
                  )),
              ...List.generate(
                max(0, totalMaxForgeUpgrades - card.forgeUpgrades.length),
                (index) => Container(
                  width: 18.0,
                  height: 18.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: Colors.white24,
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${card.forgeUpgrades.length} / $totalMaxForgeUpgrades ${locale == 'fr' ? 'Améliorations' : 'Upgrades'}',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}
