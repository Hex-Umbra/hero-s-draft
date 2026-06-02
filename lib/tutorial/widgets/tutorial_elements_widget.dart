import 'dart:async';
import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class ElementStatusInfo {
  final IconData icon;
  final Color color;
  final String nameEn;
  final String nameFr;
  final String descEn;
  final String descFr;

  const ElementStatusInfo({
    required this.icon,
    required this.color,
    required this.nameEn,
    required this.nameFr,
    required this.descEn,
    required this.descFr,
  });
}

class TutorialElementsWidget extends StatefulWidget {
  final TutorialEngine engine;
  const TutorialElementsWidget({super.key, required this.engine});

  @override
  State<TutorialElementsWidget> createState() => _TutorialElementsWidgetState();
}

class _TutorialElementsWidgetState extends State<TutorialElementsWidget> {
  Timer? _timer;
  int _poisonVal = 3;
  int _burnVal = 6;
  bool _gelActive = true;
  int _shockHits = 0;

  static const List<ElementStatusInfo> _elements = [
    ElementStatusInfo(
      icon: Icons.science_rounded,
      color: Colors.greenAccent,
      nameEn: 'Poison',
      nameFr: 'Poison',
      descEn:
          'Deals damage equal to its value at start of turn, then decreases by 1.',
      descFr:
          'Inflige des dégâts égaux au Poison au début du tour, puis diminue de 1.',
    ),
    ElementStatusInfo(
      icon: Icons.local_fire_department_rounded,
      color: Colors.orangeAccent,
      nameEn: 'Burn',
      nameFr: 'Brûlure',
      descEn:
          'Deals damage equal to its value at end of turn, then decreases by half.',
      descFr:
          'Inflige des dégâts de Feu à la fin du tour, puis diminue de moitié.',
    ),
    ElementStatusInfo(
      icon: Icons.ac_unit_rounded,
      color: Colors.lightBlueAccent,
      nameEn: 'Freeze',
      nameFr: 'Gel',
      descEn: 'Reduces the enemy\'s next attack damage by 50%.',
      descFr: 'Réduit les dégâts de la prochaine attaque ennemie de 50%.',
    ),
    ElementStatusInfo(
      icon: Icons.flash_on_rounded,
      color: Colors.amberAccent,
      nameEn: 'Shock',
      nameFr: 'Électrocution',
      descEn: 'Takes bonus damage on every card hit received.',
      descFr: 'Subit des dégâts supplémentaires à chaque coup reçu.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Start simulation timer
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        // Poison tick: 3 -> 2 -> 1 -> reset
        _poisonVal = _poisonVal > 1 ? _poisonVal - 1 : 3;

        // Burn tick: 6 -> 3 -> 1 -> reset
        _burnVal = _burnVal > 1 ? (_burnVal / 2).floor() : 6;

        // Gel toggle
        _gelActive = !_gelActive;

        // Shock hits: 0 -> 1 -> 2 -> reset
        _shockHits = _shockHits < 2 ? _shockHits + 1 : 0;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildSimulationVisual(int index) {
    switch (index) {
      case 0: // Poison
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.science, color: Colors.greenAccent, size: 14),
            const SizedBox(width: 4),
            Text(
              '$_poisonVal',
              style: const TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '->  -$_poisonVal HP',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case 1: // Burn
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_fire_department,
              color: Colors.orangeAccent,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              '$_burnVal',
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '->  -$_burnVal HP',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case 2: // Freeze
        return AnimatedOpacity(
          opacity: _gelActive ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 300),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hardware_rounded, color: Colors.grey, size: 16),
              const SizedBox(width: 4),
              Text(
                _gelActive ? '10 -> 5 ⚔️' : '10 ⚔️',
                style: TextStyle(
                  color: _gelActive ? Colors.lightBlueAccent : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      case 3: // Shock
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flash_on, color: Colors.amberAccent, size: 16),
            const SizedBox(width: 4),
            Text(
              'HIT ${_shockHits + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '+${(_shockHits + 1) * 2} ⚡',
              style: const TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 350,
          height: 300,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 165 / 140,
            ),
            itemCount: _elements.length,
            itemBuilder: (context, index) {
              final element = _elements[index];
              final name = isFrench ? element.nameFr : element.nameEn;
              final desc = isFrench ? element.descFr : element.descEn;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: element.color.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon & Name Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: element.color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(element.icon, color: element.color, size: 22),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              color: element.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Description
                    Expanded(
                      child: Center(
                        child: Text(
                          desc,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 11,
                            height: 1.25,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Visual Simulation Area
                    Container(
                      height: 28,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: _buildSimulationVisual(index)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
