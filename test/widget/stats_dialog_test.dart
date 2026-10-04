import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/widgets/map/dialogs/stats_dialog.dart';

/// La fiche des stats de la carte du monde dit ce que la Maîtrise change
/// vraiment au passif actif (spec P-43 E3, §4.11, §8 ; C2.6).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;
  setUpAll(() async {
    registry = await loadGameDataRegistry(rootBundle);
  });

  /// Une run de mage sous *Flux de Mana*, à [mastery] points de Maîtrise,
  /// fiche ouverte par `StatsDialog.show`.
  Future<void> openOnFlux(WidgetTester tester, int mastery) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [gameDataLoaderProvider.overrideWith((ref) => registry)],
    );
    addTearDown(container.dispose);
    await container.read(gameDataLoaderProvider.future);
    final run = container.read(runProvider.notifier);
    run.startNewRun(
      registry.heroes.singleWhere((h) => h.id == 'mage'),
      registry.passives.singleWhere((p) => p.id == 'mana_flux'),
    );
    final state = container.read(runProvider);
    run.updateState(state.copyWith(
      heroStats: state.heroStats.copyWith(mastery: mastery),
    ));

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
          locale: const Locale('fr', ''),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => StatsDialog.show(context),
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

  testWidgets('Flux a Maitrise 9 dit -1 Competence a reunir, et non -9',
      (tester) async {
    await openOnFlux(tester, 9);

    expect(find.text('Maîtrise : -1 Compétence à réunir'), findsOneWidget);
    expect(find.textContaining('-9'), findsNothing);
  });

  testWidgets('a Maitrise 0, aucune ligne de Maitrise', (tester) async {
    await openOnFlux(tester, 0);

    expect(find.textContaining('à réunir'), findsNothing);
  });
}
