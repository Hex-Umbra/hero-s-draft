import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class NodeTypeInfo {
  final IconData icon;
  final Color color;
  final String titleEn;
  final String titleFr;
  final String descEn;
  final String descFr;

  const NodeTypeInfo({
    required this.icon,
    required this.color,
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
      descEn: 'Buy cards, relics, or clean deck.',
      descFr: 'Achetez des cartes, reliques ou épurés.',
    ),
    NodeTypeInfo(
      icon: Icons.nightlight_round,
      color: Colors.greenAccent,
      titleEn: 'Rest Site',
      titleFr: 'Repos',
      descEn: 'Heal health or upgrade a card.',
      descFr: 'Soignez vos PV ou forgez une carte.',
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
      icon: Icons.dangerous,
      color: Colors.purpleAccent,
      titleEn: 'Boss',
      titleFr: 'Boss',
      descEn: 'Defeat to complete the current Act.',
      descFr: 'Battez-le pour terminer l\'Acte.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth < 450 ? 2 : 3;
          final childAspectRatio = constraints.maxWidth < 450 ? 1.8 : 1.65;

          return GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: _types.length,
            itemBuilder: (context, index) {
              final type = _types[index];
              final title = isFrench ? type.titleFr : type.titleEn;
              final desc = isFrench ? type.descFr : type.descEn;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF334155).withOpacity(0.5),
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
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: type.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(type.icon, color: type.color, size: 15),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: type.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        desc,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 9.5,
                          height: 1.25,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
