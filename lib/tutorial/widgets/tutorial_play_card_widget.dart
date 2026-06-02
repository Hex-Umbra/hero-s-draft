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

    // Filter hand in two phases to guide the player:
    // Phase 1 (slime has full HP): show only Strike to target the enemy.
    // Phase 2 (slime took damage): show only Defend to target the hero.
    final displayedHand = hand.where((card) {
      if (enemy != null && enemy.hp == 20) {
        return card.id == 'strike';
      } else {
        return card.id == 'defend';
      }
    }).toList();

    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double scaleHeight = constraints.maxHeight / 280.0;
          final double scaleWidth = constraints.maxWidth / 360.0;
          final double scale = (scaleHeight < scaleWidth ? scaleHeight : scaleWidth).clamp(0.65, 1.4);

          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return SizedBox(
            width: width,
            height: height,
            child: Padding(
              padding: EdgeInsets.all(8.0 * scale),
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
                              ScaffoldMessenger.of(context).clearSnackBars();
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

                              if (_selectedCard!.id == 'strike') {
                                final success = widget.engine.playCard(_selectedCard!);
                                if (success) {
                                  _triggerFloatingText(
                                    '-${_selectedCard!.damage} HP',
                                    Colors.redAccent,
                                  );
                                  setState(() {
                                    _selectedCard = null;
                                  });
                                }
                              } else if (_selectedCard!.id == 'defend') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isFrench
                                          ? 'La Défense doit être jouée sur vous-même ! Touchez votre Héros.'
                                          : 'Defense must be played on yourself! Tap your Hero.',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: MouseRegion(
                              cursor: _selectedCard != null
                                  ? SystemMouseCursors.precise
                                  : SystemMouseCursors.basic,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.all(10 * scale),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (_selectedCard != null && _selectedCard!.id == 'strike')
                                      ? Colors.redAccent.withValues(alpha: 0.08)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: (_selectedCard != null && _selectedCard!.id == 'strike')
                                        ? Colors.redAccent.withValues(alpha: 0.3)
                                        : Colors.transparent,
                                    width: 2 * scale,
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
                                        size: 50 * scale,
                                        color: enemy.hp > 0
                                            ? Colors.greenAccent
                                            : Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 4 * scale),
                                    // Enemy Name
                                    Text(
                                      isFrench ? enemy.nameFr : enemy.nameEn,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11 * scale,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 2 * scale),
                                    // Health Bar
                                    Container(
                                      width: 100 * scale,
                                      height: 10 * scale,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade800,
                                        borderRadius: BorderRadius.circular(5 * scale),
                                      ),
                                      child: Stack(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            width: (100 * scale) * (enemy.hp / enemy.maxHp),
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent,
                                              borderRadius: BorderRadius.circular(5 * scale),
                                            ),
                                          ),
                                          Center(
                                            child: Text(
                                              '${enemy.hp}/${enemy.maxHp}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 8 * scale,
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
                              top: (30 * scale) + _floatingYOffset,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 700),
                                opacity: _floatingYOffset == 0.0 ? 1.0 : 0.0,
                                child: Text(
                                  _floatingText,
                                  style: TextStyle(
                                    color: _floatingColor,
                                    fontSize: 20 * scale,
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
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        if (_selectedCard == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFrench
                                    ? 'Sélectionnez d\'abord la carte de Défense en bas !'
                                    : 'Select the Defend card from the bottom first!',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                          return;
                        }

                        if (_selectedCard!.id == 'defend') {
                          final success = widget.engine.playCard(_selectedCard!);
                          if (success) {
                            _triggerFloatingText(
                              '+${_selectedCard!.armor} 🛡️',
                              Colors.blueAccent,
                            );
                            setState(() {
                              _selectedCard = null;
                            });
                          }
                        } else if (_selectedCard!.id == 'strike') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFrench
                                    ? 'Ne vous attaquez pas vous-même ! Touchez le Slime.'
                                    : 'Don\'t attack yourself! Tap the Slime.',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: MouseRegion(
                        cursor: _selectedCard != null
                            ? SystemMouseCursors.precise
                            : SystemMouseCursors.basic,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                          margin: EdgeInsets.symmetric(vertical: 4 * scale),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10 * scale),
                            border: Border.all(
                              color: (_selectedCard != null && _selectedCard!.id == 'defend')
                                  ? Colors.cyanAccent.withValues(alpha: 0.4)
                                  : Colors.transparent,
                              width: 1.5 * scale,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // HP
                              Row(
                                children: [
                                  Icon(Icons.favorite, color: Colors.red, size: 14 * scale),
                                  SizedBox(width: 6 * scale),
                                  Text(
                                    'HP: $heroHp/$heroMaxHp',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10 * scale,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (heroArmor > 0) ...[
                                    SizedBox(width: 8 * scale),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4 * scale,
                                        vertical: 2 * scale,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent,
                                        borderRadius: BorderRadius.circular(4 * scale),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.shield,
                                            color: Colors.white,
                                            size: 10 * scale,
                                          ),
                                          SizedBox(width: 2 * scale),
                                          Text(
                                            '$heroArmor',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10 * scale,
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
                                    style: TextStyle(
                                      color: Colors.cyanAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10 * scale,
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(3, (index) {
                                      final active = index < mana;
                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 1.0 * scale,
                                        ),
                                        child: Icon(
                                          Icons.diamond_rounded,
                                          color: active
                                              ? Colors.cyanAccent
                                              : Colors.cyan.withValues(alpha: 0.15),
                                          size: 13 * scale,
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
                    ),
                  ),

                  // Bottom Part: Hand
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hand.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(bottom: 6 * scale),
                            child: Text(
                              (enemy?.hp ?? 20) == 20
                                  ? (isFrench
                                      ? "Étape 1 : Sélectionnez 'Frappe Basique' puis touchez le Slime."
                                      : "Step 1: Select 'Basic Strike' then tap the Slime.")
                                  : (isFrench
                                      ? "Étape 2 : Sélectionnez 'Défense' puis touchez votre Héros (la barre PV/Mana)."
                                      : "Step 2: Select 'Defend' then tap your Hero (the HP/Mana bar)."),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 10 * scale,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        Expanded(
                          child: hand.isEmpty
                              ? Center(
                                  child: Text(
                                    isFrench
                                        ? 'Bien joué ! Appuyez sur SUIVANT.'
                                        : 'Well played! Tap NEXT to proceed.',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 12 * scale,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(displayedHand.length, (index) {
                                    final card = displayedHand[index];
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
                                      width: (100 * scale).clamp(70.0, 120.0),
                                      margin: EdgeInsets.symmetric(horizontal: 5 * scale),
                                      child: TutorialUiCard(
                                        title: title,
                                        description: cardDesc,
                                        cost: card.cost,
                                        type: card.id == 'defend' ? 'skill' : 'attack',
                                        isSelected: isSelected,
                                        damage: card.damage,
                                        armor: card.armor,
                                        effectType: card.effectType,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
