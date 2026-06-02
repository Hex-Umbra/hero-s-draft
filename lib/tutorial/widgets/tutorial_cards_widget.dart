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
    Color typeColor = Colors.blueAccent;
    if (type == 'attack') typeColor = Colors.redAccent;
    if (type == 'power') typeColor = Colors.amber;

    return AspectRatio(
      aspectRatio: 70 / 110,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            border: Border.all(
              color: isSelected ? Colors.white : typeColor,
              width: isSelected ? 3.0 : 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: typeColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
              // Separator
              Container(
                height: 1,
                width: 30,
                color: typeColor.withValues(alpha: 0.5),
              ),
              // Description
              Expanded(
                child: Center(
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 8.5,
                      height: 1.15,
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
                      size: 11,
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

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
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
          const SizedBox(height: 12),

          // Horizontal view of hand cards
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                          _selectedCardIndex = index;
                        });
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Detail box
          if (_selectedCardIndex >= 0 && _selectedCardIndex < hand.length)
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
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
  }
}

