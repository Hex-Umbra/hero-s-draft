import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/screens/draft_screen.dart';
import 'package:roguelike_card_game/ui/widgets/relic_carousel/draft_card_reel.dart';

/// Le décor du rouleau vient du registre, plus d'une liste écrite à la main
/// (spec P-41, §8.1 : « le carrousel lit le registre »).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;
  setUpAll(() async {
    registry = await loadGameDataRegistry(rootBundle);
  });

  testWidgets('le rouleau affiche le décor qu on lui donne, pas une liste interne', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DraftCardReel(
            title: 'Vitalité',
            description: '+15 PV Max',
            rarity: 'ÉPIQUE',
            index: 0,
            onTap: () {},
            spinPool: const [
              (title: 'Récompense factice', description: '+7 Factices'),
            ],
          ),
        ),
      ),
    );

    // Le rouleau démarre sur une entrée de son décor, jamais sur la
    // récompense réelle : celle-ci n'apparaît qu'à l'atterrissage.
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Récompense factice'), findsWidgets);
    // La liste écrite en dur d'avant ce chantier ne doit plus exister.
    expect(find.text('+4 Puissance'), findsNothing);
    expect(find.text('+2 Maîtrise'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('un rouleau déjà posé montre la récompense réelle', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DraftCardReel(
            title: 'Vitalité',
            description: '+15 PV Max',
            rarity: 'ÉPIQUE',
            index: 0,
            onTap: () {},
            initialLanded: true,
            spinPool: const [
              (title: 'Récompense factice', description: '+7 Factices'),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Vitalité'), findsOneWidget);
    expect(find.text('+15 PV Max'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'le Trèfle porte sa valeur réelle au palier rare-ou-mythique, jamais +0',
    (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [gameDataLoaderProvider.overrideWith((ref) => registry)],
      );
      addTearDown(container.dispose);
      // DraftScreen lit `.requireValue` pendant `initState` : le futur doit
      // être résolu avant le premier pump.
      await container.read(gameDataLoaderProvider.future);

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
            home: DraftScreen(onDraftComplete: () {}),
          ),
        ),
      );
      await tester.pump();

      // Le décor est le même sur les trois rouleaux de base : un seul
      // suffit pour lire le spinPool que l'écran a construit.
      final reel = tester.widget<DraftCardReel>(
        find.byType(DraftCardReel).first,
      );
      final clover = reel.spinPool.firstWhere(
        (entry) => entry.title == 'Trèfle à 4 feuilles',
      );

      // Le Trèfle ne déclare que le palier "mythic" dans sa table `values` :
      // amountFor(RewardRarity.rare) seul y rendrait 0, et le décor
      // afficherait "+0 Chance" au lieu de "+1 Chance". C'est la régression
      // que ce test empêche (constat de la tâche 3).
      expect(clover.description, '+1 Chance');
      expect(clover.description, isNot(contains('+0')));

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
