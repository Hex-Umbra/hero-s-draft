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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

                return Expanded(
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
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.4),
                                    blurRadius: 16,
                                    spreadRadius: 3,
                                  )
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
                            // Notify screen to enable Next button
                            widget.engine.nextStep(); // Advance or notify?
                            // Actually, standard behavior is we update state and let user tap NEXT.
                            // Let's notify listeners.
                            widget.engine.playCard(const TutorialCard(id: 'dummy', nameEn: '', nameFr: '', cost: 0, damage: 0, armor: 0));
                            // Wait, playCard triggers notifyListeners. Or we can just call:
                            // widget.engine.notifyListeners() if we expose it, but wait: 
                            // in TutorialEngine, playCard is one way to notify. Let's look at TutorialEngine:
                            // we can call playCard with a dummy card or we can just trigger a state change.
                            // In _selectedIndex tap, we just set hasDrafted = true and trigger notifyListeners.
                            // But notifyListeners is protected in ChangeNotifier!
                            // Ah! Let's check: playCard is public and calls notifyListeners!
                            // Yes, in TutorialEngine, playCard has notifyListeners at the end.
                            // Wait! Let's check if we can call playCard or if we should add a specific method.
                            // Wait, playCard takes a TutorialCard. We can just call playCard(card) or we can call a dummy action.
                            // Actually, we can check how we defined TutorialEngine:
                            // playCard(TutorialCard card) removes the card from hand and modifies mana. That is not ideal for the draft screen because hand is empty!
                            // Let's see: how did we implement TutorialEngine?
                            // Let's call playCard or do we have another notify trigger?
                            // Wait! In TutorialEngine:
                            // mockState has hand, deck, enemy, playerXp, playerLevel, hasDrafted.
                            // Wait, if playCard is called, it returns false if mana is insufficient or does card playing.
                            // We can just call playCard of a 0-cost card! But wait, does it remove from hand?
                            // "mockState.hand.remove(card)"
                            // If the card is not in the hand, remove does nothing and it returns true!
                            // So calling playCard with a 0-cost dummy card works perfectly to trigger notifyListeners.
                            // Let's do:
                            // widget.engine.playCard(const TutorialCard(id: 'dummy', nameEn: '', nameFr: '', cost: 0, damage: 0, armor: 0));
                            // That triggers notifyListeners cleanly!
                          },
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

