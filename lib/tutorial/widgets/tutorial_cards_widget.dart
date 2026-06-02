import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialUiCard extends StatelessWidget {
  final String title;
  final String description;
  final int cost;
  final String type; // 'attack', 'skill', 'power'
  final bool isSelected;
  final VoidCallback onTap;

  const TutorialUiCard({
    super.key,
    required this.title,
    required this.description,
    required this.cost,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color typeColor = Colors.cyanAccent;
    if (type == 'attack') typeColor = const Color(0xFFF43F5E); // Sleek Rose/Red
    if (type == 'power') typeColor = const Color(0xFFF59E0B); // Amber
    if (type == 'skill') typeColor = const Color(0xFF3B82F6); // Blue

    return AspectRatio(
      aspectRatio: 70 / 110,
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
              // Description
              Expanded(
                child: Center(
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade400,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      height: 1.2,
                    ),
                  ),
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

  @override
  void initState() {
    super.initState();
    // Ensure the mock state is populated for this step
    widget.engine.resetMockState();
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';
    final hand = widget.engine.mockState.hand;
    final mana = widget.engine.mockState.heroMana;

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
                        final title = isFrench ? card.nameFr : card.nameEn;

                        // Simple text descriptions for mockup
                        String cardDesc = '';
                        if (card.id == 'strike') {
                          cardDesc = isFrench ? 'Inflige 6 dégâts.' : 'Deals 6 damage.';
                        } else if (card.id == 'defend') {
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
                            cost: card.cost,
                            type: card.id == 'defend' ? 'skill' : 'attack',
                            isSelected: isSelected,
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
                        ? 'Chaque cristal 💎 vaut 1 mana. La carte sélectionnée coûte ${hand[_selectedCardIndex].cost} mana.'
                        : 'Each crystal 💎 counts as 1 mana. The selected card costs ${hand[_selectedCardIndex].cost} mana.',
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
