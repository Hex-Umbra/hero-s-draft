import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
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

CardData _cardData(CardRarity rarity, int baseMaxForgeUpgrades) => CardData(
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
      baseMaxForgeUpgrades: baseMaxForgeUpgrades,
    );

void main() {
  testWidgets('une carte de classe affiche 5 emplacements de rune, pas 10', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester, CardInstance(data: _cardData(CardRarity.unique, 5)));

    expect(_socketCount(tester), 5);
  });

  testWidgets('une carte globale legendaire affiche 5 emplacements', (
    WidgetTester tester,
  ) async {
    await _pumpCard(
      tester,
      CardInstance(data: _cardData(CardRarity.common, 1), rarity: CardRarity.legendary),
    );

    expect(_socketCount(tester), 5);
  });
}
