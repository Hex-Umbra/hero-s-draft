import 'package:flutter/material.dart';
import '../tutorial_engine.dart';
import 'tutorial_cards_widget.dart'; // Reuses TutorialUiCard

class TutorialPlayCardWidget extends StatefulWidget {
  final TutorialEngine engine;
  const TutorialPlayCardWidget({super.key, required this.engine});

  @override
  State<TutorialPlayCardWidget> createState() => _TutorialPlayCardWidgetState();
}

class _TutorialPlayCardWidgetState extends State<TutorialPlayCardWidget> {
  TutorialCard? _selectedCard;
  bool _showFloatingText = false;
  String _floatingText = '';
  Color _floatingColor = Colors.red;
  double _floatingYOffset = 0.0;

  @override
  void initState() {
    super.initState();
    widget.engine.resetMockState();
  }

  void _triggerFloatingText(String text, Color color) {
    setState(() {
      _floatingText = text;
      _floatingColor = color;
      _showFloatingText = true;
      _floatingYOffset = 0.0;
    });

    // Animate upward
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          _floatingYOffset = -40.0;
        });
      }
    });

    // Fade out
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showFloatingText = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';
    final hand = widget.engine.mockState.hand;
    final enemy = widget.engine.mockState.enemy;
    final heroHp = widget.engine.mockState.heroHp;
    final heroMaxHp = widget.engine.mockState.heroMaxHp;
    final heroArmor = widget.engine.mockState.heroArmor;
    final mana = widget.engine.mockState.heroMana;

    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 360,
          height: 280,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Top Part: Slime Enemy
                if (enemy != null)
                  Expanded(
                    flex: 5,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Slime Body
                        GestureDetector(
                          onTap: () {
                            if (_selectedCard == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isFrench
                                        ? 'Sélectionnez d\'abord une carte en bas !'
                                        : 'Select a card from the bottom first!',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                              return;
                            }

                            final success = widget.engine.playCard(_selectedCard!);
                            if (success) {
                              if (_selectedCard!.damage > 0) {
                                _triggerFloatingText(
                                  '-${_selectedCard!.damage} HP',
                                  Colors.redAccent,
                                );
                              } else if (_selectedCard!.armor > 0) {
                                _triggerFloatingText(
                                  '+${_selectedCard!.armor} 🛡️',
                                  Colors.blueAccent,
                                );
                              }
                              setState(() {
                                _selectedCard = null;
                              });
                            }
                          },
                          child: MouseRegion(
                            cursor: _selectedCard != null
                                ? SystemMouseCursors.precise
                                : SystemMouseCursors.basic,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _selectedCard != null
                                    ? Colors.redAccent.withOpacity(0.08)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: _selectedCard != null
                                      ? Colors.redAccent.withOpacity(0.3)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Monster Icon (Slime representation)
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.95, end: 1.05),
                                    duration: const Duration(milliseconds: 1500),
                                    curve: Curves.easeInOutSine,
                                    builder: (context, val, child) {
                                      return Transform.scale(
                                        scale: val,
                                        child: child,
                                      );
                                    },
                                    child: Icon(
                                      Icons.pest_control_rodent_rounded,
                                      size: 50,
                                      color: enemy.hp > 0
                                          ? Colors.greenAccent
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Enemy Name
                                  Text(
                                    isFrench ? enemy.nameFr : enemy.nameEn,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  // Health Bar
                                  Container(
                                    width: 100,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade800,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Stack(
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          width: 100 * (enemy.hp / enemy.maxHp),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent,
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            '${enemy.hp}/${enemy.maxHp}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Floating Damage/Block Text Overlay
                        if (_showFloatingText)
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutQuad,
                            top: 30 + _floatingYOffset,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 700),
                              opacity: _showFloatingText ? 0.0 : 1.0,
                              child: Text(
                                _floatingText,
                                style: TextStyle(
                                  color: _floatingColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 4,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                // Mid Part: Hero Stats Mock (Health and Mana)
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // HP
                        Row(
                          children: [
                            const Icon(Icons.favorite, color: Colors.red, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'HP: $heroHp/$heroMaxHp',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (heroArmor > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.shield,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '$heroArmor',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Mana
                        Row(
                          children: [
                            Text(
                              isFrench ? 'MANA : ' : 'MANA: ',
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            Row(
                              children: List.generate(3, (index) {
                                final active = index < mana;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 1.0,
                                  ),
                                  child: Icon(
                                    Icons.diamond_rounded,
                                    color: active
                                        ? Colors.cyanAccent
                                        : Colors.cyan.withOpacity(0.15),
                                    size: 13,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Part: Hand
                Expanded(
                  flex: 4,
                  child: hand.isEmpty
                      ? Center(
                          child: Text(
                            isFrench
                                ? 'Bien joué ! Appuyez sur SUIVANT.'
                                : 'Well played! Tap NEXT to proceed.',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(hand.length, (index) {
                            final card = hand[index];
                            final isSelected = _selectedCard == card;
                            final title = isFrench ? card.nameFr : card.nameEn;

                            String cardDesc = '';
                            if (card.id == 'strike') {
                              cardDesc = isFrench
                                  ? 'Inflige 6 dégâts.'
                                  : 'Deals 6 damage.';
                            } else {
                              cardDesc = isFrench
                                  ? 'Gagne 4 armure.'
                                  : 'Gains 4 armor.';
                            }

                            return Container(
                              width: 85,
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              child: TutorialUiCard(
                                title: title,
                                description: cardDesc,
                                cost: card.cost,
                                type: card.id == 'defend' ? 'skill' : 'attack',
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _selectedCard = isSelected ? null : card;
                                  });
                                },
                              ),
                            );
                          }),
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
