import 'package:flutter/material.dart';
import '../../models/data/card_data.dart';

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

  String _buildDescription() {
    if (level == null || effects == null || effects!.isEmpty) {
      return description;
    }

    String desc = '';
    for (var effect in effects!) {
      final scaledValue = (effect.value * (1 + (level! - 1) * 0.5)).round();
      if (effect.type == 'damage') desc += 'Inflige $scaledValue dégâts.\n';
      if (effect.type == 'heal') desc += 'Soigne $scaledValue PV.\n';
      if (effect.type == 'armor') desc += 'Donne $scaledValue Armure.\n';
      if (effect.type == 'gain_mana') desc += 'Gagne $scaledValue Mana.\n';
      if (effect.type == 'draw') desc += 'Pioche $scaledValue cartes.\n';
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
                  child: Icon(
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
                      color: _getRarityColor(rarity!),
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
                      child: const Text(
                        'USAGE UNIQUE',
                        style: TextStyle(
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
                    _buildDescription(),
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
                  _getTypeLabel().toUpperCase(),
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

  String _getTypeLabel() {
    switch (type) {
      case CardType.attack:
        return 'Attaque';
      case CardType.skill:
        return 'Compétence';
      case CardType.power:
        return 'Pouvoir';
      case CardType.status:
        return 'Statut';
      default:
        return 'Carte';
    }
  }

  Color _getRarityColor(String rarity) {
    final r = rarity.toLowerCase();
    if (r.contains('légendaire')) return Colors.orangeAccent;
    if (r.contains('épique') || r.contains('epic')) return Colors.purpleAccent;
    if (r.contains('rare')) return Colors.blueAccent;
    if (r.contains('peu commun')) return Colors.greenAccent;
    if (r.contains('commun')) return Colors.white70;
    return Colors.white54;
  }
}
