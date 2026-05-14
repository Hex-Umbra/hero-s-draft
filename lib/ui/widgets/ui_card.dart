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
    }

    return desc.isNotEmpty ? desc.trim() : description;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 70 / 110,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2C3E50),
            border: Border.all(color: Colors.amber, width: 1.5),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(128),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Titre
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                    const Divider(color: Colors.white24, height: 12),

                    // Rareté et Type (Usage Unique pour Pouvoirs)
                    if (rarity != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            rarity!,
                            style: TextStyle(
                              color: _getRarityColor(rarity!),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          if (effects != null &&
                              effects!.any((e) => false)) // Placeholder
                            const Text(''), // Reserved
                        ],
                      ),

                    // Badge Usage Unique pour les Pouvoirs
                    if (title.contains('Forme') ||
                        title.contains('Métallisation') ||
                        description.contains('épuisée'))
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'USAGE UNIQUE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // Cible
                    if (target != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Cible : $target',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Description
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Text(
                            _buildDescription(),
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Coût en Mana (Haut Gauche)
              if (cost != null)
                Positioned(
                  top: -2,
                  left: -2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B59B6), // Couleur Mana
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white70, width: 1),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: Text(
                      '$cost',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
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

  Color _getRarityColor(String rarity) {
    final r = rarity.toLowerCase();
    if (r.contains('légendaire')) return Colors.orangeAccent;
    if (r.contains('épique') || r.contains('epic')) return Colors.purpleAccent;
    if (r.contains('rare')) return Colors.blueAccent;
    if (r.contains('peu commun')) return Colors.greenAccent;
    if (r.contains('commun')) return Colors.white;
    return Colors.white70;
  }
}
