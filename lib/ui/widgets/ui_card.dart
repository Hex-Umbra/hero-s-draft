import 'dart:math' show max, cos, sin;
import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../models/data/card_data.dart';

class _UiCardEffectVisuals {
  final IconData icon;
  final Color color;
  const _UiCardEffectVisuals({required this.icon, required this.color});
}

class UiCard extends StatelessWidget {
  final String title;
  final String description;
  final String? rarity;
  final String? target;
  final int? cost;
  final int? level;
  final double rarityMultiplier;
  final List<String> forgeUpgrades;
  final int baseMaxForgeUpgrades;
  final List<CardEffect>? effects;
  final CardType? type;
  final CardTarget? targetType;
  final bool isExhaust;
  final bool isSelected;
  final bool isGrayedOut;
  final VoidCallback? onTap;

  const UiCard({
    super.key,
    required this.title,
    required this.description,
    this.rarity,
    this.target,
    this.cost,
    this.level,
    this.rarityMultiplier = 1.0,
    this.forgeUpgrades = const [],
    this.baseMaxForgeUpgrades = 1,
    this.effects,
    this.type,
    this.targetType,
    this.isExhaust = false,
    this.isSelected = false,
    this.isGrayedOut = false,
    this.onTap,
  });

  CardTarget? _resolveTarget() {
    if (targetType != null) return targetType;
    if (target == null) return null;
    final t = target!.toLowerCase();
    if (t.contains('single') || t.contains('unique') || t == 'singleenemy') {
      return CardTarget.singleEnemy;
    }
    if (t.contains('all') || t.contains('tous') || t == 'allenemies') {
      return CardTarget.allEnemies;
    }
    if (t.contains('self') || t.contains('soi')) {
      return CardTarget.self;
    }
    if (t.contains('none') || t.contains('aucun')) {
      return CardTarget.none;
    }
    return null;
  }

  // Les badges textuels de ciblage ont été supprimés pour réduire la pollution visuelle.
  // Le ciblage multi-cible est désormais représenté par le doublement de l'icône d'effet.

  String _determineDamageType() {
    final lowerTitle = title.toLowerCase();

    if (effects != null) {
      for (var effect in effects!) {
        if (effect.type == 'apply_status') {
          if (effect.statusId == 'burn') return 'fire';
          if (effect.statusId == 'freeze') return 'cold';
          if (effect.statusId == 'shock') return 'electric';
        }
      }
    }

    if (lowerTitle.contains('feu') ||
        lowerTitle.contains('fire') ||
        lowerTitle.contains('brûlure') ||
        lowerTitle.contains('burn')) {
      return 'fire';
    }
    if (lowerTitle.contains('glace') ||
        lowerTitle.contains('ice') ||
        lowerTitle.contains('gel') ||
        lowerTitle.contains('freeze') ||
        lowerTitle.contains('froid') ||
        lowerTitle.contains('cold')) {
      return 'cold';
    }
    if (lowerTitle.contains('foudre') ||
        lowerTitle.contains('thunder') ||
        lowerTitle.contains('shock') ||
        lowerTitle.contains('lightning') ||
        lowerTitle.contains('tonnerre') ||
        lowerTitle.contains('élec')) {
      return 'electric';
    }
    return 'physical';
  }

  _UiCardEffectVisuals _getEffectVisuals(CardEffect effect) {
    if (effect.type == 'damage') {
      return const _UiCardEffectVisuals(
        icon: Icons.hardware_rounded,
        color: Colors.redAccent,
      );
    }
    if (effect.type == 'armor') {
      return const _UiCardEffectVisuals(
        icon: Icons.shield_rounded,
        color: Colors.blueAccent,
      );
    }
    if (effect.type == 'heal') {
      return const _UiCardEffectVisuals(
        icon: Icons.favorite_rounded,
        color: Colors.pinkAccent,
      );
    }
    if (effect.type == 'gain_mana') {
      return const _UiCardEffectVisuals(
        icon: Icons.diamond_rounded,
        color: Colors.cyanAccent,
      );
    }
    if (effect.type == 'draw') {
      return const _UiCardEffectVisuals(
        icon: Icons.style_rounded,
        color: Colors.amber,
      );
    }
    if (effect.type == 'apply_status') {
      switch (effect.statusId) {
        case 'strength':
        case 'strength_regen':
          return const _UiCardEffectVisuals(
            icon: Icons.bolt_rounded,
            color: Colors.orangeAccent,
          );
        case 'armor_regen':
          return const _UiCardEffectVisuals(
            icon: Icons.autorenew_rounded,
            color: Colors.blueAccent,
          );
        case 'poison':
          return const _UiCardEffectVisuals(
            icon: Icons.science_rounded,
            color: Colors.greenAccent,
          );
        case 'weakness':
          return const _UiCardEffectVisuals(
            icon: Icons.trending_down_rounded,
            color: Colors.purpleAccent,
          );
        case 'vulnerable':
          return const _UiCardEffectVisuals(
            icon: Icons.gps_fixed_rounded,
            color: Colors.deepOrangeAccent,
          );
        case 'burn':
          return const _UiCardEffectVisuals(
            icon: Icons.local_fire_department_rounded,
            color: Colors.orangeAccent,
          );
        case 'freeze':
          return const _UiCardEffectVisuals(
            icon: Icons.ac_unit_rounded,
            color: Colors.lightBlueAccent,
          );
        case 'shock':
          return const _UiCardEffectVisuals(
            icon: Icons.flash_on_rounded,
            color: Colors.amberAccent,
          );
      }
    }
    return const _UiCardEffectVisuals(
      icon: Icons.help_outline,
      color: Colors.grey,
    );
  }

