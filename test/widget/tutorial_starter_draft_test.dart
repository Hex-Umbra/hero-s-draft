import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/tutorial/tutorial_engine.dart';
import 'package:roguelike_card_game/tutorial/widgets/tutorial_starter_deck_widget.dart';

import '../tutorial/tutorial_test_registry.dart';

Future<TutorialEngine> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final engine = TutorialEngine(data: await buildTutorialTestRegistry());
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

Future<void> _tapAll(WidgetTester tester, Iterable<CardData> cards) async {
  for (final card in cards) {
    await tester.tap(find.byKey(ValueKey('tutorial-pool-${card.id}')));
    await tester.pump();
  }
}

void main() {
  testWidgets('deux sections, le lot de Regeneration d Armure puis les neutres, compteurs 0/2 et 0/3', (tester) async {
    final engine = await _pump(tester);
    final draft = engine.fixtures.starterDraft('regen_armor');

    expect(find.text("Cartes de Régénération d'Armure"), findsOneWidget);
    expect(find.text('Cartes neutres'), findsOneWidget);
    expect(find.text('0/2'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);
    for (final card in draft.lot) {
      expect(find.byKey(ValueKey('tutorial-pool-${card.id}')), findsOneWidget);
    }
    for (final other in ['rage', 'mana_flux']) {
      for (final card in engine.fixtures.starterDraft(other).lot) {
        expect(find.byKey(ValueKey('tutorial-pool-${card.id}')), findsNothing);
      }
    }
  });

  testWidgets('les compteurs demarrent a 0/2 et 0/3', (tester) async {
    await _pump(tester);
    expect(find.text('0/2'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);
  });

  testWidgets('sélectionner 1 seule carte laisse le deck vide', (tester) async {
    // Régression : `_toggle` appelle `setStarterDeck([])` tant que les quotas
    // ne sont pas remplis ; le deck ne doit pas se remplir avant, sans quoi le
    // bouton SUIVANT se débloquerait avec un deck incomplet et le joueur
    // resterait bloqué dessus (verrou d'amont dès l'étape suivante).
    final engine = await _pump(tester);
    final draft = engine.fixtures.starterDraft(engine.mockState.activePassive?.id);

    await _tapAll(tester, [draft.lot.first]);

    expect(find.text('1/2'), findsOneWidget);
    expect(engine.mockState.masterDeck, isEmpty);
  });

  testWidgets('selectionner 2 cartes du lot et 3 neutres remplit le deck des 5 cartes choisies, sans signature', (tester) async {
    final engine = await _pump(tester);
    final draft = engine.fixtures.starterDraft(engine.mockState.activePassive?.id);

    await _tapAll(tester, [...draft.lot.take(2), ...draft.neutrals.take(3)]);

    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('3/3'), findsOneWidget);
    // Les signatures du Paladin ne sont plus des cartes du deck.
    expect(engine.mockState.masterDeck, hasLength(5));
    expect(
      engine.mockState.masterDeck.map((c) => c.data.id),
      isNot(anyOf(contains('holy_shield'), contains('smite'))),
    );
  });

  testWidgets('le bandeau nomme les signatures de la classe, toujours disponibles en combat', (tester) async {
    await _pump(tester);

    expect(
      find.text('Vos signatures, toujours disponibles en combat : Bouclier Sacré, Châtiment'),
      findsOneWidget,
    );
    expect(find.textContaining("Ajoutées d'office"), findsNothing);
  });

  testWidgets('la sélection est bornee par les quotas', (tester) async {
    final engine = await _pump(tester);
    final draft = engine.fixtures.starterDraft(engine.mockState.activePassive?.id);

    await _tapAll(tester, [...draft.lot.take(3), ...draft.neutrals.take(4)]);

    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('3/3'), findsOneWidget);
    expect(engine.mockState.masterDeck, hasLength(5));
  });
}
