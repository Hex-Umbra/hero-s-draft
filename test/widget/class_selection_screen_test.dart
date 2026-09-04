import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/class_selection_screen.dart';
import 'package:roguelike_card_game/ui/screens/starter_deck_draft_screen.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

const _heroes = [
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
    passiveTrait: 'regenArmor',
  ),
  HeroData(
    id: 'berserker',
    nameEn: 'Berserker',
    nameFr: 'Le Berserker',
    descriptionEn: 'Damage Oriented',
    descriptionFr: 'Orienté Dégâts',
    iconPath: 'hero_berserker.png',
    maxHp: 80,
    maxMana: 3,
    baseDamage: 15,
    passiveTrait: 'berserkerArmor',
  ),
  HeroData(
    id: 'mage',
    nameEn: 'Mage',
    nameFr: 'Le Mage',
    descriptionEn: 'Alteration Oriented',
    descriptionFr: 'Orienté Altération',
    iconPath: 'hero_mage.png',
    maxHp: 60,
    maxMana: 3,
    baseDamage: 10,
    passiveTrait: 'spellArmor',
  ),
];

// Mock registry so ClassSelectionScreen (which calls `.requireValue` on
// gameDataLoaderProvider) can build without loading real JSON assets.
final _mockRegistry = GameDataRegistry(
  enemies: const [],
  heroes: _heroes,
  cards: const [],
  events: const [],
  passives: const [],
  relics: const [],
  forgeUpgrades: const [],
);

Future<ProviderContainer> _buildAndReady(
  WidgetTester tester, {
  Locale locale = const Locale('en', ''),
}) async {
  // GridView.builder only lays out visible children. The default test
  // surface (800x600) fits just one row of hero cards at the desktop
  // breakpoint, hiding the 3rd (Mage). Widen the surface so all seeded
  // heroes are simultaneously visible without needing to scroll.
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [gameDataLoaderProvider.overrideWith((ref) => _mockRegistry)],
  );
  addTearDown(container.dispose);

  // Ensure the FutureProvider has resolved before pumping, since the screen
  // calls `.requireValue` synchronously during build.
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
        locale: locale,
        home: const ClassSelectionScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));

  return container;
}

void main() {
  testWidgets('ClassSelectionScreen renders all seeded hero options', (
    WidgetTester tester,
  ) async {
    await _buildAndReady(tester);

    expect(find.text('Paladin'), findsOneWidget);
    expect(find.text('Berserker'), findsOneWidget);
    expect(find.text('Mage'), findsOneWidget);
    // One "Select" button per hero card.
    expect(find.text('Select'), findsNWidgets(_heroes.length));
  });

  testWidgets(
    'Tapping a hero card navigates to StarterDeckDraftScreen with that hero',
    (WidgetTester tester) async {
      await _buildAndReady(tester);

      expect(find.byType(ClassSelectionScreen), findsOneWidget);
      expect(find.byType(StarterDeckDraftScreen), findsNothing);

      // Tap the Berserker card's "Select" button (index 1 in the grid,
      // matching _heroes order). ClassSelectionScreen itself doesn't call
      // startNewRun (that happens later, inside StarterDeckDraftScreen's
      // "start adventure" flow) — what it owns is navigating onward with
      // the tapped hero, which we verify via the pushed screen's data.
      await tester.tap(find.text('Select').at(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ClassSelectionScreen), findsNothing);
      expect(find.byType(StarterDeckDraftScreen), findsOneWidget);

      final pushedScreen = tester.widget<StarterDeckDraftScreen>(
        find.byType(StarterDeckDraftScreen),
      );
      expect(pushedScreen.playerClass.id, 'berserker');
    },
  );

  testWidgets('ClassSelectionScreen shows French labels when locale is fr', (
    WidgetTester tester,
  ) async {
    await _buildAndReady(tester, locale: const Locale('fr', ''));

    // PageHeader upper-cases its title.
    expect(find.text('CHOISISSEZ VOTRE CLASSE'), findsOneWidget);
    expect(find.text('Le Paladin'), findsOneWidget);
    expect(find.text('Sélectionner'), findsNWidgets(_heroes.length));
  });
}
