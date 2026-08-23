import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/tutorial/tutorial_engine.dart';
import 'package:roguelike_card_game/tutorial/widgets/tutorial_starter_deck_widget.dart';

import '../tutorial/tutorial_test_registry.dart';

Future<TutorialEngine> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final engine = TutorialEngine(data: buildTutorialTestRegistry());
  engine.chooseHero(engine.fixtures.heroes.first); // paladin

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
      home: Scaffold(body: TutorialStarterDeckWidget(engine: engine)),
    ),
  );
  await tester.pumpAndSettle();
  return engine;
}

void main() {
  testWidgets('le compteur démarre à 0/5', (tester) async {
    await _pump(tester);
    expect(find.text('0 / 5'), findsOneWidget);
  });

  testWidgets('sélectionner 1 seule carte laisse le deck vide', (tester) async {
    // Régression : `_toggle` appelle `setStarterDeck([])` tant que la
    // sélection n'atteint pas 5 ; le deck ne doit pas se remplir avant que
    // le compte soit atteint, sans quoi le bouton SUIVANT se débloquerait
    // avec un deck incomplet et le joueur resterait bloqué dessus (verrou
    // d'amont dès l'étape suivante).
    final engine = await _pump(tester);
    final pool = engine.fixtures.starterPool;

    await tester.tap(find.byKey(ValueKey('tutorial-pool-${pool[0].id}')));
    await tester.pump();

    expect(find.text('1 / 5'), findsOneWidget);
    expect(engine.mockState.masterDeck, isEmpty);
  });

  testWidgets('sélectionner 5 cartes remplit le deck avec les cartes de classe', (tester) async {
    final engine = await _pump(tester);
    final pool = engine.fixtures.starterPool;

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(ValueKey('tutorial-pool-${pool[i].id}')));
      await tester.pump();
    }

    expect(find.text('5 / 5'), findsOneWidget);
    // 5 choisies + 2 cartes de classe du Paladin.
    expect(engine.mockState.masterDeck, hasLength(7));
    expect(
      engine.mockState.masterDeck.map((c) => c.data.id),
      containsAll(<String>['holy_shield', 'smite']),
    );
  });

  testWidgets('la sélection est bornée à 5', (tester) async {
    final engine = await _pump(tester);
    final pool = engine.fixtures.starterPool;

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byKey(ValueKey('tutorial-pool-${pool[i].id}')));
      await tester.pump();
    }

    expect(find.text('5 / 5'), findsOneWidget);
    expect(engine.mockState.masterDeck, hasLength(7));
  });
}
