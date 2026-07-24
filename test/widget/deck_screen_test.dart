import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/deck_screen.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

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
}
