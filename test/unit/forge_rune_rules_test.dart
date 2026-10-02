import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/forge_rune_rules.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

import 'shipped_data.dart';

ForgeUpgradeData _rune(
  String id, {
  bool stackable = true,
  int? maxLevel,
  int minFusionRank = 1,
  int weight = 10,
}) =>
    ForgeUpgradeData(
      id: id,
      nameEn: id,
      nameFr: id,
      descriptionEn: '',
      descriptionFr: '',
      icon: '',
      color: '',
      pools: const ['common'],
      minFusionRank: minFusionRank,
      stackable: stackable,
      maxLevel: maxLevel,
      weight: weight,
    );

CardInstance _cardWith(List<String> runes) => CardInstance(
      data: const CardData(
        id: 'strike',
        cost: 1,
        type: CardType.attack,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        effects: [],
      ),
      forgeUpgrades: runes,
    );

void main() {
  setUp(() {
    // Construire le registre renseigne `GameDataRegistry.instance`, que lit
    // `ForgeUpgradeData.getById`.
    GameDataRegistry(
      enemies: const [],
      heroes: const [],
      cards: const [],
      events: const [],
      passives: const [],
      relics: const [],
      forgeUpgrades: [
        _rune('sharp'),
        _rune('hardened'),
        _rune('enduring', stackable: false),
        _rune('eco', maxLevel: 1),
        _rune('capped', maxLevel: 2),
      ],
    );
  });

  group('ForgeUpgradeData.stackable', () {
    test('une rune est cumulable par defaut', () {
      final rune = ForgeUpgradeData.fromJson({
        'id': 'sharp',
        'pools': ['common'],
        'minFusionRank': 1,
        'maxLevel': null,
        'deltas': [
          {'type': 'percentBonus', 'effect': 'damage', 'valuePercentPerLevel': 15},
        ],
      });
      expect(rune.stackable, isTrue);
    });

    test('le JSON declare une rune non cumulable, et toJson la conserve', () {
      final rune = ForgeUpgradeData.fromJson({
        'id': 'enduring',
        'pools': ['rare'],
        'minFusionRank': 1,
        'stackable': false,
        'maxLevel': 1,
        'deltas': [
          {'type': 'removeExhaust'},
        ],
      });
      expect(rune.stackable, isFalse);
      expect(ForgeUpgradeData.fromJson(rune.toJson()).stackable, isFalse);
    });
  });

  group('ForgeRuneRules.consolidate', () {
    test('additionne les tiers des runes cumulables de meme id', () {
      expect(
        ForgeRuneRules.consolidate(['sharp:1', 'hardened:1', 'sharp:2']),
        ['sharp:3', 'hardened:1'],
      );
    });

    test('garde une rune non cumulable une seule fois, au tier 1', () {
      expect(
        ForgeRuneRules.consolidate(['enduring:1', 'sharp:1', 'enduring:1']),
        ['enduring:1', 'sharp:1'],
      );
    });

    test('ramene au tier 1 une rune non cumulable deja montee', () {
      expect(ForgeRuneRules.consolidate(['enduring:3']), ['enduring:1']);
    });

    test('borne la somme au plafond de la rune : le surplus se perd', () {
      expect(ForgeRuneRules.consolidate(['capped:1', 'capped:2']), ['capped:2']);
    });

    test('traite une rune absente du registre comme cumulable', () {
      expect(ForgeRuneRules.consolidate(['legacy:1', 'legacy:1']), ['legacy:2']);
    });

    test('ignore une reference mal formee ou de tier nul', () {
      expect(
        ForgeRuneRules.consolidate(['sharp', 'sharp:0', 'sharp:x', 'hardened:2']),
        ['hardened:2'],
      );
    });
  });

  group('ForgeRuneRules.consolidate, exclusions', () {
    test('trois Potions de Soin enduring, eco et vide : eco est ecartee', () {
      // Le catalogue livré : enduring exclut eco dans son fichier.
      final potions = [
        for (final carried in const [
          ['enduring:1'],
          ['eco:1'],
          <String>[],
        ])
          CardInstance(data: shippedCard('heal_potion'), forgeUpgrades: carried),
      ];
      shippedRuneRegistry(shippedRuneIds(), cards: [potions.first.data]);

      final runes = ForgeRuneRules.consolidate(
        [for (final potion in potions) ...potion.forgeUpgrades],
      );

      // Une carte rendant du mana sans s'épuiser : le moteur que D44 et D51
      // ferment. La première arrivée est gardée.
      expect(runes, ['enduring:1']);
    });
  });

  group('ForgeRuneRules.fusionOptionsFor', () {
    test('une fusion par rune cumulable portee au moins deux fois', () {
      final options = ForgeRuneRules.fusionOptionsFor(
        _cardWith(['sharp:1', 'sharp:2', 'hardened:1']),
      );

      expect(options, hasLength(1));
      expect(options.single.upgradeId, 'sharp');
      expect(options.single.originalUpgrades, ['sharp:1', 'sharp:2']);
      expect(options.single.totalTier, 3);
      expect(options.single.cost, 80);
    });

    test('une reference mal formee ne compte pas, comme dans consolidate', () {
      expect(
        ForgeRuneRules.fusionOptionsFor(_cardWith(['sharp', 'sharp:x', 'sharp:1'])),
        isEmpty,
      );
    });

    test('deux eco:1 : aucune option, la fusion perdrait un niveau', () {
      expect(
        ForgeRuneRules.fusionOptionsFor(_cardWith(['eco:1', 'eco:1'])),
        isEmpty,
      );
    });

    test('1 + 1 sous un plafond de 2 : proposee', () {
      final options =
          ForgeRuneRules.fusionOptionsFor(_cardWith(['capped:1', 'capped:1']));
      expect(options.single.totalTier, 2);
    });

    test('2 + 1 sous un plafond de 2 : non proposee', () {
      expect(
        ForgeRuneRules.fusionOptionsFor(_cardWith(['capped:2', 'capped:1'])),
        isEmpty,
      );
    });

    test('jamais de fusion pour une rune non cumulable', () {
      expect(
        ForgeRuneRules.fusionOptionsFor(_cardWith(['enduring:1', 'enduring:1'])),
        isEmpty,
      );
    });
  });

  // L'offre de la fusion (spec P-43 E2, A2, §4.4).
  group('ForgeRuneRules.drawRunes', () {
    // Une Frappe peu commune : le rang 1 qu'atteint une premiere fusion.
    final card = CardInstance(
      data: const CardData(
        id: 'strike',
        cost: 1,
        type: CardType.attack,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        effects: [CardEffect(type: 'damage', value: 6)],
      ),
      rarity: CardRarity.uncommon,
    );
    // Refusee a une peu commune : elle attend le rang 2.
    final refused = _rune('refused', minFusionRank: 2);

    test('au plus count ids distincts, tous eligibles', () {
      const eligible = ['a', 'b', 'c', 'd', 'e'];
      final catalog = [for (final id in eligible) _rune(id), refused];
      for (var seed = 0; seed < 20; seed++) {
        final drawn =
            ForgeRuneRules.drawRunes(card, catalog, Random(seed), count: 3);
        expect(drawn, hasLength(3), reason: 'graine $seed');
        expect(drawn.toSet(), hasLength(3), reason: 'graine $seed');
        expect(drawn, everyElement(isIn(eligible)), reason: 'graine $seed');
      }
    });

    test('moins s il y en a moins', () {
      final drawn = ForgeRuneRules.drawRunes(
          card, [_rune('a'), _rune('b'), refused], Random(1),
          count: 3);
      expect(drawn.toSet(), {'a', 'b'});
    });

    test('aucune s il n y en a pas', () {
      expect(ForgeRuneRules.drawRunes(card, [refused], Random(1), count: 3),
          isEmpty);
    });

    test('le tirage suit weight', () {
      final catalog = [_rune('heavy', weight: 90), _rune('light', weight: 10)];
      final rng = Random(42);
      var heavy = 0;
      for (var i = 0; i < 2000; i++) {
        if (ForgeRuneRules.drawRunes(card, catalog, rng, count: 1).single ==
            'heavy') {
          heavy++;
        }
      }
      expect(heavy / 2000, inInclusiveRange(0.86, 0.94));
    });

    // Review Focus 1 : un fichier peut declarer weight 0 ; D65 veut une offre
    // tant qu'une rune est eligible.
    test('des runes de poids nul se tirent encore', () {
      final catalog = [_rune('a', weight: 0), _rune('b', weight: 0)];
      expect(
        ForgeRuneRules.drawRunes(card, catalog, Random(3), count: 3).toSet(),
        {'a', 'b'},
      );
    });
  });

  // L'affutage (spec P-43 E2, §4.7).
  group('l affutage', () {
    test('sharpenCost : 50 or par niveau porte (D20, D63)', () {
      expect(
        [for (var level = 1; level <= 4; level++) ForgeRuneRules.sharpenCost(level)],
        [50, 100, 150, 200],
      );
    });

    test('canSharpen : jusqu au plafond, sans fin sans plafond', () {
      expect(ForgeRuneRules.canSharpen(_rune('sharp'), 9), isTrue);
      expect(ForgeRuneRules.canSharpen(_rune('capped', maxLevel: 2), 1), isTrue);
      expect(
          ForgeRuneRules.canSharpen(_rune('capped', maxLevel: 2), 2), isFalse);
      expect(ForgeRuneRules.canSharpen(_rune('eco', maxLevel: 1), 1), isFalse);
    });

    test('hasSharpenableRune : une rune portee sous son plafond, et du '
        'catalogue', () {
      final catalog = [_rune('sharp'), _rune('eco', maxLevel: 1)];
      expect(ForgeRuneRules.hasSharpenableRune(_cardWith([]), catalog), isFalse);
      expect(ForgeRuneRules.hasSharpenableRune(_cardWith(['eco:1']), catalog),
          isFalse);
      expect(
          ForgeRuneRules.hasSharpenableRune(_cardWith(['absente:1']), catalog),
          isFalse);
      expect(
        ForgeRuneRules.hasSharpenableRune(
            _cardWith(['eco:1', 'sharp:3']), catalog),
        isTrue,
      );
    });
  });
}
