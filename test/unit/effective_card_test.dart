import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/effective_card.dart';

CardData _card(List<CardEffect> effects) => CardData(
      id: 'test_card',
      cost: 1,
      type: CardType.attack,
      category: CardCategory.global,
      rarity: CardRarity.common,
      target: CardTarget.singleEnemy,
      effects: effects,
    );

CardEffect _damage(int value) => CardEffect(type: 'damage', value: value);

const _sharp = PercentBonusDelta(effect: 'damage', valuePercentPerLevel: 15);
const _hardened = PercentBonusDelta(effect: 'armor', valuePercentPerLevel: 15);
const _burn = AddEffectDelta(
  effect: 'apply_status',
  valuePerLevel: 1,
  statusId: 'burn',
  durationPerLevel: 1,
);
const _draw = AddEffectDelta(effect: 'draw', valuePerLevel: 1);

List<int> _values(EffectiveCard card) => [for (final e in card.effects) e.value];

ForgeUpgradeData _rune(String id, List<CardDelta> deltas) => ForgeUpgradeData(
      id: id,
      nameEn: id,
      nameFr: id,
      descriptionEn: '',
      descriptionFr: '',
      icon: '',
      color: '',
      deltas: deltas,
    );

/// L'applicateur : la carte telle qu'elle se joue (spec P-43 E1, §4.1, §4.2).
void main() {
  group('G1 et G2', () {
    // Spec §4.3 : la valeur d'un effet, de commune a legendaire.
    List<int> ladder(CardEffect effect) => [
          for (final rarity in const [
            CardRarity.common,
            CardRarity.uncommon,
            CardRarity.rare,
            CardRarity.epic,
            CardRarity.legendary,
          ])
            EffectiveCard.apply(_card([effect]), rarity, const [])
                .effects
                .single
                .value,
        ];

    test('G1 : chaque palier ajoute au moins 1 aux petites valeurs', () {
      expect(ladder(_damage(1)), [1, 2, 3, 4, 5]);
      expect(ladder(_damage(2)), [2, 3, 4, 5, 6]);
      expect(ladder(_damage(3)), [3, 4, 5, 6, 7]);
      expect(ladder(_damage(4)), [4, 5, 6, 7, 8]);
    });

    test('G1 : a partir de 5, la valeur multipliee d aujourd hui', () {
      expect(ladder(_damage(5)), [5, 6, 7, 8, 10]);
      expect(ladder(_damage(12)), [12, 14, 17, 19, 24]);
    });

    test('G1 vaut pour le soin et pour la valeur d un statut', () {
      expect(ladder(const CardEffect(type: 'heal', value: 3)), [3, 4, 5, 6, 7]);
      expect(
        ladder(const CardEffect(
            type: 'apply_status', value: 1, statusId: 'poison', duration: 2)),
        [1, 2, 3, 4, 5],
      );
    });

    test('unique rend la base', () {
      expect(
        EffectiveCard.apply(_card([_damage(1)]), CardRarity.unique, const [])
            .effects
            .single
            .value,
        1,
      );
    });

    test('G2 : la pioche et le mana ne grandissent pas avec la rarete', () {
      expect(ladder(const CardEffect(type: 'draw', value: 2)), [2, 2, 2, 2, 2]);
      expect(
          ladder(const CardEffect(type: 'gain_mana', value: 1)), [1, 1, 1, 1, 1]);
    });

    // Review Focus 1 : sans sa garde, une valeur nulle gagnerait 1 par palier.
    test('une valeur nulle reste nulle a toute rarete', () {
      expect(ladder(_damage(0)), [0, 0, 0, 0, 0]);
    });
  });

  group('percentBonus', () {
    test('la table de D33 sur une carte commune', () {
      // Spec §4.8 : le bonus des niveaux 1 a 4 selon la valeur de l'effet.
      const expected = {
        7: [1, 2, 3, 4],
        8: [1, 2, 4, 5],
        10: [2, 3, 5, 6],
        12: [2, 4, 5, 7],
      };
      expected.forEach((base, bonuses) {
        for (var level = 1; level <= 4; level++) {
          final card = EffectiveCard.apply(
            _card([_damage(base)]),
            CardRarity.common,
            [(_sharp, level)],
          );
          expect(_values(card), [base + bonuses[level - 1]],
              reason: 'base $base, niveau $level');
        }
      });
    });

    test('la base est la valeur de l effet a la rarete de la carte', () {
      // Frappe : 6 en commune, 10 en epique, 12 en legendaire.
      expect(
        _values(EffectiveCard.apply(
            _card([_damage(6)]), CardRarity.epic, [(_sharp, 1)])),
        [10 + 2],
      );
      expect(
        _values(EffectiveCard.apply(
            _card([_damage(6)]), CardRarity.legendary, [(_sharp, 2)])),
        [12 + 4],
      );
    });

    test('l arithmetique est entiere : 15 % x 3 x 30 donne 14', () {
      // 0,15 x 3 x 30 vaut 13,499... en virgule flottante (spec P-43 E1, A7).
      expect(
        _values(EffectiveCard.apply(
            _card([_damage(30)]), CardRarity.common, [(_sharp, 3)])),
        [30 + 14],
      );
    });

    test('chaque effet du type vise est servi', () {
      expect(
        _values(EffectiveCard.apply(_card([_damage(6), _damage(10)]),
            CardRarity.common, [(_sharp, 1)])),
        [6 + 1, 10 + 2],
      );
    });

    test('un pourcentage ne touche que le type qu il vise', () {
      final card = _card([_damage(6), const CardEffect(type: 'armor', value: 5)]);
      expect(
        _values(EffectiveCard.apply(card, CardRarity.common, [(_hardened, 1)])),
        [6, 5 + 1],
      );
    });

    test('deux pourcentages sur un meme effet ne se composent pas', () {
      // Chacun sur la valeur a la rarete, 10 : +2 et +2, et non +2 puis
      // 15 % de 12.
      expect(
        _values(EffectiveCard.apply(_card([_damage(10)]), CardRarity.common,
            [(_sharp, 1), (_sharp, 1)])),
        [10 + 2 + 2],
      );
    });
  });

  group('addEffect', () {
    test('valeur et duree par niveau', () {
      final card = EffectiveCard.apply(
        _card([_damage(6)]),
        CardRarity.common,
        [(_burn, 2), (_draw, 1)],
      );
      expect(
        card.addedEffects.map((e) => (e.type, e.value, e.statusId, e.duration)),
        [('apply_status', 2, 'burn', 2), ('draw', 1, null, null)],
      );
    });

    test('ni multiplie par la rarete ni vise par un pourcentage', () {
      const strike = AddEffectDelta(effect: 'damage', valuePerLevel: 3);
      final card = EffectiveCard.apply(
        _card([_damage(6)]),
        CardRarity.legendary,
        [(strike, 1), (_sharp, 1)],
      );
      expect(card.addedEffects.single.value, 3);
      expect(_values(card), [12 + 2]);
    });
  });

  test('removeExhaust leve l epuisement, quel que soit le niveau', () {
    for (final level in [1, 3]) {
      expect(
        EffectiveCard.apply(_card(const []), CardRarity.common,
            [(const RemoveExhaustDelta(), level)]).removesExhaust,
        isTrue,
        reason: 'niveau $level',
      );
    }
    expect(
      EffectiveCard.apply(_card(const []), CardRarity.common, const [])
          .removesExhaust,
      isFalse,
    );
  });

  // Les trois sortes neuves (spec P-43 E2, §4.1, §4.2).
  group('reduceCost, critBonus, addExhaust', () {
    CardData costing(int cost) => CardData(
          id: 'test_card',
          cost: cost,
          type: CardType.attack,
          category: CardCategory.global,
          rarity: CardRarity.common,
          target: CardTarget.singleEnemy,
          effects: [_damage(6)],
        );
    const cut = ReduceCostDelta(valuePerLevel: 1);

    test('reduceCost : le cout moins valuePerLevel x niveau, plancher 0, la '
        'rarete sans effet', () {
      expect(
          EffectiveCard.apply(costing(2), CardRarity.common, [(cut, 1)]).cost,
          1);
      expect(
          EffectiveCard.apply(costing(1), CardRarity.common, [(cut, 3)]).cost,
          0);
      expect(
          EffectiveCard.apply(costing(2), CardRarity.legendary, const []).cost,
          2);
    });

    test('critBonus : additionne dans critChanceBonus', () {
      const crit = CritBonusDelta(valuePerLevel: 5);
      expect(
        EffectiveCard.apply(
                costing(1), CardRarity.common, [(crit, 2), (crit, 1)])
            .critChanceBonus,
        15,
      );
      expect(
        EffectiveCard.apply(costing(1), CardRarity.common, const [])
            .critChanceBonus,
        0,
      );
    });

    test('addExhaust leve addsExhaust, quel que soit le niveau', () {
      for (final level in [1, 3]) {
        expect(
          EffectiveCard.apply(costing(1), CardRarity.common,
              [(const AddExhaustDelta(), level)]).addsExhaust,
          isTrue,
          reason: 'niveau $level',
        );
      }
      expect(
        EffectiveCard.apply(costing(1), CardRarity.common, const [])
            .addsExhaust,
        isFalse,
      );
    });

    // Deux pourcentages sur un meme effet s'additionnent, sans se composer.
    test('sharp et spectral s additionnent, chacun sur la valeur a la '
        'rarete', () {
      // 10 en commune, 14 en rare : +2 a 15 %, +6 a 40 %.
      const spectral =
          PercentBonusDelta(effect: 'damage', valuePercentPerLevel: 40);
      expect(
        _values(EffectiveCard.apply(_card([_damage(10)]), CardRarity.rare,
            [(_sharp, 1), (spectral, 1)])),
        [14 + 2 + 6],
      );
    });
  });

  // CardInstance lit l'applicateur sur le registre (spec P-43 E2, §4.2,
  // A10).
  group('CardInstance', () {
    setUp(() {
      GameDataRegistry(
        enemies: const [],
        heroes: const [],
        cards: const [],
        events: const [],
        passives: const [],
        relics: const [],
        forgeUpgrades: [
          _rune('leger', const [ReduceCostDelta(valuePerLevel: 1)]),
          _rune('ephemere', const [AddExhaustDelta()]),
          _rune('tenace', const [RemoveExhaustDelta()]),
        ],
      );
    });

    CardInstance carrying(List<String> runes, {bool isExhaust = false}) =>
        CardInstance(
          data: CardData(
            id: 'test_card',
            cost: 2,
            type: CardType.attack,
            category: CardCategory.global,
            rarity: CardRarity.common,
            target: CardTarget.singleEnemy,
            isExhaust: isExhaust,
            effects: [_damage(6)],
          ),
          forgeUpgrades: runes,
        );

    test('currentCost est le cout de l applicateur', () {
      expect(carrying(const []).currentCost, 2);
      expect(carrying(const ['leger:1']).currentCost, 1);
    });

    test('exhaustsOnPlay : addExhaust epuise, et l emporte sur removeExhaust',
        () {
      expect(carrying(const ['ephemere:1']).exhaustsOnPlay, isTrue);
      expect(
        carrying(const ['tenace:1', 'ephemere:1'], isExhaust: true)
            .exhaustsOnPlay,
        isTrue,
      );
      expect(carrying(const ['tenace:1'], isExhaust: true).exhaustsOnPlay,
          isFalse);
    });
  });

  test('effects a la longueur et l ordre des effets de la donnee', () {
    final data = _card([
      _damage(6),
      const CardEffect(
          type: 'apply_status', value: 1, statusId: 'poison', duration: 2),
      const CardEffect(type: 'draw', value: 1),
    ]);
    final card = EffectiveCard.apply(
        data, CardRarity.common, [(_burn, 1), (_sharp, 1)]);
    expect(card.effects.map((e) => e.type), data.effects.map((e) => e.type));
  });

  test('apply ne lit aucune rune : des paires d une autre provenance suffisent',
      () {
    // La couture des evolutions de signature (vague 5) : un delta construit
    // hors de tout fichier de rune, sans catalogue.
    final fromElsewhere = <(CardDelta, int)>[
      (const PercentBonusDelta(effect: 'damage', valuePercentPerLevel: 50), 2),
    ];
    expect(
      _values(EffectiveCard.apply(
          _card([_damage(6)]), CardRarity.common, fromElsewhere)),
      [6 + 6],
    );
  });

  group('runeDeltas', () {
    final catalog = [
      _rune('quick', const [_draw]),
      _rune('sharp', const [_sharp]),
    ];

    test('additionne les exemplaires, dans l ordre de premiere apparition', () {
      expect(
        EffectiveCard.runeDeltas(
            const ['quick:1', 'sharp:1', 'sharp:2'], catalog).toList(),
        [(_draw, 1), (_sharp, 3)],
      );
    });

    test('ignore une reference mal formee ou de niveau nul, et un id hors du '
        'catalogue', () {
      expect(
        EffectiveCard.runeDeltas(const ['sharp', 'sharp:0', 'legacy:2'], catalog),
        isEmpty,
      );
    });
  });
}
