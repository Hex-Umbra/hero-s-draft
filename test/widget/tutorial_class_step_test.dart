import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/tutorial/tutorial_engine.dart';
import 'package:roguelike_card_game/tutorial/widgets/tutorial_class_choice_widget.dart';

import '../tutorial/tutorial_test_registry.dart';

Future<TutorialEngine> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final engine = TutorialEngine(data: await buildTutorialTestRegistry());
  engine.prepareStep(0);

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
      home: Scaffold(body: TutorialClassChoiceWidget(engine: engine)),
    ),
  );
  await tester.pumpAndSettle();
  return engine;
}

void main() {
  testWidgets('les trois classes s\'affichent avec leurs PV réels', (tester) async {
    await _pump(tester);

    expect(find.text('Le Paladin'), findsOneWidget);
    expect(find.text('Le Berserker'), findsOneWidget);
    expect(find.text('Le Mage'), findsOneWidget);

    expect(find.text('100 PV'), findsOneWidget);
    expect(find.text('80 PV'), findsOneWidget);
    expect(find.text('60 PV'), findsOneWidget);
  });

  testWidgets('chaque carte montre son passif par defaut, repliee', (tester) async {
    final engine = await _pump(tester);

    // Repliee, la carte montre quand meme le passif avec lequel la run
    // partirait : le joueur compare les trois classes sans rien ouvrir
    // (meme regle que l'ecran de selection, `class_passive_list.dart:56`).
    for (final hero in engine.fixtures.heroes) {
      expect(
        find.text(engine.fixtures.passivesFor(hero).first.getName('fr')),
        findsOneWidget,
        reason: hero.id,
      );
    }

    // Et seulement celui-la : les autres n'apparaissent qu'une fois la
    // classe choisie.
    for (final hero in engine.fixtures.heroes) {
      for (final passif in engine.fixtures.passivesFor(hero).skip(1)) {
        expect(find.text(passif.getName('fr')), findsNothing, reason: passif.id);
      }
    }
  });

  testWidgets('choisir une classe deplie ses passifs', (tester) async {
    final engine = await _pump(tester);

    await tester.tap(find.text('Le Mage'));
    await tester.pumpAndSettle();

    final mage = engine.fixtures.heroes.firstWhere((h) => h.id == 'mage');
    for (final passif in engine.fixtures.passivesFor(mage)) {
      expect(find.text(passif.getName('fr')), findsOneWidget, reason: passif.id);
    }
  });

  testWidgets('toucher un passif deplie le retient', (tester) async {
    final engine = await _pump(tester);

    await tester.tap(find.text('Le Mage'));
    await tester.pumpAndSettle();

    final mage = engine.fixtures.heroes.firstWhere((h) => h.id == 'mage');
    final autre = engine.fixtures.passivesFor(mage).last;
    expect(autre.id, isNot(engine.mockState.activePassive?.id));

    await tester.tap(find.text(autre.getName('fr')));
    await tester.pumpAndSettle();

    expect(engine.mockState.activePassive?.id, autre.id);
  });

  testWidgets('retaper une classe deja choisie ne reinitialise pas son passif', (tester) async {
    // Regression : la carte entiere portait un seul InkWell dont le onTap
    // rappelait chooseHero sans condition. Retaper le nom d'une carte deja
    // choisie (un geste plausible en comparant les classes) reinitialisait
    // donc silencieusement le passif retenu sur le premier de la classe.
    final engine = await _pump(tester);

    await tester.tap(find.text('Le Mage'));
    await tester.pumpAndSettle();

    final mage = engine.fixtures.heroes.firstWhere((h) => h.id == 'mage');
    final autre = engine.fixtures.passivesFor(mage).last;
    expect(autre.id, isNot(engine.mockState.activePassive?.id));

    await tester.tap(find.text(autre.getName('fr')));
    await tester.pumpAndSettle();
    expect(engine.mockState.activePassive?.id, autre.id);

    await tester.tap(find.text('Le Mage'));
    await tester.pumpAndSettle();

    expect(engine.mockState.activePassive?.id, autre.id);
  });

  testWidgets('choisir une classe l\'écrit dans la tranche persistante', (tester) async {
    final engine = await _pump(tester);
    expect(engine.mockState.chosenHero, isNull);

    await tester.tap(find.text('Le Mage'));
    await tester.pumpAndSettle();

    expect(engine.mockState.chosenHero?.id, 'mage');
    expect(engine.mockState.activePassive?.id, 'channeling');
    expect(engine.mockState.heroStats.maxPv, 60);
  });
}
