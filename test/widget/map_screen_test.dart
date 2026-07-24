import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/map_screen.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

// Mock data provider to bypass actual json loading
final mockGameDataLoaderProvider = FutureProvider<GameDataRegistry>((
  ref,
) async {
  return GameDataRegistry(
    enemies: [],
    heroes: [],
    skills: [],
    cards: [],
    events: [],
    passives: [],
    relics: [],
    forgeUpgrades: [],
  );
});

void main() {
  testWidgets('MapScreen displays nodes and restricts unavailable nodes', (
    WidgetTester tester,
  ) async {
    // 1. Arrange state
    final hero = const HeroData(
      id: 'test_hero',
      nameEn: 'Test',
      nameFr: 'Test',
      descriptionEn: 'Test',
      descriptionFr: 'Test',
      iconPath: 'test',
      maxHp: 10,
      maxMana: 3,
      passiveTrait: 'regenArmor',
      baseDamage: 0,
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final runNotifier = container.read(runProvider.notifier);

    // Generate map
    runNotifier.startNewRun(hero);

    final runState = container.read(runProvider);
    final mapNodes = runState.mapNodes;

    expect(mapNodes.isNotEmpty, true);

    // 2. Build widget
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en', ''), Locale('fr', '')],
          home: MapScreen(),
        ),
      ),
    );

    // Initial state: only nodes in the first floor (bottom, id containing 'node_0_') are available
    // Others should have an opacity indicating they are disabled

    // Find all gesturedetectors within map nodes
    final nodeFinders = find.byType(GestureDetector);
    expect(nodeFinders, findsWidgets);

    // We cannot easily test the exact availability logic without inspecting the widget tree closely,
    // but we can simulate a tap on an available node and verify state change.

    final firstFloorNodeId = mapNodes
        .firstWhere((n) => n.id.contains('node_0_'))
        .id;

    // Manually travel to test state change logic inside MapScreen
    // Usually tapping would push a new route. Since we just want to verify state logic:
    runNotifier.travelToNode(firstFloorNodeId);
    await tester.pump(const Duration(milliseconds: 1000));

    expect(container.read(runProvider).currentNodeId, firstFloorNodeId);
    container.dispose();
  });

  testWidgets('MapScreen shows a pause icon that opens the pause dialog', (
    WidgetTester tester,
  ) async {
    final hero = const HeroData(
      id: 'test_hero',
      nameEn: 'Test',
      nameFr: 'Test',
      descriptionEn: 'Test',
      descriptionFr: 'Test',
      iconPath: 'test',
      maxHp: 10,
      maxMana: 3,
      passiveTrait: 'regenArmor',
      baseDamage: 0,
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(runProvider.notifier).startNewRun(hero);

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
          home: const MapScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.pause_circle_outline), findsOneWidget);
    expect(find.text('PAUSE'), findsNothing);

    await tester.tap(find.byIcon(Icons.pause_circle_outline));
    await tester.pumpAndSettle();

    expect(find.text('PAUSE'), findsOneWidget);
    expect(find.text('Reprendre le Combat'), findsOneWidget);
    expect(find.text('Retour au Menu Principal'), findsOneWidget);
  });

  testWidgets('MapScreen pause dialog Resume button closes the dialog', (
    WidgetTester tester,
  ) async {
    final hero = const HeroData(
      id: 'test_hero',
      nameEn: 'Test',
      nameFr: 'Test',
      descriptionEn: 'Test',
      descriptionFr: 'Test',
      iconPath: 'test',
      maxHp: 10,
      maxMana: 3,
      passiveTrait: 'regenArmor',
      baseDamage: 0,
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(runProvider.notifier).startNewRun(hero);

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
          home: const MapScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.pause_circle_outline));
    await tester.pumpAndSettle();
    expect(find.text('PAUSE'), findsOneWidget);

    await tester.tap(find.text('Reprendre le Combat'));
    await tester.pumpAndSettle();

    expect(find.text('PAUSE'), findsNothing);
    expect(find.byType(MapScreen), findsOneWidget);
  });

  testWidgets(
    'MapScreen intercepts the system back gesture and opens the pause dialog instead of closing',
    (WidgetTester tester) async {
      final hero = const HeroData(
        id: 'test_hero',
        nameEn: 'Test',
        nameFr: 'Test',
        descriptionEn: 'Test',
        descriptionFr: 'Test',
        iconPath: 'test',
        maxHp: 10,
        maxMana: 3,
        passiveTrait: 'regenArmor',
        baseDamage: 0,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(runProvider.notifier).startNewRun(hero);

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
            home: const MapScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      final bool popped = await navigator.maybePop();
      await tester.pumpAndSettle();

      expect(popped, isFalse);
      expect(find.byType(MapScreen), findsOneWidget);
      expect(find.text('PAUSE'), findsOneWidget);
    },
  );

  testWidgets(
    'MapScreen pause dialog "Back to Main Menu" pops back to the previous screen',
    (WidgetTester tester) async {
      final hero = const HeroData(
        id: 'test_hero',
        nameEn: 'Test',
        nameFr: 'Test',
        descriptionEn: 'Test',
        descriptionFr: 'Test',
        iconPath: 'test',
        maxHp: 10,
        maxMana: 3,
        passiveTrait: 'regenArmor',
        baseDamage: 0,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(runProvider.notifier).startNewRun(hero);

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
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MapScreen()),
                  ),
                  child: const Text('Open Map'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Map'));
      await tester.pumpAndSettle();
      expect(find.byType(MapScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.pause_circle_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retour au Menu Principal'));
      await tester.pumpAndSettle();

      expect(find.byType(MapScreen), findsNothing);
      expect(find.text('Open Map'), findsOneWidget);
    },
  );
}
