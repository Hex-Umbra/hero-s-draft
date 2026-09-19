import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/ui/widgets/passive_choice_dialog.dart';

// Le Paladin est la seule classe livree qui demarre avec de la Maitrise
// (assets/data/classes/paladin/class.json, "mastery": 1) ; le Berserker
// demarre a 0 comme le Mage. Les deux sont ici parce que la ligne de
// Maitrise du panneau se lit differemment dans chaque cas, et que le cas a
// 0 concerne deux classes sur trois.
const _paladin = HeroData(
  id: 'paladin',
  nameEn: 'Paladin',
  nameFr: 'Le Paladin',
  descriptionEn: 'Survival Oriented',
  descriptionFr: 'Orienté Survie',
  classCard: 'hero_paladin.png',
  maxHp: 100,
  maxMana: 3,
  mastery: 1,
  displayOrder: 1,
);
const _berserker = HeroData(
  id: 'berserker',
  nameEn: 'Berserker',
  nameFr: 'Le Berserker',
  descriptionEn: 'Damage Oriented',
  descriptionFr: 'Orienté Dégâts',
  classCard: 'hero_berserker.png',
  maxHp: 80,
  maxMana: 3,
  displayOrder: 2,
);

// Les trois passifs reels du Berserker (assets/data/passives/), recopies
// mot pour mot : ce sont les textes que le panneau doit rendre lisibles
// cote a cote, et leur longueur est celle que le jeu livre vraiment.
const _rage = PassiveData(
  id: 'rage',
  nameEn: 'Rage',
  nameFr: 'Rage',
  descriptionEn:
      'At the start of your turn, gain 1 Might for the turn, plus 1 per '
      '10 missing HP.',
  descriptionFr:
      'Au début du tour, gagne 1 Puissance pour le tour, plus 1 par '
      'tranche de 10 PV manquants.',
  classes: ['berserker'],
  trigger: RelicTrigger.startOfTurn,
  effectType: 'rage',
  value: 1,
  duration: 1,
  displayOrder: 1,
  mastery: PassiveMastery(
    field: 'value',
    perPoint: 1,
    descriptionEn: '+{amount} Might per tranche',
    descriptionFr: '+{amount} Puissance par tranche',
  ),
);
const _bloodthirst = PassiveData(
  id: 'bloodthirst',
  nameEn: 'Bloodthirst',
  nameFr: 'Soif de Sang',
  descriptionEn:
      'Playing an Attack arms Lifesteal for 2 turns: 1 HP per damaging '
      'card, plus 1 per quarter of missing HP.',
  descriptionFr:
      'Jouer une Attaque arme le Vol de Vie pendant 2 tours : 1 PV par '
      'carte de dégâts, plus 1 par quart de PV manquants.',
  classes: ['berserker'],
  trigger: RelicTrigger.onAttackPlayed,
  effectType: 'bloodthirst',
  value: 1,
  duration: 2,
  displayOrder: 2,
  mastery: PassiveMastery(
    field: 'value',
    perPoint: 1,
    descriptionEn: '+{amount} HP drained',
    descriptionFr: '+{amount} PV drainé',
  ),
);
const _frenzy = PassiveData(
  id: 'frenzy',
  nameEn: 'Frenzy',
  nameFr: 'Frénésie',
  descriptionEn:
      'Each enemy killed grants 2 Might for the turn and draws 1 card.',
  descriptionFr:
      'Chaque ennemi abattu donne 2 Puissance pour le tour et fait '
      'piocher 1 carte.',
  classes: ['berserker'],
  trigger: RelicTrigger.onEnemyKilled,
  effectType: 'frenzy',
  value: 2,
  duration: 1,
  draw: 1,
  displayOrder: 3,
  mastery: PassiveMastery(
    field: 'value',
    perPoint: 1,
    descriptionEn: '+{amount} Might per kill',
    descriptionFr: '+{amount} Puissance par ennemi abattu',
  ),
);

