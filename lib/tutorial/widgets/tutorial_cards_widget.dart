import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';

import '../../ui/widgets/ui_card.dart';
import '../tutorial_engine.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final isFrench = locale == 'fr';
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

                        return SizedBox(
                          width: cardWidth,
                          child: UiCard.fromInstance(
                            card: card,
                            locale: locale,
                            l10n: l10n,
                            isSelected: isSelected,
                            onTap: () => setState(() => _selectedCardIndex = index),
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
