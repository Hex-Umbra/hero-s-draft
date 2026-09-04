import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/boss_card_draft_screen.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';
import 'package:roguelike_card_game/ui/widgets/game_button.dart';
import 'package:roguelike_card_game/game/controllers/reward_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
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

  final mockRegistry = GameDataRegistry(
    enemies: [],
    heroes: [],
    cards: mockCards,
    events: [],
    passives: [],
    relics: [],
    forgeUpgrades: [],
  );

  /// Builds a ProviderContainer with 5 rolled cards seeded directly into
  /// rewardProvider's state, mirroring what RewardController.handleVictory
  /// would produce for a BossRewardType.cards node.
  ProviderContainer buildSeededContainer(List<CardInstance> rolled) {
    final container = ProviderContainer(
      overrides: [gameDataLoaderProvider.overrideWith((ref) => mockRegistry)],
    );

    final rewardNotifier = container.read(rewardProvider.notifier);
    rewardNotifier.state = rewardNotifier.state.copyWith(rolledCards: rolled);

    return container;
  }

  Widget wrapWithApp(ProviderContainer container, Widget child) {
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
        locale: const Locale('en', ''),
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('BossCardDraftScreen renders the 5 rolled cards from a seeded rewardProvider state', (
    WidgetTester tester,
  ) async {
    final rolled = mockCards.map((c) => CardInstance(data: c)).toList();
    final container = buildSeededContainer(rolled);
    addTearDown(container.dispose);

    await tester.pumpWidget(wrapWithApp(container, const BossCardDraftScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(UiCard), findsNWidgets(5));
    expect(find.text('Selected cards: 0 / 2'), findsOneWidget);
  });

  testWidgets(
    'Selecting exactly 2 cards enables confirm; a 3rd selection is rejected and does not exceed 2',
    (WidgetTester tester) async {
      final rolled = mockCards.map((c) => CardInstance(data: c)).toList();
      final container = buildSeededContainer(rolled);
      addTearDown(container.dispose);

      await tester.pumpWidget(wrapWithApp(container, const BossCardDraftScreen()));
      await tester.pumpAndSettle();

      // Confirm button starts disabled (0 selected).
      GameButton confirmButton = tester.widget<GameButton>(find.byType(GameButton));
      expect(confirmButton.onPressed, isNull);

      final cardFinders = find.byType(UiCard);

      // Select first card.
      await tester.tap(cardFinders.at(0));
      await tester.pump();
      expect(find.text('Selected cards: 1 / 2'), findsOneWidget);
      confirmButton = tester.widget<GameButton>(find.byType(GameButton));
      expect(confirmButton.onPressed, isNull);

      // Select second card -> confirm becomes enabled.
      await tester.tap(cardFinders.at(1));
      await tester.pump();
      expect(find.text('Selected cards: 2 / 2'), findsOneWidget);
      confirmButton = tester.widget<GameButton>(find.byType(GameButton));
      expect(confirmButton.onPressed, isNotNull);

      // Attempt to select a 3rd card: should be rejected, stays at 2/2.
      await tester.tap(cardFinders.at(2));
      await tester.pump();
      expect(find.text('Selected cards: 2 / 2'), findsOneWidget);
      confirmButton = tester.widget<GameButton>(find.byType(GameButton));
      expect(confirmButton.onPressed, isNotNull);

      // The rejected 3rd tap raises a notification with a pending
      // auto-dismiss timer; let it expire before the widget tree is torn
      // down so the test binding doesn't flag a pending timer.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Confirming the selection adds clones of the 2 chosen cards to the master deck and closes the screen',
    (WidgetTester tester) async {
      final rolled = mockCards.map((c) => CardInstance(data: c)).toList();
      final container = buildSeededContainer(rolled);
      addTearDown(container.dispose);

      // Push BossCardDraftScreen on a real navigator stack so pop() is observable.
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
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BossCardDraftScreen()),
                  ),
                  child: const Text('Open Boss Draft'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Boss Draft'));
      await tester.pumpAndSettle();

      expect(container.read(deckProvider).masterDeck, isEmpty);

      final cardFinders = find.byType(UiCard);
      await tester.tap(cardFinders.at(0));
      await tester.pump();
      await tester.tap(cardFinders.at(3));
      await tester.pump();

      expect(find.text('Selected cards: 2 / 2'), findsOneWidget);

      await tester.tap(find.text('CONFIRM SELECTION'));
      await tester.pumpAndSettle();

      final masterDeck = container.read(deckProvider).masterDeck;
      expect(masterDeck.length, 2);
      expect(masterDeck.map((c) => c.data.id).toSet(), {'strike', 'extra_card_1'});

      // Screen popped back to the launcher.
      expect(find.byType(BossCardDraftScreen), findsNothing);
      expect(find.text('Open Boss Draft'), findsOneWidget);
    },
  );
}
