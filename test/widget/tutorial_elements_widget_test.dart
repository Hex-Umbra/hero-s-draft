import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/proportional_status.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/tutorial/tutorial_engine.dart';
import 'package:roguelike_card_game/tutorial/widgets/tutorial_elements_widget.dart';

import '../tutorial/tutorial_test_registry.dart';

/// La galerie et le tableau des statuts de l'etape « Les Effets Elementaires »
/// lisent le bareme de P-1 par les cles `status…Hint` (spec P-42/P-44 lot 1,
/// §4.4, §6.2) : aucun pourcentage en dur.
Future<void> _pump(WidgetTester tester, Locale locale) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final engine = TutorialEngine(data: await buildTutorialTestRegistry());
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
      home: Scaffold(body: TutorialElementsWidget(engine: engine)),
    ),
  );
  await tester.pump();
}

void main() {
  const vulnerable = ProportionalStatus.vulnerable;
  const weakness = ProportionalStatus.weakness;
  const freeze = ProportionalStatus.freeze;

  Future<void> check(
    WidgetTester tester,
    Locale locale,
    List<String> gone,
  ) async {
    await _pump(tester, locale);
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;

    expect(
      find.text(l10n.statusFreezeHint(freeze.percentPerPoint, freeze.maxPercent)),
      findsOneWidget,
    );
    expect(
      find.text(l10n.statusVulnerableHint(
          vulnerable.percentPerPoint, vulnerable.maxPercent)),
      findsOneWidget,
    );
    expect(
      find.text(l10n.statusWeaknessHint(
          weakness.percentPerPoint, weakness.maxPercent)),
      findsOneWidget,
    );
    for (final text in gone) {
      expect(find.text(text), findsNothing);
    }
    // La simulation de la galerie reste juste : deux points de Gel.
    expect(find.text('10 -> 5 ⚔️'), findsOneWidget);

    // Coupe le `Timer.periodic` du widget.
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('la galerie et le tableau lisent le bareme, en francais',
      (tester) async {
    await check(tester, const Locale('fr', ''), [
      'Réduit les dégâts de la prochaine attaque ennemie de 50%.',
      '+50 % de dégâts subis',
      '-25 % de dégâts infligés',
    ]);
  });

  testWidgets('la galerie et le tableau lisent le bareme, en anglais',
      (tester) async {
    await check(tester, const Locale('en', ''), [
      'Reduces the enemy\'s next attack damage by 50%.',
      '+50% damage taken',
      '-25% damage dealt',
    ]);
  });
}
