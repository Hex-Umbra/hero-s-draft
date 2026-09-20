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

/// Presse « Voir la différence » et laisse passer le temps 1 (le gain,
/// 200 ms), sans laisser le temps 2 (le coup, 900 ms) se déclencher.
///
/// C'est le seul instant où l'écran distingue une classe qui convertit d'une
/// classe qui garde : après le coup, `_demoDamage` (10) dépasse toujours
/// `_demoArmorGain` (4), donc `EntityStats.takeDamage` ramène l'Armure du
/// panneau droit à 0 **dans les deux cas** — converti ou non. Un test qui
/// n'observe qu'après le coup ne peut donc jamais faire la différence.
Future<void> _declencherLeGain(WidgetTester tester) async {
  await tester.tap(find.textContaining('Voir la différence'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

/// Laisse passer le temps 2 (le coup) puis le nettoyage des textes
/// flottants, à partir de l'état laissé par [_declencherLeGain]. Le dernier
/// pump va au-delà des 2200 ms du nettoyage : un timer encore en attente à
/// la fin du test ferait échouer l'assertion `!timersPending` de
/// `flutter_test`, qui tourne sous `FakeAsync`.
Future<void> _laisserPasserLeCoup(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 750));
  await tester.pump(const Duration(milliseconds: 1300));
}

/// La démonstration complète : le gain, puis le coup.
Future<void> _simuler(WidgetTester tester) async {
  await _declencherLeGain(tester);
  await _laisserPasserLeCoup(tester);
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

  testWidgets(
    'au temps du gain, une classe sans regle affiche l Armure gagnee, pas de Puissance',
    (tester) async {
      await _pump(tester, 'paladin');

      await _declencherLeGain(tester);

      // Le geste discriminant (decision de plan n2) : entre le gain (200 ms)
      // et le coup (900 ms), une classe qui ne convertit pas garde l'Armure
      // gagnee telle quelle, et aucune Puissance n'apparait.
      expect(find.text('4'), findsOneWidget); // le badge d'Armure du panneau droit
      expect(find.byIcon(Icons.bolt_rounded), findsNothing);

      await _laisserPasserLeCoup(tester); // draine les timers restants
    },
  );

  testWidgets(
    'au temps du gain, une classe qui convertit affiche la Puissance, pas l Armure',
    (tester) async {
      await _pump(tester, 'berserker');

      await _declencherLeGain(tester);

      // Meme instant que le test Paladin ci-dessus : ce contraste ne tient
      // que si le gain passe reellement par StatGains.apply et les statRules
      // de la classe (ADR-081) — jamais par une ecriture directe de l'Armure.
      expect(find.text('0'), findsWidgets); // le badge d'Armure du panneau droit, converti
      expect(find.text('4'), findsOneWidget); // le badge de Puissance
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);

      await _laisserPasserLeCoup(tester); // draine les timers restants
    },
  );

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
    // passages, sans quoi `addStatus` les empilerait. C'est le garde reel :
    // `_rightMightGain` (widget) est un delta borne a un seul appel de
    // `gainArmorForDemo`, donc toujours 0 ou 4 par construction, jamais 8,
    // que la classe empile ou non — le badge affiche ne peut donc jamais
    // trahir un empilement. Seul l'etat du moteur le peut.
    expect(engine.mockState.heroStats.effectiveMight, 4);
  });
}
