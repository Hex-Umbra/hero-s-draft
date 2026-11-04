import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/rest_screen.dart';
import 'package:roguelike_card_game/ui/widgets/notification_overlay.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/models/card_instance.dart';

void main() {
  const mockHero = HeroData(
    id: 'paladin',
    nameEn: 'Paladin',
    nameFr: 'Paladin',
    descriptionEn: 'A holy knight',
    descriptionFr: 'Un saint chevalier',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
    luck: 0,
    mastery: 0,
  );

  const mockCard = CardData(
    id: 'strike',
    nameEn: 'Strike',
    nameFr: 'Frappe',
    descriptionEn: 'Deal 6 damage',
    descriptionFr: 'Inflige 6 dégâts',
    cost: 1,
    type: CardType.attack,
    rarity: CardRarity.common,
    target: CardTarget.singleEnemy,
    effects: [],
  );

  /// Une run neuve, au premier nœud de sa carte, sur [registry] — un
  /// registre sans rune par défaut —, avec [deck] pour deck.
  ProviderContainer startRun(
    WidgetTester tester, {
    GameDataRegistry? registry,
    List<CardInstance> deck = const [],
  }) {
    // Rest option cards are wide; use a larger viewport so the column of
    // three options fits without a RenderFlex overflow.
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final data = registry ??
        GameDataRegistry(
          enemies: const [],
          heroes: const [mockHero],
          cards: const [mockCard],
          events: const [],
          passives: const [],
          relics: const [],
          forgeUpgrades: const [],
        );
    final container = ProviderContainer(
      overrides: [gameDataLoaderProvider.overrideWith((ref) => data)],
    );
    addTearDown(container.dispose);

    final run = container.read(runProvider.notifier);
    run.startNewRun(mockHero);
    run.travelToNode(container.read(runProvider).mapNodes.first.id);
    for (final card in deck) {
      container.read(deckProvider.notifier).addCardToMasterDeck(card);
    }
    return container;
  }

  Widget app(ProviderContainer container, Widget home) =>
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
          home: home,
        ),
      );

  /// `RestScreen` en page d'accueil.
  Future<ProviderContainer> pumpRestScreen(
    WidgetTester tester, {
    GameDataRegistry? registry,
    List<CardInstance> deck = const [],
  }) async {
    final container = startRun(tester, registry: registry, deck: deck);
    await tester.pumpWidget(app(container, const RestScreen()));
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

  testWidgets(
    'Tapping Heal restores 30% of max HP and shows a success notification',
    (WidgetTester tester) async {
      final container = await pumpRestScreen(tester);

      final maxPv = container.read(runProvider).heroStats.maxPv;
      final healAmount = (maxPv * 0.3).round();

      // Damage the hero first (well below max) so we can observe an
      // uncapped heal, then verify the notification and state update.
      container.read(runProvider.notifier).takeDamage(healAmount + 5);
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
      container.read(runProvider.notifier).takeDamage(1);

      await tester.tap(find.text('SE REPOSER'));
      await tester.pumpAndSettle();

      expect(container.read(runProvider).heroStats.currentPv, maxPv);

      await settlePendingNotificationTimers(tester);
    },
  );

}
