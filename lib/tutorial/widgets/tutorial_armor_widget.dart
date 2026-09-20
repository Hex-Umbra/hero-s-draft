import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';

import '../../models/data/model_extensions.dart';
import '../../models/data/stat_rule.dart';
import '../tutorial_engine.dart';

class TutorialArmorWidget extends StatefulWidget {
  final TutorialEngine engine;
  const TutorialArmorWidget({super.key, required this.engine});

  @override
  State<TutorialArmorWidget> createState() => _TutorialArmorWidgetState();
}

class _TutorialArmorWidgetState extends State<TutorialArmorWidget> {
  // Le gain d'Armure de démonstration, et le coup qu'il encaisse : deux
  // paramètres du scénario pédagogique (« et si vous jouiez Défense ? »),
  // pas des valeurs de jeu. Ce que la classe en fait, en revanche, est une
  // vraie règle : `gainArmorForDemo` la lui demande.
  static const int _demoArmorGain = 4;
  static const int _demoDamage = 10;

  // `null` tant qu'aucune simulation n'a tourné : le panneau affiche alors
  // la pleine vie réelle (`_maxHp`). Un champ ne peut pas lire `_maxHp` à
  // l'initialisation (`widget` n'est pas encore attaché à cet instant) —
  // d'où le `null` plutôt qu'une constante comme 80.
  int? _leftHp;
  int _leftArmor = 0;
  int _leftHpLoss = 0;

  // Le panneau droit démarre à **0 Armure**, comme le gauche : ce qu'il aura
  // après le gain dépend de la classe, et l'écrire en dur ici était
  // exactement le défaut que ce lot corrige.
  int? _rightHp;
  int _rightArmor = 0;
  int _rightArmorLoss = 0;
  int _rightHpLoss = 0;

  /// La Puissance temporaire que le gain a produite chez une classe qui
  /// convertit son Armure ; 0 pour une classe qui la garde.
  int _rightMightGain = 0;

  bool _leftShowDamage = false;
  bool _rightShowGain = false;
  bool _rightShowDamage = false;
  double _leftDamageY = 0.0;
  double _rightGainY = 0.0;
  double _rightDamageY = 0.0;

  /// PV max réels du héros choisi, ou le repli neutre de `baseStatsForHero`
  /// si l'étape de classe a été sautée (jamais une constante en dur : un
  /// Mage a 60 PV, pas 80). Les deux panneaux illustrent le même
  /// personnage dans deux scénarios (avec/sans Armure), jamais deux
  /// personnages différents : un seul plafond leur suffit.
  int get _maxHp => widget.engine.mockState.baseStatsForHero().maxPv;

  /// Remet `heroStats` à un socle neutre avant un scénario de démonstration :
  /// PV pleins, Armure à 0, statuts vidés. Le moteur plafonne lui-même ce
  /// socle au `maxPv` réel du héros choisi et notifie ses observateurs.
  void _resetDemoBaseline() {
    widget.engine.resetHeroStatsForDemo(_maxHp);
  }

