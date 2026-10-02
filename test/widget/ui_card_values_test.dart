import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card/card_compact_description.dart';

import '../unit/shipped_data.dart';

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

/// Le texte de l'infobulle de la carte.
String _tooltip(WidgetTester tester) =>
    tester.widget<Tooltip>(find.byType(Tooltip)).richMessage!.toPlainText();

/// Un texte du corps de la carte.
Finder _body(String text) => find.descendant(
      of: find.byType(CardCompactDescription),
      matching: find.text(text),
    );

/// Les rendus Flutter de la carte lisent l'applicateur : ce qu'ils montrent
/// est ce que le moteur joue (spec P-43 E1, §4.2).
void main() {
  setUpAll(() => shippedRuneRegistry(const ['sharp']));

  testWidgets('une Frappe legendaire portant Tranchant 2 montre 16 degats',
      (tester) async {
    await _pumpCard(
      tester,
      CardInstance(
        data: shippedCard('strike_basic'),
        rarity: CardRarity.legendary,
        forgeUpgrades: const ['sharp:2'],
      ),
    );

    expect(_tooltip(tester), contains('Inflige 16 dégâts.'));
    expect(_body('12'), findsOneWidget);
    expect(_body(' +4🔨'), findsOneWidget);
  });

  testWidgets('une Frappe epique portant deux Tranchant 1 montre 13 degats',
      (tester) async {
    // 10 a la rarete, et le bonus du niveau total 2 : +3, pas deux fois +2.
    await _pumpCard(
      tester,
      CardInstance(
        data: shippedCard('strike_basic'),
        rarity: CardRarity.epic,
        forgeUpgrades: const ['sharp:1', 'sharp:1'],
      ),
    );

    expect(_tooltip(tester), contains('Inflige 13 dégâts.'));
    expect(_body('10'), findsOneWidget);
    expect(_body(' +3🔨'), findsOneWidget);
  });

  testWidgets('un Eveil epique montre 7 Armure et pioche 1 carte',
      (tester) async {
    await _pumpCard(
      tester,
      CardInstance(data: shippedCard('awakening'), rarity: CardRarity.epic),
    );

    expect(_tooltip(tester),
        allOf(contains('Donne 7 Armure.'), contains('Pioche 1 cartes.')));
    expect(_body('7'), findsOneWidget);
    expect(_body('1'), findsOneWidget);
  });
}
