import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialArmorWidget extends StatefulWidget {
  final TutorialEngine engine;
  const TutorialArmorWidget({super.key, required this.engine});

  @override
  State<TutorialArmorWidget> createState() => _TutorialArmorWidgetState();
}

class _TutorialArmorWidgetState extends State<TutorialArmorWidget> {
  // Point d'Armure de départ pour le panneau de droite : un paramètre du
  // scénario pédagogique (« et si vous aviez 4 Armure ? »), pas une valeur
  // de jeu réelle — contrairement au maximum de PV, l'Armure de départ ne
  // dépend d'aucune classe.
  static const int _rightStartArmor = 4;

  // `null` tant qu'aucune simulation n'a tourné : le panneau affiche alors
  // la pleine vie réelle (`_maxHp`). Un champ ne peut pas lire `_maxHp` à
  // l'initialisation (`widget` n'est pas encore attaché à cet instant) —
  // d'où le `null` plutôt qu'une constante comme 80.
  int? _leftHp;
  int _leftArmor = 0;
  int _leftHpLoss = 0;

  int? _rightHp;
  int _rightArmor = _rightStartArmor;
  int _rightArmorLoss = 0;
  int _rightHpLoss = 0;

  bool _leftShowDamage = false;
  bool _rightShowDamage = false;
  double _leftDamageY = 0.0;
  double _rightDamageY = 0.0;

  /// PV max réels du héros choisi, ou le repli neutre de `baseStatsForHero`
  /// si l'étape de classe a été sautée (jamais une constante en dur : un
  /// Mage a 60 PV, pas 80). Les deux panneaux illustrent le même
  /// personnage dans deux scénarios (avec/sans Armure), jamais deux
  /// personnages différents : un seul plafond leur suffit.
  int get _maxHp => widget.engine.mockState.baseStatsForHero().maxPv;

  /// Remet `heroStats` à un socle neutre avant un calcul de démonstration.
  ///
  /// `setHeroArmor` et `applyDamageToHero` ne peuvent qu'appauvrir l'état
  /// (fixer l'Armure ou infliger des dégâts), jamais restaurer les PV. Les
  /// deux panneaux comparent pourtant deux scénarios sur le même `heroStats`
  /// partagé par le moteur, et le bouton peut être pressé plusieurs fois :
  /// chaque scénario repart donc explicitement d'un socle identique. Le
  /// moteur (`resetHeroStatsForDemo`) plafonne lui-même ce socle au `maxPv`
  /// réel du héros choisi et notifie ses observateurs.
  void _resetDemoBaseline() {
    widget.engine.resetHeroStatsForDemo(_maxHp);
  }

  void _runSimulation() {
    // Reset to start : null -> les barres réaffichent la pleine vie réelle
    // du héros (voir _maxHp), pas une constante.
    setState(() {
      _leftHp = null;
      _leftArmor = 0;
      _rightHp = null;
      _rightArmor = _rightStartArmor;
      _leftShowDamage = false;
      _rightShowDamage = false;
      _leftDamageY = 0.0;
      _rightDamageY = 0.0;
    });

    // Run after a short delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      // Gauche : pas d'Armure -> les dégâts tapent les PV en direct. Les
      // pertes se mesurent avant/après setHeroArmor (pas juste après le
      // reset) plutôt que par rapport à _maxHp : le socle réel dépend du
      // héros (resetHeroStatsForDemo le plafonne, ex. 60 pour le Mage), et
      // l'Armure de départ n'est fixée qu'à l'appel de setHeroArmor.
      _resetDemoBaseline();
      widget.engine.setHeroArmor(0);
      final beforeLeft = widget.engine.mockState.heroStats;
      widget.engine.applyDamageToHero(10);
      final afterLeft = widget.engine.mockState.heroStats;

      // Droite : l'Armure absorbe une partie des dégâts, le reste entame
      // les PV. La vraie formule d'absorption (EntityStats.takeDamage)
      // calcule le résultat : on ne le recopie plus à la main.
      _resetDemoBaseline();
      widget.engine.setHeroArmor(_rightStartArmor);
      final beforeRight = widget.engine.mockState.heroStats;
      widget.engine.applyDamageToHero(10);
      final afterRight = widget.engine.mockState.heroStats;

      setState(() {
        _leftHp = afterLeft.currentPv;
        _leftHpLoss = beforeLeft.currentPv - afterLeft.currentPv;
        _leftArmor = afterLeft.armure;
        _leftShowDamage = true;
        _leftDamageY = -30.0;

        _rightArmor = afterRight.armure;
        _rightArmorLoss = beforeRight.armure - afterRight.armure;
        _rightHp = afterRight.currentPv;
        _rightHpLoss = beforeRight.currentPv - afterRight.currentPv;
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
    final maxHp = _maxHp;

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 320,
          height: 380,
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
                                      child: Text(
                                        '-$_leftHpLoss HP',
                                        style: const TextStyle(
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
                                _leftHp ?? maxHp,
                                maxHp,
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
                                            ? '-$_rightArmorLoss Armure\n-$_rightHpLoss HP'
                                            : '-$_rightArmorLoss Armor\n-$_rightHpLoss HP',
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
                                _rightHp ?? maxHp,
                                maxHp,
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

                // Passif de la classe choisie : lu depuis la tranche
                // persistante, jamais recopié en dur (nom/description
                // viennent de `assets/data/passives/` via le moteur).
                Builder(
                  builder: (context) {
                    final passive = widget.engine.mockState.activePassive;
                    if (passive == null) return const SizedBox.shrink();
                    final locale = Localizations.localeOf(context).languageCode;
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale == 'fr'
                                ? 'Votre passif : ${passive.getName(locale)}'
                                : 'Your passive: ${passive.getName(locale)}',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            passive.getDescription(locale),
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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

