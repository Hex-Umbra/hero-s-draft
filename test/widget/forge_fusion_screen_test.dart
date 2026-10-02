import 'package:flutter/material.dart';
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
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/screens/forge_fusion_screen.dart';
import 'package:roguelike_card_game/ui/widgets/forge/forge_slot_row.dart';
import 'package:roguelike_card_game/ui/widgets/notification_overlay.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';

import '../unit/shipped_data.dart';

/// Le Puits d'échange (spec P-43 E2, A5, §4.8), sur les runes livrées.
void main() {
  const hero = HeroData(
    id: 'paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
  );

  /// Une Frappe rare portant [runes].
  CardInstance strike(List<String> runes) => CardInstance(
        data: shippedCard('strike_basic'),
        rarity: CardRarity.rare,
        forgeUpgrades: runes,
      );

  /// Une run neuve, au premier nœud de sa carte, avec [deck] pour deck et
  /// [gold] or. Une liste fixe de runes livrées : le cas ne bouge pas quand
  /// une rune s'ajoute au catalogue. Le chargeur de données est remplacé :
  /// sans cela, la vraie donnée se charge en tâche de fond et remplace le
  /// registre pendant le test.
  ProviderContainer startRun(
    WidgetTester tester, {
    required List<CardInstance> deck,
    int gold = 1000,
  }) {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final registry =
        shippedRuneRegistry(const ['burning', 'eco', 'hardened', 'sharp']);
    final container = ProviderContainer(
      overrides: [gameDataLoaderProvider.overrideWith((ref) => registry)],
    );
    addTearDown(container.dispose);

    final run = container.read(runProvider.notifier);
    run.startNewRun(hero);
    run.travelToNode(container.read(runProvider).mapNodes.first.id);
    container.read(inventoryProvider.notifier).reset(initialGold: gold);
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

  /// Le Puits en page d'accueil.
  Future<ProviderContainer> pumpWell(
    WidgetTester tester, {
    required List<CardInstance> deck,
    int gold = 1000,
  }) async {
    final container = startRun(tester, deck: deck, gold: gold);
    await tester.pumpWidget(app(container, const ForgeFusionScreen()));
    await tester.pumpAndSettle();
    return container;
  }

  /// Le Puits poussé sur une vraie pile, comme la carte du monde le pousse :
  /// le retour système a une page où revenir.
  Future<ProviderContainer> pushWell(
    WidgetTester tester, {
    required List<CardInstance> deck,
  }) async {
    final container = startRun(tester, deck: deck);
    await tester.pumpWidget(app(
      container,
      Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ForgeFusionScreen()),
            ),
            child: const Text('Ouvrir le Puits'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Ouvrir le Puits'));
    await tester.pumpAndSettle();
    return container;
  }

  /// Échange Tranchant 3, sur la seule carte du deck, contre Brûlant : la
  /// carte, la rune donnée, puis la première remplaçante.
  Future<void> exchangeSharp(WidgetTester tester) async {
    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tranchant 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Échanger — 150 or').first);
    await tester.pumpAndSettle();
  }

  // La notification se ferme d'elle-même après 3,5 s.
  Future<void> settleNotification(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpWidget(const SizedBox());
  }

  /// La couleur que le texte [label] porte vraiment : celle du style que la
  /// tuile applique.
  Color? titleColor(WidgetTester tester, String label) => tester
      .widget<DefaultTextStyle>(find
          .ancestor(
              of: find.text(label), matching: find.byType(DefaultTextStyle))
          .first)
      .style
      .color;

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

  testWidgets('les cartes qui portent une rune, et elles seules',
      (tester) async {
    await pumpWell(tester, deck: [
      strike(const ['sharp:2']),
      CardInstance(data: shippedCard('defend_basic')),
    ]);

    expect(find.text('PUITS D\'ÉCHANGE'), findsOneWidget);
    expect(find.text('Choisissez une carte, puis la rune à donner.'),
        findsOneWidget);
    expect(find.byType(UiCard), findsOneWidget);
  });

  testWidgets('les remplacantes d une rune : toutes, a leur niveau d arrivee, '
      'au cout de la rune donnee', (tester) async {
    await pumpWell(tester, deck: [strike(const ['sharp:3'])]);

    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();
    final before = titleColor(tester, 'Tranchant 3');
    await tester.tap(find.text('Tranchant 3'));
    await tester.pumpAndSettle();
    // La rune choisie se montre choisie.
    expect(titleColor(tester, 'Tranchant 3'), isNot(before));

    // Brulant aux deux tiers de 3, Econome borne a 1 ; Endurci ne vise que
    // l'armure.
    expect(find.byType(ForgeSlotRow), findsNWidgets(2));
    expect(find.text('Échanger — 150 or'), findsNWidgets(2));
    expect(find.text('Reçue au niveau 2'), findsOneWidget);
    expect(find.text('Reçue au niveau 1'), findsOneWidget);
  });

  testWidgets('un echange par visite : le Puits echange, puis ne propose plus '
      'que la sortie', (tester) async {
    final card = strike(const ['sharp:3']);
    final container = await pumpWell(tester, deck: [card], gold: 300);

    await exchangeSharp(tester);

    expect(container.read(deckProvider).masterDeck.single.forgeUpgrades,
        ['burning:2']);
    expect(container.read(inventoryProvider).gold, 150);
    expect(container.read(notificationProvider).last.message,
        'Tranchant devient Brûlant (niveau 2).');
    // L'or suffirait a un second echange : rien ne le propose plus.
    expect(find.byType(UiCard), findsNothing);
    expect(find.byType(ForgeSlotRow), findsNothing);
    expect(find.text('Quitter le Puits'), findsOneWidget);

    await settleNotification(tester);
  });

  // Review Focus 2.
  testWidgets('une rune sans remplacante se montre inactive, avec son motif',
      (tester) async {
    // Une Defense peu commune, sur ce catalogue sans Allege : ni degats, ni
    // rang 2.
    await pumpWell(tester, deck: [
      CardInstance(
        data: shippedCard('defend_basic'),
        rarity: CardRarity.uncommon,
        forgeUpgrades: const ['hardened:1'],
      ),
    ]);

    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();
    expect(find.text('Aucune autre rune ne peut la remplacer.'),
        findsOneWidget);
    // Et se montre inactive : ni blanche, ni de la couleur du choix.
    expect(titleColor(tester, 'Endurci 1'), isNot(Colors.white));

    await tester.tap(find.text('Endurci 1'));
    await tester.pumpAndSettle();
    expect(find.byType(ForgeSlotRow), findsNothing);
  });

  testWidgets('un deck sans rune montre l ecran vide et la sortie',
      (tester) async {
    await pumpWell(tester, deck: [CardInstance(data: shippedCard('defend_basic'))]);

    expect(find.text('Aucune carte de votre deck ne porte de rune à échanger.'),
        findsOneWidget);
    expect(find.text('Quitter le Puits'), findsOneWidget);
  });

  // Spec P-43 E2, A5 : apres un echange, toute sortie resout le noeud ; sans
  // echange, le joueur peut revenir.
  group('le retour systeme', () {
    testWidgets('apres un echange, il resout le noeud et ferme l ecran, une '
        'seule fois', (tester) async {
      final container = await pushWell(tester, deck: [strike(const ['sharp:3'])]);

      await exchangeSharp(tester);
      await pressBack(tester);

      expect(find.byType(ForgeFusionScreen), findsNothing);
      expect(find.text('Ouvrir le Puits'), findsOneWidget);
      expect(currentNodeCompleted(container), isTrue);
      expect(container.read(checkpointProvider), 1);

      await settleNotification(tester);
    });

    testWidgets('sans echange, il ferme l ecran et le noeud reste non resolu',
        (tester) async {
      final container = await pushWell(tester, deck: [strike(const ['sharp:3'])]);

      await pressBack(tester);

      expect(find.byType(ForgeFusionScreen), findsNothing);
      expect(currentNodeCompleted(container), isFalse);
      expect(container.read(checkpointProvider), 0);
    });
  });
}
