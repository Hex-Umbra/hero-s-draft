import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/checkpoint_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/event_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/screens/event_screen.dart';
import 'package:roguelike_card_game/ui/screens/rest_card_selection_screen.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';

import '../unit/shipped_data.dart';

/// L'écran d'événement, sur les événements livrés (spec P-43 E3, §4.9, §8,
/// « L'écran d'événement »).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const hero = HeroData(
    id: 'paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
  );

  const leave = 'Passer votre chemin (Rien)';
  const handRune = 'Lui confier une rune (-10 % des PV max, +1 niveau de rune)';

  late GameDataRegistry shipped;
  setUpAll(() async {
    shipped = await loadGameDataRegistry(rootBundle);
  });

  EventData eventOf(String id) =>
      shipped.events.singleWhere((e) => e.id == id);

  /// Une run neuve, au premier nœud de sa carte, sur un registre dont le
  /// seul événement est [event] : `initState` en tire un au hasard parmi
  /// `events` (`event_screen.dart:24-29`), et un `setEvent` posé avant le
  /// premier pump serait écrasé. Le deck reçoit [deck] ; [prepare] agit
  /// avant l'ouverture — l'échange vise sa relique à l'ouverture (A20).
  Future<ProviderContainer> startRun(
    WidgetTester tester,
    EventData event, {
    List<CardInstance> deck = const [],
    void Function(ProviderContainer container)? prepare,
  }) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final registry = GameDataRegistry(
      enemies: const [],
      heroes: const [hero],
      cards: shipped.cards,
      events: [event],
      passives: const [],
      relics: shipped.relics,
      forgeUpgrades: shipped.forgeUpgrades,
    );
    final container = ProviderContainer(
      overrides: [gameDataLoaderProvider.overrideWith((ref) => registry)],
    );
    addTearDown(container.dispose);
    // L'écran appelle `.requireValue` dans `initState` : le futur doit être
    // résolu avant le premier pump.
    await container.read(gameDataLoaderProvider.future);

    final run = container.read(runProvider.notifier);
    run.startNewRun(hero);
    run.travelToNode(container.read(runProvider).mapNodes.first.id);
    for (final card in deck) {
      container.read(deckProvider.notifier).addCardToMasterDeck(card);
    }
    prepare?.call(container);
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

  /// L'écran d'événement en page d'accueil.
  Future<ProviderContainer> pumpEvent(
    WidgetTester tester,
    EventData event, {
    List<CardInstance> deck = const [],
    void Function(ProviderContainer container)? prepare,
  }) async {
    final container =
        await startRun(tester, event, deck: deck, prepare: prepare);
    await tester.pumpWidget(app(container, const EventScreen()));
    await tester.pumpAndSettle();
    return container;
  }

  /// L'écran poussé sur une vraie pile, comme la carte du monde le pousse :
  /// le retour système a une page où revenir.
  Future<ProviderContainer> pushEvent(
    WidgetTester tester,
    EventData event,
  ) async {
    final container = await startRun(tester, event);
    await tester.pumpWidget(app(
      container,
      Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EventScreen()),
            ),
            child: const Text('Ouvrir l evenement'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Ouvrir l evenement'));
    await tester.pumpAndSettle();
    return container;
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

  // A22 : le mécanisme du feu et du Puits.
  group('le retour systeme', () {
    testWidgets('apres un choix, il resout le noeud et ferme l ecran, une '
        'seule fois', (tester) async {
      final container = await pushEvent(tester, eventOf('relic_peddler'));

      await tester.tap(find.text(leave));
      await tester.pumpAndSettle();
      await pressBack(tester);

      expect(find.byType(EventScreen), findsNothing);
      expect(find.text('Ouvrir l evenement'), findsOneWidget);
      expect(currentNodeCompleted(container), isTrue);
      // `completeCurrentNode` pousse le point de sauvegarde : un cran, donc
      // un seul `_leave`.
      expect(container.read(checkpointProvider), 1);
    });

    testWidgets('avant tout choix, il ne fait rien', (tester) async {
      final container = await pushEvent(tester, eventOf('relic_peddler'));

      await pressBack(tester);

      expect(find.byType(EventScreen), findsOneWidget);
      expect(currentNodeCompleted(container), isFalse);
      expect(container.read(checkpointProvider), 0);
    });
  });

  group('le Remouleur', () {
    /// Une Frappe rare portant Tranchant 1 : la rune peut monter.
    CardInstance sharpStrike() => CardInstance(
          data: shippedCard('strike_basic'),
          rarity: CardRarity.rare,
          forgeUpgrades: const ['sharp:1'],
        );

    testWidgets('il affute la rune choisie, sans or, contre 10 % des PV max',
        (tester) async {
      final container = await pumpEvent(
        tester,
        eventOf('wandering_grinder'),
        deck: [sharpStrike(), CardInstance(data: shippedCard('defend_basic'))],
      );
      final goldBefore = container.read(inventoryProvider).gold;

      await tester.tap(find.text(handRune));
      await tester.pumpAndSettle();

      // La sélection du feu, sans or : la carte sans rune est grisée.
      final cards = find.byType(UiCard);
      expect(cards, findsNWidgets(2));
      expect(tester.widget<UiCard>(cards.at(1)).isGrayedOut, isTrue);

      await tester.tap(cards.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choisir'));
      await tester.pumpAndSettle();

      expect(find.byType(RestCardSelectionScreen), findsNothing);
      expect(container.read(deckProvider).masterDeck.first.forgeUpgrades,
          ['sharp:2']);
      expect(container.read(runProvider).heroStats.currentPv, 90);
      expect(container.read(inventoryProvider).gold, goldBefore);
      expect(find.text('CONTINUER'), findsOneWidget);
    });

  });
}
