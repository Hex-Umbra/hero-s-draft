import 'dart:math';

import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/relic_exchange_screen.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/map_node.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

// This mirrors the exact seeding/rarity-roll algorithm implemented in
// RelicExchangeScreen (see lib/ui/screens/relic_exchange_screen.dart), so the
// test can know ahead of time which rarity will be offered for a given
// (node id, act) pair without hardcoding a value that could silently drift
// from production if the algorithm's constants ever change.
RelicRarity _computeOfferedRarity(String nodeId, int act) {
  final seed = (nodeId.hashCode ^ act).abs();
  final random = Random(seed);
  final double roll = random.nextDouble();
  if (roll < 0.40) return RelicRarity.uncommon;
  if (roll < 0.75) return RelicRarity.rare;
  if (roll < 0.95) return RelicRarity.epic;
  return RelicRarity.legendary;
}

RelicRarity _requiredSacrificeRarityFor(RelicRarity offered) {
  switch (offered) {
    case RelicRarity.uncommon:
      return RelicRarity.common;
    case RelicRarity.rare:
      return RelicRarity.uncommon;
    case RelicRarity.epic:
      return RelicRarity.rare;
    case RelicRarity.legendary:
      return RelicRarity.epic;
    default:
      return RelicRarity.common;
  }
}

