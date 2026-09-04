import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/card_dictionary_screen.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
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
}
