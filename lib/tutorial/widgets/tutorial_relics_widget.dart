import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialRelicsWidget extends StatefulWidget {
  final TutorialEngine engine;
  const TutorialRelicsWidget({super.key, required this.engine});

  @override
  State<TutorialRelicsWidget> createState() => _TutorialRelicsWidgetState();
}

class _TutorialRelicsWidgetState extends State<TutorialRelicsWidget> {
  bool _isCollected = false;
  double _relicScale = 1.0;
  double _relicOpacity = 1.0;

  void _collectRelic() {
    if (_isCollected) return;

    setState(() {
      _relicScale = 0.2;
      _relicOpacity = 0.0;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _isCollected = true;
        });
      }
    });
  }

  // Pas de resetMockState() ici : `TutorialEngine.nextStep()`/`prevStep()`
  // l'ont déjà appelé avant que cette page ne soit montée, donc le
  // refaire ici est redondant. C'est aussi dangereux : `TutorialScreen`
  // reconstruit tout le sous-arbre de la PageView au franchissement d'un
  // seuil de layout (bascule portrait/paysage, ou largeur 720px), ce qui
  // rejoue initState() ici sans que `_currentStepIndex` ait changé. Si un
  // futur cas de `resetMockState()` venait semer `seedHand`/`seedEnemy`
  // pour cette étape, `notifyListeners()` partirait en plein passage de
  // build de la PageView, ce que Flutter refuse : « setState() or
  // markNeedsBuild() called during build. »

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    return LayoutBuilder(
      builder: (context, constraints) {
        // Dynamic card sizing for the relic display
        final double relicCardWidth = (constraints.maxWidth * 0.45).clamp(140.0, 180.0);

        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              // Relic display card
              Expanded(
                child: Center(
                  child: _isCollected
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              color: Colors.amber,
                              size: 54,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isFrench ? 'Relique Collectée !' : 'Relic Collected!',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        )
                      : AnimatedOpacity(
                          opacity: _relicOpacity,
                          duration: const Duration(milliseconds: 300),
                          child: AnimatedScale(
                            scale: _relicScale,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              width: relicCardWidth,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF1E293B).withValues(alpha: 0.6),
                                    const Color(0xFF0F172A).withValues(alpha: 0.6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Glowing Relic Icon
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.shield_outlined,
                                      color: Colors.amber,
                                      size: 38,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Relic Name
                                  Text(
                                    isFrench ? 'Talisman de Fer' : 'Iron Talisman',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  // Relic Description
                                  Text(
                                    isFrench
                                        ? 'Au début du combat, gagnez 4 Armure.'
                                        : 'At start of combat, gain 4 Armor.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 11,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Rarities Legend
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceAround,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildRarityBadge(
                      isFrench ? 'Commun' : 'Common',
                      Colors.white70,
                    ),
                    _buildRarityBadge(
                      isFrench ? 'Rare' : 'Rare',
                      Colors.blueAccent,
                    ),
                    _buildRarityBadge(
                      isFrench ? 'Épique' : 'Epic',
                      Colors.purpleAccent,
                    ),
                    _buildRarityBadge(
                      isFrench ? 'Légendaire' : 'Legendary',
                      Colors.amber,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Collect button
              if (!_isCollected)
                InkWell(
                  onTap: _collectRelic,
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
                        color: Colors.amber.withValues(alpha: 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      isFrench ? 'Collecter 👑' : 'Collect 👑',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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

  Widget _buildRarityBadge(String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
