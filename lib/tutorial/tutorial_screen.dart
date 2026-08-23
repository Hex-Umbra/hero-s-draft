import 'package:flutter/material.dart';
import '../models/data/card_data.dart';
import '../models/data/game_data_registry.dart';
import 'tutorial_engine.dart';
import 'tutorial_step.dart';
import 'tutorial_data.dart';
import 'tutorial_progress_service.dart';
import 'widgets/tutorial_welcome_widget.dart';
import 'widgets/tutorial_class_choice_widget.dart';
import 'widgets/tutorial_starter_deck_widget.dart';
import 'widgets/tutorial_map_widget.dart';
import 'widgets/tutorial_node_types_widget.dart';
import 'widgets/tutorial_combat_overview_widget.dart';
import 'widgets/tutorial_cards_widget.dart';
import 'widgets/tutorial_play_card_widget.dart';
import 'widgets/tutorial_armor_widget.dart';
import 'widgets/tutorial_elements_widget.dart';
import 'widgets/tutorial_enemy_intents_widget.dart';
import 'widgets/tutorial_merge_widget.dart';
import 'widgets/tutorial_xp_widget.dart';
import 'widgets/tutorial_draft_widget.dart';
import 'widgets/tutorial_relics_widget.dart';

class TutorialScreen extends StatefulWidget {
  final GameDataRegistry data;

