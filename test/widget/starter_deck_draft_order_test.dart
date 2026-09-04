import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/starter_deck_draft_screen.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Pool à rareté et coût mélangés : `starter_deck_draft_screen_test.dart`
/// n'utilise que des cartes communes à coût 1 (slash_1..5, shield_1..5), un
/// pool sous lequel *n'importe quel* ordre — y compris l'absence de tri —
/// satisfait ses assertions. Ce fichier exerce les trois paliers du
/// comparateur (rareté, puis coût, puis id) avec un pool où ils divergent.
///
/// Déclarées dans un ordre qui n'est ni celui du tri ni son inverse, pour
/// qu'un retrait ou une inversion du tri change la sortie de façon détectable
/// dans les deux cas (voir `class_selection_screen_test.dart` pour le même
/// raisonnement appliqué à `displayOrder`).
const _pool = [
  CardData(
    id: 'c_common_cost2',
    nameEn: 'Common Two',
    nameFr: 'Commune Deux',
    descriptionEn: 'A common card at cost 2.',
    descriptionFr: 'Une carte commune à coût 2.',
    cost: 2,
    type: CardType.attack,
    category: CardCategory.global,
    rarity: CardRarity.common,
    target: CardTarget.singleEnemy,
    effects: [],
  ),
  CardData(
    id: 'a_common_cost1',
    nameEn: 'Common One A',
    nameFr: 'Commune Un A',
    descriptionEn: 'A common card at cost 1, id "a".',
    descriptionFr: 'Une carte commune à coût 1, id « a ».',
    cost: 1,
    type: CardType.attack,
    category: CardCategory.global,
    rarity: CardRarity.common,
    target: CardTarget.singleEnemy,
    effects: [],
  ),
  CardData(
    id: 'b_common_cost1',
    nameEn: 'Common One B',
    nameFr: 'Commune Un B',
    descriptionEn: 'A common card at cost 1, id "b".',
    descriptionFr: 'Une carte commune à coût 1, id « b ».',
    cost: 1,
    type: CardType.attack,
    category: CardCategory.global,
    rarity: CardRarity.common,
    target: CardTarget.singleEnemy,
    effects: [],
  ),
  CardData(
    id: 'a_rare_cost1',
    nameEn: 'Rare One',
    nameFr: 'Rare Un',
    descriptionEn: 'A rare card at cost 1 — lower cost and id than the '
        'commons above, but rarity outranks both.',
    descriptionFr: 'Une carte rare à coût 1 — coût et id plus bas que les '
        'communes ci-dessus, mais la rareté prime sur les deux.',
    cost: 1,
    type: CardType.attack,
    category: CardCategory.global,
    rarity: CardRarity.rare,
    target: CardTarget.singleEnemy,
    effects: [],
  ),
];

const _mockHero = HeroData(
  id: 'paladin',
  nameEn: 'Paladin',
  nameFr: 'Paladin',
  iconPath: 'paladin.png',
  maxHp: 100,
  maxMana: 3,
  baseDamage: 5,
);

final _mockRegistry = GameDataRegistry(
  enemies: const [],
  heroes: const [_mockHero],
  cards: _pool,
  events: const [],
  passives: const [],
  relics: const [],
  forgeUpgrades: const [],
);

void main() {
  testWidgets(
    'le pool du draft de depart suit rarete puis cout puis id, pas la declaration',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [gameDataLoaderProvider.overrideWith((ref) => _mockRegistry)],
      );
      addTearDown(container.dispose);
      await container.read(gameDataLoaderProvider.future);

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
            home: const StarterDeckDraftScreen(
              playerClass: _mockHero,
              passive: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // L'ordre de rendu de la grille suit l'ordre de `_draftPool` (même
      // hypothèse que `starter_deck_draft_screen_test.dart`, qui sélectionne
      // déjà par `find.byType(UiCard).at(index)`).
      final titles = tester
          .widgetList<UiCard>(find.byType(UiCard))
          .map((card) => card.title)
          .toList();

      expect(titles, [
        'Common One A', // commun, coût 1, id "a" — départage par id
        'Common One B', // commun, coût 1, id "b"
        'Common Two', // commun, coût 2 — départage par coût
        'Rare One', // rare — la rareté prime, malgré le plus petit coût/id
      ]);
    },
  );
}
