import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/signature_data.dart';
import 'package:roguelike_card_game/ui/widgets/signature_tile.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card/ui_card_helpers.dart';

const _classColor = Color(0xFF2196F3);

SignatureData _smite({int cooldown = 2, CardType type = CardType.attack}) =>
    SignatureData(
      id: 'smite',
      heroClass: 'paladin',
      nameEn: 'Smite',
      nameFr: 'Châtiment',
      descriptionEn: 'Deal 6 damage and gain 4 Block.',
      descriptionFr: "Inflige 6 dégâts et donne 4 d'Armure.",
      cost: 1,
      cooldown: cooldown,
      type: type,
      effects: const [],
    );

Future<void> _pump(
  WidgetTester tester,
  SignatureData signature, {
  String locale = 'en',
  bool detailed = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('fr', '')],
      locale: Locale(locale),
      home: Scaffold(
        body: SignatureTile(
          signature: signature,
          classColor: _classColor,
          detailed: detailed,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'la tuile compacte montre le nom, la ligne cout et recharge, la description',
    (tester) async {
      await _pump(tester, _smite());

      expect(find.text('Smite'), findsOneWidget);
      expect(find.text('Cost: 1 Mana · Cooldown: 2 turns'), findsOneWidget);
      expect(find.text('Deal 6 damage and gain 4 Block.'), findsOneWidget);
    },
  );

  testWidgets(
    'en francais la ligne dit Cout et Recharge, au singulier pour un tour',
    (tester) async {
      await _pump(tester, _smite(), locale: 'fr');
      expect(find.text('Coût : 1 Mana · Recharge : 2 tours'), findsOneWidget);

      await _pump(tester, _smite(cooldown: 1), locale: 'fr');
      expect(find.text('Coût : 1 Mana · Recharge : 1 tour'), findsOneWidget);
    },
  );

  testWidgets('la tuile detaillee montre aussi le type de la signature', (
    tester,
  ) async {
    await _pump(tester, _smite(), detailed: true);
    expect(find.text('Attack'), findsOneWidget);

    await _pump(tester, _smite());
    expect(find.text('Attack'), findsNothing);
  });

  testWidgets('le fond est neutre quel que soit le type, sans liseré', (
    tester,
  ) async {
    for (final type in [CardType.attack, CardType.skill]) {
      for (final detailed in [false, true]) {
        await _pump(tester, _smite(type: type), detailed: detailed);

        final tile = tester
            .widgetList<Container>(find.byType(Container))
            .map((c) => c.decoration)
            .whereType<BoxDecoration>()
            .firstWhere((d) => d.border?.top.color == _classColor);
        expect(tile.color, neutralCardBackground);

        final stripes = tester
            .widgetList<ColoredBox>(find.byType(ColoredBox))
            .map((b) => b.color)
            .where((c) => c == Colors.redAccent || c == Colors.blueAccent);
        expect(stripes, isEmpty);
      }
    }
  });

  testWidgets('la bordure porte la couleur de la classe', (tester) async {
    await _pump(tester, _smite());

    final borderColors = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.border?.top.color)
        .toList();
    expect(borderColors, contains(_classColor));
  });
}
