import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/forge_rune_rules.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

ForgeUpgradeData _rune(String id, {bool stackable = true, int? maxLevel}) =>
    ForgeUpgradeData(
      id: id,
      nameEn: id,
      nameFr: id,
      descriptionEn: '',
      descriptionFr: '',
      icon: '',
      color: '',
      pools: const ['common'],
      stackable: stackable,
      maxLevel: maxLevel,
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
}
