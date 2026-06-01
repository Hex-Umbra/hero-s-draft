import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../models/enemy_instance.dart';
import '../../../models/enemy_intent.dart';

class EnemyIntentsPanel extends StatelessWidget {
  final List<EnemyInstance> enemies;

  const EnemyIntentsPanel({super.key, required this.enemies});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C).withAlpha(240),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amberAccent.withAlpha(100),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(150),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.remove_red_eye_outlined,
                color: Colors.amberAccent,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.enemyIntentsTitle.toUpperCase(),
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 12),
          ...enemies.map((enemy) {
            final intent = enemy.effectiveIntent;
            final name = enemy.data.getName(locale);

            Widget intentWidget;
            if (intent == null) {
              intentWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withAlpha(30),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.hourglass_empty,
                      color: Colors.white30,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.waitingIntents,
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              IconData icon;
              Color color;
              String label;

              switch (intent.type) {
                case IntentType.attack:
                  if (intent.value >= 20) {
                    icon = Icons.gavel;
                    color = const Color(0xFFC0392B); // Crimson profond
                    label = l10n.intentDevastatingAttack(intent.value);
                  } else if (intent.value >= 12) {
                    icon = Icons.whatshot;
                    color = const Color(0xFFE74C3C); // Écarlate
                    label = l10n.intentHeavyAttack(intent.value);
                  } else if (intent.value >= 6) {
                    icon = Icons.flash_on;
                    color = const Color(0xFFFF7675); // Corail
                    label = l10n.intentAttack(intent.value);
                  } else {
                    icon = Icons.bolt;
                    color = const Color(0xFFF39C12); // Ambre/Orange
                    label = l10n.intentQuickAttack(intent.value);
                  }
                  break;
                case IntentType.defend:
                  icon = Icons.shield;
                  color = const Color(0xFF448AFF);
                  label = l10n.intentDefend(intent.value);
                  break;
                case IntentType.buff:
                  icon = Icons.trending_up;
                  color = const Color(0xFFE040FB);
                  label = l10n.intentBuff(intent.value);
                  break;
                case IntentType.debuffDeck:
                  icon = Icons.sick;
                  color = const Color(0xFF69F0AE);
                  label = l10n.intentCurse(intent.value);
                  break;
              }

              intentWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withAlpha(60), width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          locale == 'fr'
                              ? '$name (Niv. ${enemy.stats.level})'
                              : '$name (Lvl. ${enemy.stats.level})',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: enemy.isBoss
                                ? Colors.amberAccent
                                : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${enemy.stats.currentPv}/${enemy.stats.maxPv} ${l10n.hpAbbreviation}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  intentWidget,
                  if (enemy != enemies.last)
                    const Divider(color: Colors.white10, height: 12),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
