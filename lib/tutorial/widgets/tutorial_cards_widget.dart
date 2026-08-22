import 'package:flutter/material.dart';
import '../../models/card_instance.dart';
import '../tutorial_engine.dart';
import '../tutorial_fixtures.dart';

/// Dérive un score d'effet scalaire (dégâts, armure) depuis les données
/// réelles de la carte, en appliquant le multiplicateur de rareté.
///
/// Collage jetable : `TutorialUiCard` prend encore des scalaires. La Task 8
/// supprime ce widget et cet helper avec.
int _effectValue(CardInstance card, String type) {
  for (final effect in card.data.effects) {
    if (effect.type == type) {
      return (effect.value * card.rarityMultiplier).round();
    }
  }
  return 0;
}

/// Dérive l'identifiant de statut élémentaire (ex: 'burn') appliqué par la
/// carte, s'il y en a un. Même statut jetable que `_effectValue`.
String? _effectStatusId(CardInstance card) {
  for (final effect in card.data.effects) {
    if (effect.type == 'apply_status') return effect.statusId;
  }
  return null;
}

class TutorialUiCard extends StatelessWidget {
  final String title;
  final String description;
  final int cost;
  final String type; // 'attack', 'skill', 'power'
  final bool isSelected;
  final VoidCallback onTap;
  final int damage;
  final int armor;
  final String? effectType;
  final int? effectValue;

  const TutorialUiCard({
    super.key,
    required this.title,
    required this.description,
    required this.cost,
    required this.type,
    required this.isSelected,
    required this.onTap,
    this.damage = 0,
    this.armor = 0,
    this.effectType,
    this.effectValue,
  });

