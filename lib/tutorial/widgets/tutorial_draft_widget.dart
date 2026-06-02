import 'package:flutter/material.dart';
import '../tutorial_engine.dart';
import 'tutorial_cards_widget.dart'; // Reuses TutorialUiCard

class TutorialDraftWidget extends StatefulWidget {
  final TutorialEngine engine;
  const TutorialDraftWidget({super.key, required this.engine});

  @override
  State<TutorialDraftWidget> createState() => _TutorialDraftWidgetState();
}

class _TutorialDraftWidgetState extends State<TutorialDraftWidget> {
  int? _selectedIndex;
  int? _hoveredIndex;

  static const List<Map<String, dynamic>> _choices = [
    {
      'titleEn': 'Heavy Strike',
      'titleFr': 'Frappe Lourde',
      'descEn': 'Deals 12 damage.',
      'descFr': 'Inflige 12 dégâts.',
      'cost': 2,
      'type': 'attack',
    },
    {
      'titleEn': 'Holy Shield',
      'titleFr': 'Bouclier Divin',
      'descEn': 'Gains 8 Armor.',
      'descFr': 'Gains 8 Armure.',
      'cost': 1,
      'type': 'skill',
    },
    {
      'titleEn': 'Adrenaline',
      'titleFr': 'Adrénaline',
      'descEn': 'Draw 2 cards, gain 1 mana.',
      'descFr': 'Piochez 2 cartes, +1 mana.',
      'cost': 0,
      'type': 'power',
    },
  ];

  @override
  void initState() {
    super.initState();
    widget.engine.resetMockState();
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Header / Instruction
          Text(
            isFrench ? 'Choisissez une récompense :' : 'Choose a reward:',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),

          // 3 cards grid/row
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_choices.length, (index) {
                    final choice = _choices[index];
                    final title = isFrench ? choice['titleFr'] : choice['titleEn'];
                    final desc = isFrench ? choice['descFr'] : choice['descEn'];
                    final cost = choice['cost'] as int;
                    final type = choice['type'] as String;

                    final isSelected = _selectedIndex == index;
                    final isHovered = _hoveredIndex == index;

                    // Scale transition
                    final scale = isSelected ? 1.12 : (isHovered ? 1.05 : 1.0);

                    return Container(
                      width: 95,
                      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                      child: MouseRegion(
                        onEnter: (_) => setState(() => _hoveredIndex = index),
                        onExit: (_) => setState(() => _hoveredIndex = null),
                        cursor: SystemMouseCursors.click,
                        child: AnimatedScale(
                          scale: scale,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.amber.withOpacity(0.4),
                                        blurRadius: 16,
                                        spreadRadius: 3,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: TutorialUiCard(
                              title: title,
                              description: desc,
                              cost: cost,
                              type: type,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedIndex = index;
                                });
                                widget.engine.mockState.hasDrafted = true;
                                widget.engine.playCard(
                                  const TutorialCard(
                                    id: 'dummy',
                                    nameEn: '',
                                    nameFr: '',
                                    cost: 0,
                                    damage: 0,
                                    armor: 0,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
