import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/home_screen.dart';
import 'package:roguelike_card_game/services/save_service.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

Widget wrapHome() {
  final container = ProviderContainer();
  return UncontrolledProviderScope(
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
      home: const HomeScreen(),
    ),
  );
}

// Minimal registry so ClassSelectionScreen (which calls `.requireValue` on
// gameDataLoaderProvider) can build without loading real JSON assets.
final _mockRegistry = GameDataRegistry(
  enemies: const [],
  heroes: const [
    HeroData(
      id: 'paladin',
      nameEn: 'Paladin',
      nameFr: 'Le Paladin',
      descriptionEn: 'Survival Oriented',
      descriptionFr: 'Orienté Survie',
      classCard: 'hero_paladin.png',
      maxHp: 100,
      maxMana: 3,
    ),
  ],
  cards: const [],
  events: const [],
  passives: const [],
  relics: const [],
  forgeUpgrades: const [],
);

Future<void> pumpHomeWithGameData(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [gameDataLoaderProvider.overrideWith((ref) => _mockRegistry)],
  );
  addTearDown(container.dispose);
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
        home: const HomeScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('HomeScreen save/continue', () {
    testWidgets('Continuer explains a save written by a newer build and keeps it', (tester) async {
      SharedPreferences.setMockInitialValues({
        'run_save': '{"schemaVersion":999,"run":{},"deck":{},"inventory":{}}',
      });

      await tester.pumpWidget(wrapHome());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(find.text("Partie d'une version plus récente"), findsOneWidget);

      await tester.ensureVisible(find.text('OK'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text("Partie d'une version plus récente"), findsNothing);
      expect(find.text('Continuer'), findsOneWidget);
      expect(await SaveService.hasSave(), isTrue);
    });

  });
}
