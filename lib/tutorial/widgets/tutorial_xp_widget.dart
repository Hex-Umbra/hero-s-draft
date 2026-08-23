import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialXpWidget extends StatefulWidget {
  final TutorialEngine engine;
  const TutorialXpWidget({super.key, required this.engine});

  @override
  State<TutorialXpWidget> createState() => _TutorialXpWidgetState();
}

class _TutorialXpWidgetState extends State<TutorialXpWidget> {
  bool _showLevelUpBanner = false;

  // Pas de resetMockState() ici : `TutorialEngine.nextStep()`/`prevStep()`
  // l'ont déjà appelé avant que cette page ne soit montée, donc le
  // refaire ici est redondant. C'est aussi dangereux : `TutorialScreen`
  // reconstruit tout le sous-arbre de la PageView au franchissement d'un
  // seuil de layout (bascule portrait/paysage, ou largeur 720px), ce qui
  // rejoue initState() ici sans que `_currentStepIndex` ait changé.
  // `resetScratch()` effacerait alors une progression déjà validée
  // (`playerLevel`) et re-verrouillerait le bouton SUIVANT. Si un futur
  // cas de `resetMockState()` venait en plus semer `seedHand`/`seedEnemy`
  // pour cette étape, `notifyListeners()` partirait en plein passage de
  // build de la PageView, ce que Flutter refuse : « setState() or
  // markNeedsBuild() called during build. »
  @override
  void initState() {
    super.initState();
    widget.engine.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.engine.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (!mounted) return;
    if (widget.engine.mockState.playerLevel > 1 && !_showLevelUpBanner) {
      setState(() {
        _showLevelUpBanner = true;
      });
      // Hide banner after delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _showLevelUpBanner = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';
    final state = widget.engine.mockState;
    final progress = (state.playerXp / state.xpToNextLevel).clamp(0.0, 1.0);
    // L'XP du Gobelin vient du registre (enemies.json) : jamais recopiée en dur ici.
    final goblinXp = widget.engine.fixtures.goblin.xp;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Main view content
        Center(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hero Level Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.amber, width: 1.5),
                    ),
                    child: Text(
                      isFrench
                          ? 'Niveau : ${state.playerLevel}'
                          : 'Level: ${state.playerLevel}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // XP Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isFrench ? 'EXPÉRIENCE' : 'EXPERIENCE',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '${state.playerXp}/${state.xpToNextLevel} XP',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Stack(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.purpleAccent,
                                        Colors.blueAccent,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Drafts en attente : tant qu'il en reste, la carte du monde
                  // est verrouillée (map_screen.dart, _onNodeTap).
                  if (widget.engine.pendingDrafts > 0) ...[
                    Text(
                      isFrench
                          ? 'Drafts en attente : ${widget.engine.pendingDrafts}'
                          : 'Pending drafts: ${widget.engine.pendingDrafts}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action button
                  if (state.playerLevel == 1)
                    InkWell(
                      onTap: () => widget.engine.gainXp(goblinXp),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xFF1E293B),
                          border: Border.all(
                            color: Colors.purpleAccent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          isFrench
                              ? 'Battre un Gobelin (+$goblinXp XP) ⚔️'
                              : 'Defeat a Goblin (+$goblinXp XP) ⚔️',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    Text(
                      isFrench
                          ? 'Passage de niveau atteint ! 🎉'
                          : 'Level Up Achieved! 🎉',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Golden Level Up Overlay Banner
        if (_showLevelUpBanner)
          Positioned.fill(
            child: Container(
              color: Colors.black45,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      isFrench ? 'LEVEL UP ! 👑' : 'LEVEL UP ! 👑',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
