import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/shop_screen.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

void main() {
  final mockCards = [
    const CardData(
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
    ),
    const CardData(
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
    ),
    const CardData(
      id: 'power_card',
      nameEn: 'Power Card',
      nameFr: 'Carte Pouvoir',
      descriptionEn: 'Unleash power',
      descriptionFr: 'Libère le pouvoir',
      cost: 2,
      type: CardType.power,
      category: CardCategory.global,
      rarity: CardRarity.rare,
      target: CardTarget.none,
      effects: [],
    ),
    const CardData(
      id: 'extra_card_1',
      nameEn: 'Extra Card 1',
      nameFr: 'Carte Extra 1',
      descriptionEn: 'An extra card',
      descriptionFr: 'Une carte extra',
      cost: 1,
      type: CardType.attack,
      category: CardCategory.global,
      rarity: CardRarity.common,
      target: CardTarget.singleEnemy,
      effects: [],
    ),
    const CardData(
      id: 'extra_card_2',
      nameEn: 'Extra Card 2',
      nameFr: 'Carte Extra 2',
      descriptionEn: 'Another extra card',
      descriptionFr: 'Une autre carte extra',
      cost: 1,
      type: CardType.skill,
      category: CardCategory.global,
      rarity: CardRarity.common,
      target: CardTarget.self,
      effects: [],
    ),
  ];

  final mockHero = const HeroData(
    id: 'paladin',
    nameEn: 'Paladin',
    nameFr: 'Paladin',
    descriptionEn: 'A holy knight',
    descriptionFr: 'Un saint chevalier',
    iconPath: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
    baseDamage: 5,
    luck: 0,
    armorMastery: 0,
    passiveTrait: 'regenArmor',
  );

  final mockRegistry = GameDataRegistry(
    enemies: [],
    heroes: [mockHero],
    skills: [],
    cards: mockCards,
    events: [],
    passives: [],
    relics: [],
  );

  testWidgets(
    'ShopScreen shows correct cards and handles Reroll and Expand services',
    (WidgetTester tester) async {
      // Set a larger viewport size so sidebar buttons are on-screen
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Setup Riverpod Container
      final container = ProviderContainer(
        overrides: [gameDataLoaderProvider.overrideWith((ref) => mockRegistry)],
      );
      addTearDown(container.dispose);

      // Initialize run with enough gold (e.g. 200)
      final runNotifier = container.read(runProvider.notifier);
      runNotifier.startNewRun(mockHero);

      // Give player plenty of gold for testing services (80 + 15 = 95 gold required minimum)
      container.read(inventoryProvider.notifier).reset(initialGold: 200);

      // 2. Build the ShopScreen widget
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
            home: const Scaffold(body: ShopScreen()),
          ),
        ),
      );

      // Wait for frames
      await tester.pumpAndSettle();

      // 3. Verify the screen displays 3 cards originally (default capacity)
      expect(find.byType(UiCard), findsNWidgets(3));

      // 4. Verify shop services buttons exist
      expect(find.text('Étal étendu'), findsOneWidget);
      expect(find.text('Renouveler'), findsOneWidget);

      // 5. Test Shop Expansion ('Étal étendu' costing 100 gold)
      final initialGold = container.read(inventoryProvider).gold;
      expect(initialGold, 200);
      expect(container.read(inventoryProvider).bonusShopCards, 0);

      // Find the 'Étal étendu' button and tap it
      final expandButton = find.text('Étal étendu');
      await tester.tap(expandButton);
      await tester.pumpAndSettle();

      // Verify gold decreases by 100 and bonusShopCards increases to 1
      expect(container.read(inventoryProvider).gold, 100);
      expect(container.read(inventoryProvider).bonusShopCards, 1);

      // Now, there should be 4 cards displayed on the screen!
      expect(find.byType(UiCard), findsNWidgets(4));

      // 6. Test Card Reroll ('Renouveler' costing 15 gold)
      // Find the 'Renouveler' button and tap it
      final rerollButton = find.text('Renouveler');
      await tester.tap(rerollButton);
      await tester.pumpAndSettle();

      // Verify gold decreases by 15
      expect(container.read(inventoryProvider).gold, 85);

      // There should still be 4 cards on the shelf
      expect(find.byType(UiCard), findsNWidgets(4));

      container.dispose();
    },
  );
}
