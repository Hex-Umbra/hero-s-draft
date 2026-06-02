import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialIntentInfo {
  final IconData icon;
  final Color color;
  final String labelEn;
  final String labelFr;
  final String descEn;
  final String descFr;

  const TutorialIntentInfo({
    required this.icon,
    required this.color,
    required this.labelEn,
    required this.labelFr,
    required this.descEn,
    required this.descFr,
  });
}

class TutorialEnemyIntentsWidget extends StatefulWidget {
  final TutorialEngine engine;
  const TutorialEnemyIntentsWidget({super.key, required this.engine});

  @override
  State<TutorialEnemyIntentsWidget> createState() =>
      _TutorialEnemyIntentsWidgetState();
}

class _TutorialEnemyIntentsWidgetState
    extends State<TutorialEnemyIntentsWidget> {
  int _selectedIntentIndex = 0;

  static const List<TutorialIntentInfo> _intents = [
    TutorialIntentInfo(
      icon: Icons.flash_on,
      color: Color(0xFFFF7675),
      labelEn: 'Attack (8)',
      labelFr: 'Attaque (8)',
      descEn:
          'The enemy will deal 8 damage to your hero on their turn. Use Armor cards to block it!',
      descFr:
          'L\'ennemi infligera 8 dégâts à votre héros lors de son tour. Utilisez de l\'Armure pour bloquer !',
    ),
    TutorialIntentInfo(
      icon: Icons.shield,
      color: Color(0xFF448AFF),
      labelEn: 'Defend (6)',
      labelFr: 'Défense (6)',
      descEn:
          'The enemy will gain 6 Armor. Tapping them will deplete their armor before hurting them.',
      descFr:
          'L\'ennemi va gagner 6 Armure. Vos attaques réduiront d\'abord son armure avant ses PV.',
    ),
    TutorialIntentInfo(
      icon: Icons.trending_up,
      color: Color(0xFFE040FB),
      labelEn: 'Buff (+2 Strength)',
      labelFr: 'Renforcement (+2 Force)',
      descEn:
          'The enemy is preparing a power-up. They will gain permanent damage boost (+2 Strength).',
      descFr:
          'L\'ennemi se prépare à augmenter sa puissance. Il va gagner un bonus de dégâts permanent (+2 Force).',
    ),
    TutorialIntentInfo(
      icon: Icons.sick,
      color: Color(0xFF69F0AE),
      labelEn: 'Debuff (Curse)',
      labelFr: 'Affaiblissement (Malédiction)',
      descEn:
          'The enemy will apply a status effect to weaken your stats or clutter your deck with bad cards.',
      descFr:
          'L\'ennemi va vous appliquer un effet négatif pour réduire vos stats ou polluer votre deck.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 380,
          height: 280,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header inside the illustration box
                Row(
                  children: [
                    const Icon(
                      Icons.remove_red_eye_outlined,
                      color: Colors.amberAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isFrench ? 'INTENTIONS ENNEMIES' : 'ENEMY INTENTIONS',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Horizontal view of intents
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_intents.length, (index) {
                    final intent = _intents[index];
                    final isSelected = _selectedIntentIndex == index;
                    final label = isFrench ? intent.labelFr : intent.labelEn;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIntentIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? intent.color.withValues(alpha: 0.18)
                                : intent.color.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? intent.color
                                  : intent.color.withValues(alpha: 0.3),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: intent.color.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(intent.icon, color: intent.color, size: 22),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: intent.color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),

                // Detail display card
                if (_selectedIntentIndex >= 0 &&
                    _selectedIntentIndex < _intents.length)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _intents[_selectedIntentIndex].color.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _intents[_selectedIntentIndex].icon,
                                color: _intents[_selectedIntentIndex].color,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isFrench
                                      ? _intents[_selectedIntentIndex].labelFr
                                      : _intents[_selectedIntentIndex].labelEn,
                                  style: TextStyle(
                                    color: _intents[_selectedIntentIndex].color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white10, height: 10),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Text(
                                isFrench
                                    ? _intents[_selectedIntentIndex].descFr
                                    : _intents[_selectedIntentIndex].descEn,
                                style: TextStyle(
                                  color: Colors.grey.shade300,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

