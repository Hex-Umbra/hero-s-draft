import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/signature_data.dart';

/// Refuse un chargement en nommant [key] (spec P-44 lot 1, §3.1).
Matcher _refuses(String key) => throwsA(
      isA<FormatException>().having((e) => e.message, 'message', contains(key)),
    );

Map<String, dynamic> _effect(Map<String, dynamic> scaleWith,
        {String type = 'armor', Map<String, dynamic> extra = const {}}) =>
    {'type': type, 'value': 2, 'scaleWith': scaleWith, ...extra};

Map<String, dynamic> _card(String target, Map<String, dynamic> scaleWith) => {
      'id': 'test',
      'cost': 1,
      'type': 'attack',
      'rarity': 'common',
      'target': target,
      'effects': [_effect(scaleWith, type: 'damage')],
    };

void main() {
  group('chargement', () {
    test('scaleWith se lit : source, ratio, statusId', () {
      final card = CardData.fromJson(_card('singleEnemy', {
        'source': 'targetStatus',
        'ratio': 1,
        'statusId': 'poison',
      }));
      final scale = card.effects.single.scaleWith!;
      expect(scale.source, ScaleSource.targetStatus);
      expect(scale.ratio, 1.0);
      expect(scale.statusId, 'poison');
    });

    test('ratio 0,3 est refuse ; 0,2, 0,1, 1 et 1,5 sont acceptes', () {
      expect(
        () => CardEffect.fromJson(
            _effect({'source': 'armor', 'ratio': 0.3})),
        _refuses('ratio'),
      );
      for (final ratio in [0.2, 0.1, 1, 1.5]) {
        expect(
          CardEffect.fromJson(_effect({'source': 'armor', 'ratio': ratio}))
              .scaleWith!
              .ratio,
          ratio.toDouble(),
        );
      }
    });

    test('ratio nul ou negatif est refuse', () {
      for (final ratio in [0, -1]) {
        expect(
          () => CardEffect.fromJson(
              _effect({'source': 'armor', 'ratio': ratio})),
          _refuses('ratio'),
        );
      }
    });

    test('source inconnue est refusee, nommee', () {
      expect(
        () => CardEffect.fromJson(_effect({'source': 'block', 'ratio': 1})),
        _refuses('scaleWith.source'),
      );
    });

    test('statusId exige pour targetStatus, refuse ailleurs', () {
      expect(
        () => CardEffect.fromJson(
            _effect({'source': 'targetStatus', 'ratio': 1})),
        _refuses('statusId'),
      );
      expect(
        () => CardEffect.fromJson(_effect(
            {'source': 'armor', 'ratio': 1, 'statusId': 'poison'})),
        _refuses('statusId'),
      );
    });

    test('scaleWith refuse sur draw et gain_mana, et sur un effet a hits 2',
        () {
      const scale = {'source': 'armor', 'ratio': 1};
      for (final type in ['draw', 'gain_mana']) {
        expect(
          () => CardEffect.fromJson(_effect(scale, type: type)),
          _refuses('scaleWith'),
        );
      }
      expect(
        () => CardEffect.fromJson(
            _effect(scale, type: 'damage', extra: {'hits': 2})),
        _refuses('scaleWith'),
      );
    });

    test('targetStatus et targetMissingHp refuses hors d une cible unique', () {
      const status = {
        'source': 'targetStatus',
        'ratio': 1,
        'statusId': 'poison',
      };
      const missing = {'source': 'targetMissingHp', 'ratio': 1};
      expect(
        () => CardData.fromJson(_card('allEnemies', status)),
        _refuses('scaleWith.source'),
      );
      expect(
        () => CardData.fromJson(_card('self', missing)),
        _refuses('scaleWith.source'),
      );
      expect(
        () => SignatureData.fromJson({
          'id': 'sig',
          'heroClass': 'mage',
          'name_en': 'Sig',
          'name_fr': 'Sig',
          'description_en': 'Sig',
          'description_fr': 'Sig',
          'cost': 1,
          'cooldown': 1,
          'type': 'attack',
          'target': 'allEnemies',
          'effects': [_effect(status, type: 'damage')],
        }),
        _refuses('scaleWith.source'),
      );
    });

    test('toJson ecrit scaleWith, et l aller-retour le garde', () {
      final effect = CardEffect.fromJson(_effect({
        'source': 'targetStatus',
        'ratio': 0.5,
        'statusId': 'poison',
      }, type: 'damage'));
      final back = CardEffect.fromJson(effect.toJson()).scaleWith!;
      expect(back.source, ScaleSource.targetStatus);
      expect(back.ratio, 0.5);
      expect(back.statusId, 'poison');
    });
  });
}
