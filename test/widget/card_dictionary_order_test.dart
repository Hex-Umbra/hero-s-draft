import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/card_dictionary_screen.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

const _skill = CardData(
  id: 'defend',
  nameEn: 'Defend',
  nameFr: 'Défense',
  cost: 1,
  type: CardType.skill,
  category: CardCategory.global,
  rarity: CardRarity.common,
  target: CardTarget.self,
  effects: [],
);

const _attack = CardData(
  id: 'strike',
  nameEn: 'Strike',
  nameFr: 'Frappe',
  cost: 1,
  type: CardType.attack,
  category: CardCategory.global,
  rarity: CardRarity.common,
  target: CardTarget.singleEnemy,
  effects: [],
);

/// Un seul groupe (`CardType.attack`), à rareté et coût mélangés, déclaré
/// dans un ordre qui n'est ni celui du tri ni son inverse — même raisonnement
/// que `starter_deck_draft_order_test.dart`. Sert à vérifier le tri
/// intra-groupe (rareté→coût→id), jusqu'ici seulement vérifié par lecture de
/// code (`_buildCardsTab`).
const _mixedGroup = [
  CardData(
    id: 'atk_c_common_cost2',
    nameEn: 'Group Common Two',
    nameFr: 'Groupe Commune Deux',
    cost: 2,
    type: CardType.attack,
    category: CardCategory.global,
    rarity: CardRarity.common,
    target: CardTarget.singleEnemy,
    effects: [],
  ),
  CardData(
    id: 'atk_a_common_cost1',
    nameEn: 'Group Common One A',
    nameFr: 'Groupe Commune Un A',
    cost: 1,
    type: CardType.attack,
    category: CardCategory.global,
    rarity: CardRarity.common,
    target: CardTarget.singleEnemy,
    effects: [],
  ),
  CardData(
    id: 'atk_b_common_cost1',
    nameEn: 'Group Common One B',
    nameFr: 'Groupe Commune Un B',
    cost: 1,
    type: CardType.attack,
    category: CardCategory.global,
    rarity: CardRarity.common,
    target: CardTarget.singleEnemy,
    effects: [],
  ),
  CardData(
    id: 'atk_a_rare_cost1',
    nameEn: 'Group Rare One',
    nameFr: 'Groupe Rare Un',
    cost: 1,
    type: CardType.attack,
    category: CardCategory.global,
    rarity: CardRarity.rare,
    target: CardTarget.singleEnemy,
    effects: [],
  ),
];

/// Deux reliques de meme rarete, declarees a l'envers de l'ordre d'id. Le
/// jumeau exact de `_mixedGroup` pour l'onglet reliques, dont le tri
/// intra-groupe n'etait jusqu'ici verifie que par lecture de code.
const _mixedRelics = [
  RelicData(
    id: 'relic_z_rare',
    nameEn: 'Zulu Charm',
    nameFr: 'Charme Zoulou',
    trigger: RelicTrigger.startOfTurn,
    effectType: 'gain_armor',
    value: 1,
    rarity: RelicRarity.rare,
    emoji: '🔮',
  ),
  RelicData(
    id: 'relic_a_rare',
    nameEn: 'Alpha Charm',
    nameFr: 'Charme Alpha',
    trigger: RelicTrigger.startOfTurn,
    effectType: 'gain_armor',
    value: 1,
    rarity: RelicRarity.rare,
    emoji: '🔷',
  ),
];

Future<List<String>> _renderedRelicNames(
  WidgetTester tester,
  List<RelicData> relics,
) async {
  final registry = GameDataRegistry(
    enemies: const [],
    heroes: const [],
    cards: const [],
    events: const [],
    passives: const [],
    relics: relics,
    forgeUpgrades: const [],
  );
  final container = ProviderContainer(
    overrides: [gameDataLoaderProvider.overrideWith((ref) => registry)],
  );
  addTearDown(container.dispose);
  await container.read(gameDataLoaderProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en', ''), Locale('fr', '')],
        locale: Locale('en', ''),
        home: CardDictionaryScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));

  // Les reliques sont rendues par une classe privee de l'ecran : on releve
  // donc les Text dans l'ordre de rendu, filtres sur les noms de la fixture.
  await tester.tap(find.byType(Tab).at(1));
  await tester.pumpAndSettle();

  final expected = relics.map((r) => r.nameEn).toSet();
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .where(expected.contains)
      .toList();
}

Future<List<String>> _renderedGroupHeaders(
  WidgetTester tester,
  List<CardData> cards,
) async {
  final registry = GameDataRegistry(
    enemies: const [],
    heroes: const [],
    cards: cards,
    events: const [],
    passives: const [],
    relics: const [],
    forgeUpgrades: const [],
  );
  final container = ProviderContainer(
    overrides: [gameDataLoaderProvider.overrideWith((ref) => registry)],
  );
  addTearDown(container.dispose);
  await container.read(gameDataLoaderProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en', ''), Locale('fr', '')],
        locale: Locale('en', ''),
        home: CardDictionaryScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));

  // Les en-têtes de groupe sont les seuls Text en amber/24.
  return tester
      .widgetList<Text>(find.byType(Text))
      .where((t) => t.style?.fontSize == 24)
      .map((t) => t.data ?? '')
      .toList();
}

Future<List<String>> _renderedCardTitles(
  WidgetTester tester,
  List<CardData> cards,
) async {
  final registry = GameDataRegistry(
    enemies: const [],
    heroes: const [],
    cards: cards,
    events: const [],
    passives: const [],
    relics: const [],
    forgeUpgrades: const [],
  );
  final container = ProviderContainer(
    overrides: [gameDataLoaderProvider.overrideWith((ref) => registry)],
  );
  addTearDown(container.dispose);
  await container.read(gameDataLoaderProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en', ''), Locale('fr', '')],
        locale: Locale('en', ''),
        home: CardDictionaryScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));

  return tester
      .widgetList<UiCard>(find.byType(UiCard))
      .map((c) => c.title)
      .toList();
}

void main() {
  testWidgets(
    'l ordre des groupes ne depend pas de l ordre du catalogue',
    (tester) async {
      final forward = await _renderedGroupHeaders(tester, const [_attack, _skill]);
      final reversed = await _renderedGroupHeaders(tester, const [_skill, _attack]);

      expect(forward, isNotEmpty);
      expect(reversed, equals(forward));
    },
  );

  testWidgets(
    'l ordre intra-groupe suit rarete puis cout puis id, pas la declaration',
    (tester) async {
      final titles = await _renderedCardTitles(tester, _mixedGroup);

      expect(titles, [
        'Group Common One A', // commun, coût 1, id "a" — départage par id
        'Group Common One B', // commun, coût 1, id "b"
        'Group Common Two', // commun, coût 2 — départage par coût
        'Group Rare One', // rare — la rareté prime malgré le plus petit coût/id
      ]);
    },
  );

  testWidgets(
    'l ordre intra-groupe des reliques suit l id, pas la declaration',
    (tester) async {
      final names = await _renderedRelicNames(tester, _mixedRelics);

      expect(names, ['Alpha Charm', 'Zulu Charm']);
    },
  );
}
