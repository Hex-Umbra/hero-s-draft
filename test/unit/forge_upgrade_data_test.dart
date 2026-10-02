import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

/// Un fichier de rune minimal et valide : chaque test n'y change que ce qu'il
/// veut casser.
Map<String, dynamic> _json([Map<String, dynamic> overrides = const {}]) => {
      'id': 'sharp',
      'pools': ['common'],
      'maxLevel': null,
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

  group('maxLevel', () {
    test('null : sans plafond ; un entier : le plafond', () {
      expect(ForgeUpgradeData.fromJson(_json()).maxLevel, isNull);
      expect(ForgeUpgradeData.fromJson(_json({'maxLevel': 1})).maxLevel, 1);
    });

    test('refuse une rune sans maxLevel', () {
      expect(() => ForgeUpgradeData.fromJson(_json()..remove('maxLevel')),
          _refused('maxLevel'));
    });

    test('refuse un maxLevel nul, negatif ou decimal', () {
      for (final bad in [0, -1, 1.5]) {
        expect(() => ForgeUpgradeData.fromJson(_json({'maxLevel': bad})),
            _refused('maxLevel'),
            reason: '$bad');
      }
    });

    test('toJson ecrit maxLevel, meme nul', () {
      expect(ForgeUpgradeData.fromJson(_json()).toJson(),
          containsPair('maxLevel', null));
      final capped = ForgeUpgradeData.fromJson(_json({'maxLevel': 2}));
      expect(ForgeUpgradeData.fromJson(capped.toJson()).maxLevel, 2);
    });
  });

  // Review Focus 3 : une sauvegarde peut porter une rune que le catalogue n'a
  // plus.
  test('tooltipLines : une ligne par id au niveau total, rien pour une rune '
      'absente du registre', () {
    GameDataRegistry(
      enemies: const [],
      heroes: const [],
      cards: const [],
      events: const [],
      passives: const [],
      relics: const [],
      forgeUpgrades: [
        ForgeUpgradeData.fromJson(_json(
            {'name_fr': 'Tranchant', 'description_fr': '+{val} Dégâts'})),
      ],
    );
    const strike = CardData(
      id: 'strike_basic',
      cost: 1,
      type: CardType.attack,
      category: CardCategory.global,
      rarity: CardRarity.common,
      target: CardTarget.singleEnemy,
      effects: [CardEffect(type: 'damage', value: 6)],
    );

    expect(
      ForgeUpgradeData.tooltipLines(const ['sharp:1', 'legacy:2', 'sharp:2'],
          'fr', strike, CardRarity.common),
      ['Tranchant 3 : +3 Dégâts'],
    );
  });

  group('eligibilite', () {
    test('lit les champs d eligibilite', () {
      final rune = ForgeUpgradeData.fromJson(_json({
        'eligibleEffects': ['damage'],
        'excludesEffects': ['draw'],
        'requiresMinCost': 1,
        'excludesRunes': ['eco'],
      }));
      expect(rune.eligibleEffects, ['damage']);
      expect(rune.excludesEffects, ['draw']);
      expect(rune.requiresMinCost, 1);
      expect(rune.excludesRunes, ['eco']);
    });

    test('absents : toute carte, aucune exclusion, aucun cout minimal', () {
      final rune = ForgeUpgradeData.fromJson(_json());
      expect(rune.eligibleEffects, isNull);
      expect(rune.excludesEffects, isEmpty);
      expect(rune.requiresMinCost, 0);
      expect(rune.excludesRunes, isEmpty);
    });

    test('refuse eligibleEffects vide, eligible a rien', () {
      expect(() => ForgeUpgradeData.fromJson(_json({'eligibleEffects': []})),
          _refused('eligibleEffects'));
    });

    test('accepte excludesEffects vide : aucune exclusion', () {
      expect(
        ForgeUpgradeData.fromJson(_json({'excludesEffects': []}))
            .excludesEffects,
        isEmpty,
      );
    });

    test('refuse un requiresMinCost negatif ou non entier', () {
      for (final bad in [-1, 1.5]) {
        expect(() => ForgeUpgradeData.fromJson(_json({'requiresMinCost': bad})),
            _refused('requiresMinCost'),
            reason: '$bad');
      }
    });

    test('refuse excludesRunes vide', () {
      expect(() => ForgeUpgradeData.fromJson(_json({'excludesRunes': []})),
          _refused('excludesRunes'));
    });

    test('refuse son propre id dans excludesRunes', () {
      expect(
        () => ForgeUpgradeData.fromJson(_json({
          'excludesRunes': ['eco', 'sharp'],
        })),
        _refused('excludesRunes'),
      );
    });

    test('toJson fait l aller-retour des champs d eligibilite', () {
      final rune = ForgeUpgradeData.fromJson(_json({
        'eligibleEffects': ['armor'],
        'excludesEffects': ['gain_mana', 'draw'],
        'requiresMinCost': 1,
        'excludesRunes': ['quick'],
      }));
      final restored = ForgeUpgradeData.fromJson(rune.toJson());
      expect(restored.eligibleEffects, ['armor']);
      expect(restored.excludesEffects, ['gain_mana', 'draw']);
      expect(restored.requiresMinCost, 1);
      expect(restored.excludesRunes, ['quick']);
    });
  });

  group('boundLevel', () {
    final uncapped = ForgeUpgradeData.fromJson(_json());
    final capped = ForgeUpgradeData.fromJson(_json({'maxLevel': 2}));

    test('sans plafond : la demande', () {
      expect(uncapped.boundLevel(3), 3);
      expect(uncapped.boundLevel(3, carried: 5), 3);
    });

    test('un plafond borne la demande', () {
      expect(capped.boundLevel(1), 1);
      expect(capped.boundLevel(3), 2);
    });

    test('ce que la carte porte deja compte', () {
      expect(capped.boundLevel(3, carried: 1), 1);
      expect(capped.boundLevel(1, carried: 2), 0);
    });

    // Review Focus 2 : une sauvegarde d'avant 0.5.3 peut porter plus que le
    // plafond.
    test('jamais negatif', () {
      expect(capped.boundLevel(1, carried: 3), 0);
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
