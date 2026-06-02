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

  Widget _buildSimulationVisual(int index, double scale) {
    switch (index) {
      case 0: // Poison
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science, color: Colors.greenAccent, size: 14 * scale),
            SizedBox(width: 4 * scale),
            Text(
              '$_poisonVal',
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16 * scale,
              ),
            ),
            SizedBox(width: 8 * scale),
            Text(
              '->  -$_poisonVal HP',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 12 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case 1: // Burn
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_fire_department,
              color: Colors.orangeAccent,
              size: 14 * scale,
            ),
            SizedBox(width: 4 * scale),
            Text(
              '$_burnVal',
              style: TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16 * scale,
              ),
            ),
            SizedBox(width: 8 * scale),
            Text(
              '->  -$_burnVal HP',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 12 * scale,
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
              Icon(Icons.hardware_rounded, color: Colors.grey, size: 16 * scale),
              SizedBox(width: 4 * scale),
              Text(
                _gelActive ? '10 -> 5 ⚔️' : '10 ⚔️',
                style: TextStyle(
                  color: _gelActive ? Colors.lightBlueAccent : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13 * scale,
                ),
              ),
            ],
          ),
        );
      case 3: // Shock
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flash_on, color: Colors.amberAccent, size: 16 * scale),
            SizedBox(width: 4 * scale),
            Text(
              'HIT ${_shockHits + 1}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12 * scale,
              ),
            ),
            SizedBox(width: 6 * scale),
            Text(
              '+${(_shockHits + 1) * 2} ⚡',
              style: TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12 * scale,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double scaleHeight = constraints.maxHeight / 300.0;
          final double scaleWidth = constraints.maxWidth / 350.0;
          final double scale = (scaleHeight < scaleWidth ? scaleHeight : scaleWidth).clamp(0.65, 1.4);

          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          final double crossAxisSpacing = 10.0 * scale;
          final double mainAxisSpacing = 10.0 * scale;

          final double itemWidth = (width - crossAxisSpacing) / 2;
          final double itemHeight = (height - mainAxisSpacing) / 2;

          double childAspectRatio = 165 / 140;
          if (itemWidth > 0 && itemHeight > 0) {
            childAspectRatio = itemWidth / itemHeight;
          }

          return SizedBox(
            width: width,
            height: height,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: _elements.length,
              itemBuilder: (context, index) {
                final element = _elements[index];
                final name = isFrench ? element.nameFr : element.nameEn;
                final desc = isFrench ? element.descFr : element.descEn;

                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10 * scale,
                    vertical: 8 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16 * scale),
                    border: Border.all(
                      color: element.color.withValues(alpha: 0.3),
                      width: 1.5 * scale,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon & Name Row
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6 * scale),
                            decoration: BoxDecoration(
                              color: element.color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              element.icon,
                              color: element.color,
                              size: 22 * scale,
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                color: element.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 13 * scale,
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
                              fontSize: 11 * scale,
                              height: 1.25,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      SizedBox(height: 4 * scale),

                      // Visual Simulation Area
                      Container(
                        height: 28 * scale,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8 * scale),
                        ),
                        child: Center(
                          child: _buildSimulationVisual(index, scale),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