  const TutorialScreen({super.key, required this.data});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late final TutorialEngine _engine;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _engine = TutorialEngine(data: widget.data);
    _engine.prepareStep(_engine.currentStepIndex);
    _pageController = PageController(initialPage: _engine.currentStepIndex);
    _engine.addListener(_onEngineChanged);
  }

  void _onEngineChanged() {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        _engine.currentStepIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineChanged);
    _engine.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool _isStepActionComplete(TutorialEngine engine) {
    final step = kTutorialSteps[engine.currentStepIndex];
    switch (step.type) {
      case TutorialStepType.playCard:
        final enemy = engine.mockState.enemy;
        return enemy != null &&
            enemy.stats.currentPv < enemy.stats.maxPv &&
            engine.mockState.heroStats.armure > 0;
      case TutorialStepType.merge:
        return engine.mockState.hand.length == 1 &&
            engine.mockState.hand.first.rarity != CardRarity.common;
      case TutorialStepType.xp:
        return engine.mockState.playerLevel > 1;
      case TutorialStepType.draft:
        return engine.mockState.hasDrafted;
      case TutorialStepType.classChoice:
        return engine.mockState.chosenHero != null;
      case TutorialStepType.starterDeck:
        return engine.mockState.masterDeck.isNotEmpty;
      default:
        return true;
    }
  }

  Widget _buildIllustration(TutorialStepType type) {
    switch (type) {
      case TutorialStepType.welcome:
        return TutorialWelcomeWidget(engine: _engine);
      case TutorialStepType.classChoice:
        return TutorialClassChoiceWidget(engine: _engine);
      case TutorialStepType.starterDeck:
        return TutorialStarterDeckWidget(engine: _engine);
      case TutorialStepType.map:
        return TutorialMapWidget(engine: _engine);
      case TutorialStepType.nodeTypes:
        return TutorialNodeTypesWidget(engine: _engine);
      case TutorialStepType.combatOverview:
        return TutorialCombatOverviewWidget(engine: _engine);
      case TutorialStepType.cards:
        return TutorialCardsWidget(engine: _engine);
      case TutorialStepType.playCard:
        return TutorialPlayCardWidget(engine: _engine);
      case TutorialStepType.armorDamage:
        return TutorialArmorWidget(engine: _engine);
      case TutorialStepType.elements:
        return TutorialElementsWidget(engine: _engine);
      case TutorialStepType.enemies:
        return TutorialEnemyIntentsWidget(engine: _engine);
      case TutorialStepType.merge:
        return TutorialMergeWidget(engine: _engine);
      case TutorialStepType.xp:
        return TutorialXpWidget(engine: _engine);
      case TutorialStepType.draft:
        return TutorialDraftWidget(engine: _engine);
      case TutorialStepType.relics:
        return TutorialRelicsWidget(engine: _engine);
    }
  }

  Future<void> _handleNext(bool isComplete) async {
    if (!isComplete) return;

    if (_engine.isLastStep) {
      await TutorialProgressService.markTutorialCompleted();
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      _engine.nextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19), // Deep rich dark blue-gray
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _engine,
          builder: (context, _) {
            final currentStep = kTutorialSteps[_engine.currentStepIndex];
            final stepTitle = isFrench
                ? currentStep.titleFr
                : currentStep.titleEn;
            final stepBody = isFrench ? currentStep.bodyFr : currentStep.bodyEn;
            final isComplete = _isStepActionComplete(_engine);

            return Stack(
              children: [
                // Background subtle glows
                Positioned(
                  top: -100,
                  left: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
                          blurRadius: 100,
                          spreadRadius: 30,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 200,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB45309).withValues(alpha: 0.08),
                          blurRadius: 100,
                          spreadRadius: 30,
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Layout
                Column(
                  children: [
                    // Header row (with skip option)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isFrench
                                ? 'Tutoriel - Étape ${_engine.currentStepIndex + 1}/${kTutorialSteps.length}'
                                : 'Tutorial - Step ${_engine.currentStepIndex + 1}/${kTutorialSteps.length}',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              isFrench ? '✕ Passer' : '✕ Skip',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main Content: Responsive layout builder
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isLandscape = constraints.maxWidth > constraints.maxHeight && constraints.maxHeight < 500 || constraints.maxWidth >= 720;

                          Widget buildIllustrationView(bool isLand) {
                            return PageView.builder(
                              controller: _pageController,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: kTutorialSteps.length,
                              itemBuilder: (context, index) {
                                final stepType = kTutorialSteps[index].type;
                                return Container(
                                  margin: EdgeInsets.only(
                                    left: 16,
                                    right: isLand ? 8 : 16,
                                    bottom: isLand ? 16 : 0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF131A2D),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFF1E293B),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: _buildIllustration(stepType),
                                  ),
                                );
                              },
                            );
                          }

                          Widget buildTextPanel(bool isLand) {
                            return Container(
                              margin: EdgeInsets.only(
                                left: isLand ? 8 : 16,
                                right: 16,
                                bottom: 16,
                              ),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF131A2D).withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isComplete
                                      ? Colors.amber.withValues(alpha: 0.3)
                                      : const Color(0xFF1E293B),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Step Title
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Text(
                                      stepTitle,
                                      key: ValueKey<int>(_engine.currentStepIndex),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Step Body Text
                                  Expanded(
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 200),
                                        child: Text(
                                          stepBody,
                                          key: ValueKey<int>(
                                            _engine.currentStepIndex,
                                          ),
                                          style: TextStyle(
                                            color: Colors.grey.shade300,
                                            fontSize: 13.5,
                                            height: 1.45,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Progress indicators & Next button
                                  Row(
                                    children: [
                                      // Back Button (only if currentStepIndex > 0)
                                      if (_engine.currentStepIndex >
                                          _engine.minReachableStep)
                                        IconButton(
                                          onPressed: () => _engine.prevStep(),
                                          icon: const Icon(
                                            Icons.arrow_back_ios_new,
                                            color: Colors.grey,
                                            size: 16,
                                          ),
                                          tooltip: isFrench ? 'Précédent' : 'Previous',
                                          padding: const EdgeInsets.all(8),
                                          constraints: const BoxConstraints(),
                                        )
                                      else
                                        const SizedBox(width: 32),
                                      const SizedBox(width: 8),

                                      // Steps Indicator Dots (Centered & Scrollable if needed)
                                      Expanded(
                                        child: Center(
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: List.generate(
                                                kTutorialSteps.length,
                                                (index) {
                                                  final isActive =
                                                      index == _engine.currentStepIndex;
                                                  return AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 200,
                                                    ),
                                                    margin: const EdgeInsets.symmetric(
                                                      horizontal: 2.5,
                                                    ),
                                                    width: isActive ? 10 : 5,
                                                    height: 5,
                                                    decoration: BoxDecoration(
                                                      color: isActive
                                                          ? Colors.amber
                                                          : Colors.grey.shade600,
                                                      borderRadius: BorderRadius.circular(
                                                        10,
                                                      ),
                                                      boxShadow: isActive
                                                          ? [
                                                              BoxShadow(
                                                                color: Colors.amber
                                                                    .withValues(alpha: 0.5),
                                                                blurRadius: 4,
                                                                spreadRadius: 1,
                                                              ),
                                                            ]
                                                          : null,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Action / Next Button
                                      InkWell(
                                        onTap: isComplete
                                            ? () => _handleNext(isComplete)
                                            : null,
                                        borderRadius: BorderRadius.circular(12),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            gradient: isComplete
                                                ? const LinearGradient(
                                                    colors: [
                                                      Color(0xFFD97706),
                                                      Color(0xFFF59E0B),
                                                    ],
                                                  )
                                                : null,
                                            color: isComplete
                                                ? null
                                                : const Color(0xFF1E293B),
                                            boxShadow: isComplete
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.amber.withValues(alpha: 0.3),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 3),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              _engine.isLastStep
                                                  ? (isFrench ? 'TERMINER' : 'FINISH')
                                                  : (isComplete
                                                        ? (isFrench
                                                              ? 'SUIVANT'
                                                              : 'NEXT')
                                                        : (isFrench
                                                              ? 'AGIR'
                                                              : 'ACTION')),
                                              style: TextStyle(
                                                color: isComplete
                                                    ? Colors.white
                                                    : Colors.grey.shade500,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }

                          if (isLandscape) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: buildIllustrationView(true),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: buildTextPanel(true),
                                ),
                              ],
                            );
                          } else {
                            // Portrait: give illustration a generous fixed height
                            // derived from available constraints to avoid over-constraining
                            // the inner FittedBox widgets. The text panel takes the rest.
                            final illustrationHeight =
                                (constraints.maxHeight * 0.58).clamp(280.0, 520.0);
                            return Column(
                              children: [
                                SizedBox(
                                  height: illustrationHeight,
                                  child: buildIllustrationView(false),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: buildTextPanel(false),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

