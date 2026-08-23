import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class NodeTypeInfo {
  // L'Autel des Reliques n'a pas d'IconData ni de couleur dédiées dans
  // map_legend.dart (seulement un emoji) : icon/color sont donc optionnels,
  // et emoji sert de repli, comme LegendItem dans map_legend.dart.
  final IconData? icon;
  final Color? color;
  final String? emoji;
  final String titleEn;
  final String titleFr;
  final String descEn;
  final String descFr;

  const NodeTypeInfo({
    this.icon,
    this.color,
    this.emoji,
    required this.titleEn,
    required this.titleFr,
    required this.descEn,
    required this.descFr,
  });
}

class TutorialNodeTypesWidget extends StatelessWidget {
  final TutorialEngine engine;
  const TutorialNodeTypesWidget({super.key, required this.engine});

  static const List<NodeTypeInfo> _types = [
    NodeTypeInfo(
      icon: Icons.flash_on,
      color: Colors.white70,
      titleEn: 'Combat',
      titleFr: 'Combat',
      descEn: 'Fight base monsters for gold & XP.',
      descFr: 'Combattez des monstres pour de l\'or et XP.',
    ),
    NodeTypeInfo(
      icon: Icons.warning_amber_rounded,
      color: Colors.redAccent,
      titleEn: 'Elite',
      titleFr: 'Élite',
      descEn: 'Difficult fight. Rewards a Relic.',
      descFr: 'Combat difficile. Offre une Relique.',
    ),
    NodeTypeInfo(
      icon: Icons.shopping_cart_outlined,
      color: Colors.amber,
      titleEn: 'Shop',
      titleFr: 'Boutique',
      descEn: 'Buy cards, reroll stock, purge a card. No relics.',
      descFr:
          'Achetez des cartes, relancez le stock, purgez-en une. Aucune '
          'relique.',
    ),
    NodeTypeInfo(
      icon: Icons.nightlight_round,
      color: Colors.greenAccent,
      titleEn: 'Rest Site',
      titleFr: 'Repos',
      descEn: 'Heal 30% max HP, forge, or remove a card.',
      descFr: 'Soignez 30 % des PV max, forgez ou retirez une carte.',
    ),
    NodeTypeInfo(
      icon: Icons.help_outline,
      color: Colors.blueAccent,
      titleEn: 'Event',
      titleFr: 'Événement',
      descEn: 'Narrative choices & rewards.',
      descFr: 'Choix narratifs et récompenses.',
    ),
    NodeTypeInfo(
      emoji: '🔄',
      titleEn: 'Relic Shrine',
      titleFr: 'Autel des Reliques',
      descEn: 'Sacrifice relics for a better one.',
      descFr: 'Sacrifiez des reliques pour une meilleure.',
    ),
    NodeTypeInfo(
      icon: Icons.layers_rounded,
      color: Colors.deepPurpleAccent,
      titleEn: 'Fusion Forge',
      titleFr: 'Forge de Fusion',
      descEn: 'Merge duplicate upgrades, for gold.',
      descFr: 'Fusionne les améliorations dupliquées, contre de l\'or.',
    ),
    NodeTypeInfo(
      icon: Icons.style,
      color: Colors.orangeAccent,
      titleEn: 'Boss (Cards)',
      titleFr: 'Boss (Cartes)',
      descEn: 'Rewards 1-3 cards of your choice.',
      descFr: 'Offre 1 à 3 cartes au choix.',
    ),
    NodeTypeInfo(
      icon: Icons.auto_awesome,
      color: Colors.cyanAccent,
      titleEn: 'Boss (3× XP & Gold)',
      titleFr: 'Boss (XP & Or ×3)',
      descEn: 'Rewards triple XP and gold.',
      descFr: 'Offre le triple d\'XP et d\'or.',
    ),
    NodeTypeInfo(
      icon: Icons.diamond,
      color: Colors.deepPurpleAccent,
      titleEn: 'Boss (Relic)',
      titleFr: 'Boss (Relique)',
      descEn: 'Rewards an improved relic.',
      descFr: 'Offre une relique améliorée.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int crossAxisCount = 2;
        if (width > 600) {
          crossAxisCount = 3;
        } else if (width < 280) {
          crossAxisCount = 1;
        }

        const double spacing = 12.0;
        const double padding = 24.0; // 12.0 padding on left and right
        final double itemWidth = (width - padding - (spacing * (crossAxisCount - 1))) / crossAxisCount;
        
        // Target a comfortable height for each node type card
        final double targetHeight = width > 600 ? 70.0 : 75.0;
        final double childAspectRatio = (itemWidth / targetHeight).clamp(1.1, 3.5);

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: _types.length,
            itemBuilder: (context, index) {
              final type = _types[index];
              final title = isFrench ? type.titleFr : type.titleEn;
              final desc = isFrench ? type.descFr : type.descEn;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF334155).withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: (type.color ?? Colors.white)
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: type.icon != null
                              ? Icon(type.icon, color: type.color, size: 20)
                              : Text(
                                  type.emoji!,
                                  style: const TextStyle(fontSize: 16),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: type.color ?? Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        desc,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

