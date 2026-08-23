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

  final engine = TutorialEngine(data: buildTutorialTestRegistry());
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

  testWidgets('le passif de chaque classe est affiché depuis passives.json', (tester) async {
    await _pump(tester);

    expect(find.text('Régénération d\'Armure'), findsOneWidget);
    expect(find.text('Armure du Berserker'), findsOneWidget);
    expect(find.text('Armure Magique'), findsOneWidget);
  });

  testWidgets('choisir une classe l\'écrit dans la tranche persistante', (tester) async {
    final engine = await _pump(tester);
    expect(engine.mockState.chosenHero, isNull);

    await tester.tap(find.text('Le Mage'));
    await tester.pumpAndSettle();

    expect(engine.mockState.chosenHero?.id, 'mage');
    expect(engine.mockState.activePassive?.id, 'spellArmor');
    expect(engine.mockState.heroStats.maxPv, 60);
  });
}
