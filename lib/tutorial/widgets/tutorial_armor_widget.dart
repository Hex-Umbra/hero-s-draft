import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialArmorWidget extends StatefulWidget {
  final TutorialEngine engine;
  const TutorialArmorWidget({super.key, required this.engine});

  @override
  State<TutorialArmorWidget> createState() => _TutorialArmorWidgetState();
}

class _TutorialArmorWidgetState extends State<TutorialArmorWidget> {
  int _leftHp = 80;
  final int _leftMaxHp = 80;
  int _leftArmor = 0;

  int _rightHp = 80;
  final int _rightMaxHp = 80;
  int _rightArmor = 4;

  bool _leftShowDamage = false;
  bool _rightShowDamage = false;
  double _leftDamageY = 0.0;
  double _rightDamageY = 0.0;

  void _runSimulation() {
    // Reset to start
    setState(() {
      _leftHp = 80;
      _leftArmor = 0;
      _rightHp = 80;
      _rightArmor = 4;
      _leftShowDamage = false;
      _rightShowDamage = false;
      _leftDamageY = 0.0;
      _rightDamageY = 0.0;
    });

    // Run after a short delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        // Appliquer dégâts de 10
        // Gauche : Pas d'armure -> prend 10 dégâts directs sur HP
        _leftHp = 70;
        _leftShowDamage = true;
        _leftDamageY = -30.0;

        // Droite : 4 armure -> l'armure absorbe 4 dégâts, 6 dégâts sur HP
        _rightArmor = 0;
        _rightHp = 74;
        _rightShowDamage = true;
        _rightDamageY = -30.0;
      });
    });

    // Clean damage displays after animation finishes
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _leftShowDamage = false;
        _rightShowDamage = false;
      });
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
          height: 250,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Split comparison layout
                Expanded(
                  child: Row(
                    children: [
                      // Left Panel: No Armor
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isFrench ? 'SANS ARMURE' : 'NO ARMOR',
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(
                                    Icons.accessibility_new_rounded,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  if (_leftShowDamage)
                                    AnimatedPositioned(
                                      duration: const Duration(milliseconds: 800),
                                      curve: Curves.easeOutQuad,
                                      top: _leftDamageY,
                                      child: const Text(
                                        '-10 HP',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // HP bar
                              buildHealthBar(
                                'HP',
                                _leftHp,
                                _leftMaxHp,
                                Colors.redAccent,
                              ),
                              const SizedBox(height: 6),
                              // Armor display (0)
                              buildArmorBadge(_leftArmor),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Right Panel: With Armor
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blueAccent.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isFrench ? 'AVEC ARMURE' : 'WITH ARMOR',
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(
                                    Icons.shield_rounded,
                                    size: 40,
                                    color: Colors.blueAccent,
                                  ),
                                  if (_rightShowDamage)
                                    AnimatedPositioned(
                                      duration: const Duration(milliseconds: 800),
                                      curve: Curves.easeOutQuad,
                                      top: _rightDamageY,
                                      child: Text(
                                        isFrench
                                            ? '-4 Armure\n-6 HP'
                                            : '-4 Armor\n-6 HP',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.cyanAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          height: 1.1,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // HP bar
                              buildHealthBar(
                                'HP',
                                _rightHp,
                                _rightMaxHp,
                                Colors.redAccent,
                              ),
                              const SizedBox(height: 6),
                              // Armor display
                              buildArmorBadge(_rightArmor),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Simulation Button
                InkWell(
                  onTap: _runSimulation,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFF1E293B),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      isFrench ? 'Voir la différence ⚡' : 'See the difference ⚡',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
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

  Widget buildHealthBar(String label, int value, int max, Color color) {
    double percent = (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$value/$max',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildArmorBadge(int armor) {
    final active = armor > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.blueAccent : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield,
            color: active ? Colors.white : Colors.white30,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            '$armor',
            style: TextStyle(
              color: active ? Colors.white : Colors.white30,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

