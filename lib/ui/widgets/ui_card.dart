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
  final List<CardEffect>? effects;
  final CardType? type;
  final CardTarget? targetType;
  final bool isExhaust;
  final bool isSelected;
  final bool isGrayedOut;
  final VoidCallback? onTap;
  final int baseMaxForgeUpgrades;

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
    this.effects,
    this.type,
    this.targetType,
    this.isExhaust = false,
    this.isSelected = false,
    this.isGrayedOut = false,
    this.onTap,
    this.baseMaxForgeUpgrades = 1,
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

  Widget _buildTargetIcon(BuildContext context) {
    final resolved = _resolveTarget();
    if (resolved == null || resolved == CardTarget.none) {
      return const SizedBox.shrink();
    }

    final String emoji;
    final String label;
    final Color badgeColor;

    final locale = Localizations.localeOf(context).languageCode;

    switch (resolved) {
      case CardTarget.singleEnemy:
        emoji = '🎯';
        label = locale == 'fr' ? 'Cible unique' : 'Single Target';
        badgeColor = Colors.redAccent.withAlpha(50);
        break;
      case CardTarget.allEnemies:
        emoji = '💥';
        label = locale == 'fr' ? 'Tous les ennemis' : 'All Enemies';
        badgeColor = Colors.orangeAccent.withAlpha(50);
        break;
      case CardTarget.self:
        emoji = '🛡️';
        label = locale == 'fr' ? 'Soi-même' : 'Self';
        badgeColor = Colors.blueAccent.withAlpha(50);
        break;
      case CardTarget.none:
        return const SizedBox.shrink();
    }

    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white24, width: 0.5),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 10),
              ),
              const SizedBox(width: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 7.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
    final targetWidget = _buildTargetIcon(context);
    final hasTarget = targetWidget is! SizedBox;

    if (effects == null || effects!.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasTarget) ...[
            targetWidget,
            const SizedBox(height: 6),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 8.0,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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

    for (int i = 0; i < effects!.length; i++) {
      final effect = effects![i];
      int scaledValue = (effect.value * rarityMultiplier).round();
      if (effect.type == 'damage') {
        scaledValue += extraDamage;
      } else if (effect.type == 'armor') {
        scaledValue += extraArmor;
      }
      final visuals = _getEffectVisuals(effect);

      final effectMainRow = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            visuals.icon,
            color: visuals.color,
            size: 22.0,
          ),
          const SizedBox(width: 4),
          Text(
            '$scaledValue',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                  size: 10,
                ),
                const SizedBox(width: 2),
                Text(
                  '$duration',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
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
                fontSize: 15.0,
                fontWeight: FontWeight.w200,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasTarget) ...[
          targetWidget,
          const SizedBox(height: 6),
        ],
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: badges,
        ),
      ],
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
    return isGrayedOut ? const Color(0xFF1A1A1A) : const Color(0xFF2A2A3D);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typeColor = _getTypeColor();
    final bgColor = _getBackgroundColor();

    return AspectRatio(
      aspectRatio: 70 / 110,
      child: Tooltip(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C).withAlpha(245),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: typeColor, width: 1.5),
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
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bgColor, bgColor.withAlpha(200)],
              ),
              border: Border.all(
                color: isSelected ? Colors.white : typeColor,
                width: isSelected ? 3.0 : 2.0,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: typeColor.withAlpha(200),
                    blurRadius: 15,
                    spreadRadius: 4,
                  ),
                BoxShadow(
                  color: Colors.black.withAlpha(150),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Titre (Fixé en haut)
                Positioned(
                  top: 10,
                  left: 8,
                  right: 8,
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),

                // Ligne de séparation
                Positioned(
                  top: 26,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      height: 1.5,
                      width: 40,
                      color: typeColor.withAlpha(100),
                    ),
                  ),
                ),

                // Rareté
                if (rarity != null)
                  Positioned(
                    top: 32,
                    left: 0,
                    right: 0,
                    child: Text(
                      rarity!.toUpperCase(),
                      style: TextStyle(
                        color: _getRarityColor(context, rarity!),
                        fontSize: 7.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Étoiles de Forge
                if (rarity != null)
                  Positioned(
                    top: 42,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        baseMaxForgeUpgrades + _getRarityIndex(context),
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0.5),
                          child: Icon(
                            index < forgeUpgrades.length
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 8,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Badge Usage Unique
                if (isExhaust || type == CardType.power)
                  Positioned(
                    top: 54,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withAlpha(200),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.oncePlayed.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Description (Centrée verticalement)
                Positioned(
                  top: 70,
                  bottom: 38,
                  left: 8,
                  right: 8,
                  child: Center(child: _buildCompactDescription(context)),
                ),

                // Cristaux de Mana (En bas au centre)
                if (cost != null && cost! > 0)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        cost!,
                        (index) => const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 1.0),
                          child: Icon(
                            Icons.diamond_rounded,
                            color: Colors.cyanAccent,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Type Label (Fixé tout en bas)
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: Text(
                    _getTypeLabel(context).toUpperCase(),
                    style: TextStyle(
                      color: typeColor.withAlpha(180),
                      fontSize: 7.0,
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
}
