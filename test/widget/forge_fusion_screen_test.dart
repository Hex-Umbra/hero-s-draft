import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/forge_fusion_screen.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

void main() {
  const strikeCard = CardData(
    id: 'strike',
    nameEn: 'Strike',
    nameFr: 'Frappe',
    descriptionEn: 'Deal 6 damage',
    descriptionFr: 'Inflige 6 dégâts',
    cost: 1,
    type: CardType.attack,
    category: CardCategory.global,
    rarity: CardRarity.common,
    target: CardTarget.singleEnemy,
    effects: [],
  );

  const defendCard = CardData(
    id: 'defend',
    nameEn: 'Defend',
    nameFr: 'Défense',
    descriptionEn: 'Gain 5 armor',
    descriptionFr: 'Gagne 5 armure',
    cost: 1,
    type: CardType.skill,
    category: CardCategory.global,
    rarity: CardRarity.common,
    target: CardTarget.self,
    effects: [],
  );

  const sharpUpgrade = ForgeUpgradeData(
    id: 'sharp',
    nameEn: 'Sharp',
    nameFr: 'Tranchant',
    descriptionEn: '+{val} Damage on the card',
    descriptionFr: '+{val} Dégâts sur la carte',
    icon: 'hardware_rounded',
    color: 'redAccent',
    pools: ['common', 'uncommon', 'rare'],
    eligibleCardTypes: ['attack'],
    valueMultiplier: 2,
    weight: 100,
    emoji: '⚔️',
  );

  // Constructing GameDataRegistry sets its static `instance`, which is what
  // ForgeUpgradeData.getById() reads from (see lib/models/data/forge_upgrade_data.dart).
  // ignore: unused_local_variable
  final mockRegistry = GameDataRegistry(
    enemies: const [],
    heroes: const [],
    skills: const [],
    cards: const [strikeCard, defendCard],
    events: const [],
    passives: const [],
    relics: const [],
    forgeUpgrades: const [sharpUpgrade],
  );

  Future<ProviderContainer> pumpForgeFusionScreen(
    WidgetTester tester, {
    required List<CardInstance> masterDeck,
    int initialGold = 200,
  }) async {
    // Wide viewport so the desktop (side-by-side) layout is used, keeping the
    // eligible-cards list and the fusion-options panel both on screen at once.
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(inventoryProvider.notifier).reset(initialGold: initialGold);
    final deckNotifier = container.read(deckProvider.notifier);
    for (final card in masterDeck) {
      deckNotifier.addCardToMasterDeck(card);
    }

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
          locale: const Locale('en', ''),
          home: const Scaffold(body: ForgeFusionScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
    'shows the empty-state fallback when no card has duplicate upgrades',
    (WidgetTester tester) async {
      final noDupCard = CardInstance(data: strikeCard, forgeUpgrades: const ['sharp:1']);
      final noUpgradeCard = CardInstance(data: defendCard);

      await pumpForgeFusionScreen(tester, masterDeck: [noDupCard, noUpgradeCard]);

      expect(
        find.text('No cards in your deck have identical runes to merge.'),
        findsOneWidget,
      );
      expect(find.text('ELIGIBLE CARDS'), findsNothing);
      expect(find.text('Strike'), findsNothing);
      expect(find.text('Defend'), findsNothing);
    },
  );

  testWidgets(
    'lists a card with two identical upgrades as fusable',
    (WidgetTester tester) async {
      final fusableCard = CardInstance(
        data: strikeCard,
        forgeUpgrades: const ['sharp:1', 'sharp:1'],
      );
      final plainCard = CardInstance(data: defendCard);

      await pumpForgeFusionScreen(tester, masterDeck: [fusableCard, plainCard]);

      expect(find.text('ELIGIBLE CARDS'), findsOneWidget);
      expect(find.text('Strike'), findsOneWidget);
      expect(find.text('1 merge(s) available'), findsOneWidget);
      // The non-eligible card must not appear in the eligible list.
      expect(find.text('Defend'), findsNothing);
    },
  );

  testWidgets(
    'performing a fusion deducts gold and merges the upgrades into one higher tier',
    (WidgetTester tester) async {
      final fusableCard = CardInstance(
        data: strikeCard,
        forgeUpgrades: const ['sharp:1', 'sharp:1'],
      );

      final container = await pumpForgeFusionScreen(
        tester,
        masterDeck: [fusableCard],
        initialGold: 200,
      );

      // Select the eligible card to reveal its fusion options.
      await tester.tap(find.text('Strike'));
      await tester.pumpAndSettle();

      // Cost is 80 * (2 upgrades - 1) = 80, shown on the fuse button
      // (note: the button label always renders "Or", the French word for
      // gold, regardless of locale — this is how the widget is implemented).
      final fuseButton = find.text('80 Or');
      expect(fuseButton, findsOneWidget);

      await tester.tap(fuseButton);
      await tester.pumpAndSettle();

      // Gold was deducted.
      expect(container.read(inventoryProvider).gold, 120);

      // The two sharp:1 upgrades merged into a single sharp:2.
      final updatedCard = container
          .read(deckProvider)
          .masterDeck
          .firstWhere((c) => c.uniqueId == fusableCard.uniqueId);
      expect(updatedCard.forgeUpgrades, ['sharp:2']);

      // The card is no longer eligible, so the empty-state message returns.
      expect(
        find.text('No cards in your deck have identical runes to merge.'),
        findsOneWidget,
      );

      // Pump to let any notification timers expire.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
