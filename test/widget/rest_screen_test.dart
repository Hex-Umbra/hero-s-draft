import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/rest_card_selection_screen.dart';
import 'package:roguelike_card_game/ui/screens/rest_screen.dart';
import 'package:roguelike_card_game/ui/widgets/notification_overlay.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';
import 'package:roguelike_card_game/game/controllers/checkpoint_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/models/card_instance.dart';

import '../unit/shipped_data.dart';

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
    category: CardCategory.global,
    rarity: CardRarity.common,
    target: CardTarget.singleEnemy,
    effects: [],
  );

  /// Une Frappe peu commune portant Tranchant 1 : la rune s'affûte pour
  /// 50 or, l'or d'une run neuve.
  CardInstance sharpStrike() => CardInstance(
        data: shippedCard('strike_basic'),
        rarity: CardRarity.uncommon,
        forgeUpgrades: const ['sharp:1'],
      );

  /// Le registre des runes livrées, que le feu lit pour l'affûtage.
  GameDataRegistry shippedRegistry() => shippedRuneRegistry(
        shippedRuneIds(),
        cards: [shippedCard('strike_basic')],
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

  /// `RestScreen` poussé sur une vraie pile, comme la carte du monde le
  /// pousse : le retour système a une page où revenir (le précédent de
  /// `map_screen_test.dart`).
  Future<ProviderContainer> pushRestScreen(
    WidgetTester tester, {
    GameDataRegistry? registry,
    List<CardInstance> deck = const [],
  }) async {
    final container = startRun(tester, registry: registry, deck: deck);
    await tester.pumpWidget(app(
      container,
      Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RestScreen()),
            ),
            child: const Text('Ouvrir le feu'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Ouvrir le feu'));
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

  /// Affûte Tranchant 1 de la seule carte du deck, par l'écran : l'option,
  /// la carte, puis le bouton du dialogue.
  Future<void> sharpenTheOnlyCard(WidgetTester tester) async {
    await tester.tap(find.text('AFFÛTER'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Affûter — 50 or'));
    await tester.pumpAndSettle();
  }

  bool currentNodeCompleted(ProviderContainer container) {
    final run = container.read(runProvider);
    return run.mapNodes
        .singleWhere((n) => n.id == run.currentNodeId)
        .isCompleted;
  }

  Future<void> pressBack(WidgetTester tester) async {
    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();
  }

  testWidgets('RestScreen renders the three action buttons', (
    WidgetTester tester,
  ) async {
    await pumpRestScreen(tester);

    expect(find.text('SE REPOSER'), findsOneWidget);
    expect(find.text('AFFÛTER'), findsOneWidget);
    expect(find.text('OUBLIER'), findsOneWidget);
    expect(find.text('FORGER'), findsNothing);
  });

  testWidgets('AFFUTER est inactive, avec son motif, quand aucune rune du '
      'deck ne peut monter', (WidgetTester tester) async {
    await pumpRestScreen(tester, deck: [CardInstance(data: mockCard)]);

    expect(find.text('Aucune rune de votre deck ne peut gagner de niveau.'),
        findsOneWidget);

    await tester.tap(find.text('AFFÛTER'));
    await tester.pumpAndSettle();

    expect(find.byType(RestCardSelectionScreen), findsNothing);
    expect(find.text('SE REPOSER'), findsOneWidget);
  });

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

  testWidgets('Affuter monte une rune d un niveau, notifie, et clot les '
      'options (D14)', (WidgetTester tester) async {
    final container = await pumpRestScreen(
      tester,
      registry: shippedRegistry(),
      deck: [sharpStrike()],
    );

    await sharpenTheOnlyCard(tester);

    expect(find.byType(RestScreen), findsOneWidget);
    expect(container.read(deckProvider).masterDeck.single.forgeUpgrades,
        ['sharp:2']);
    expect(container.read(inventoryProvider).gold, 0);
    expect(container.read(notificationProvider).last.message,
        'Tranchant passe au niveau 2 sur Frappe !');
    // Une seule rune, un seul niveau par visite : les trois options ont
    // disparu, seul « Continuer » reste.
    expect(find.text('SE REPOSER'), findsNothing);
    expect(find.text('AFFÛTER'), findsNothing);
    expect(find.text('OUBLIER'), findsNothing);
    expect(find.text('CONTINUER LA ROUTE'), findsOneWidget);

    await settlePendingNotificationTimers(tester);
  });

  testWidgets(
    'Remove flow removes the selected card from the master deck',
    (WidgetTester tester) async {
      final cardToRemove = CardInstance(data: mockCard);
      final container = await pumpRestScreen(tester, deck: [cardToRemove]);

      await tester.tap(find.text('OUBLIER'));
      await tester.pumpAndSettle();

      // RestCardSelectionScreen renders the deck's single card as a UiCard;
      // tapping it triggers the real (non-sharpen) removal path, which pops
      // the navigator with the CardInstance directly.
      await tester.tap(find.byType(UiCard));
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

  // Spec P-43 E2, A4 : apres une action, toute sortie de l'ecran resout le
  // noeud, que la carte du monde ne laisse plus rejouer.
  group('le retour systeme', () {
    testWidgets('apres un repos, il resout le noeud et ferme l ecran, une '
        'seule fois', (WidgetTester tester) async {
      final container = await pushRestScreen(tester);

      await tester.tap(find.text('SE REPOSER'));
      await tester.pumpAndSettle();
      await pressBack(tester);

      expect(find.byType(RestScreen), findsNothing);
      expect(find.text('Ouvrir le feu'), findsOneWidget);
      expect(currentNodeCompleted(container), isTrue);
      // `completeCurrentNode` pousse le point de sauvegarde : un cran, donc
      // un seul `_leave`.
      expect(container.read(checkpointProvider), 1);

      await settlePendingNotificationTimers(tester);
    });

    testWidgets('apres un affutage, de meme', (WidgetTester tester) async {
      final container = await pushRestScreen(
        tester,
        registry: shippedRegistry(),
        deck: [sharpStrike()],
      );

      await sharpenTheOnlyCard(tester);
      await pressBack(tester);

      expect(find.byType(RestScreen), findsNothing);
      expect(currentNodeCompleted(container), isTrue);
      expect(container.read(checkpointProvider), 1);

      await settlePendingNotificationTimers(tester);
    });

    testWidgets('apres un oubli, de meme', (WidgetTester tester) async {
      final container =
          await pushRestScreen(tester, deck: [CardInstance(data: mockCard)]);

      await tester.tap(find.text('OUBLIER'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(UiCard));
      await tester.pumpAndSettle();
      expect(container.read(deckProvider).masterDeck, isEmpty);

      await pressBack(tester);

      expect(find.byType(RestScreen), findsNothing);
      expect(currentNodeCompleted(container), isTrue);
      expect(container.read(checkpointProvider), 1);

      await settlePendingNotificationTimers(tester);
    });

    testWidgets('avant toute action, il ne fait rien', (
      WidgetTester tester,
    ) async {
      final container = await pushRestScreen(tester);

      await pressBack(tester);

      expect(find.byType(RestScreen), findsOneWidget);
      expect(currentNodeCompleted(container), isFalse);
      expect(container.read(checkpointProvider), 0);
    });
  });
}
