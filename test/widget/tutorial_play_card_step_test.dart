import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/tutorial/tutorial_engine.dart';
import 'package:roguelike_card_game/tutorial/tutorial_fixtures.dart';
import 'package:roguelike_card_game/tutorial/widgets/tutorial_play_card_widget.dart';

import '../tutorial/tutorial_test_registry.dart';

/// Le texte flottant d'un gain d'Armure annonce ce que la classe a
/// réellement obtenu, pas la valeur imprimée sur la carte (spec P-41, §9.1,
/// périmètre élargi le 2026-09-20).
///
/// La main sème Frappe *et* Défense, comme le fait réellement
/// `TutorialEngine._seedPlayCardHand` pour cette étape : `_buildHandZone`
/// (`tutorial_play_card_widget.dart`) filtre la main affichée par phase —
/// attaque tant que l'ennemi est à PV pleins, compétence une fois qu'il a
/// encaissé un coup — et `_handHint` fait `hand.firstWhere` sur le type
/// attendu de la phase en cours. Ne semer que Défense affamerait ce
/// `firstWhere` dès la construction (aucune carte d'attaque en main tant que
/// l'ennemi est à PV pleins) et ferait planter le premier `pumpWidget`, avant
/// même d'atteindre la carte visée par cette tâche.
Future<TutorialEngine> _pump(WidgetTester tester, String heroId) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final engine = TutorialEngine(data: await buildTutorialTestRegistry());
  engine.chooseHero(engine.fixtures.heroes.firstWhere((h) => h.id == heroId));
  engine.seedEnemy();
  engine.seedHand([TutorialFixtureIds.strike, TutorialFixtureIds.defend]);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('fr', '')],
      locale: const Locale('fr', ''),
      home: Scaffold(body: TutorialPlayCardWidget(engine: engine)),
    ),
  );
  await tester.pumpAndSettle();
  return engine;
}

/// Sélectionne Frappe, puis la joue sur le Slime.
///
/// Seul geste qui fait sortir l'ennemi de ses PV pleins : c'est ce qui fait
/// basculer `_buildHandZone`/`_handHint` de la phase 1 (attaque) à la
/// phase 2 (compétence), et révèle ainsi Défense dans la main affichée.
/// Drainé sur 900 ms pour que le texte flottant du coup (« -6 HP », 800 ms
/// de vie) soit entièrement retombé avant `_jouerDefense` : sans ça, son
/// `Future.delayed` de nettoyage resterait en attente pendant la suite du
/// test.
///
/// `nom.toUpperCase()` : `UiCard` (`lib/ui/widgets/ui_card.dart:220`) affiche
/// toujours son titre en capitales (`title.toUpperCase()`), jamais la
/// casse d'origine des données.
Future<void> _jouerFrappe(WidgetTester tester, TutorialEngine engine) async {
  final nom = engine.fixtures.card(TutorialFixtureIds.strike).getName('fr');
  await tester.tap(find.text(nom.toUpperCase()).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(engine.fixtures.trainingEnemy.getName('fr')));
  await tester.pump(const Duration(milliseconds: 900));
}

/// Sélectionne la carte de Défense, puis la joue sur la carte Héros.
///
/// La zone Héros est le bloc intitulé « HÉROS » au centre du plateau
/// (`tutorial_play_card_widget.dart`, `_buildHeroZone`) : son `GestureDetector`
/// enveloppe ce titre, donc taper le texte suffit. Le dernier pump ne va
/// qu'à 100 ms : le texte flottant vit 800 ms, et c'est justement lui que
/// les tests observent — le drainer ici le ferait disparaître avant
/// l'assertion.
Future<void> _jouerDefense(WidgetTester tester, TutorialEngine engine) async {
  final nom = engine.fixtures.card(TutorialFixtureIds.defend).getName('fr');
  await tester.tap(find.text(nom.toUpperCase()).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('HÉROS'));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('une classe qui garde son Armure l annonce en armure', (tester) async {
    final engine = await _pump(tester, 'paladin');
    final valeur = engine.fixtures
        .card(TutorialFixtureIds.defend)
        .effects
        .firstWhere((e) => e.type == 'armor')
        .value;

    await _jouerFrappe(tester, engine);
    await _jouerDefense(tester, engine);

    expect(find.text('+$valeur 🛡️'), findsOneWidget);

    // Draine le texte flottant restant : sinon son `Future.delayed` de
    // nettoyage (800 ms) est encore en attente à la fin du test.
    await tester.pump(const Duration(milliseconds: 900));
  });

  testWidgets('une classe qui convertit annonce la Puissance', (tester) async {
    final engine = await _pump(tester, 'berserker');
    final valeur = engine.fixtures
        .card(TutorialFixtureIds.defend)
        .effects
        .firstWhere((e) => e.type == 'armor')
        .value;

    await _jouerFrappe(tester, engine);
    await _jouerDefense(tester, engine);

    // Le badge d'Armure reste a 0 : annoncer « +5 bouclier » etait le
    // mensonge que cette tache corrige.
    expect(engine.mockState.heroStats.armure, 0);
    expect(find.text('+$valeur 🛡️'), findsNothing);
    expect(find.text('+$valeur ⚡'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
  });
}
