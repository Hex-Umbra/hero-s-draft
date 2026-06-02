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

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 320,
          height: 240,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
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
                                size: 48,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                isFrench ? 'Relique Collectée !' : 'Relic Collected!',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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
                                width: 160,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.amber.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withValues(alpha: 0.15),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Icon
                                    const Icon(
                                      Icons.shield_outlined,
                                      color: Colors.amber,
                                      size: 36,
                                    ),
                                    const SizedBox(height: 8),
                                    // Name
                                    Text(
                                      isFrench ? 'Talisman de Fer' : 'Iron Talisman',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Description
                                    Text(
                                      isFrench
                                          ? 'Au début du combat, gagnez 4 Armure.'
                                          : 'At start of combat, gain 4 Armor.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 10.5,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                ),

                // Rarities Legend
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceAround,
                    spacing: 8,
                    runSpacing: 4,
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
                const SizedBox(height: 10),

                // Collect button
                if (!_isCollected)
                  InkWell(
                    onTap: _collectRelic,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0xFF1E293B),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        isFrench ? 'Collecter 👑' : 'Collect 👑',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
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

  Widget _buildRarityBadge(String label, Color color) {
    return Column(
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
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

