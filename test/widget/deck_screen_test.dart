import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/deck_screen.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/ui/widgets/forge/forge_slot_row.dart';
import 'package:roguelike_card_game/ui/widgets/forge_upgrade_dialog.dart';
import 'package:roguelike_card_game/ui/widgets/notification_overlay.dart';

import '../unit/shipped_data.dart';

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

  Widget buildApp(ProviderContainer container, {bool allowMerge = true}) {
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
        home: DeckScreen(allowMerge: allowMerge),
      ),
    );
  }

  /// Une vue large : le dialogue de fusion est plein écran.
  void largeView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Un deck de [cards], sur le registre des runes livrées, que l'écran de
  /// deck lit pour tirer l'offre.
  ProviderContainer deckOf(List<CardInstance> cards) {
    shippedRuneRegistry(shippedRuneIds());
    final container = ProviderContainer();
    addTearDown(container.dispose);
    for (final card in cards) {
      container.read(deckProvider.notifier).addCardToMasterDeck(card);
    }
    return container;
  }

  List<String> messagesOf(ProviderContainer container) =>
      [for (final n in container.read(notificationProvider)) n.message];

  /// Laisse expirer les notifications avant de démonter l'arbre.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('DeckScreen renders all cards from the seeded master deck', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final deckNotifier = container.read(deckProvider.notifier);
    deckNotifier.addCardToMasterDeck(CardInstance(data: strikeCard));
    deckNotifier.addCardToMasterDeck(CardInstance(data: defendCard));

    await tester.pumpWidget(buildApp(container));
    await tester.pumpAndSettle();

    // 2 distinct groups (1 copy each) => 2 UiCards rendered
    expect(find.byType(UiCard), findsNWidgets(2));
    expect(find.text('Total : 2 cartes'), findsOneWidget);
    // Neither group has 3 copies, so merge-related requirement text is shown
    // instead of a merge action.
    expect(find.textContaining('de plus requis'), findsNWidgets(2));
  });

  testWidgets(
    'DeckScreen shows the merge action when allowMerge is true and 3 duplicates exist',
    (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final deckNotifier = container.read(deckProvider.notifier);
      deckNotifier.addCardToMasterDeck(CardInstance(data: strikeCard));
      deckNotifier.addCardToMasterDeck(CardInstance(data: strikeCard));
      deckNotifier.addCardToMasterDeck(CardInstance(data: strikeCard));

      await tester.pumpWidget(buildApp(container, allowMerge: true));
      await tester.pumpAndSettle();

      expect(find.text('FUSIONNER (3)'), findsOneWidget);
      expect(find.text('Fusion possible'), findsNothing);
    },
  );

  testWidgets(
    'DeckScreen hides the merge action when allowMerge is false, even with 3 duplicates',
    (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final deckNotifier = container.read(deckProvider.notifier);
      deckNotifier.addCardToMasterDeck(CardInstance(data: strikeCard));
      deckNotifier.addCardToMasterDeck(CardInstance(data: strikeCard));
      deckNotifier.addCardToMasterDeck(CardInstance(data: strikeCard));

      await tester.pumpWidget(buildApp(container, allowMerge: false));
      await tester.pumpAndSettle();

      expect(find.text('FUSIONNER (3)'), findsNothing);
      // The screen still signals a merge is possible, just not actionable here.
      expect(find.text('Fusion possible'), findsOneWidget);
    },
  );

  testWidgets(
    'Performing a merge fuses 3 duplicates into 1 higher-rarity card in the master deck',
    (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final deckNotifier = container.read(deckProvider.notifier);
      deckNotifier.addCardToMasterDeck(CardInstance(data: strikeCard));
      deckNotifier.addCardToMasterDeck(CardInstance(data: strikeCard));
      deckNotifier.addCardToMasterDeck(CardInstance(data: strikeCard));

      await tester.pumpWidget(buildApp(container, allowMerge: true));
      await tester.pumpAndSettle();

      expect(container.read(deckProvider).masterDeck.length, 3);

      await tester.tap(find.text('FUSIONNER (3)'));
      // The merge confirmation dialog auto-selects all 3 duplicates and
      // proceeds automatically via a post-frame callback when exactly 3
      // duplicates exist, so a couple of pumps drive it to completion.
      await tester.pumpAndSettle();

      final masterDeck = container.read(deckProvider).masterDeck;
      expect(masterDeck.length, 1);
      expect(masterDeck.first.data.id, 'strike');
      expect(masterDeck.first.rarity, CardRarity.uncommon);

      // Let the success notification's auto-dismiss timer expire before the
      // test tears down the widget tree.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'DeckScreen ne propose aucune fusion pour trois legendaires',
    (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final deckNotifier = container.read(deckProvider.notifier);
      for (var i = 0; i < 3; i++) {
        deckNotifier.addCardToMasterDeck(
          CardInstance(data: strikeCard, rarity: CardRarity.legendary),
        );
      }

      // Le bouton ne s'affiche qu'avec allowMerge, la mention « Fusion
      // possible » que sans : chaque mode garde l'une des deux.
      await tester.pumpWidget(buildApp(container, allowMerge: true));
      await tester.pumpAndSettle();
      expect(find.text('FUSIONNER (3)'), findsNothing);

      await tester.pumpWidget(buildApp(container, allowMerge: false));
      await tester.pumpAndSettle();
      expect(find.text('Fusion possible'), findsNothing);
    },
  );

  // Spec P-43 E2, §4.5, §4.6 : plus d'etape de capacite, l'heritage entier.
  testWidgets(
    'trois Frappes runees differemment fusionnent sans etape de capacite, '
    'toutes leurs runes gardees',
    (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final deckNotifier = container.read(deckProvider.notifier);
      for (final rune in const ['sharp:1', 'burning:1', 'shocking:1']) {
        deckNotifier.addCardToMasterDeck(
          CardInstance(data: strikeCard, forgeUpgrades: [rune]),
        );
      }

      await tester.pumpWidget(buildApp(container));
      await tester.pumpAndSettle();
      await tester.tap(find.text('FUSIONNER (3)'));
      await tester.pumpAndSettle();

      expect(find.text('Capacité de Forge Dépassée'), findsNothing);
      final merged = container.read(deckProvider).masterDeck.single;
      expect(merged.rarity, CardRarity.uncommon);
      expect(merged.forgeUpgrades, ['sharp:1', 'burning:1', 'shocking:1']);

      // Les notifications expirent avant le demontage de l'arbre.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
    },
  );

  // Spec P-43 E2, A1, §4.5 : la fusion, puis le choix d'une rune.
  testWidgets('trois Frappes fusionnent, et la carte recoit la rune choisie '
      'parmi trois', (WidgetTester tester) async {
    largeView(tester);
    final strike = shippedCard('strike_basic');
    final container =
        deckOf([for (var i = 0; i < 3; i++) CardInstance(data: strike)]);

    await tester.pumpWidget(buildApp(container));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FUSIONNER (3)'));
    await tester.pumpAndSettle();

    // Peu commune : Tranchant, Brulant, Congelant, Surcharge, Allege, Precis
    // et Spectral s'offrent ; trois sont tirees.
    expect(find.byType(ForgeUpgradeDialog), findsOneWidget);
    expect(find.byType(ForgeSlotRow), findsNWidgets(3));
    expect(messagesOf(container), isEmpty);

    await tester.tap(find.text('Choisir').first);
    await tester.pumpAndSettle();

    expect(find.byType(ForgeUpgradeDialog), findsNothing);
    final merged = container.read(deckProvider).masterDeck.single;
    expect(merged.rarity, CardRarity.uncommon);
    final (id, level) = ForgeUpgradeData.parseRef(merged.forgeUpgrades.single)!;
    expect(level, 1);
    expect(
      id,
      isIn([
        'sharp',
        'burning',
        'freezing',
        'shocking',
        'cheap',
        'precise',
        'spectral',
      ]),
    );
    expect(messagesOf(container),
        ['Fusion réussie : Frappe est maintenant Niveau 2 !']);
    await settle(tester);
  });

  testWidgets('trois Concentrations communes fusionnent sans choix : le '
      'succes, puis le motif', (WidgetTester tester) async {
    largeView(tester);
    final container = deckOf([
      for (var i = 0; i < 3; i++)
        CardInstance(data: shippedCard('concentration')),
    ]);

    await tester.pumpWidget(buildApp(container));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FUSIONNER (3)'));
    await tester.pumpAndSettle();

    // Peu commune, une carte gratuite qui pioche : aucune rune ne s'offre.
    expect(find.byType(ForgeUpgradeDialog), findsNothing);
    expect(container.read(deckProvider).masterDeck.single.forgeUpgrades,
        isEmpty);
    expect(messagesOf(container), [
      'Fusion réussie : Concentration est maintenant Niveau 2 !',
      'Aucune rune ne peut être ajoutée à cette carte.',
    ]);
    await settle(tester);
  });

  testWidgets('le rang atteint : trois Concentrations peu communes, fusionnees '
      'en rare, n offrent que Veloce', (WidgetTester tester) async {
    largeView(tester);
    final container = deckOf([
      for (var i = 0; i < 3; i++)
        CardInstance(
          data: shippedCard('concentration'),
          rarity: CardRarity.uncommon,
        ),
    ]);

    await tester.pumpWidget(buildApp(container));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FUSIONNER (3)'));
    await tester.pumpAndSettle();

    // Jugee au rang des exemplaires, peu commune, l'offre serait vide.
    expect(find.byType(ForgeSlotRow), findsOneWidget);
    expect(find.text('Véloce'), findsOneWidget);

    await tester.tap(find.text('Choisir'));
    await tester.pumpAndSettle();

    expect(container.read(deckProvider).masterDeck.single.forgeUpgrades,
        ['quick:1']);
    expect(messagesOf(container),
        ['Fusion réussie : Concentration est maintenant Niveau 3 !']);
    await settle(tester);
  });

  testWidgets('la case fusionnee sort de la grille : le succes s affiche '
      'quand meme', (WidgetTester tester) async {
    largeView(tester);
    final strike = shippedCard('strike_basic');
    final container = deckOf([
      CardInstance(data: strike, rarity: CardRarity.uncommon),
      CardInstance(data: shippedCard('defend_basic')),
      for (var i = 0; i < 3; i++) CardInstance(data: strike),
    ]);

    await tester.pumpWidget(buildApp(container));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FUSIONNER (3)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choisir').first);
    await tester.pumpAndSettle();

    // Le groupe fusionne, dernier de la grille, en est sorti : la carte
    // fusionnee a rejoint la Frappe peu commune (`mergeCards` l'ajoute en
    // fin de deck), et sa case a ete demontee pendant le choix.
    expect(find.byType(UiCard), findsNWidgets(2));
    expect(messagesOf(container),
        ['Fusion réussie : Frappe est maintenant Niveau 2 !']);
    await settle(tester);
  });

  // Transcendance, lue par la fusion de l'écran de deck (spec P-43 E3, §4.8,
  // §8 ; A17) : sans le bonus de la run, la somme serait bornée à 1.
  testWidgets('trois rares a Econome 1 fusionnent en epique a Econome 2 sous '
      'le plafond releve de la run', (WidgetTester tester) async {
    largeView(tester);
    final container = deckOf([
      for (var i = 0; i < 3; i++)
        CardInstance(
          data: shippedCard('strike_basic'),
          rarity: CardRarity.rare,
          forgeUpgrades: const ['eco:1'],
        ),
    ]);
    container.read(runProvider.notifier).raiseRuneCap('eco');

    await tester.pumpWidget(buildApp(container));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FUSIONNER (3)'));
    await tester.pumpAndSettle();
    // L'offre de la carte fusionnée — Tranchant au moins s'y offre.
    await tester.tap(find.text('Choisir').first);
    await tester.pumpAndSettle();

    final merged = container.read(deckProvider).masterDeck.single;
    expect(merged.rarity, CardRarity.epic);
    expect(ForgeUpgradeData.levelsOf(merged.forgeUpgrades)['eco'], 2);
    await settle(tester);
  });
}
