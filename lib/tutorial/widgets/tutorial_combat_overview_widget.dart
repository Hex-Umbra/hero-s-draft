import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialCombatOverviewWidget extends StatefulWidget {
  final TutorialEngine engine;
  const TutorialCombatOverviewWidget({super.key, required this.engine});

  @override
  State<TutorialCombatOverviewWidget> createState() => _TutorialCombatOverviewWidgetState();
}

class _TutorialCombatOverviewWidgetState extends State<TutorialCombatOverviewWidget> {
  bool _showEnemyLabel = false;
  bool _showHeroLabel = false;
  bool _showHandLabel = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showEnemyLabel = true);
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showHeroLabel = true);
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showHandLabel = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    return Stack(
      children: [
        // Mock Combat Layout Background
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top: Enemy Zone Mock
              Container(
                height: 55,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.mood_bad, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isFrench ? 'Zone Ennemie (PV, Intentions)' : 'Enemy Zone (HP, Intentions)',
                      style: TextStyle(
                        color: Colors.redAccent.shade100,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Middle: Hero Info Mock
              Container(
                height: 45,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.red, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '80 / 80',
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.shield, color: Colors.blue, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '0',
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.lens, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          isFrench ? '3/3 Mana' : '3/3 Mana',
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom: Hand & End Turn Mock
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1.2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return Container(
                            width: 30,
                            height: 42,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.amber.withOpacity(0.3)),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 60,
                    width: 55,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Text(
                        isFrench ? 'Fin' : 'End',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Floating Annotation Labels
        // Label 1 (points to Enemy Zone)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          top: _showEnemyLabel ? 75 : 90,
          left: 20,
          right: 20,
          child: AnimatedOpacity(
            opacity: _showEnemyLabel ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: _buildAnnotationBubble(
              text: isFrench
                  ? '1. L\'ennemi s\'affiche en haut avec ses PV et son action prévue.'
                  : '1. The enemy displays at the top with their HP and planned action.',
              color: Colors.redAccent,
            ),
          ),
        ),

        // Label 2 (points to Player Stats)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          top: _showHeroLabel ? 130 : 145,
          left: 20,
          right: 20,
          child: AnimatedOpacity(
            opacity: _showHeroLabel ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: _buildAnnotationBubble(
              text: isFrench
                  ? '2. Votre santé, votre armure et vos cristaux de mana sont au centre.'
                  : '2. Your health, armor, and mana crystals are in the center.',
              color: Colors.blueAccent,
            ),
          ),
        ),

        // Label 3 (points to Hand of Cards)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          bottom: _showHandLabel ? 85 : 100,
          left: 20,
          right: 20,
          child: AnimatedOpacity(
            opacity: _showHandLabel ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: _buildAnnotationBubble(
              text: isFrench
                  ? '3. Vos cartes utilisables sont en bas. Utilisez le bouton pour terminer votre tour.'
                  : '3. Your playable cards are at the bottom. Use the button to end your turn.',
              color: Colors.amber,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnnotationBubble({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.25),
      ),
    );
  }
}
