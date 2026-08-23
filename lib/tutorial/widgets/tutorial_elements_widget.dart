import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/status_effect.dart';
import '../../ui/widgets/hud/status_effects_panel.dart';
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
  static const int _poisonValue = 3;
  int _poisonDuration = 2;
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
          'Deals its value at the start of the turn. The value holds; the duration ticks down.',
      descFr:
          'Inflige sa valeur au début du tour. La valeur ne baisse pas ; la durée décrémente.',
    ),
    ElementStatusInfo(
      icon: Icons.local_fire_department_rounded,
      color: Colors.orangeAccent,
      nameEn: 'Burn',
      nameFr: 'Brûlure',
      descEn: 'Deals its value at the start of the enemy turn, then loses 1.',
      descFr: 'Inflige sa valeur au début du tour ennemi, puis perd 1.',
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

  // Les cinq autres statuts qui circulent en combat mais que la galerie
  // ci-dessus ne montre pas.
  static const List<ElementStatusInfo> _missingStatuses = [
    ElementStatusInfo(
      icon: Icons.arrow_downward,
      color: Colors.redAccent,
      nameEn: 'Vulnerable',
      nameFr: 'Vulnérable',
      descEn: '+50% damage taken',
      descFr: '+50 % de dégâts subis',
    ),
    ElementStatusInfo(
      icon: Icons.arrow_downward,
      color: Colors.redAccent,
      nameEn: 'Weakness',
      nameFr: 'Faiblesse',
      descEn: '-25% damage dealt',
      descFr: '-25 % de dégâts infligés',
    ),
    ElementStatusInfo(
      icon: Icons.flash_on,
      color: Colors.orangeAccent,
      nameEn: 'Attack',
      nameFr: 'Attaque',
      descEn: 'Adds to every attack\'s damage',
      descFr: 'S\'ajoute aux dégâts de chaque attaque',
    ),
    ElementStatusInfo(
      icon: Icons.flash_on,
      color: Colors.orangeAccent,
      nameEn: 'Attack Awakening',
      nameFr: 'Éveil d\'Attaque',
      descEn: 'Grants Strength at the start of the turn',
      descFr: 'Donne de la Force au début du tour',
    ),
    ElementStatusInfo(
      icon: Icons.shield,
      color: Colors.cyanAccent,
      nameEn: 'Plated Armor',
      nameFr: 'Métallisation',
      descEn: 'Grants Armor at the start of the turn',
      descFr: 'Donne de l\'Armure au début du tour',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Démarre le minuteur de simulation
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        // Poison : la valeur reste constante, seule la durée décroît
        // jusqu'à expiration (2 -> 1 -> 0), puis le cycle repart.
        _poisonDuration = _poisonDuration > 0 ? _poisonDuration - 1 : 2;

        // Brûlure : perd 1 par tour au lieu d'être divisée par deux.
        _burnVal = _burnVal > 1 ? _burnVal - 1 : 6;

        // Gel : bascule l'état visuel
        _gelActive = !_gelActive;

        // Électrocution : 0 -> 1 -> 2 -> reset
        _shockHits = _shockHits < 2 ? _shockHits + 1 : 0;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildSimulationVisual(int index, double scale, bool isFrench) {
    switch (index) {
      case 0: // Poison
        final String durationLabel = _poisonDuration > 0
            ? '$_poisonDuration'
            : (isFrench ? 'expiré' : 'expired');
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science, color: Colors.greenAccent, size: 14 * scale),
            SizedBox(width: 4 * scale),
            Text(
              '$_poisonValue',
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16 * scale,
              ),
            ),
            SizedBox(width: 8 * scale),
            Text(
              '($durationLabel)',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case 1: // Brûlure
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
      case 2: // Gel
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
      case 3: // Électrocution
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

  // Galerie 2x2 des quatre effets élémentaires, avec leur simulation animée.
  Widget _buildGallery(bool isFrench) {
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
                      // Icône et nom
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

                      // Zone de simulation visuelle
                      Container(
                        height: 28 * scale,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8 * scale),
                        ),
                        child: Center(
                          child: _buildSimulationVisual(index, scale, isFrench),
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

  // Une ligne du tableau des statuts absents de la galerie.
  Widget _buildStatusRow(ElementStatusInfo status, bool isFrench) {
    final name = isFrench ? status.nameFr : status.nameEn;
    final desc = isFrench ? status.descFr : status.descEn;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(status.icon, color: status.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: status.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 300,
            child: _buildGallery(isFrench),
          ),
          const SizedBox(height: 20),
          Text(
            isFrench
                ? 'Cinq autres altérations circulent en combat :'
                : 'Five more status effects circulate in combat:',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ..._missingStatuses.map((status) => _buildStatusRow(status, isFrench)),
          const SizedBox(height: 16),
          Text(
            isFrench
                ? 'Voilà comment ils apparaissent en combat :'
                : 'This is how they show up in combat:',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: StatusEffectsPanel(
              statuses: const [
                StatusEffect(
                  id: 'poison',
                  name: 'Poison',
                  type: StatusType.debuff,
                  value: 3,
                  duration: 2,
                ),
                StatusEffect(
                  id: 'burn',
                  name: 'Brûlure',
                  type: StatusType.debuff,
                  value: 2,
                  duration: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