// Le passif du Paladin, pour le seul cas ou la classe demarre avec de la
// Maitrise.
const _regenArmor = PassiveData(
  id: 'regen_armor',
  nameEn: 'Armor Regeneration',
  nameFr: "Régénération d'Armure",
  descriptionEn: 'Gain 2 Block automatically at the end of each turn.',
  descriptionFr:
      'Gagne 2 points d\'Armure automatiquement à la fin de chaque tour.',
  classes: ['paladin'],
  trigger: RelicTrigger.endOfTurn,
  effectType: 'gain_armor',
  value: 2,
  displayOrder: 1,
  mastery: PassiveMastery(
    field: 'value',
    perPoint: 1,
    descriptionEn: '+{amount} Block at end of turn',
    descriptionFr: '+{amount} Armure en fin de tour',
  ),
);

// Passif synthetique, jamais livre : `mastery` est nullable dans le modele
// et aucun des neuf passifs du jeu ne l'omet aujourd'hui. Le panneau ne
// doit pas supposer qu'il est toujours la.
const _sansMaitrise = PassiveData(
  id: 'sans_maitrise',
  nameEn: 'No Mastery',
  nameFr: 'Sans Maitrise',
  descriptionEn: 'Exists only in tests: declares no mastery block.',
  descriptionFr: "N'existe qu'en test : ne declare aucun bloc de Maitrise.",
  classes: ['berserker'],
  trigger: RelicTrigger.startOfTurn,
  effectType: 'none',
  value: 1,
  displayOrder: 4,
);

/// Ce que `PassiveChoiceDialog.show` a rendu, et s'il a rendu quelque chose.
///
/// `value` seul ne suffit pas : `null` est une reponse legitime (annulation)
/// qu'il faut distinguer de « la future n'est pas encore retombee ».
class _Captured {
  PassiveData? value;
  bool done = false;
}

Future<_Captured> _open(
  WidgetTester tester, {
  required HeroData playerClass,
  required List<PassiveData> passives,
  int initialIndex = 0,
  Locale locale = const Locale('fr', ''),
  Size taille = const Size(800, 1000),
  TextScaler? echelle,
}) async {
  final captured = _Captured();

  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('fr', '')],
      locale: locale,
      builder: echelle == null
          ? null
          : (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: echelle),
              child: child!,
            ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                captured.value = await PassiveChoiceDialog.show(
                  context,
                  playerClass: playerClass,
                  passives: passives,
                  initialIndex: initialIndex,
                );
                captured.done = true;
              },
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
  return captured;
}

/// La ligne entiere d'un passif : c'est elle qui porte le geste, pas le
/// seul texte du nom.
Finder _ligneDe(String nom) =>
    find.ancestor(of: find.text(nom), matching: find.byType(InkWell)).first;

