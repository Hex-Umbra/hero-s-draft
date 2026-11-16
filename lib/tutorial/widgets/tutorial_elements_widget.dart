import 'dart:async';
import 'package:flutter/material.dart';
import '../../game/services/proportional_status.dart';
import '../../game/systems/charge_rules.dart';
import '../../l10n/app_localizations.dart';
import '../../models/data/charge_data.dart';
import '../../models/entity_stats.dart';
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

  // Le pas du cycle des trois charges : chacune le lit modulo sa propre
  // longueur, ses chiffres viennent de la donnée.
  int _chargeStep = 0;

  // Les deux points de Feu du panneau de démonstration, posés comme le jeu
  // les pose, sur un héros de démonstration.
  late final EntityStats _demoStats = ChargeRules.pose(
    EntityStats(maxPv: 1, currentPv: 1, armure: 0, might: 0),
    widget.engine.data.charges['burn']!,
    2,
    ChargeBearer.hero,
  );

  // Les entrées lisent la langue active : elles ne sont pas constantes. Les
  // charges disent leur nom et leur règle depuis le catalogue ; le barème des
  // statuts proportionnels vient de [ProportionalStatus].
  List<ElementStatusInfo> _elements(bool isFrench) {
    final locale = isFrench ? 'fr' : 'en';
    final charges = widget.engine.data.charges;
    final burn = charges['burn']!;
    final freeze = charges['freeze']!;
    final shock = charges['shock']!;
    return [
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
        name: burn.name(locale),
        desc: burn.describe(locale),
      ),
      ElementStatusInfo(
        icon: Icons.ac_unit_rounded,
        color: Colors.lightBlueAccent,
        name: freeze.name(locale),
        desc: freeze.describe(locale),
      ),
      ElementStatusInfo(
        icon: Icons.flash_on_rounded,
        color: Colors.amberAccent,
        name: shock.name(locale),
        desc: shock.describe(locale),
      ),
    ];
  }

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

        // Les trois charges avancent d'un pas ; chacune reboucle à sa longueur.
        _chargeStep++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Une ligne du cycle d'une charge : son icône et le chiffre du pas.
  Widget _chargeCycle(IconData icon, Color color, String label, double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 14 * scale),
        SizedBox(width: 4 * scale),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12 * scale,
          ),
        ),
      ],
    );
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
      case 1: // Feu : 1, 2, 3 points, puis l'explosion
        final burn = widget.engine.data.charges['burn']!;
        final step = _chargeStep % (burn.threshold + 1);
        return _chargeCycle(
          Icons.local_fire_department,
          Colors.orangeAccent,
          step < burn.threshold
              ? '🔥 ${step + 1}'
              : '💥 ${burn.rupture.explosionDamage}',
          scale,
        );
      case 2: // Gel : 1/3, 2/3, puis l'état gelé
        final freeze = widget.engine.data.charges['freeze']!;
        final step = _chargeStep % freeze.threshold;
        return _chargeCycle(
          Icons.ac_unit,
          Colors.lightBlueAccent,
          step < freeze.threshold - 1
              ? '❄ ${step + 1}/${freeze.threshold}'
              : '❄ ${freeze.brokenName(isFrench ? 'fr' : 'en')}',
          scale,
        );
      case 3: // Foudre : +1 par point sous le seuil, puis chargée
        final shock = widget.engine.data.charges['shock']!;
        final step = _chargeStep % shock.threshold;
        return _chargeCycle(
          Icons.flash_on,
          Colors.amberAccent,
          step < shock.threshold - 1
              ? '⚡ ${step + 1}/${shock.threshold} : +${(step + 1) * shock.belowValue!}'
              : '⚡ ${shock.brokenName(isFrench ? 'fr' : 'en')} : '
                  '+${shock.threshold * shock.rupture.bonusPerPoint}',
          scale,
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
            child: _buildGallery(_elements(isFrench), isFrench),
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
              effectIcons: widget.engine.data.effectIcons,
              statuses: const [
                StatusEffect(
                  id: 'poison',
                  name: 'Poison',
                  type: StatusType.debuff,
                  value: 3,
                  duration: 2,
                ),
              ],
              chargeLines: ChargeRules.linesFor(_demoStats),
              charges: widget.engine.data.charges,
            ),
          ),
        ],
      ),
    );
  }
}
