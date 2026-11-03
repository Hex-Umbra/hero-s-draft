import 'dart:async';
import 'package:flutter/material.dart';
import '../../game/services/proportional_status.dart';
import '../../l10n/app_localizations.dart';
import '../../models/status_effect.dart';
import '../../ui/widgets/hud/status_effects_panel.dart';
import '../tutorial_engine.dart';

class ElementStatusInfo {
  final IconData icon;
  final Color color;
  final String name;
  final String desc;

  const ElementStatusInfo({
    required this.icon,
    required this.color,
    required this.name,
    required this.desc,
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

  // Les entrées lisent la langue active : elles ne sont pas constantes, et le
  // barème des statuts proportionnels vient de [ProportionalStatus].
  static List<ElementStatusInfo> _elements(AppLocalizations l10n, bool isFrench) =>
      [
        ElementStatusInfo(
          icon: Icons.science_rounded,
          color: Colors.greenAccent,
          name: 'Poison',
          desc: isFrench
              ? 'Inflige sa valeur au début du tour. La valeur ne baisse pas ; la durée décrémente.'
              : 'Deals its value at the start of the turn. The value holds; the duration ticks down.',
        ),
        ElementStatusInfo(
          icon: Icons.local_fire_department_rounded,
          color: Colors.orangeAccent,
          name: isFrench ? 'Brûlure' : 'Burn',
          desc: isFrench
              ? 'Inflige sa valeur au début du tour ennemi, puis perd 1.'
              : 'Deals its value at the start of the enemy turn, then loses 1.',
        ),
        ElementStatusInfo(
          icon: Icons.ac_unit_rounded,
          color: Colors.lightBlueAccent,
          name: isFrench ? 'Gel' : 'Freeze',
          desc: l10n.statusFreezeHint(
            ProportionalStatus.freeze.percentPerPoint,
            ProportionalStatus.freeze.maxPercent,
          ),
        ),
        ElementStatusInfo(
          icon: Icons.flash_on_rounded,
          color: Colors.amberAccent,
          name: isFrench ? 'Électrocution' : 'Shock',
          desc: isFrench
              ? 'Subit des dégâts supplémentaires à chaque coup reçu.'
              : 'Takes bonus damage on every card hit received.',
        ),
      ];

  // Les cinq autres statuts qui circulent en combat mais que la galerie
  // ci-dessus ne montre pas.
  static List<ElementStatusInfo> _missingStatuses(
    AppLocalizations l10n,
    bool isFrench,
  ) =>
      [
        ElementStatusInfo(
          icon: Icons.arrow_downward,
          color: Colors.redAccent,
          name: isFrench ? 'Vulnérable' : 'Vulnerable',
          desc: l10n.statusVulnerableHint(
            ProportionalStatus.vulnerable.percentPerPoint,
            ProportionalStatus.vulnerable.maxPercent,
          ),
        ),
        ElementStatusInfo(
          icon: Icons.arrow_downward,
          color: Colors.redAccent,
          name: isFrench ? 'Faiblesse' : 'Weakness',
          desc: l10n.statusWeaknessHint(
            ProportionalStatus.weakness.percentPerPoint,
            ProportionalStatus.weakness.maxPercent,
          ),
        ),
        ElementStatusInfo(
          icon: Icons.flash_on,
          color: Colors.orangeAccent,
          name: isFrench ? 'Puissance' : 'Might',
          desc: isFrench
              ? 'S\'ajoute à ce que renforce votre classe'
              : 'Adds to what your class strengthens',
        ),
        ElementStatusInfo(
          icon: Icons.flash_on,
          color: Colors.orangeAccent,
          name: isFrench ? 'Éveil de Puissance' : 'Might Awakening',
          desc: isFrench
              ? 'Donne de la Puissance au début du tour'
              : 'Grants Might at the start of the turn',
        ),
        ElementStatusInfo(
          icon: Icons.shield,
          color: Colors.cyanAccent,
          name: isFrench ? 'Métallisation' : 'Plated Armor',
          desc: isFrench
              ? 'Donne de l\'Armure au début du tour'
              : 'Grants Armor at the start of the turn',
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
  Widget _buildGallery(List<ElementStatusInfo> elements, bool isFrench) {
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
              itemCount: elements.length,
              itemBuilder: (context, index) {
                final element = elements[index];
                final name = element.name;
                final desc = element.desc;

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
  Widget _buildStatusRow(ElementStatusInfo status) {
    final name = status.name;
    final desc = status.desc;

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
    final l10n = AppLocalizations.of(context)!;
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 300,
            child: _buildGallery(_elements(l10n, isFrench), isFrench),
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
          ..._missingStatuses(l10n, isFrench).map(_buildStatusRow),
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