void main() {
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

  final node = MapNode(
    id: 'relic_shrine_test_node',
    floor: 3,
    type: MapNodeType.relicExchange,
    connections: const [],
    position: Vector2.zero(),
  );

  // Offered relics: exactly one per non-common rarity so the offered-relic
  // pick inside the screen (which indexes into the filtered list with a
  // seeded Random) is deterministic regardless of the exact roll.
  const offeredUncommon = RelicData(
    id: 'offered_uncommon',
    nameEn: 'Offered Uncommon',
    nameFr: 'Offerte Peu Commune',
    trigger: RelicTrigger.startOfCombat,
    effectType: 'gain_armor',
    value: 1,
    rarity: RelicRarity.uncommon,
    emoji: '🟢',
  );
  const offeredRare = RelicData(
    id: 'offered_rare',
    nameEn: 'Offered Rare',
    nameFr: 'Offerte Rare',
    trigger: RelicTrigger.startOfCombat,
    effectType: 'gain_armor',
    value: 1,
    rarity: RelicRarity.rare,
    emoji: '🔵',
  );
  const offeredEpic = RelicData(
    id: 'offered_epic',
    nameEn: 'Offered Epic',
    nameFr: 'Offerte Épique',
    trigger: RelicTrigger.startOfCombat,
    effectType: 'gain_armor',
    value: 1,
    rarity: RelicRarity.epic,
    emoji: '🟣',
  );
  const offeredLegendary = RelicData(
    id: 'offered_legendary',
    nameEn: 'Offered Legendary',
    nameFr: 'Offerte Légendaire',
    trigger: RelicTrigger.startOfCombat,
    effectType: 'gain_armor',
    value: 1,
    rarity: RelicRarity.legendary,
    emoji: '🟡',
  );

  final mockRegistry = GameDataRegistry(
    enemies: const [],
    heroes: [hero],
    cards: const [],
    events: const [],
    passives: const [],
    relics: const [offeredUncommon, offeredRare, offeredEpic, offeredLegendary],
    forgeUpgrades: const [],
  );

  // Owned relics: 3 unique relics per rarity tier that can ever be a
  // "required sacrifice" tier (common, uncommon, rare, epic), so the test is
  // correct no matter which tier the seeded roll for `node`/act=1 lands on.
  RelicData ownedRelic(String id, String label, RelicRarity rarity) {
    return RelicData(
      id: id,
      nameEn: label,
      nameFr: label,
      trigger: RelicTrigger.startOfCombat,
      effectType: 'gain_armor',
      value: 1,
      rarity: rarity,
      emoji: '🔶',
    );
  }

  final Map<RelicRarity, List<RelicData>> ownedByRarity = {
    RelicRarity.common: [
      ownedRelic('owned_common_1', 'Owned Common One', RelicRarity.common),
      ownedRelic('owned_common_2', 'Owned Common Two', RelicRarity.common),
      ownedRelic('owned_common_3', 'Owned Common Three', RelicRarity.common),
    ],
    RelicRarity.uncommon: [
      ownedRelic('owned_uncommon_1', 'Owned Uncommon One', RelicRarity.uncommon),
      ownedRelic('owned_uncommon_2', 'Owned Uncommon Two', RelicRarity.uncommon),
      ownedRelic('owned_uncommon_3', 'Owned Uncommon Three', RelicRarity.uncommon),
    ],
    RelicRarity.rare: [
      ownedRelic('owned_rare_1', 'Owned Rare One', RelicRarity.rare),
      ownedRelic('owned_rare_2', 'Owned Rare Two', RelicRarity.rare),
      ownedRelic('owned_rare_3', 'Owned Rare Three', RelicRarity.rare),
    ],
    RelicRarity.epic: [
      ownedRelic('owned_epic_1', 'Owned Epic One', RelicRarity.epic),
      ownedRelic('owned_epic_2', 'Owned Epic Two', RelicRarity.epic),
      ownedRelic('owned_epic_3', 'Owned Epic Three', RelicRarity.epic),
    ],
    RelicRarity.legendary: <RelicData>[],
  };

  final List<RelicData> allOwnedRelics =
      ownedByRarity.values.expand((r) => r).toList();

  final offeredRarity = _computeOfferedRarity(node.id, 1);
  final requiredRarity = _requiredSacrificeRarityFor(offeredRarity);
  final expectedOffered = switch (offeredRarity) {
    RelicRarity.uncommon => offeredUncommon,
    RelicRarity.rare => offeredRare,
    RelicRarity.epic => offeredEpic,
    RelicRarity.legendary => offeredLegendary,
    RelicRarity.common => offeredUncommon,
  };
  final eligibleOwned = ownedByRarity[requiredRarity]!;

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [gameDataLoaderProvider.overrideWith((ref) => mockRegistry)],
    );
    container.read(runProvider.notifier).startNewRun(hero);
    container.read(inventoryProvider.notifier).reset(initialRelics: allOwnedRelics);
    return container;
  }

  Widget wrapDirect(ProviderContainer container) {
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
        home: RelicExchangeScreen(node: node),
      ),
    );
  }

  Widget wrapWithNavigator(ProviderContainer container) {
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
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => RelicExchangeScreen(node: node)),
              ),
              child: const Text('Open Exchange'),
            ),
          ),
        ),
      ),
    );
  }

  void useLargeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<void> tapRelicCard(WidgetTester tester, String name) async {
    final target = find.ancestor(
      of: find.text(name),
      matching: find.byType(GestureDetector),
    );
    expect(target, findsOneWidget, reason: 'Expected a tappable card for "$name"');
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.tap(target);
    await tester.pump();
  }

  testWidgets(
    'renders the offered relic and the owned relics eligible for sacrifice',
    (WidgetTester tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(wrapDirect(container));
      await tester.pumpAndSettle();

      // Offered relic name is shown.
      expect(find.text(expectedOffered.getName('fr')), findsOneWidget);

      // All 3 eligible owned relics (matching the required sacrifice
      // rarity) are listed.
      for (final relic in eligibleOwned) {
        expect(find.text(relic.getName('fr')), findsOneWidget);
      }

      // Selection counter starts at 0/3.
      expect(find.textContaining('0/3'), findsOneWidget);
    },
  );

  testWidgets(
    'exchange button stays disabled until exactly 3 relics are selected',
    (WidgetTester tester) async {
      useLargeViewport(tester);
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(wrapDirect(container));
      await tester.pumpAndSettle();

      ElevatedButton exchangeButton() => tester.widget<ElevatedButton>(
            find.ancestor(
              of: find.text('ÉCHANGER'),
              matching: find.byType(ElevatedButton),
            ),
          );

      // Nothing selected yet.
      expect(exchangeButton().onPressed, isNull);

      // Select only 1 of the 3 required relics.
      await tapRelicCard(tester, eligibleOwned[0].getName('fr'));
      expect(exchangeButton().onPressed, isNull);

      // Select a 2nd relic: still not enough.
      await tapRelicCard(tester, eligibleOwned[1].getName('fr'));
      expect(exchangeButton().onPressed, isNull);

      // No exchange should have happened - inventory untouched.
      expect(container.read(inventoryProvider).relics.length, allOwnedRelics.length);
    },
  );

  testWidgets(
    'selecting exactly 3 eligible relics and confirming performs the exchange',
    (WidgetTester tester) async {
      useLargeViewport(tester);
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(wrapWithNavigator(container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Exchange'));
      await tester.pumpAndSettle();
      expect(find.byType(RelicExchangeScreen), findsOneWidget);

      for (final relic in eligibleOwned) {
        await tapRelicCard(tester, relic.getName('fr'));
      }

      final exchangeFinder = find.ancestor(
        of: find.text('ÉCHANGER'),
        matching: find.byType(ElevatedButton),
      );
      expect(tester.widget<ElevatedButton>(exchangeFinder).onPressed, isNotNull);

      await tester.ensureVisible(exchangeFinder);
      await tester.pump();
      await tester.tap(exchangeFinder);
      await tester.pumpAndSettle();

      // Screen popped back to the launcher.
      expect(find.byType(RelicExchangeScreen), findsNothing);
      expect(find.text('Open Exchange'), findsOneWidget);

      final finalRelics = container.read(inventoryProvider).relics;
      // The 3 sacrificed relics are gone, and the offered relic was added.
      for (final relic in eligibleOwned) {
        expect(finalRelics.any((r) => r.id == relic.id), isFalse);
      }
      expect(finalRelics.any((r) => r.id == expectedOffered.id), isTrue);
      expect(finalRelics.length, allOwnedRelics.length - 3 + 1);
    },
  );

  testWidgets(
    'the player can leave without selecting relics and no exchange happens',
    (WidgetTester tester) async {
      useLargeViewport(tester);
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(wrapWithNavigator(container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Exchange'));
      await tester.pumpAndSettle();
      expect(find.byType(RelicExchangeScreen), findsOneWidget);

      final leaveFinder = find.text('PARTIR');
      await tester.ensureVisible(leaveFinder);
      await tester.pump();
      await tester.tap(leaveFinder);
      await tester.pumpAndSettle();

      expect(find.byType(RelicExchangeScreen), findsNothing);
      expect(find.text('Open Exchange'), findsOneWidget);

      // Inventory is untouched: no relic sacrificed or gained.
      final finalRelics = container.read(inventoryProvider).relics;
      expect(finalRelics.length, allOwnedRelics.length);
      expect(finalRelics.any((r) => r.id == expectedOffered.id), isFalse);
    },
  );
}
