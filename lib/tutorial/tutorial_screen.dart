import 'package:flutter/material.dart';
import 'tutorial_engine.dart';
import 'tutorial_step.dart';
import 'tutorial_data.dart';
import 'tutorial_progress_service.dart';
import 'widgets/tutorial_welcome_widget.dart';
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
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late final TutorialEngine _engine;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _engine = TutorialEngine();
    _engine.resetMockState();
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
        return engine.mockState.enemy != null && engine.mockState.enemy!.hp < 20;
      case TutorialStepType.merge:
        return engine.mockState.hand.length == 1 &&
            engine.mockState.hand.first.id == 'strike_upgraded';
      case TutorialStepType.xp:
        return engine.mockState.playerLevel > 1;
      case TutorialStepType.draft:
        return engine.mockState.hasDrafted;
      default:
        return true;
    }
  }

  Widget _buildIllustration(TutorialStepType type) {
    switch (type) {
      case TutorialStepType.welcome:
        return TutorialWelcomeWidget(engine: _engine);
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
            final stepTitle = isFrench ? currentStep.titleFr : currentStep.titleEn;
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
                      color: const Color(0xFF1E3A8A).withOpacity(0.15),
                      blurRadius: 100,
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
                      color: const Color(0xFFB45309).withOpacity(0.08),
                      blurRadius: 100,
                    ),
                  ),
                ),

                // Main Layout
                Column(
                  children: [
                    // Header row (with skip option)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

                    // Top 60%: Illustration Widget View
                    Expanded(
                      flex: 6,
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: kTutorialSteps.length,
                        itemBuilder: (context, index) {
                          final stepType = kTutorialSteps[index].type;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131A2D),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF1E293B),
                                width: 1.5,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _buildIllustration(stepType),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bottom 40%: Text panel + Buttons
                    Expanded(
                      flex: 4,
                      child: Container(
                        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131A2D).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isComplete
                                ? Colors.amber.withOpacity(0.3)
                                : const Color(0xFF1E293B),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
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
                                    key: ValueKey<int>(_engine.currentStepIndex),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Steps Indicator Dots
                                Row(
                                  children: List.generate(
                                    kTutorialSteps.length,
                                    (index) {
                                      final isActive = index == _engine.currentStepIndex;
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                        width: isActive ? 10 : 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? Colors.amber
                                              : Colors.grey.shade600,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: isActive
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.amber.withOpacity(0.5),
                                                    blurRadius: 4,
                                                    spreadRadius: 1,
                                                  )
                                                ]
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // Action / Next Button
                                InkWell(
                                  onTap: isComplete ? () => _handleNext(isComplete) : null,
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
                                              colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                                            )
                                          : null,
                                      color: isComplete ? null : const Color(0xFF1E293B),
                                      boxShadow: isComplete
                                          ? [
                                              BoxShadow(
                                                color: Colors.amber.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        _engine.isLastStep
                                            ? (isFrench ? 'TERMINER' : 'FINISH')
                                            : (isComplete
                                                ? (isFrench ? 'SUIVANT' : 'NEXT')
                                                : (isFrench ? 'AGIR' : 'ACTION')),
                                        style: TextStyle(
                                          color: isComplete ? Colors.white : Colors.grey.shade500,
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
