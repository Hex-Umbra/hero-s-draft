import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/tutorial/tutorial_engine.dart';
import 'package:roguelike_card_game/tutorial/widgets/tutorial_merge_widget.dart';

import '../tutorial/tutorial_test_registry.dart';

/// Monte l'étape de fusion sur trois exemplaires de [cardId], puis fusionne :
/// l'animation de 600 ms, puis le rappel différé de 150 ms. Jamais de
/// `pumpAndSettle()` : la carte fusionnée grandit par une animation
/// élastique.
Future<TutorialEngine> _merge(WidgetTester tester, String cardId) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final engine = TutorialEngine(data: await buildTutorialTestRegistry());
  engine.seedHand([cardId, cardId, cardId]);

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
      home: Scaffold(body: TutorialMergeWidget(engine: engine)),
    ),
  );
  await tester.tap(find.text('Sélectionner les 3 et fusionner'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 650));
  await tester.pump(const Duration(milliseconds: 200));
  return engine;
}

/// L'étape de fusion du tutoriel enseigne le choix d'une rune (spec P-43 E2,
/// A18, §5.5).
void main() {
  testWidgets('l offre se montre, et la rune choisie se dit', (tester) async {
    final engine = await _merge(tester, 'strike_basic');

    expect(find.text('Choisissez une rune :'), findsOneWidget);
    final id = engine.mockState.mergeOffer.first;
    final name = engine.runeById(id)!.getName('fr');

    await tester.tap(find.byKey(ValueKey('tutorial-merge-rune-$id')));
    await tester.pump();

    expect(engine.mockState.hand.single.forgeUpgrades, ['$id:1']);
    expect(find.text('Rune ajoutée : $name'), findsOneWidget);
  });

  testWidgets('sans rune eligible, l etape le dit', (tester) async {
    await _merge(tester, 'concentration');

    expect(find.text('Choisissez une rune :'), findsNothing);
    expect(find.text('Aucune rune ne peut s\'ajouter à cette carte.'),
        findsOneWidget);
  });
}
