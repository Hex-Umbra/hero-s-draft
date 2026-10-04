import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

import 'shipped_data.dart';

/// Un fichier de rune minimal et valide : chaque test n'y change que ce qu'il
/// veut casser.
Map<String, dynamic> _json([Map<String, dynamic> overrides = const {}]) => {
      'id': 'sharp',
      'minFusionRank': 1,
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

    test('lit les trois sortes neuves', () {
      final rune = ForgeUpgradeData.fromJson(_json({
        'deltas': [
          {'type': 'reduceCost', 'valuePerLevel': 1},
          {'type': 'critBonus', 'valuePerLevel': 5},
          {'type': 'addExhaust'},
        ],
      }));

      final [cut, crit, exhaust] = rune.deltas;
      expect(cut, isA<ReduceCostDelta>().having((d) => d.valuePerLevel, 'valuePerLevel', 1));
      expect(crit, isA<CritBonusDelta>().having((d) => d.valuePerLevel, 'valuePerLevel', 5));
      expect(exhaust, isA<AddExhaustDelta>());
    });

    test('refuse un reduceCost ou un critBonus sans valuePerLevel strictement '
        'positif', () {
      for (final type in ['reduceCost', 'critBonus']) {
        for (final bad in [
          <String, dynamic>{},
          {'valuePerLevel': 0},
          {'valuePerLevel': -1},
        ]) {
          expect(
            () => ForgeUpgradeData.fromJson(_json({
              'deltas': [
                {'type': type, ...bad},
              ],
            })),
            _refused('valuePerLevel'),
            reason: '$type $bad',
          );
        }
      }
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

    test('toJson fait l aller-retour des sortes neuves', () {
      const deltas = [
        {'type': 'reduceCost', 'valuePerLevel': 1},
        {'type': 'critBonus', 'valuePerLevel': 5},
        {'type': 'addExhaust'},
      ];
      final rune = ForgeUpgradeData.fromJson(_json({'deltas': deltas}));
      expect(
        [
          for (final delta
              in ForgeUpgradeData.fromJson(rune.toJson()).deltas)
            delta.toJson(),
        ],
        deltas,
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

  // Spec P-43 E2, A8 : la cle est obligatoire, un entier d'au moins 1.
  group('minFusionRank', () {
    test('lu dans le fichier ; 1 au constructeur', () {
      expect(
        ForgeUpgradeData.fromJson(_json({'minFusionRank': 2})).minFusionRank,
        2,
      );
      expect(
        const ForgeUpgradeData(
          id: 'x',
          nameEn: 'x',
          nameFr: 'x',
          descriptionEn: '',
          descriptionFr: '',
          icon: '',
          color: '',
        ).minFusionRank,
        1,
      );
    });

    test('refuse une rune sans minFusionRank', () {
      expect(() => ForgeUpgradeData.fromJson(_json()..remove('minFusionRank')),
          _refused('minFusionRank'));
    });

    test('refuse un minFusionRank nul, negatif, decimal ou null', () {
      for (final bad in [0, -1, 1.5, null]) {
        expect(() => ForgeUpgradeData.fromJson(_json({'minFusionRank': bad})),
            _refused('minFusionRank'),
            reason: '$bad');
      }
    });

    test('toJson ecrit minFusionRank', () {
      final rune = ForgeUpgradeData.fromJson(_json({'minFusionRank': 2}));
      expect(rune.toJson(), containsPair('minFusionRank', 2));
      expect(ForgeUpgradeData.fromJson(rune.toJson()).minFusionRank, 2);
    });
  });

  // Spec P-43 E2, §4.11 : les cles que le modele ne lit plus ne s'ecrivent
  // plus.
  test('toJson n ecrit que les cles du modele', () {
    expect(ForgeUpgradeData.fromJson(_json()).toJson().keys.toSet(), {
      'id',
      'name_en',
      'name_fr',
      'description_en',
      'description_fr',
      'icon',
      'color',
      'minFusionRank',
      'requiresExhaust',
      'requiresMinCost',
      'maxLevel',
      'binary',
      'deltas',
      'weight',
      'emoji',
    });
  });

  // A16 : une rune binaire n'a qu'un niveau qui compte (spec P-43 E3, §3.8).
  group('binary', () {
    test('lu ; faux s il est absent ; toujours ecrit par toJson', () {
      expect(ForgeUpgradeData.fromJson(_json()).binary, isFalse);
      expect(ForgeUpgradeData.fromJson(_json()).toJson(),
          containsPair('binary', false));
      final cheap =
          ForgeUpgradeData.fromJson(_json({'maxLevel': 1, 'binary': true}));
      expect(cheap.binary, isTrue);
      expect(ForgeUpgradeData.fromJson(cheap.toJson()).binary, isTrue);
    });

    test('refuse une rune binaire de plafond autre que 1, et une valeur non '
        'booleenne', () {
      for (final maxLevel in [null, 2]) {
        expect(
          () => ForgeUpgradeData.fromJson(
              _json({'maxLevel': maxLevel, 'binary': true})),
          _refused('binary'),
          reason: '$maxLevel',
        );
      }
      expect(() => ForgeUpgradeData.fromJson(_json({'binary': 'oui'})),
          _refused('binary'));
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

  // `{val}` pour toute sorte chiffree (spec P-43 E2, A14, §5.2).
  group('{val}', () {
    const strike = CardData(
      id: 'strike_basic',
      cost: 1,
      type: CardType.attack,
      category: CardCategory.global,
      rarity: CardRarity.common,
      target: CardTarget.singleEnemy,
      effects: [CardEffect(type: 'damage', value: 30)],
    );

    test('sur addEffect : la valeur par niveau fois le niveau, pas le '
        'niveau', () {
      final rune = ForgeUpgradeData.fromJson(_json({
        'description_fr': 'Pioche +{val}',
        'deltas': [
          {'type': 'addEffect', 'effect': 'draw', 'valuePerLevel': 2},
        ],
      }));
      expect(rune.getDescription(3, 'fr', strike, CardRarity.common),
          'Pioche +6');
    });

    test('lit le premier delta chiffre', () {
      // Le pourcentage donnerait 15 % x 2 x 30 = 9 ; le premier delta
      // chiffre est le mana rendu, 1 par niveau.
      final rune = ForgeUpgradeData.fromJson(_json({
        'description_fr': '+{val}',
        'deltas': [
          {'type': 'removeExhaust'},
          {'type': 'addEffect', 'effect': 'gain_mana', 'valuePerLevel': 1},
          {'type': 'percentBonus', 'effect': 'damage', 'valuePercentPerLevel': 15},
        ],
      }));
      expect(rune.getDescription(2, 'fr', strike, CardRarity.common), '+2');
    });

    test('sur reduceCost : la baisse marginale, plancher 0 compris', () {
      final rune = ForgeUpgradeData.fromJson(_json({
        'description_fr': '-{val}',
        'deltas': [
          {'type': 'reduceCost', 'valuePerLevel': 1},
        ],
      }));
      // La Frappe coute 1 : un niveau la porte a 0, un second n'ote plus rien.
      expect(rune.getDescription(1, 'fr', strike, CardRarity.common), '-1');
      expect(
        rune.getDescription(1, 'fr', strike, CardRarity.common, carried: 1),
        '-0',
      );
    });

    test('sur critBonus : la valeur par niveau fois le niveau', () {
      final rune = ForgeUpgradeData.fromJson(_json({
        'description_fr': '+{val}%',
        'deltas': [
          {'type': 'critBonus', 'valuePerLevel': 5},
        ],
      }));
      expect(rune.getDescription(3, 'fr', strike, CardRarity.common), '+15%');
    });

    test('les cinq runes a effet ajoute disent leur valeur, que l ecran '
        'montrait deja', () {
      final card = shippedCard('strike_basic');
      String text(String id, int level) =>
          shippedRune(id).getDescription(level, 'fr', card, CardRarity.common);
      expect(text('burning', 3), 'Applique 3 Brûlure');
      expect(text('freezing', 1), 'Applique 1 Gel');
      expect(text('shocking', 2), 'Applique 2 Électrocution');
      expect(text('quick', 1), 'Pioche +1 carte(s)');
      expect(text('eco', 1), "Gagne +1 Mana à l'utilisation");
    });
  });

  // La regle des infobulles, que suivent la ligne de rune et le dialogue de
  // fusion (spec P-43 E2, §4.11) ; une rune de plafond 1 montee au-dela par
  // Transcendance ecrit son niveau (spec P-43 E3, A18).
  test('nameAt ecrit le niveau d une rune a plusieurs niveaux, ou montee '
      'au-dela de 1', () {
    final sharp = ForgeUpgradeData.fromJson(_json({'name_fr': 'Tranchant'}));
    final eco = ForgeUpgradeData.fromJson(
        _json({'name_fr': 'Économe', 'maxLevel': 1}));
    expect(sharp.nameAt(1, 'fr'), 'Tranchant 1');
    expect(sharp.nameAt(3, 'fr'), 'Tranchant 3');
    expect(eco.nameAt(1, 'fr'), 'Économe');
    expect(eco.nameAt(2, 'fr'), 'Économe 2');
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

    // Le plafond effectif (spec P-43 E3, §4.8, A17).
    test('le bonus de plafond s ajoute au plafond, et rien a une rune sans '
        'plafond', () {
      expect(capped.boundLevel(3, capBonus: 1), 3);
      expect(capped.boundLevel(1, carried: 2, capBonus: 1), 1);
      expect(capped.boundLevel(1, carried: 3, capBonus: 1), 0);
      expect(uncapped.boundLevel(3, carried: 5, capBonus: 1), 3);
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
