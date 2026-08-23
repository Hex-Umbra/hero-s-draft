import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../tutorial_engine.dart';
import '../../game/services/level_up_reward_service.dart';
import '../../ui/widgets/draft/draft_choice_card.dart';
import '../../ui/widgets/draft/draft_choice_labels.dart';

class TutorialDraftWidget extends StatefulWidget {
  final TutorialEngine engine;
  const TutorialDraftWidget({super.key, required this.engine});

  @override
  State<TutorialDraftWidget> createState() => _TutorialDraftWidgetState();
}

class _TutorialDraftWidgetState extends State<TutorialDraftWidget> {
  int? _selectedIndex;
  int? _hoveredIndex;
  late final List<DraftChoice> _choices;

  @override
  void initState() {
    super.initState();
    // Pas de resetMockState() ici : `TutorialEngine.nextStep()`/`prevStep()`
    // l'ont déjà appelé avant que cette page ne soit montée, donc le
    // refaire ici est redondant. C'est aussi dangereux : `TutorialScreen`
    // reconstruit tout le sous-arbre de la PageView au franchissement d'un
    // seuil de layout (bascule portrait/paysage, ou largeur 720px), ce qui
    // rejoue initState() ici sans que `_currentStepIndex` ait changé.
    // `resetScratch()` effacerait alors une progression déjà validée
    // (`hasDrafted`) et re-verrouillerait le bouton SUIVANT. Si un futur
    // cas de `resetMockState()` venait en plus semer `seedHand`/`seedEnemy`
    // pour cette étape, `notifyListeners()` partirait en plein passage de
    // build de la PageView, ce que Flutter refuse : « setState() or
    // markNeedsBuild() called during build. »
    //
    // `_choices` en revanche est de l'état purement local à ce widget (pas
    // le moteur du tutoriel) : le tirer ici via le vrai service de draft,
    // avec luck: 0 (Chance d'un héros niveau 1), est donc légitime et rend
    // la démo fidèle au vrai premier draft du jeu.
    _choices = LevelUpRewardService.generateChoices(luck: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive size of choice cards
        final double cardWidth = (constraints.maxWidth * 0.28).clamp(95.0, 150.0);
        final double cardHeight = cardWidth * 1.45;

        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              // Header / Instruction
              Text(
                isFrench ? 'Choisissez une récompense :' : 'Choose a reward:',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Responsive choices container using Wrap
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(_choices.length, (index) {
                        final choice = _choices[index];
                        final title = DraftChoiceLabels.getChoiceTitle(l10n, choice);
                        final desc = DraftChoiceLabels.getChoiceDescription(l10n, choice);
                        final rarity = DraftChoiceLabels.rarityToString(l10n, choice.rarity);

                        final isSelected = _selectedIndex == index;
                        final isHovered = _hoveredIndex == index;

                        final scale = isSelected ? 1.08 : (isHovered ? 1.04 : 1.0);

                        return MouseRegion(
                          onEnter: (_) => setState(() => _hoveredIndex = index),
                          onExit: (_) => setState(() => _hoveredIndex = null),
                          cursor: SystemMouseCursors.click,
                          child: AnimatedScale(
                            scale: scale,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: cardWidth,
                              height: cardHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.amber.withValues(alpha: 0.4),
                                          blurRadius: 16,
                                          spreadRadius: 3,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: DraftChoiceCard(
                                  title: title,
                                  description: desc,
                                  rarity: rarity,
                                  onTap: () {
                                    setState(() {
                                      _selectedIndex = index;
                                    });
                                    widget.engine.draftReward();
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
      },
    );
  }
}
