import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/widgets/map/dialogs/probabilities_dialog.dart';

/// La fiche des probabilités de la carte du monde (spec P-43 E3, §5.1, §8 ;
/// C4.1, C4.2, C4.7). En partie 1, elle ne lit que la run (`runProvider`) :
/// le conteneur ne porte rien d'autre.
///
/// Ouvre la fiche par `ProbabilitiesDialog.show`, sur un écran assez haut
/// pour que la zone défilante de la fiche soit à sa taille maximale.
Future<void> _openDialog(
  WidgetTester tester,
  ProviderContainer container,
  Locale locale,
) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', ''), Locale('fr', '')],
        locale: locale,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ProbabilitiesDialog.show(context),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la section du draft standard a quitte la fiche, en francais',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _openDialog(tester, container, const Locale('fr', ''));

    // `_buildProbabilitySectionCard` écrit les titres en capitales.
    expect(find.text('DRAFT STANDARD DE RÉCOMPENSES'), findsNothing);
    expect(
      find.text(
        "Chances d'obtenir chaque rareté de carte/stat en fin de combat "
        'standard',
      ),
      findsNothing,
    );
    expect(find.text('RÉCOMPENSE DE NIVEAU'), findsOneWidget);
    expect(find.text('BUTIN DE RELIQUES'), findsOneWidget);
  });

  testWidgets('la section du draft standard a quitte la fiche, en anglais',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _openDialog(tester, container, const Locale('en', ''));

    expect(find.text('STANDARD REWARD DRAFT'), findsNothing);
    expect(
      find.text(
        'Chances of getting each card/stat rarity at the end of standard '
        'combat',
      ),
      findsNothing,
    );
    expect(find.text('LEVEL REWARD'), findsOneWidget);
    expect(find.text('RELIC LOOT'), findsOneWidget);
  });

  testWidgets('la recompense de niveau affiche les chances du tirage',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final run = container.read(runProvider.notifier);
    run.updateState(
      run.currentState.copyWith(
        heroStats: run.currentState.heroStats.copyWith(luck: 5),
      ),
    );

    await _openDialog(tester, container, const Locale('fr', ''));

    // La commune à Chance 0, puis à Chance 5, selon `slotRarityChances` ;
    // aucune autre ligne de la fiche n'écrit ces deux textes, et l'ancienne
    // table afficherait « 60.0% » et « 15.0% ».
    expect(find.text('52.0%'), findsOneWidget);
    expect(find.text('7.0%'), findsOneWidget);
  });
}