  Widget _buildCompactDescription(BuildContext context) {
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

    final isAllEnemies = _resolveTarget() == CardTarget.allEnemies;

    for (int i = 0; i < effects!.length; i++) {
      final effect = effects![i];
      int baseValue = (effect.value * rarityMultiplier).round();
      int bonusValue = 0;
      if (effect.type == 'damage') {
        bonusValue = extraDamage;
      } else if (effect.type == 'armor') {
        bonusValue = extraArmor;
      }
      final visuals = _getEffectVisuals(effect);
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

  String _buildDetailedDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Add elemental header if applicable
    String desc = '';
    final elementalType = _determineDamageType();
    if (effects != null && effects!.isNotEmpty && elementalType != 'physical') {
      final typeStr = elementalType == 'fire'
          ? 'FEU 🔥'
          : elementalType == 'cold'
          ? 'FROID ❄️'
          : elementalType == 'poison'
          ? 'POISON 🧪'
          : 'FOUDRE ⚡';
      desc += '[$typeStr]\n';
    }

    if (effects == null || effects!.isEmpty) {
      return desc + description;
    }

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

    for (var effect in effects!) {
      int scaledValue = (effect.value * rarityMultiplier).round();
      if (effect.type == 'damage') {
        scaledValue += extraDamage;
      } else if (effect.type == 'armor') {
        scaledValue += extraArmor;
      }

      if (effect.type == 'damage') {
        if (target == 'Tous les ennemis' || target == 'allEnemies') {
          desc += '${l10n.cardDescDamageAll(scaledValue)}\n';
        } else {
          desc += '${l10n.cardDescDamage(scaledValue)}\n';
        }
      }
      if (effect.type == 'heal') desc += '${l10n.cardDescHeal(scaledValue)}\n';
      if (effect.type == 'armor') {
        desc += '${l10n.cardDescArmor(scaledValue)}\n';
      }
      if (effect.type == 'gain_mana') {
        desc += '${l10n.cardDescGainMana(scaledValue)}\n';
      }
      if (effect.type == 'draw') desc += '${l10n.cardDescDraw(scaledValue)}\n';
      if (effect.type == 'apply_status') {
        final duration = effect.duration ?? 1;
        final localeCode = Localizations.localeOf(context).languageCode;
        switch (effect.statusId) {
          case 'strength':
            desc += '${l10n.cardDescStatusStrength(scaledValue, duration)}\n';
            break;
          case 'armor_regen':
            desc += '${l10n.cardDescStatusArmorRegen(scaledValue, duration)}\n';
            break;
          case 'poison':
            desc +=
                '${l10n.cardDescStatusPoisonDuration(scaledValue, duration)}\n';
            desc += localeCode == 'fr'
                ? '  (Subit des dégâts égaux au Poison au début de son tour, puis la durée diminue)\n'
                : '  (Takes damage equal to Poison at turn start, then duration decreases)\n';
            break;
          case 'weakness':
            desc +=
                '${l10n.cardDescStatusWeaknessDuration(scaledValue, duration)}\n';
            desc += localeCode == 'fr'
                ? '  (Réduit les dégâts infligés par l\'ennemi de 25%)\n'
                : '  (Reduces damage dealt by the enemy by 25%)\n';
            break;
          case 'vulnerable':
            desc +=
                '${l10n.cardDescStatusVulnerableDuration(scaledValue, duration)}\n';
            desc += localeCode == 'fr'
                ? '  (L\'ennemi subit 50% de dégâts supplémentaires)\n'
                : '  (Enemy takes 50% more damage from attacks)\n';
            break;
          case 'strength_regen':
            desc +=
                '${l10n.cardDescStatusStrengthRegen(scaledValue, duration)}\n';
            break;
          case 'burn':
            desc +=
                '${l10n.cardDescStatusBurnDuration(scaledValue, duration)}\n';
            desc += localeCode == 'fr'
                ? '  (Subit des dégâts de feu égaux à la Brûlure au début de son tour, puis la valeur diminue de 1)\n'
                : '  (Takes fire damage equal to Burn at turn start, then the value decreases by 1)\n';
            break;
          case 'freeze':
            desc +=
                '${l10n.cardDescStatusFreezeDuration(scaledValue, duration)}\n';
            desc += localeCode == 'fr'
                ? '  (Réduit les dégâts de la prochaine attaque de l\'ennemi de 50%)\n'
                : '  (Reduces next enemy attack damage by 50%)\n';
            break;
          case 'shock':
            desc +=
                '${l10n.cardDescStatusShockDuration(scaledValue, duration)}\n';
            desc += localeCode == 'fr'
                ? '  (Subit des dégâts supplémentaires égaux à l\'Électrocution à chaque coup reçu)\n'
                : '  (Takes extra damage equal to Shock on every hit)\n';
            break;
        }
      }
    }

    final List<String> upgradeDescs = [];
    final activeLocale = Localizations.localeOf(context).languageCode;
    for (var upgrade in forgeUpgrades) {
      final parts = upgrade.split(':');
      if (parts.length != 2) continue;
      final id = parts[0];
      final k = int.tryParse(parts[1]) ?? 0;
      if (k <= 0) continue;
      switch (id) {
        case 'sharp':
          upgradeDescs.add(activeLocale == 'fr' ? 'Tranchant $k (+${2 * k} Dégâts)' : 'Sharp $k (+${2 * k} Damage)');
          break;
        case 'hardened':
          upgradeDescs.add(activeLocale == 'fr' ? 'Endurci $k (+${2 * k} Armure)' : 'Hardened $k (+${2 * k} Armor)');
          break;
        case 'quick':
          upgradeDescs.add(activeLocale == 'fr' ? 'Véloce $k (+$k Carte(s) piochée(s))' : 'Quick $k (+$k Card(s) drawn)');
          break;
        case 'eco':
          upgradeDescs.add(activeLocale == 'fr' ? 'Économe $k (+$k Mana)' : 'Eco $k (+$k Mana)');
          break;
        case 'burning':
          upgradeDescs.add(activeLocale == 'fr' ? 'Brûlant $k (Applique $k Brûlure)' : 'Burning $k (Apply $k Burn)');
          break;
        case 'freezing':
          upgradeDescs.add(activeLocale == 'fr' ? 'Congelant $k (Applique $k Gel)' : 'Freezing $k (Apply $k Freeze)');
          break;
        case 'shocking':
          upgradeDescs.add(activeLocale == 'fr' ? 'Surchargé $k (Applique $k Électrocution)' : 'Shocking $k (Apply $k Shock)');
          break;
        case 'enduring':
          upgradeDescs.add(activeLocale == 'fr' ? 'Persistant' : 'Enduring');
          break;
      }
    }
    if (upgradeDescs.isNotEmpty) {
      desc += '\n⚙️ Upgrades:\n${upgradeDescs.map((u) => '• $u').join('\n')}\n';
    }

    return desc.isNotEmpty ? desc.trim() : description;
  }

  Color _getTypeColor() {
    if (isGrayedOut) return Colors.grey;
    switch (type) {
      case CardType.attack:
        return Colors.redAccent;
      case CardType.skill:
        return Colors.blueAccent;
      case CardType.power:
        return Colors.amber;
      case CardType.status:
        return Colors.blueGrey;
      default:
        return Colors.blueAccent;
    }
  }

  Color _getBackgroundColor() {
    if (isGrayedOut) return const Color(0xFF1A1A1A);
    switch (type) {
      case CardType.attack:
        return const Color(0xFF4A1D1D);
      case CardType.skill:
        return const Color(0xFF152A4A);
      case CardType.power:
        return const Color(0xFF453215);
      case CardType.status:
        return const Color(0xFF2D2D2D);
      default:
        return const Color(0xFF2A2A3D);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typeColor = _getTypeColor();
    final bgColor = _getBackgroundColor();
    final rarityColor = rarity != null ? _getRarityColor(context, rarity!) : Colors.white70;

    final rarityIndex = _getRarityIndex(context);
    final totalSlots = baseMaxForgeUpgrades + rarityIndex;
    final filledSlots = forgeUpgrades.length;
    final emptySlots = max(0, totalSlots - filledSlots);

    final runeSocketsRow = SizedBox(
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
                      _getRuneEmoji(upgrade),
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

    final showBadge = isExhaust || type == CardType.power;
    final descriptionTop = showBadge ? 52.0 : 40.0;

    return AspectRatio(
      aspectRatio: 70 / 110,
      child: Tooltip(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C).withAlpha(245),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: rarityColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(185),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        preferBelow: false,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          height: 1.3,
        ),
        richMessage: TextSpan(
          children: [
            TextSpan(
              text: '${title.toUpperCase()}\n',
              style: TextStyle(
                color: typeColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const TextSpan(text: '\n'),
            TextSpan(text: _buildDetailedDescription(context)),
          ],
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Card body (clipped to rounded rect)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: rarityColor.withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 4,
                      ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: PolychromaticBorder(
                    rarityColor: rarityColor,
                    isUnique: rarity != null && rarity!.toLowerCase().contains('unique'),
                    isSelected: isSelected,
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Titre, Ligne de Séparateur, Rareté et Rune Sockets groupés
                          Positioned(
                            top: 10,
                            left: 8,
                            right: 8,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 3),
                                Center(
                                  child: Container(
                                    height: 1.5,
                                    width: 30,
                                    color: typeColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                runeSocketsRow,
                                if (showBadge) ...[
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4.5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      l10n.oncePlayed.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 6,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Description (Centrée verticalement)
                          Positioned(
                            top: descriptionTop,
                            bottom: 22,
                            left: 8,
                            right: 8,
                            child: Center(child: _buildCompactDescription(context)),
                          ),

                          // Type Label (Fixé tout en bas)
                          Positioned(
                            bottom: 6,
                            left: 0,
                            right: 0,
                            child: Text(
                              _getTypeLabel(context).toUpperCase(),
                              style: TextStyle(
                                color: typeColor.withValues(alpha: 0.7),
                                fontSize: 6,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Circular Mana Medallion — outside ClipRRect so it's never cropped
              if (cost != null)
                Positioned(
                  top: -6,
                  left: -6,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0D1B2A),
                      border: Border.all(
                        color: Colors.cyanAccent,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$cost',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case CardType.attack:
        return l10n.cardTypeAttack;
      case CardType.skill:
        return l10n.cardTypeSkill;
      case CardType.power:
        return l10n.cardTypePower;
      case CardType.status:
        return l10n.cardTypeStatus;
      default:
        return 'Carte';
    }
  }

  Color _getRarityColor(BuildContext context, String rarity) {
    final l10n = AppLocalizations.of(context)!;
    final r = rarity.toLowerCase();
    if (r.contains('unique')) {
      return const Color(0xFFFFD700); // Gold pur — rareté Unique
    }
    if (r == l10n.rarityLegendary.toLowerCase() ||
        r.contains('legendary') ||
        r.contains('légendaire')) {
      return Colors.orangeAccent;
    }
    if (r == l10n.rarityEpic.toLowerCase() ||
        r.contains('epic') ||
        r.contains('épique')) {
      return Colors.purpleAccent;
    }
    if (r == l10n.rarityRare.toLowerCase() || r.contains('rare')) {
      return Colors.blueAccent;
    }
    if (r == l10n.rarityUncommon.toLowerCase() ||
        r.contains('uncommon') ||
        r.contains('peu commun')) {
      return Colors.greenAccent;
    }
    if (r == l10n.rarityCommon.toLowerCase() ||
        r.contains('common') ||
        r.contains('commun')) {
      return Colors.white70;
    }
    return Colors.white54;
  }

  int _getRarityIndex(BuildContext context) {
    if (rarity == null) return 0;
    final l10n = AppLocalizations.of(context)!;
    final r = rarity!.toLowerCase();
    if (r == l10n.rarityLegendary.toLowerCase() ||
        r.contains('legendary') ||
        r.contains('légendaire')) {
      return 4;
    }
    if (r == l10n.rarityEpic.toLowerCase() ||
        r.contains('epic') ||
        r.contains('épique')) {
      return 3;
    }
    if (r == l10n.rarityRare.toLowerCase() || r.contains('rare')) {
      return 2;
    }
    if (r == l10n.rarityUncommon.toLowerCase() ||
        r.contains('uncommon') ||
        r.contains('peu commun')) {
      return 1;
    }
    if (r == l10n.rarityCommon.toLowerCase() ||
        r.contains('common') ||
        r.contains('commun')) {
      return 0;
    }
    if (r.contains('unique')) {
      return 5;
    }
    return 0;
  }

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
}

class PolychromaticBorder extends StatefulWidget {
  final Widget child;
  final Color rarityColor;
  final bool isSelected;
  final bool isUnique;

  const PolychromaticBorder({
    super.key,
    required this.child,
    required this.rarityColor,
    required this.isSelected,
    this.isUnique = false,
  });

  @override
  State<PolychromaticBorder> createState() => _PolychromaticBorderState();
}

class _PolychromaticBorderState extends State<PolychromaticBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
        _controller.repeat();
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
        _controller.stop();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            foregroundPainter: _PolychromaticBorderPainter(
              animationValue: _controller.value,
              rarityColor: widget.rarityColor,
              isSelected: widget.isSelected,
              isHovered: _isHovered,
              isUnique: widget.isUnique,
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _PolychromaticBorderPainter extends CustomPainter {
  final double animationValue;
  final Color rarityColor;
  final bool isSelected;
  final bool isHovered;
  final bool isUnique;

  _PolychromaticBorderPainter({
    required this.animationValue,
    required this.rarityColor,
    required this.isSelected,
    required this.isHovered,
    this.isUnique = false,
  });

  List<Color> _getRarityShineColors(Color baseColor) {
    // Rareté Unique → arc-en-ciel complet
    if (isUnique) {
      return [
        Colors.red,
        Colors.orangeAccent,
        Colors.yellow,
        Colors.greenAccent,
        Colors.cyanAccent,
        Colors.blueAccent,
        Colors.purpleAccent,
        Colors.pinkAccent,
        Colors.red,
      ];
    }
    final hsv = HSVColor.fromColor(baseColor);
    if (hsv.saturation < 0.15 || hsv.value < 0.15) {
      return [
        baseColor,
        Colors.white,
        const Color(0xFFE0E0E0),
        const Color(0xFFBDBDBD),
        Colors.white,
        baseColor,
      ];
    }
    final hue = hsv.hue;
    if (hue >= 340 || hue < 20) {
      return [
        baseColor,
        Colors.orangeAccent,
        Colors.red,
        Colors.pinkAccent,
        baseColor,
      ];
    } else if (hue >= 20 && hue < 50) {
      return [
        baseColor,
        Colors.amber,
        Colors.yellow,
        Colors.deepOrange,
        baseColor,
      ];
    } else if (hue >= 50 && hue < 70) {
      return [
        baseColor,
        Colors.lightGreenAccent,
        Colors.yellowAccent,
        Colors.amberAccent,
        baseColor,
      ];
    } else if (hue >= 70 && hue < 165) {
      return [
        baseColor,
        Colors.limeAccent,
        Colors.tealAccent,
        Colors.green,
        baseColor,
      ];
    } else if (hue >= 165 && hue < 200) {
      return [
        baseColor,
        Colors.cyanAccent,
        Colors.blueAccent,
        Colors.tealAccent,
        baseColor,
      ];
    } else if (hue >= 200 && hue < 260) {
      return [
        baseColor,
        Colors.cyan,
        Colors.indigoAccent,
        Colors.blue,
        baseColor,
      ];
    } else {
      return [
        baseColor,
        Colors.pinkAccent,
        Colors.deepPurpleAccent,
        Colors.purple,
        baseColor,
      ];
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    final paint = Paint()
      ..style = PaintingStyle.stroke;

    if (isHovered) {
      paint.strokeWidth = 3.0;
      final colors = _getRarityShineColors(rarityColor);
      final angle = animationValue * 2 * 3.141592653589793;
      final cosVal = cos(angle);
      final sinVal = sin(angle);
      paint.shader = LinearGradient(
        begin: Alignment(cosVal, sinVal),
        end: Alignment(-cosVal, -sinVal),
        colors: colors,
      ).createShader(rect);
    } else {
      paint.strokeWidth = isSelected ? 2.5 : 1.5;
      paint.color = isSelected
          ? Colors.white.withValues(alpha: 0.8)
          : rarityColor.withValues(alpha: 0.5);
    }

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _PolychromaticBorderPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.rarityColor != rarityColor ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isUnique != isUnique ||
        oldDelegate.isHovered != isHovered;
  }
}
