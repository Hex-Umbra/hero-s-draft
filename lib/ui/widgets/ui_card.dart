import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../models/data/card_data.dart';
import 'sword_icon.dart';

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
  final List<CardEffect>? effects;
  final CardType? type;
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
    this.effects,
    this.type,
    this.isExhaust = false,
    this.isSelected = false,
    this.isGrayedOut = false,
    this.onTap,
  });



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
    
    if (lowerTitle.contains('feu') || lowerTitle.contains('fire') || lowerTitle.contains('brûlure') || lowerTitle.contains('burn')) {
      return 'fire';
    }
    if (lowerTitle.contains('glace') || lowerTitle.contains('ice') || lowerTitle.contains('gel') || lowerTitle.contains('freeze') || lowerTitle.contains('froid') || lowerTitle.contains('cold')) {
      return 'cold';
    }
    if (lowerTitle.contains('foudre') || lowerTitle.contains('thunder') || lowerTitle.contains('shock') || lowerTitle.contains('lightning') || lowerTitle.contains('tonnerre') || lowerTitle.contains('élec')) {
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
            fontSize: 9,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final List<Widget> badges = [];
    for (int i = 0; i < effects!.length; i++) {
      final effect = effects![i];
      final currentLevel = level ?? 1;
      final scaledValue = (effect.value * (1 + (currentLevel - 1) * 0.5)).round();
      final visuals = _getEffectVisuals(effect);
      
      final effectMainRow = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            visuals.icon,
            color: visuals.color,
            size: 25, // Reduced by 1/4 (from 33)
          ),
          const SizedBox(width: 4),
          Text(
            '$scaledValue',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18, // Reduced from 22
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
                fontSize: 20, // Reduced from 24
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

    if (level == null || effects == null || effects!.isEmpty) {
      return desc + description;
    }

    for (var effect in effects!) {
      final scaledValue = (effect.value * (1 + (level! - 1) * 0.5)).round();
      if (effect.type == 'damage') {
        if (target == 'Tous les ennemis' || target == 'allEnemies') {
          desc += '${l10n.cardDescDamageAll(scaledValue)}\n';
        } else {
          desc += '${l10n.cardDescDamage(scaledValue)}\n';
        }
      }
      if (effect.type == 'heal') desc += '${l10n.cardDescHeal(scaledValue)}\n';
      if (effect.type == 'armor') desc += '${l10n.cardDescArmor(scaledValue)}\n';
      if (effect.type == 'gain_mana') desc += '${l10n.cardDescGainMana(scaledValue)}\n';
      if (effect.type == 'draw') desc += '${l10n.cardDescDraw(scaledValue)}\n';
      if (effect.type == 'apply_status') {
        final duration = effect.duration ?? 1;
        switch (effect.statusId) {
          case 'strength':
            desc += '${l10n.cardDescStatusStrength(scaledValue, duration)}\n';
            break;
          case 'armor_regen':
            desc += '${l10n.cardDescStatusArmorRegen(scaledValue, duration)}\n';
            break;
          case 'poison':
            desc += '${l10n.cardDescStatusPoisonDuration(scaledValue, duration)}\n';
            break;
          case 'weakness':
            desc += '${l10n.cardDescStatusWeaknessDuration(scaledValue, duration)}\n';
            break;
          case 'vulnerable':
            desc += '${l10n.cardDescStatusVulnerableDuration(scaledValue, duration)}\n';
            break;
          case 'strength_regen':
            desc += '${l10n.cardDescStatusStrengthRegen(scaledValue, duration)}\n';
            break;
          case 'burn':
            desc += '${l10n.cardDescStatusBurnDuration(scaledValue, duration)}\n';
            break;
          case 'freeze':
            desc += '${l10n.cardDescStatusFreezeDuration(scaledValue, duration)}\n';
            break;
          case 'shock':
            desc += '${l10n.cardDescStatusShockDuration(scaledValue, duration)}\n';
            break;
        }
      }
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
          border: Border.all(
            color: typeColor,
            width: 1.5,
          ),
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
                colors: [
                  bgColor,
                  bgColor.withAlpha(200),
                ],
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
                // Motif de fond subtil selon le type
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.05,
                    child: type == CardType.attack
                        ? const Center(
                            child: SwordIcon(
                              size: 80,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _getTypeIcon(),
                            size: 80,
                            color: Colors.white,
                          ),
                  ),
                ),

                // Titre (Fixé en haut)
                Positioned(
                  top: 10,
                  left: 8,
                  right: 8,
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),

                // Ligne de séparation
                Positioned(
                  top: 28,
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
                    top: 36,
                    left: 0,
                    right: 0,
                    child: Text(
                      rarity!.toUpperCase(),
                      style: TextStyle(
                        color: _getRarityColor(context, rarity!),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Badge Usage Unique
                if (isExhaust || type == CardType.power)
                  Positioned(
                    top: 50,
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
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Description (Centrée verticalement)
                Positioned(
                  top: 68,
                  bottom: 40,
                  left: 8,
                  right: 8,
                  child: Center(
                    child: _buildCompactDescription(context),
                  ),
                ),

              // Cristaux de Mana (En bas au centre)
              if (cost != null && cost! > 0)
                Positioned(
                  bottom: 22,
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
                    fontSize: 8,
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

  IconData _getTypeIcon() {
    switch (type) {
      case CardType.attack:
        return Icons.hardware_rounded;
      case CardType.skill:
        return Icons.shield_rounded;
      case CardType.power:
        return Icons.auto_fix_high_rounded;
      case CardType.status:
        return Icons.warning_rounded;
      default:
        return Icons.help_outline;
    }
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
    if (r == l10n.rarityLegendary.toLowerCase() || r.contains('legendary') || r.contains('légendaire')) {
      return Colors.orangeAccent;
    }
    if (r == l10n.rarityEpic.toLowerCase() || r.contains('epic') || r.contains('épique')) {
      return Colors.purpleAccent;
    }
    if (r == l10n.rarityRare.toLowerCase() || r.contains('rare')) {
      return Colors.blueAccent;
    }
    if (r == l10n.rarityUncommon.toLowerCase() || r.contains('uncommon') || r.contains('peu commun')) {
      return Colors.greenAccent;
    }
    if (r == l10n.rarityCommon.toLowerCase() || r.contains('common') || r.contains('commun')) {
      return Colors.white70;
    }
    return Colors.white54;
  }
}
