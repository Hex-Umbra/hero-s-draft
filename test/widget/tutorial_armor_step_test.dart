import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/tutorial/tutorial_engine.dart';
import 'package:roguelike_card_game/tutorial/widgets/tutorial_armor_widget.dart';

import '../tutorial/tutorial_test_registry.dart';

/// L'etape « Armure & Degats » n'enseigne jamais une regle que la classe
/// choisie ne suit pas (spec P-41, §9.1).
Future<TutorialEngine> _pump(WidgetTester tester, String heroId) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final engine = TutorialEngine(data: await buildTutorialTestRegistry());
  engine.chooseHero(engine.fixtures.heroes.firstWhere((h) => h.id == heroId));

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
      home: Scaffold(body: TutorialArmorWidget(engine: engine)),
    ),
  );
  await tester.pumpAndSettle();
  return engine;
}

/// Presse « Voir la différence » et laisse passer les deux temps de la
/// démonstration : le gain (200 ms) puis le coup (900 ms). Le dernier pump
/// va au-delà des 2200 ms du nettoyage des textes flottants : un timer
/// encore en attente à la fin du test ferait échouer l'assertion
/// `!timersPending` de `flutter_test`, qui tourne sous `FakeAsync`.
Future<void> _simuler(WidgetTester tester) async {
  await tester.tap(find.textContaining('Voir la différence'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump(const Duration(milliseconds: 750));
  await tester.pump(const Duration(milliseconds: 1300));
}

void main() {
  testWidgets('une classe sans regle garde son Armure et l absorbe', (tester) async {
    final engine = await _pump(tester, 'paladin');
    expect(engine.mockState.chosenHero!.statRules, isEmpty);

    await _simuler(tester);

    // 100 PV, 4 Armure, 10 degats : l'armure encaisse 4, les PV 6.
    expect(find.text('94/100'), findsOneWidget);
    // Et le panneau sans armure perd les 10.
    expect(find.text('90/100'), findsOneWidget);
    // Sans regle sur l'Armure, le panneau garde son titre d'origine.
    expect(find.text('AVEC ARMURE'), findsOneWidget);
    // Aucun encadre de regle : la classe n'en declare aucune.
    expect(find.text('Le Paladin'), findsNothing);
  });

  testWidgets('une classe qui convertit ne garde aucune Armure', (tester) async {
    final engine = await _pump(tester, 'berserker');
    expect(engine.mockState.chosenHero!.statRules, isNotEmpty);

    await _simuler(tester);

    // 80 PV, 0 Armure conservee : les deux panneaux perdent les 10 degats.
    expect(find.text('70/80'), findsNWidgets(2));
    // Genere depuis la regle : le titre annonce ce que l'Armure devient.
    expect(find.text('ARMURE → PUISSANCE'), findsOneWidget);
    // Le badge d'Armure du panneau droit reste a 0 : rien n'est conserve.
    expect(find.text('0'), findsWidgets);
    // La Puissance temporaire produite est montree, avec sa valeur.
    expect(find.text('4'), findsOneWidget);
    expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
  });

  testWidgets('la regle de la classe est ecrite sous les panneaux', (tester) async {
    await _pump(tester, 'berserker');

    // Generee par `StatRuleLabel.describe`, jamais ecrite classe par classe
    // (ADR-090). Le nom de la classe la coiffe, ce qui rend juste la
    // troisieme personne de la phrase.
    expect(find.text('Le Berserker'), findsOneWidget);
    expect(
      find.text('Son Armure devient de la Puissance pour un tour.'),
      findsOneWidget,
    );
  });

  testWidgets('presser deux fois n empile pas la Puissance', (tester) async {
    final engine = await _pump(tester, 'berserker');

    await _simuler(tester);
    await _simuler(tester);

    // +4, jamais +8 : `resetHeroStatsForDemo` efface les statuts entre deux
    // passages, sans quoi `addStatus` les empilerait.
    expect(engine.mockState.heroStats.effectiveMight, 4);
    // Le badge affiche : jamais un 8 empile sur l'ecran non plus.
    expect(find.text('8'), findsNothing);
  });
}
