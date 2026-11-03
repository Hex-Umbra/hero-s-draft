import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/proportional_status.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card/card_compact_description.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card/card_cost_medallion.dart';

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
  setUpAll(() => shippedRuneRegistry(
      const ['enduring', 'quick', 'sharp', 'spectral']));

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

  testWidgets('l infobulle ecrit Tranchant au niveau qu il joue',
      (tester) async {
    await _pumpCard(
      tester,
      CardInstance(
        data: shippedCard('strike_basic'),
        rarity: CardRarity.legendary,
        forgeUpgrades: const ['sharp:2'],
      ),
    );

    expect(
      _tooltip(tester),
      contains('Tranchant 2 : +4 Dégâts sur la carte (+30% de la base, au '
          'moins +2)'),
    );
  });

  testWidgets('l infobulle dit le bareme de Faiblesse, Vulnerable et Gel',
      (tester) async {
    await _pumpCard(
      tester,
      CardInstance(
        data: const CardData(
          id: 'test_statuts',
          cost: 1,
          type: CardType.skill,
          rarity: CardRarity.common,
          target: CardTarget.singleEnemy,
          effects: [
            CardEffect(
                type: 'apply_status', value: 1, statusId: 'weakness', duration: 1),
            CardEffect(
                type: 'apply_status',
                value: 1,
                statusId: 'vulnerable',
                duration: 1),
            CardEffect(
                type: 'apply_status', value: 1, statusId: 'freeze', duration: 1),
          ],
        ),
      ),
    );

    final l10n = AppLocalizations.of(tester.element(find.byType(UiCard)))!;
    const weakness = ProportionalStatus.weakness;
    const vulnerable = ProportionalStatus.vulnerable;
    const freeze = ProportionalStatus.freeze;
    final tooltip = _tooltip(tester);
    expect(
      tooltip,
      contains(
          '(${l10n.statusWeaknessHint(weakness.percentPerPoint, weakness.maxPercent)})'),
    );
    expect(
      tooltip,
      contains(
          '(${l10n.statusVulnerableHint(vulnerable.percentPerPoint, vulnerable.maxPercent)})'),
    );
    expect(
      tooltip,
      contains(
          '(${l10n.statusFreezeHint(freeze.percentPerPoint, freeze.maxPercent)})'),
    );
    expect(tooltip, isNot(contains('25%')));
    expect(tooltip, isNot(contains('50%')));
  });

  testWidgets('deux Tranchant 1 font une seule ligne, au niveau total',
      (tester) async {
    await _pumpCard(
      tester,
      CardInstance(
        data: shippedCard('strike_basic'),
        rarity: CardRarity.epic,
        forgeUpgrades: const ['sharp:1', 'sharp:1'],
      ),
    );

    final tooltip = _tooltip(tester);
    expect(
      tooltip,
      contains('Tranchant 2 : +3 Dégâts sur la carte (+30% de la base, au '
          'moins +2)'),
    );
    expect('Tranchant'.allMatches(tooltip), hasLength(1));
  });

  testWidgets('une rune a niveau unique s ecrit sans niveau', (tester) async {
    await _pumpCard(
      tester,
      CardInstance(
        data: shippedCard('strike_basic'),
        forgeUpgrades: const ['quick:1'],
      ),
    );

    final tooltip = _tooltip(tester);
    expect(tooltip, contains('Véloce : Pioche +1 carte(s)'));
    expect(tooltip, isNot(contains('Véloce 1')));
  });

  // Spec P-43 E2, §5.7 : l'en-tete nomme les runes, plus la forge.
  testWidgets('l infobulle ouvre les runes par leur nom', (tester) async {
    await _pumpCard(
      tester,
      CardInstance(
        data: shippedCard('strike_basic'),
        forgeUpgrades: const ['quick:1'],
      ),
    );

    final tooltip = _tooltip(tester);
    expect(tooltip, contains('⚙️ Runes :'));
    expect(tooltip, isNot(contains('Upgrades')));
  });

  // Les cartes de ce groupe sont construites : aucune carte livree ne porte
  // encore de cout combine, de coups ni de croissance.
  CardData built({
    int cost = 1,
    int hp = 0,
    int armor = 0,
    CardType type = CardType.attack,
    CardTarget target = CardTarget.singleEnemy,
    required List<CardEffect> effects,
  }) =>
      CardData(
        id: 'test_rendu',
        cost: cost,
        hpCost: hp,
        armorCost: armor,
        type: type,
        rarity: CardRarity.common,
        target: target,
        effects: effects,
      );

  Finder medallionText(String text) => find.descendant(
        of: find.byType(CardCostMedallion),
        matching: find.text(text),
      );

  testWidgets(
      'une carte a 1 mana et 6 Armure montre deux medaillons, une a 0 mana '
      'et 4 PV aussi', (tester) async {
    await _pumpCard(
      tester,
      CardInstance(
        data: built(
          cost: 1,
          armor: 6,
          type: CardType.skill,
          effects: const [CardEffect(type: 'armor', value: 6)],
        ),
      ),
    );
    expect(find.byType(CardCostMedallion), findsNWidgets(2));
    expect(medallionText('1'), findsOneWidget);
    expect(medallionText('6'), findsOneWidget);

    await _pumpCard(
      tester,
      CardInstance(
        data: built(
          cost: 0,
          hp: 4,
          effects: const [CardEffect(type: 'damage', value: 9)],
        ),
      ),
    );
    expect(find.byType(CardCostMedallion), findsNWidgets(2));
    expect(medallionText('0'), findsOneWidget);
    expect(medallionText('4'), findsOneWidget);
  });

  testWidgets('un multi-coups montre valeur×coups', (tester) async {
    await _pumpCard(
      tester,
      CardInstance(
        data: built(
          type: CardType.skill,
          effects: const [
            CardEffect(
                type: 'apply_status', value: 1, statusId: 'shock', duration: 2),
            CardEffect(type: 'damage', value: 3, hits: 3, mightRatio: 0.5),
          ],
        ),
      ),
    );

    expect(_body('3×3'), findsOneWidget);
  });

  testWidgets('l infobulle dit les couts en PV et en Armure', (tester) async {
    await _pumpCard(
      tester,
      CardInstance(
        data: built(
          cost: 1,
          hp: 3,
          armor: 2,
          effects: const [CardEffect(type: 'damage', value: 6)],
        ),
      ),
    );

    final l10n = AppLocalizations.of(tester.element(find.byType(UiCard)))!;
    expect(
      _tooltip(tester),
      allOf(contains(l10n.cardCostHp(3)), contains(l10n.cardCostArmor(2))),
    );
  });

  testWidgets('l infobulle dit les coups et la croissance', (tester) async {
    await _pumpCard(
      tester,
      CardInstance(
        data: built(
          type: CardType.skill,
          effects: const [
            CardEffect(type: 'damage', value: 3, hits: 3, mightRatio: 0.5),
          ],
        ),
      ),
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(UiCard)))!;
    expect(_tooltip(tester), contains(l10n.cardDescDamageHits(3, 3)));

    await _pumpCard(
      tester,
      CardInstance(
        data: built(
          type: CardType.skill,
          target: CardTarget.self,
          effects: const [
            CardEffect(
              type: 'armor',
              value: 6,
              scaleWith: ScaleWith(source: ScaleSource.armor, ratio: 0.2),
            ),
          ],
        ),
      ),
    );
    expect(_tooltip(tester), contains('(${l10n.cardScaleArmorPer(5)})'));

    await _pumpCard(
      tester,
      CardInstance(
        data: built(
          effects: const [
            CardEffect(
              type: 'damage',
              value: 2,
              scaleWith: ScaleWith(source: ScaleSource.armor, ratio: 1),
            ),
          ],
        ),
      ),
    );
    expect(_tooltip(tester), contains(l10n.cardScaleArmor('1')));
  });

  // Le badge dit la regle que joue le moteur (spec P-43 E2, A13).
  group('le badge Usage unique', () {
    testWidgets('une carte Spectrale le montre', (tester) async {
      await _pumpCard(
        tester,
        CardInstance(
          data: shippedCard('strike_basic'),
          rarity: CardRarity.uncommon,
          forgeUpgrades: const ['spectral:1'],
        ),
      );
      expect(find.text('USAGE UNIQUE'), findsOneWidget);
    });

    testWidgets('une Potion de Soin Persistante ne le montre plus',
        (tester) async {
      await _pumpCard(
        tester,
        CardInstance(
          data: shippedCard('heal_potion'),
          rarity: CardRarity.uncommon,
          forgeUpgrades: const ['enduring:1'],
        ),
      );
      expect(find.text('USAGE UNIQUE'), findsNothing);
    });
  });
}
