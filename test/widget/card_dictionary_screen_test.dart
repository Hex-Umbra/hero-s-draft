import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/card_dictionary_screen.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

// Seed catalogue: a mix of global cards and hero-specific ("unique") cards
// spread across the CardType groups the screen renders (attack/skill/power).
const _cards = [
  CardData(
    id: 'atk_global',
    nameEn: 'Strike',
    nameFr: 'Frappe',
    descriptionEn: 'Deal damage.',
    descriptionFr: 'Inflige des dégâts.',
    cost: 1,
    type: CardType.attack,
    category: CardCategory.global,
    rarity: CardRarity.common,
    target: CardTarget.singleEnemy,
    effects: [],
  ),
  CardData(
    id: 'atk_hero',
    nameEn: 'Holy Strike',
    nameFr: 'Frappe Sacrée',
    descriptionEn: 'A paladin-only attack.',
    descriptionFr: 'Une attaque réservée au paladin.',
    cost: 2,
    type: CardType.attack,
    category: CardCategory.characterSpecific,
    heroClass: 'paladin',
    rarity: CardRarity.unique,
    target: CardTarget.singleEnemy,
    effects: [],
  ),
  CardData(
    id: 'skill_global',
    nameEn: 'Defend',
    nameFr: 'Défense',
    descriptionEn: 'Gain armor.',
    descriptionFr: 'Gagne de l\'armure.',
    cost: 1,
    type: CardType.skill,
    category: CardCategory.global,
    rarity: CardRarity.common,
    target: CardTarget.self,
    effects: [],
  ),
  CardData(
    id: 'power_hero',
    nameEn: 'Arcane Mastery',
    nameFr: 'Maîtrise Arcanique',
    descriptionEn: 'A mage-only power.',
    descriptionFr: 'Un pouvoir réservé au mage.',
    cost: 3,
    type: CardType.power,
    category: CardCategory.characterSpecific,
    heroClass: 'mage',
    rarity: CardRarity.unique,
    target: CardTarget.self,
    effects: [],
  ),
];

const _relics = [
  RelicData(
    id: 'relic_common',
    nameEn: 'Lucky Coin',
    nameFr: 'Pièce Chanceuse',
    descriptionEn: 'Grants a little luck.',
    descriptionFr: 'Un peu de chance.',
    trigger: RelicTrigger.startOfRun,
    effectType: 'gain_energy',
    value: 1,
    rarity: RelicRarity.common,
    emoji: '🪙',
  ),
  RelicData(
    id: 'relic_rare',
    nameEn: 'War Banner',
    nameFr: 'Bannière de Guerre',
    descriptionEn: 'Rallies the troops.',
    descriptionFr: 'Rassemble les troupes.',
    trigger: RelicTrigger.startOfCombat,
    effectType: 'gain_strength',
    value: 2,
    rarity: RelicRarity.rare,
    emoji: '🚩',
  ),
];

final _mockRegistry = GameDataRegistry(
  enemies: const [],
  heroes: const [],
  skills: const [],
  cards: _cards,
  events: const [],
  passives: const [],
  relics: _relics,
  forgeUpgrades: const [],
);

Future<ProviderContainer> _buildAndReady(
  WidgetTester tester, {
  Locale locale = const Locale('en', ''),
}) async {
  final container = ProviderContainer(
    overrides: [gameDataLoaderProvider.overrideWith((ref) => _mockRegistry)],
  );
  addTearDown(container.dispose);

  // The screen's build reacts to the FutureProvider via .when(), so make
  // sure it has resolved before the first pump.
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
        locale: locale,
        home: const CardDictionaryScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));

  return container;
}

void main() {
  testWidgets(
    'CardDictionaryScreen renders the seeded catalogue without crashing',
    (WidgetTester tester) async {
      await _buildAndReady(tester);

      // App bar title and tabs.
      expect(find.text('DICTIONARY'), findsOneWidget);
      expect(find.text('Cards'), findsOneWidget);
      expect(find.text('Relics'), findsOneWidget);

      // Cards tab is shown by default, grouped by CardType, mixing global
      // and hero-specific cards under the same type header.
      expect(find.text('ATTACKS'), findsOneWidget);
      expect(find.text('SKILLS'), findsOneWidget);
      expect(find.text('POWERS'), findsOneWidget);

      expect(find.text('STRIKE'), findsOneWidget);
      expect(find.text('HOLY STRIKE'), findsOneWidget);
      expect(find.text('DEFEND'), findsOneWidget);
      expect(find.text('ARCANE MASTERY'), findsOneWidget);
    },
  );

  testWidgets(
    'Switching to the Relics tab shows relics grouped by rarity',
    (WidgetTester tester) async {
      await _buildAndReady(tester);

      // Sanity check: still on the Cards tab initially.
      expect(find.text('STRIKE'), findsOneWidget);

      await tester.tap(find.text('Relics'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('COMMONS'), findsOneWidget);
      expect(find.text('RARES'), findsOneWidget);
      expect(find.text('Lucky Coin'), findsOneWidget);
      expect(find.text('War Banner'), findsOneWidget);
    },
  );

  testWidgets(
    'CardDictionaryScreen shows French labels when locale is fr',
    (WidgetTester tester) async {
      await _buildAndReady(tester, locale: const Locale('fr', ''));

      expect(find.text('DICTIONNAIRE'), findsOneWidget);
      expect(find.text('Cartes'), findsOneWidget);
      expect(find.text('Reliques'), findsOneWidget);

      expect(find.text('ATTAQUES'), findsOneWidget);
      expect(find.text('FRAPPE'), findsOneWidget);
      expect(find.text('FRAPPE SACRÉE'), findsOneWidget);
    },
  );
}
