import 'package:flutter/material.dart';
import '../../../models/data/card_data.dart';
import 'ui_card_helpers.dart';

class CardCompactDescription extends StatelessWidget {
  final String description;
  final double rarityMultiplier;
  final List<String> forgeUpgrades;
  final List<CardEffect>? effects;
  final CardTarget? targetType;
  final String? target;

  const CardCompactDescription({
    super.key,
    required this.description,
    required this.rarityMultiplier,
    required this.forgeUpgrades,
    this.effects,
    this.targetType,
    this.target,
  });

  @override
  Widget build(BuildContext context) {
    if (effects == null || effects!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Text(
          description,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 7,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final List<Widget> badges = [];
    int extraDamage = 0;
    int extraArmor = 0;
    for (var upgrade in forgeUpgrades) {
      final parts = upgrade.split(':');
      if (parts.length != 2) continue;
      final id = parts[0];
      final k = int.tryParse(parts[1]) ?? 0;
      if (k <= 0) continue;
      if (id == 'sharp') extraDamage += 2 * k;
      if (id == 'hardened') extraArmor += 2 * k;
    }

    final isAllEnemies = resolveTarget(targetType, target) == CardTarget.allEnemies;

    for (int i = 0; i < effects!.length; i++) {
      final effect = effects![i];
      int baseValue = (effect.value * rarityMultiplier).round();
      int bonusValue = 0;
      if (effect.type == 'damage') {
        bonusValue = extraDamage;
      } else if (effect.type == 'armor') {
        bonusValue = extraArmor;
      }
      final visuals = getEffectVisuals(effect);
      final isPlayerEffect = effect.type == 'armor' ||
          effect.type == 'heal' ||
          effect.type == 'gain_mana' ||
          effect.type == 'draw' ||
          (effect.type == 'apply_status' &&
              (effect.statusId == 'strength' ||
                  effect.statusId == 'strength_regen' ||
                  effect.statusId == 'armor_regen'));
      final shouldDouble = isAllEnemies && !isPlayerEffect;

      final effectMainRow = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (shouldDouble) ...[
            Icon(
              visuals.icon,
              color: visuals.color,
              size: 19,
            ),
            const SizedBox(width: 1),
            Icon(
              visuals.icon,
              color: visuals.color,
              size: 19,
            ),
          ] else ...[
            Icon(
              visuals.icon,
              color: visuals.color,
              size: 19,
            ),
          ],
          const SizedBox(width: 4),
          if (bonusValue > 0) ...[
            Text(
              '$baseValue',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' +$bonusValue🔨',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else ...[
            Text(
              '${baseValue + bonusValue}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      );

      Widget badgeWidget = effectMainRow;

      if (effect.type == 'apply_status') {
        final duration = effect.duration ?? 1;
        badgeWidget = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            effectMainRow,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: Colors.white60,
                  size: 8,
                ),
                const SizedBox(width: 2),
                Text(
                  '$duration',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ],
        );
      }

      badges.add(badgeWidget);

      if (i < effects!.length - 1) {
        badges.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(
              '|',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 15,
                fontWeight: FontWeight.w200,
              ),
            ),
          ),
        );
      }
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: badges,
    );
  }
}
