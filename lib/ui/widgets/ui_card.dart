import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../models/data/card_data.dart';
import 'sword_icon.dart';

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

  String _buildDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (level == null || effects == null || effects!.isEmpty) {
      return description;
    }

    String desc = '';
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
            desc += '${l10n.cardDescStatusPoison(scaledValue)}\n';
            break;
          case 'weakness':
            desc += '${l10n.cardDescStatusWeakness(scaledValue)}\n';
            break;
          case 'vulnerable':
            desc += '${l10n.cardDescStatusVulnerable(scaledValue)}\n';
            break;
          case 'strength_regen':
            desc += '${l10n.cardDescStatusStrengthRegen(scaledValue, duration)}\n';
            break;
          case 'burn':
            desc += '${l10n.cardDescStatusBurn(scaledValue)}\n';
            break;
          case 'freeze':
            desc += '${l10n.cardDescStatusFreeze(scaledValue)}\n';
            break;
          case 'shock':
            desc += '${l10n.cardDescStatusShock(scaledValue)}\n';
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
                  child: Text(
                    _buildDescription(context),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
