import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/rest_screen.dart';
import 'package:roguelike_card_game/ui/widgets/notification_overlay.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/models/card_instance.dart';

void main() {
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
    passiveTrait: 'regen_armor',
  );

  const mockCard = CardData(
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

  final mockRegistry = GameDataRegistry(
    enemies: const [],
    heroes: [mockHero],
    cards: const [mockCard],
    events: const [],
    passives: const [],
    relics: const [],
    forgeUpgrades: const [],
  );

  Future<ProviderContainer> pumpRestScreen(WidgetTester tester) async {
    // Rest option cards are wide; use a larger viewport so the column of
    // three options fits without a RenderFlex overflow.
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [gameDataLoaderProvider.overrideWith((ref) => mockRegistry)],
    );
    addTearDown(container.dispose);

    container.read(runProvider.notifier).startNewRun(mockHero);

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
          home: const RestScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  // Notifications schedule a 3.5s auto-dismiss Timer via `showNotification`.
  // RestScreen never mounts a GameNotificationOverlay (that timer is only
  // cancelled by that widget's dispose), so tests that trigger a
  // notification must let the timer fire before the widget tree is torn
  // down, otherwise flutter_test fails with "Timer is still pending".
  Future<void> settlePendingNotificationTimers(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('RestScreen renders the three action buttons', (
    WidgetTester tester,
  ) async {
    await pumpRestScreen(tester);

    expect(find.text('SE REPOSER'), findsOneWidget);
    expect(find.text('FORGER'), findsOneWidget);
    expect(find.text('OUBLIER'), findsOneWidget);
  });

  testWidgets(
    'Tapping Heal restores 30% of max HP and shows a success notification',
    (WidgetTester tester) async {
      final container = await pumpRestScreen(tester);

      final maxPv = container.read(runProvider).heroStats.maxPv;
      final healAmount = (maxPv * 0.3).round();

      // Damage the hero first (well below max) so we can observe an
      // uncapped heal, then verify the notification and state update.
      container.read(runProvider.notifier).setHeroStats(
        currentPv: maxPv - healAmount - 5,
      );
      final pvBeforeHeal = container.read(runProvider).heroStats.currentPv;

      await tester.tap(find.text('SE REPOSER'));
      await tester.pumpAndSettle();

      final pvAfterHeal = container.read(runProvider).heroStats.currentPv;
      // The heal amount (5 below max) should NOT get capped in this case.
      expect(pvAfterHeal, pvBeforeHeal + healAmount);

      final notifications = container.read(notificationProvider);
      expect(notifications, isNotEmpty);
      expect(notifications.last.type, NotificationType.success);
      expect(notifications.last.message, contains('$healAmount'));

      await settlePendingNotificationTimers(tester);
    },
  );

  testWidgets(
    'Tapping Heal near-full HP caps the restored amount at max HP',
    (WidgetTester tester) async {
      final container = await pumpRestScreen(tester);

      final maxPv = container.read(runProvider).heroStats.maxPv;
      container.read(runProvider.notifier).setHeroStats(currentPv: maxPv - 1);

      await tester.tap(find.text('SE REPOSER'));
      await tester.pumpAndSettle();

      expect(container.read(runProvider).heroStats.currentPv, maxPv);

      await settlePendingNotificationTimers(tester);
    },
  );

  testWidgets(
    'Forge flow returning a card result shows a confirmation notification without crashing',
    (WidgetTester tester) async {
      final container = await pumpRestScreen(tester);

      await tester.tap(find.text('FORGER'));
      await tester.pumpAndSettle();

      // We are now on RestCardSelectionScreen (pushed for real). Rather than
      // driving the ForgeUpgradeDialog UI, simulate it returning a result the
      // same way RestCardSelectionScreen._onCardTapped does for the forge path:
      // Navigator.of(context).pop({'card': card, 'upgrade': upgradeId}).
      final cardInstance = CardInstance(data: mockCard);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop(<String, dynamic>{
        'card': cardInstance,
        'upgrade': 'sharpen',
      });
      await tester.pumpAndSettle();

      // Back on RestScreen, action-taken state should be shown (no crash from
      // the null-safe `result?['card'] as CardInstance?` cast).
      expect(find.byType(RestScreen), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

      final notifications = container.read(notificationProvider);
      expect(notifications, isNotEmpty);
      expect(notifications.last.type, NotificationType.warning);
      expect(notifications.last.message, contains('Frappe'));

      await settlePendingNotificationTimers(tester);
    },
  );

  testWidgets(
    'Remove flow removes the selected card from the master deck',
    (WidgetTester tester) async {
      final container = await pumpRestScreen(tester);

      final cardToRemove = CardInstance(data: mockCard);
      container.read(deckProvider.notifier).addCardToMasterDeck(cardToRemove);
      expect(
        container
            .read(deckProvider)
            .masterDeck
            .any((c) => c.uniqueId == cardToRemove.uniqueId),
        isTrue,
      );

      await tester.tap(find.text('OUBLIER'));
      await tester.pumpAndSettle();

      // RestCardSelectionScreen renders the deck's single card as a UiCard;
      // tapping it triggers the real (non-forge) removal path, which pops
      // the navigator with the CardInstance directly.
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop(cardToRemove);
      await tester.pumpAndSettle();

      expect(
        container
            .read(deckProvider)
            .masterDeck
            .any((c) => c.uniqueId == cardToRemove.uniqueId),
        isFalse,
      );

      final notifications = container.read(notificationProvider);
      expect(notifications, isNotEmpty);
      expect(notifications.last.type, NotificationType.error);
      expect(notifications.last.message, contains('Frappe'));

      await settlePendingNotificationTimers(tester);
    },
  );
}
