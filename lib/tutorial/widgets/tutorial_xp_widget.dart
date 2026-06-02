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

  @override
  void initState() {
    super.initState();
    widget.engine.resetMockState();
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

    return Stack(
      alignment: Alignment.center,
      children: [
        // Main view content
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hero Level Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber, width: 1.5),
                ),
                child: Text(
                  isFrench ? 'Niveau : ${state.playerLevel}' : 'Level: ${state.playerLevel}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),

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
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${state.playerXp}/${state.xpToNextLevel} XP',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.purpleAccent, Colors.blueAccent],
                                ),
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action button
              if (state.playerLevel == 1)
                InkWell(
                  onTap: () => widget.engine.gainXp(35),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFF1E293B),
                      border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                    ),
                    child: Text(
                      isFrench ? 'Battre un Ennemi (+35 XP) ⚔️' : 'Defeat an Enemy (+35 XP) ⚔️',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  isFrench ? 'Passage de niveau atteint ! 🎉' : 'Level Up Achieved! 🎉',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
            ],
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
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
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