void main() {
  testWidgets('tous les passifs disponibles sont proposes, avec leur texte', (
    tester,
  ) async {
    await _open(
      tester,
      playerClass: _berserker,
      passives: const [_rage, _bloodthirst, _frenzy],
    );

    expect(find.text('Rage'), findsOneWidget);
    expect(find.text('Soif de Sang'), findsOneWidget);
    expect(find.text('Frénésie'), findsOneWidget);
    // La description complete de chacun, pas seulement celle du passif
    // retenu : comparer les trois sans les cliquer un par un est la raison
    // d'etre du panneau.
    expect(find.text(_rage.descriptionFr), findsOneWidget);
    expect(find.text(_bloodthirst.descriptionFr), findsOneWidget);
    expect(find.text(_frenzy.descriptionFr), findsOneWidget);
  });

  testWidgets('le passif d ouverture est coche, les autres non', (
    tester,
  ) async {
    await _open(
      tester,
      playerClass: _berserker,
      passives: const [_rage, _bloodthirst, _frenzy],
    );

    expect(
      find.descendant(
        of: _ligneDe('Rage'),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _ligneDe('Soif de Sang'),
        matching: find.byIcon(Icons.circle_outlined),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('le panneau s ouvre sur le passif que l appelant designe', (
    tester,
  ) async {
    await _open(
      tester,
      playerClass: _berserker,
      passives: const [_rage, _bloodthirst, _frenzy],
      initialIndex: 2,
    );

    expect(
      find.descendant(
        of: _ligneDe('Frénésie'),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
  });

  testWidgets('toucher une autre ligne y deplace la coche', (tester) async {
    await _open(
      tester,
      playerClass: _berserker,
      passives: const [_rage, _bloodthirst, _frenzy],
    );

    await tester.tap(_ligneDe('Frénésie'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: _ligneDe('Frénésie'),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _ligneDe('Rage'),
        matching: find.byIcon(Icons.circle_outlined),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('valider rend le passif coche', (tester) async {
    final captured = await _open(
      tester,
      playerClass: _berserker,
      passives: const [_rage, _bloodthirst, _frenzy],
    );

    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(captured.done, isTrue);
    expect(captured.value, same(_rage));
  });

  testWidgets('valider rend le passif que le joueur a touche', (tester) async {
    final captured = await _open(
      tester,
      playerClass: _berserker,
      passives: const [_rage, _bloodthirst, _frenzy],
    );

    await tester.tap(_ligneDe('Soif de Sang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(captured.value, same(_bloodthirst));
  });

  testWidgets('annuler ne rend aucun passif', (tester) async {
    final captured = await _open(
      tester,
      playerClass: _berserker,
      passives: const [_rage, _bloodthirst, _frenzy],
    );

    await tester.tap(_ligneDe('Frénésie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    // Annuler apres avoir touche un autre passif : le panneau ne doit pas
    // rendre ce passif-la sous pretexte qu'il etait coche.
    expect(captured.done, isTrue);
    expect(captured.value, isNull);
  });

  testWidgets('la Maitrise de depart de la classe est dite, valeur comprise', (
    tester,
  ) async {
    await _open(
      tester,
      playerClass: _paladin,
      passives: const [_regenArmor],
    );

    expect(
      find.text('Maîtrise 1 : +1 Armure en fin de tour'),
      findsOneWidget,
    );
  });

  testWidgets('une classe sans Maitrise de depart le dit, sans cacher l effet', (
    tester,
  ) async {
    await _open(
      tester,
      playerClass: _berserker,
      passives: const [_rage],
    );

    // Le Berserker peut gagner de la Maitrise en cours de run (recompense
    // « Affinite ») : l'effet reste ecrit, seule sa valeur de depart dit
    // qu'il dort.
    expect(
      find.text('Maîtrise 0 au départ : +1 Puissance par tranche'),
      findsOneWidget,
    );
  });

  testWidgets('un passif sans bloc de Maitrise n affiche aucune ligne', (
    tester,
  ) async {
    await _open(
      tester,
      playerClass: _berserker,
      passives: const [_sansMaitrise],
    );

    expect(find.textContaining('Maîtrise'), findsNothing);
  });

  testWidgets('chaque ligne offre une cible tactile d au moins 48px', (
    tester,
  ) async {
    await _open(
      tester,
      playerClass: _berserker,
      passives: const [_rage, _bloodthirst, _frenzy],
    );

    for (final nom in ['Rage', 'Soif de Sang', 'Frénésie']) {
      expect(
        tester.getSize(_ligneDe(nom)).height,
        greaterThanOrEqualTo(48.0),
        reason: 'la ligne « $nom » est sous la cible tactile de Material',
      );
    }
  });

  testWidgets('le panneau tient sur le telephone le plus etroit (320px)', (
    tester,
  ) async {
    // 320px est le plancher de la plage mobile balayee par les tests de
    // l'ecran de selection : le panneau herite de cette exigence en
    // heritant du contenu qui etait sur la carte.
    await _open(
      tester,
      playerClass: _berserker,
      passives: const [_rage, _bloodthirst, _frenzy],
      taille: const Size(320, 900),
    );

    expect(
      tester.takeException(),
      isNull,
      reason: 'le panneau deborde sur un telephone de 320px',
    );
    expect(find.text('Rage'), findsOneWidget);
  });

  testWidgets('le panneau tient a 320px avec un texte mis a l echelle 1.3', (
    tester,
  ) async {
    await _open(
      tester,
      playerClass: _berserker,
      passives: const [_rage, _bloodthirst, _frenzy],
      taille: const Size(320, 900),
      echelle: const TextScaler.linear(1.3),
    );

    expect(
      tester.takeException(),
      isNull,
      reason: 'le panneau deborde a 320px des que le texte grossit',
    );
  });

  testWidgets('le panneau est traduit', (tester) async {
    await _open(
      tester,
      playerClass: _berserker,
      passives: const [_rage],
      locale: const Locale('en', ''),
    );

    expect(find.text('Choose your passive'), findsOneWidget);
    expect(find.text('Mastery 0 at start: +1 Might per tranche'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
  });
}