  Widget _buildCompactDescription(BuildContext context) {
    final List<Widget> badges = [];

    if (damage > 0) {
      badges.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.hardware_rounded, // Hammer/Attack icon like real game
              color: Colors.redAccent,
              size: 18,
            ),
            const SizedBox(width: 2),
            Text(
              '$damage',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (armor > 0) {
      if (badges.isNotEmpty) {
        badges.add(const SizedBox(width: 4));
      }
      badges.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shield_rounded, // Shield/Armor icon like real game
              color: Colors.blueAccent,
              size: 18,
            ),
            const SizedBox(width: 2),
            Text(
              '$armor',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (effectType != null) {
      if (badges.isNotEmpty) {
        badges.add(const SizedBox(width: 4));
      }
      IconData elementIcon = Icons.help_outline;
      Color elementColor = Colors.grey;

      if (effectType == 'fire' || effectType == 'burn') {
        elementIcon = Icons.local_fire_department_rounded;
        elementColor = Colors.orangeAccent;
      } else if (effectType == 'poison') {
        elementIcon = Icons.science_rounded;
        elementColor = Colors.greenAccent;
      } else if (effectType == 'cold' || effectType == 'freeze') {
        elementIcon = Icons.ac_unit_rounded;
        elementColor = Colors.lightBlueAccent;
      } else if (effectType == 'shock' || effectType == 'lightning') {
        elementIcon = Icons.flash_on_rounded;
        elementColor = Colors.amberAccent;
      }

      badges.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              elementIcon,
              color: elementColor,
              size: 18,
            ),
            if (effectValue != null && effectValue! > 0) ...[
              const SizedBox(width: 2),
              Text(
                '$effectValue',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Fallback if no specific values are provided
    if (badges.isEmpty) {
      return Text(
        description,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade400,
          fontSize: 9.5,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          height: 1.2,
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: badges,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color typeColor = Colors.cyanAccent;
    if (type == 'attack') typeColor = const Color(0xFFF43F5E); // Sleek Rose/Red
    if (type == 'power') typeColor = const Color(0xFFF59E0B); // Amber
    if (type == 'skill') typeColor = const Color(0xFF3B82F6); // Blue

    return AspectRatio(
      aspectRatio: 70 / 110,
      child: Tooltip(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF131A2D).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: typeColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        preferBelow: false,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          height: 1.3,
        ),
        richMessage: TextSpan(
          children: [
            TextSpan(
              text: '${title.toUpperCase()}\n',
              style: TextStyle(
                color: typeColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const TextSpan(text: '\n'),
            TextSpan(
              text: description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected
                    ? [
                        const Color(0xFF1E293B),
                        typeColor.withValues(alpha: 0.15),
                      ]
                    : [
                        const Color(0xFF111827),
                        const Color(0xFF1F2937),
                      ],
              ),
              border: Border.all(
                color: isSelected ? typeColor : typeColor.withValues(alpha: 0.4),
                width: isSelected ? 2.5 : 1.2,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: typeColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Separator
                Container(
                  height: 1.5,
                  width: 24,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                // Description (Replaced with elements/icons)
                Expanded(
                  child: Center(
                    child: _buildCompactDescription(context),
                  ),
                ),
                // Mana crystals
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    cost,
                    (index) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 1),
                      child: Icon(
                        Icons.diamond_rounded,
                        color: Colors.cyanAccent,
                        size: 12,
                      ),
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

class TutorialCardsWidget extends StatefulWidget {
  final TutorialEngine engine;
  const TutorialCardsWidget({super.key, required this.engine});

  @override
  State<TutorialCardsWidget> createState() => _TutorialCardsWidgetState();
}

class _TutorialCardsWidgetState extends State<TutorialCardsWidget> {
  int _selectedCardIndex = 0;

  // Pas de resetMockState() ici : `TutorialEngine.nextStep()`/`prevStep()`
  // l'ont déjà appelé avant que cette page ne soit montée. Le refaire ici
  // déclencherait notifyListeners() en plein passage de build de la
  // PageView (le AnimatedBuilder parent est déjà construit cette frame),
  // ce que Flutter refuse : « setState() or markNeedsBuild() called during
  // build. »

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';
    final hand = widget.engine.mockState.hand;
    final mana = widget.engine.mockState.heroStats.currentMana;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate dynamic size of card, making it responsive to available width
        final cardWidth = (constraints.maxWidth * 0.28).clamp(85.0, 110.0);

        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Mana crystals row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isFrench ? 'MANA : ' : 'MANA: ',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Row(
                    children: List.generate(3, (index) {
                      final active = index < mana;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Icon(
                          Icons.diamond_rounded,
                          color: active
                              ? Colors.cyanAccent
                              : Colors.cyan.withValues(alpha: 0.2),
                          size: 20,
                        ),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Responsive Wrap layout for cards
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(hand.length, (index) {
                        final card = hand[index];
                        final isSelected = _selectedCardIndex == index;
                        final title = card.data.getName(isFrench ? 'fr' : 'en');

                        // Simple text descriptions for mockup
                        String cardDesc = '';
                        if (card.data.id == TutorialFixtureIds.strike) {
                          cardDesc = isFrench ? 'Inflige 6 dégâts.' : 'Deals 6 damage.';
                        } else if (card.data.id == TutorialFixtureIds.defend) {
                          cardDesc = isFrench ? 'Gagne 4 armure.' : 'Gains 4 armor.';
                        } else {
                          cardDesc = isFrench
                              ? 'Inflige 10 dégâts et brûle.'
                              : 'Deals 10 damage & burns.';
                        }

                        return SizedBox(
                          width: cardWidth,
                          child: TutorialUiCard(
                            title: title,
                            description: cardDesc,
                            cost: card.currentCost,
                            type: card.data.id == TutorialFixtureIds.defend
                                ? 'skill'
                                : 'attack',
                            isSelected: isSelected,
                            damage: _effectValue(card, 'damage'),
                            armor: _effectValue(card, 'armor'),
                            effectType: _effectStatusId(card),
                            onTap: () {
                              setState(() {
                                _selectedCardIndex = index;
                              });
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Detail box
              if (_selectedCardIndex >= 0 && _selectedCardIndex < hand.length)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.cyan.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    isFrench
                        ? 'Chaque cristal 💎 vaut 1 mana. La carte sélectionnée coûte ${hand[_selectedCardIndex].currentCost} mana.'
                        : 'Each crystal 💎 counts as 1 mana. The selected card costs ${hand[_selectedCardIndex].currentCost} mana.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
