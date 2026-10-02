import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card/card_rune_sockets.dart';

Future<void> _pumpCard(WidgetTester tester, CardInstance card) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('fr', '')],
      locale: const Locale('fr', ''),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 140,
            height: 196,
            child: Builder(
              builder: (context) => UiCard.fromInstance(
                card: card,
                locale: 'fr',
                l10n: AppLocalizations.of(context)!,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Chaque emplacement, vide ou garni, est un `Container` enfant direct du
/// `Wrap` de `CardRuneSockets`.
int _socketCount(WidgetTester tester) => tester
    .widgetList(
      find.descendant(
        of: find.byType(CardRuneSockets),
        matching: find.byType(Container),
      ),
    )
    .length;

CardData _cardData(CardRarity rarity) => CardData(
      id: 'holy_shield',
      nameEn: 'Holy Shield',
      nameFr: 'Bouclier Sacre',
      descriptionEn: 'Gain armor',
      descriptionFr: 'Gagne de l armure',
      cost: 1,
      type: CardType.skill,
      category: CardCategory.global,
      rarity: rarity,
      target: CardTarget.self,
      effects: const [],
    );

/// Une prise par rune portée, aucune vide (spec P-43 E2, §4.10).
void main() {
  testWidgets('une carte de classe sans rune n affiche aucun emplacement', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester, CardInstance(data: _cardData(CardRarity.unique)));

    expect(_socketCount(tester), 0);
  });

  testWidgets('une carte legendaire a deux runes affiche deux emplacements, '
      'aucun vide', (
    WidgetTester tester,
  ) async {
    await _pumpCard(
      tester,
      CardInstance(
        data: _cardData(CardRarity.common),
        rarity: CardRarity.legendary,
        forgeUpgrades: const ['sharp:2', 'burning:1'],
      ),
    );

    expect(_socketCount(tester), 2);
  });

  testWidgets('l emoji d une prise vient de la donnee de la rune', (
    WidgetTester tester,
  ) async {
    GameDataRegistry(
      enemies: const [],
      heroes: const [],
      cards: const [],
      events: const [],
      passives: const [],
      relics: const [],
      forgeUpgrades: const [
        ForgeUpgradeData(
          id: 'test_rune',
          nameEn: 'Test',
          nameFr: 'Test',
          descriptionEn: '',
          descriptionFr: '',
          icon: '',
          color: '',
          pools: ['common'],
          emoji: '🧪',
        ),
      ],
    );

    await _pumpCard(
      tester,
      CardInstance(
        data: _cardData(CardRarity.common),
        forgeUpgrades: const ['test_rune:1'],
      ),
    );

    expect(
      find.descendant(
        of: find.byType(CardRuneSockets),
        matching: find.text('🧪'),
      ),
      findsOneWidget,
    );
  });

  // Review Focus 3 : une reference mal formee ne nomme aucune rune — l'emoji
  // passe par l'analyseur unique (spec P-43 E2, §1.3, E-S6).
  testWidgets('une reference mal formee prend l emoji par defaut', (
    WidgetTester tester,
  ) async {
    GameDataRegistry(
      enemies: const [],
      heroes: const [],
      cards: const [],
      events: const [],
      passives: const [],
      relics: const [],
      forgeUpgrades: const [
        ForgeUpgradeData(
          id: 'test_rune',
          nameEn: 'Test',
          nameFr: 'Test',
          descriptionEn: '',
          descriptionFr: '',
          icon: '',
          color: '',
          pools: ['common'],
          emoji: '🧪',
        ),
      ],
    );

    await _pumpCard(
      tester,
      CardInstance(
        data: _cardData(CardRarity.common),
        forgeUpgrades: const ['test_rune'],
      ),
    );

    Finder inSockets(String emoji) => find.descendant(
          of: find.byType(CardRuneSockets),
          matching: find.text(emoji),
        );
    expect(inSockets('🔮'), findsOneWidget);
    expect(inSockets('🧪'), findsNothing);
  });
}
