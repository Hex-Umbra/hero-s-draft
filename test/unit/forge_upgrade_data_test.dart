import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';

/// Un fichier de rune minimal et valide : chaque test n'y change que ce qu'il
/// veut casser.
Map<String, dynamic> _json([Map<String, dynamic> overrides = const {}]) => {
      'id': 'sharp',
      'pools': ['common'],
      'deltas': [
        {'type': 'percentBonus', 'effect': 'damage', 'valuePercentPerLevel': 15},
      ],
      ...overrides,
    };

Matcher _refused(String fragment) => throwsA(
      isA<FormatException>()
          .having((e) => e.message, 'message', contains(fragment)),
    );

/// Le modèle de rune (spec P-43 E1, §3.1, §3.3).
void main() {
  group('deltas', () {
    test('lit les trois sortes', () {
      final rune = ForgeUpgradeData.fromJson(_json({
        'deltas': [
          {'type': 'percentBonus', 'effect': 'armor', 'valuePercentPerLevel': 15},
          {
            'type': 'addEffect',
            'effect': 'apply_status',
            'valuePerLevel': 1,
            'statusId': 'burn',
            'durationPerLevel': 1,
          },
          {'type': 'removeExhaust'},
        ],
      }));

      final [percent, added, removed] = rune.deltas;
      expect(
        percent,
        isA<PercentBonusDelta>()
            .having((d) => d.effect, 'effect', 'armor')
            .having((d) => d.valuePercentPerLevel, 'valuePercentPerLevel', 15),
      );
      expect(
        added,
        isA<AddEffectDelta>()
            .having((d) => d.effect, 'effect', 'apply_status')
            .having((d) => d.valuePerLevel, 'valuePerLevel', 1)
            .having((d) => d.statusId, 'statusId', 'burn')
            .having((d) => d.durationPerLevel, 'durationPerLevel', 1),
      );
      expect(removed, isA<RemoveExhaustDelta>());
    });

    test('refuse une rune sans deltas', () {
      expect(() => ForgeUpgradeData.fromJson(_json()..remove('deltas')),
          _refused('deltas'));
    });

    test('refuse une liste de deltas vide', () {
      expect(() => ForgeUpgradeData.fromJson(_json({'deltas': []})),
          _refused('deltas'));
    });

    test('refuse un type inconnu', () {
      expect(
        () => ForgeUpgradeData.fromJson(_json({
          'deltas': [
            {'type': 'bonus'},
          ],
        })),
        _refused('bonus'),
      );
    });

    test('refuse un pourcentage sans effet vise', () {
      expect(
        () => ForgeUpgradeData.fromJson(_json({
          'deltas': [
            {'type': 'percentBonus', 'valuePercentPerLevel': 15},
          ],
        })),
        _refused('effect'),
      );
    });

    test('refuse un pourcentage nul ou negatif', () {
      for (final percent in [0, -15]) {
        expect(
          () => ForgeUpgradeData.fromJson(_json({
            'deltas': [
              {
                'type': 'percentBonus',
                'effect': 'damage',
                'valuePercentPerLevel': percent,
              },
            ],
          })),
          _refused('valuePercentPerLevel'),
          reason: '$percent',
        );
      }
    });

    test('refuse un apply_status sans statusId', () {
      expect(
        () => ForgeUpgradeData.fromJson(_json({
          'deltas': [
            {
              'type': 'addEffect',
              'effect': 'apply_status',
              'valuePerLevel': 1,
              'durationPerLevel': 1,
            },
          ],
        })),
        _refused('statusId'),
      );
    });

    test('refuse un apply_status sans durationPerLevel', () {
      expect(
        () => ForgeUpgradeData.fromJson(_json({
          'deltas': [
            {
              'type': 'addEffect',
              'effect': 'apply_status',
              'valuePerLevel': 1,
              'statusId': 'burn',
            },
          ],
        })),
        _refused('durationPerLevel'),
      );
    });

    test('refuse statusId ou durationPerLevel sur un autre type d effet', () {
      for (final extra in [
        {'statusId': 'burn'},
        {'durationPerLevel': 1},
      ]) {
        expect(
          () => ForgeUpgradeData.fromJson(_json({
            'deltas': [
              {
                'type': 'addEffect',
                'effect': 'draw',
                'valuePerLevel': 1,
                ...extra,
              },
            ],
          })),
          _refused('apply_status'),
          reason: '$extra',
        );
      }
    });

    test('toJson fait l aller-retour', () {
      final rune = ForgeUpgradeData.fromJson(_json({
        'deltas': [
          {
            'type': 'addEffect',
            'effect': 'apply_status',
            'valuePerLevel': 1,
            'statusId': 'shock',
            'durationPerLevel': 1,
          },
          {'type': 'addEffect', 'effect': 'draw', 'valuePerLevel': 1},
          {'type': 'removeExhaust'},
        ],
      }));

      final restored = ForgeUpgradeData.fromJson(rune.toJson());
      expect(
        [for (final delta in restored.deltas) delta.toJson()],
        [for (final delta in rune.deltas) delta.toJson()],
      );
    });
  });

  group('references id:niveau', () {
    test('parseRef lit une reference, ou rien', () {
      expect(ForgeUpgradeData.parseRef('sharp:2'), ('sharp', 2));
      for (final bad in ['sharp', 'sharp:0', 'sharp:-1', 'sharp:x', 'sharp:1:2']) {
        expect(ForgeUpgradeData.parseRef(bad), isNull, reason: bad);
      }
    });

    test('levelsOf additionne les exemplaires dans l ordre de premiere '
        'apparition', () {
      final levels = ForgeUpgradeData.levelsOf(
          const ['quick:1', 'sharp:1', 'quick:2', 'sharp:2']);
      expect(levels.entries.map((e) => (e.key, e.value)),
          [('quick', 3), ('sharp', 3)]);
    });

    test('levelsOf ignore une reference mal formee ou de niveau nul', () {
      expect(
        ForgeUpgradeData.levelsOf(const ['sharp', 'sharp:0', 'sharp:x', 'eco:1']),
        {'eco': 1},
      );
    });
  });
}
