import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

import 'shipped_data.dart';

/// Refuse un chargement en nommant [key] (spec P-44 lot 1, §3.1).
Matcher _refuses(String key) => throwsA(
      isA<FormatException>().having((e) => e.message, 'message', contains(key)),
    );

CardData _card(List<CardEffect> effects, {CardRarity rarity = CardRarity.common}) =>
    CardData(
      id: 'test',
      cost: 1,
      type: CardType.attack,
      rarity: rarity,
      target: CardTarget.singleEnemy,
      effects: effects,
    );

void main() {
  group('chargement', () {
    test('hits et mightRatio absents valent 1', () {
      final effect = CardEffect.fromJson({'type': 'damage', 'value': 3});
      expect(effect.hits, 1);
      expect(effect.mightRatio, 1.0);
      expect(effect.scaleWith, isNull);
    });

    test('hits sous 1 ou non entier est refuse, nomme', () {
      for (final hits in [0, 1.5]) {
        expect(
          () => CardEffect.fromJson(
              {'type': 'damage', 'value': 3, 'hits': hits}),
          _refuses('hits'),
        );
      }
    });

    test('mightRatio hors de ]0, 1] est refuse, nomme', () {
      for (final ratio in [0, -0.5, 1.5]) {
        expect(
          () => CardEffect.fromJson(
              {'type': 'damage', 'value': 3, 'mightRatio': ratio}),
          _refuses('mightRatio'),
        );
      }
      for (final ratio in [1, 0.5]) {
        expect(
          CardEffect.fromJson(
              {'type': 'damage', 'value': 3, 'mightRatio': ratio}).mightRatio,
          ratio.toDouble(),
        );
      }
    });

    test('hits et mightRatio sur un effet autre que damage sont refuses', () {
      expect(
        () => CardEffect.fromJson({'type': 'armor', 'value': 2, 'hits': 2}),
        _refuses('hits'),
      );
      expect(
        () => CardEffect.fromJson(
            {'type': 'heal', 'value': 2, 'mightRatio': 0.5}),
        _refuses('mightRatio'),
      );
    });

    test(
        'toJson n ecrit hits et mightRatio que hors de leur defaut ; '
        'l aller-retour les garde', () {
      final plain = CardEffect.fromJson({'type': 'damage', 'value': 3});
      expect(plain.toJson().containsKey('hits'), isFalse);
      expect(plain.toJson().containsKey('mightRatio'), isFalse);

      final multi = CardEffect.fromJson(
          {'type': 'damage', 'value': 3, 'hits': 3, 'mightRatio': 0.5});
      final back = CardEffect.fromJson(multi.toJson());
      expect(back.value, 3);
      expect(back.hits, 3);
      expect(back.mightRatio, 0.5);
    });
  });

  group('la vue jouee', () {
    setUp(() => shippedRuneRegistry(const ['sharp']));

    test(
        'une carte epique garde ses coups, son mightRatio et son scaleWith '
        'par card.effective', () {
      final card = CardInstance(
        data: _card(
          const [
            CardEffect(type: 'damage', value: 3, hits: 3, mightRatio: 0.5),
            CardEffect(
              type: 'armor',
              value: 2,
              scaleWith:
                  ScaleWith(source: ScaleSource.armor, ratio: 0.2),
            ),
          ],
          rarity: CardRarity.epic,
        ),
      );
      final effects = card.effective.effects;
      expect(effects[0].value, 6);
      expect(effects[0].hits, 3);
      expect(effects[0].mightRatio, 0.5);
      expect(effects[1].value, 5);
      expect(effects[1].scaleWith!.source, ScaleSource.armor);
      expect(effects[1].scaleWith!.ratio, 0.2);
    });

    test('A14 : Tranchant 1 sur 3 x 3 donne +1 par coup', () {
      final card = CardInstance(
        data: _card(const [
          CardEffect(type: 'damage', value: 3, hits: 3, mightRatio: 0.5),
        ]),
        forgeUpgrades: const ['sharp:1'],
      );
      final effect = card.effective.effects.single;
      expect(effect.value, 4);
      expect(effect.hits, 3);
    });

    test('A14 : Tranchant 5 sur 3 x 3 donne +3 par coup, pas +5', () {
      final card = CardInstance(
        data: _card(const [
          CardEffect(type: 'damage', value: 3, hits: 3, mightRatio: 0.5),
        ]),
        forgeUpgrades: const ['sharp:5'],
      );
      expect(card.effective.effects.single.value, 6);
    });
  });
}