  /// La démonstration, en **deux temps** : le gain, puis le coup.
  ///
  /// Le gain a son propre temps parce que c'est lui que la classe modifie :
  /// un panneau qui afficherait d'un coup « 0 Armure, +4 Puissance, −10 PV »
  /// serait illisible. Il passe par `gainArmorForDemo`, donc par
  /// `StatGains.apply` et les `statRules` de la classe — jamais par une
  /// écriture directe (ADR-081, spec §9.1).
  void _runSimulation() {
    setState(() {
      _leftHp = null;
      _leftArmor = 0;
      _leftHpLoss = 0;
      _rightHp = null;
      _rightArmor = 0;
      _rightArmorLoss = 0;
      _rightHpLoss = 0;
      _rightMightGain = 0;
      _leftShowDamage = false;
      _rightShowGain = false;
      _rightShowDamage = false;
      _leftDamageY = 0.0;
      _rightGainY = 0.0;
      _rightDamageY = 0.0;
    });

    // Temps 1 — le gain, chez la classe choisie.
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      _resetDemoBaseline();
      final avant = widget.engine.mockState.heroStats;
      widget.engine.gainArmorForDemo(_demoArmorGain);
      final apres = widget.engine.mockState.heroStats;

      setState(() {
        _rightArmor = apres.armure;
        // La différence, et non `effectiveMight` seul : la Puissance
        // permanente d'un héros de tutoriel vaut 0, mais s'y fier serait
        // s'appuyer sur un zéro, pas sur une règle.
        _rightMightGain = apres.effectiveMight - avant.effectiveMight;
        _rightShowGain = true;
        _rightGainY = -30.0;
      });
    });

    // Temps 2 — le coup, sur les deux scénarios. La vraie formule
    // d'absorption (`EntityStats.takeDamage`) calcule le résultat : on ne le
    // recopie pas à la main.
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;

      // Gauche : le même personnage, qui n'a rien joué.
      _resetDemoBaseline();
      final avantGauche = widget.engine.mockState.heroStats;
      widget.engine.applyDamageToHero(_demoDamage);
      final apresGauche = widget.engine.mockState.heroStats;

      // Droite : rejoue le gain du temps 1 sur un socle neutre plutôt que de
      // réutiliser l'état partagé du moteur — Gauche vient de le remettre à
      // zéro juste au-dessus. Le `heroStats` partagé termine donc la
      // démonstration sur le scénario de la classe choisie, jamais sur le
      // témoin sans Armure : presser « Voir la différence » une seconde fois
      // repart d'un socle neutre et ne peut pas empiler la Puissance.
      _resetDemoBaseline();
      widget.engine.gainArmorForDemo(_demoArmorGain);
      final avantDroite = widget.engine.mockState.heroStats;
      widget.engine.applyDamageToHero(_demoDamage);
      final apresDroite = widget.engine.mockState.heroStats;

      setState(() {
        _leftHp = apresGauche.currentPv;
        _leftHpLoss = avantGauche.currentPv - apresGauche.currentPv;
        _leftArmor = apresGauche.armure;
        _leftShowDamage = true;
        _leftDamageY = -30.0;

        _rightHp = apresDroite.currentPv;
        _rightHpLoss = avantDroite.currentPv - apresDroite.currentPv;
        _rightArmorLoss = avantDroite.armure - apresDroite.armure;
        _rightArmor = apresDroite.armure;
        _rightShowGain = false;
        _rightShowDamage = true;
        _rightDamageY = -30.0;
      });
    });

    // Nettoyage des textes flottants, l'animation finie.
    Future.delayed(const Duration(milliseconds: 2200), () {
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
    final l10n = AppLocalizations.of(context)!;
    // Les règles de la classe choisie. Vide pour le Paladin et le Mage : le
    // panneau droit garde alors son titre et son badge d'Armure d'origine.
    final rules = widget.engine.mockState.chosenHero?.statRules ?? const [];
    // Celles qui visent l'**Armure**, et elles seules, titrent le panneau :
    // c'est l'Armure qu'il démontre. Une classe qui convertirait son Mana
    // suivrait bien une règle, mais pas à cette étape — titrer le panneau
    // « MANA → PUISSANCE » lui enseignerait ici une règle qu'elle ne suit
    // pas, ce que la contrainte du §9.1 interdit précisément. Aucune classe
    // livrée n'est dans ce cas, et c'est bien pour ça qu'il faut le filtre :
    // le titre ne doit pas dépendre du fait qu'il n'y en ait qu'une.
    final armorRules =
        rules.where((r) => r.stat == RuleStat.armor).toList();

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 320,
          // La hauteur de base laisse tout juste la place aux deux panneaux,
          // au passif et au bouton (Paladin, Mage). L'encadré de règle
          // ci-dessous, lui, a besoin de sa propre place : sans cette marge,
          // il pousserait les panneaux hors du cadre (`RenderFlex overflow`)
          // pour toute classe qui en déclare une.
          height: rules.isEmpty ? 380 : 480,
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
                                // Généré depuis la règle quand la classe en
                                // déclare une **sur l'Armure** :
                                // « ARMURE → PUISSANCE ». Jamais écrit classe
                                // par classe (ADR-090).
                                armorRules.isEmpty
                                    ? (isFrench ? 'AVEC ARMURE' : 'WITH ARMOR')
                                    : armorRules.first.shortTitle(l10n),
                                textAlign: TextAlign.center,
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
                                  if (_rightShowGain)
                                    AnimatedPositioned(
                                      duration: const Duration(milliseconds: 800),
                                      curve: Curves.easeOutQuad,
                                      top: _rightGainY,
                                      child: Text(
                                        // Ce que le gain est devenu, pas ce
                                        // que la carte annonçait.
                                        _rightMightGain > 0
                                            ? (isFrench
                                                ? '+$_rightMightGain Puissance'
                                                : '+$_rightMightGain Might')
                                            : (isFrench
                                                ? '+$_rightArmor Armure'
                                                : '+$_rightArmor Armor'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _rightMightGain > 0
                                              ? Colors.amber
                                              : Colors.cyanAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          height: 1.1,
                                        ),
                                      ),
                                    ),
                                  if (_rightShowDamage)
                                    AnimatedPositioned(
                                      duration: const Duration(milliseconds: 800),
                                      curve: Curves.easeOutQuad,
                                      top: _rightDamageY,
                                      child: Text(
                                        _rightArmorLoss > 0
                                            ? (isFrench
                                                ? '-$_rightArmorLoss Armure\n-$_rightHpLoss HP'
                                                : '-$_rightArmorLoss Armor\n-$_rightHpLoss HP')
                                            : '-$_rightHpLoss HP',
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  buildArmorBadge(_rightArmor),
                                  if (_rightMightGain > 0) ...[
                                    const SizedBox(width: 4),
                                    buildMightBadge(_rightMightGain),
                                  ],
                                ],
                              ),
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

                // La règle de stat de la classe choisie, en clair. Générée
                // par `StatRuleLabel.describe` — la même phrase qu'à l'écran
                // de sélection de classe, jamais écrite ici (ADR-090). Le nom
                // de la classe la coiffe : la phrase est à la troisième
                // personne, et c'est sous ce titre qu'elle est juste.
                if (rules.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.engine.mockState.chosenHero!.getName(
                            Localizations.localeOf(context).languageCode,
                          ),
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        for (final rule in rules)
                          Text(
                            rule.describe(l10n),
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 11.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

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

  /// Le badge de la Puissance temporaire produite par la conversion d'une
  /// classe. Même forme que [buildArmorBadge] : les deux se lisent côte à
  /// côte, et ce qui change entre eux est ce que la règle a produit.
  ///
  /// L'éclair est l'icône de la Puissance depuis le lot B
  /// (`card_text_renderer.dart:309`, `might_icon_test.dart`) : jamais une
  /// épée, jamais un 💪.
  Widget buildMightBadge(int value) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.black87, size: 12),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

