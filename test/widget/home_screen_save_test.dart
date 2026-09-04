import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/home_screen.dart';
import 'package:roguelike_card_game/ui/screens/class_selection_screen.dart';
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
      iconPath: 'hero_paladin.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
      passiveTrait: 'regen_armor',
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
    testWidgets('CONTINUER is hidden when no save exists', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(wrapHome());
      await tester.pumpAndSettle();

      expect(find.text('Continuer'), findsNothing);
    });

    testWidgets('CONTINUER appears when a save exists', (tester) async {
      SharedPreferences.setMockInitialValues({
        'run_save_v1': '{"schemaVersion":1,"run":{},"deck":{},"inventory":{},"skills":{}}',
      });
      // Seed a syntactically valid but minimal save purely to make hasSave() true;
      // the "Continuer" tap flow itself is exercised in SaveService's own unit tests.

      await tester.pumpWidget(wrapHome());
      await tester.pumpAndSettle();

      expect(find.text('Continuer'), findsOneWidget);
    });

    testWidgets('Nouvelle Partie shows a confirmation dialog when a save exists', (tester) async {
      SharedPreferences.setMockInitialValues({
        'run_save_v1': '{"schemaVersion":1,"run":{},"deck":{},"inventory":{},"skills":{}}',
      });

      await tester.pumpWidget(wrapHome());
      await tester.pumpAndSettle();

      await tester.tap(find.text('JOUER'));
      await tester.pumpAndSettle();

      expect(find.text('Nouvelle Partie'), findsOneWidget);

      // Cancel so the test does not need to also stub ClassSelectionScreen navigation.
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(await SaveService.hasSave(), isTrue);
    });

    testWidgets(
      'CONTINUER reflects a save created after returning from JOUER, without needing app restart',
      (tester) async {
        // Regression test: the pause menu ("Quitter") and the death overlay
        // both return to HomeScreen via Navigator.popUntil((r) => r.isFirst)
        // rather than by recreating the widget. HomeScreen must refresh its
        // hasSave() check on that return, not just on first mount.
        SharedPreferences.setMockInitialValues({});

        await pumpHomeWithGameData(tester);
        expect(find.text('Continuer'), findsNothing);

        await tester.tap(find.text('JOUER'));
        // ClassSelectionScreen runs a repeating AnimationController, so
        // pumpAndSettle() would never terminate while it's mounted — pump
        // explicitly instead (same approach as class_selection_screen_test.dart).
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(ClassSelectionScreen), findsOneWidget);

        // Simulate an autosave being written while away from Home (e.g.
        // after resolving a map node).
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'run_save_v1',
          '{"schemaVersion":1,"run":{},"deck":{},"inventory":{},"skills":{}}',
        );

        // Return to Home the same way the pause menu / death overlay do.
        final navigator = tester.state<NavigatorState>(
          find.byType(Navigator).first,
        );
        navigator.popUntil((route) => route.isFirst);
        await tester.pumpAndSettle();

        expect(find.text('Continuer'), findsOneWidget);
      },
    );
  });
}
