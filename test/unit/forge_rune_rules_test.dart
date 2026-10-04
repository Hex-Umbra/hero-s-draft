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
  int? maxLevel,
  bool binary = false,
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
      minFusionRank: minFusionRank,
      maxLevel: maxLevel,
      binary: binary,
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
        _rune('enduring', maxLevel: 1),
        _rune('eco', maxLevel: 1),
        _rune('capped', maxLevel: 2),
      ],
    );
  });

  group('ForgeRuneRules.consolidate', () {
    test('additionne les niveaux des runes de meme id', () {
      expect(
        ForgeRuneRules.consolidate(['sharp:1', 'hardened:1', 'sharp:2']),
        ['sharp:3', 'hardened:1'],
      );
    });

    test('garde une rune de plafond 1 une seule fois, au niveau 1', () {
      expect(
        ForgeRuneRules.consolidate(['enduring:1', 'sharp:1', 'enduring:1']),
        ['enduring:1', 'sharp:1'],
      );
    });

    test('ramene au niveau 1 une rune de plafond 1 deja montee', () {
      expect(ForgeRuneRules.consolidate(['enduring:3']), ['enduring:1']);
    });

    test('borne la somme au plafond de la rune : le surplus se perd', () {
      expect(ForgeRuneRules.consolidate(['capped:1', 'capped:2']), ['capped:2']);
    });

    test('une rune absente du registre n a pas de plafond', () {
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

    // Les paires que tire le boss « XP » (spec P-43 E3, §4.6, A14).
    test('sharpenablePairs : les paires sous leur plafond, dans l ordre du '
        'deck puis des runes de chaque carte', () {
      final catalog = [_rune('sharp'), _rune('eco', maxLevel: 1)];
      final first = _cardWith(['eco:1', 'sharp:2']);
      final bare = _cardWith([]);
      final last = _cardWith(['sharp:1', 'absente:1']);

      expect(
        [
          for (final pair in ForgeRuneRules.sharpenablePairs(
              [first, bare, last], catalog))
            (pair.card.uniqueId, pair.rune.id, pair.level),
        ],
        [(first.uniqueId, 'sharp', 2), (last.uniqueId, 'sharp', 1)],
      );
    });

    test('canSharpen, hasSharpenableRune et sharpenablePairs lisent le bonus '
        'de plafond, par id de rune', () {
      final eco = _rune('eco', maxLevel: 1);
      final card = _cardWith(['eco:1']);

      expect(ForgeRuneRules.canSharpen(eco, 1), isFalse);
      expect(ForgeRuneRules.canSharpen(eco, 1, capBonus: {'eco': 1}), isTrue);
      expect(ForgeRuneRules.canSharpen(eco, 2, capBonus: {'eco': 1}), isFalse);
      expect(
          ForgeRuneRules.canSharpen(eco, 1, capBonus: {'quick': 1}), isFalse);
      expect(ForgeRuneRules.hasSharpenableRune(card, [eco]), isFalse);
      expect(
        ForgeRuneRules.hasSharpenableRune(card, [eco], capBonus: {'eco': 1}),
        isTrue,
      );
      expect(ForgeRuneRules.sharpenablePairs([card], [eco]), isEmpty);
      expect(
        [
          for (final pair in ForgeRuneRules.sharpenablePairs([card], [eco],
              capBonus: {'eco': 1}))
            (pair.rune.id, pair.level),
        ],
        [('eco', 1)],
      );
    });
  });

  // Les candidates de Transcendance (spec P-43 E3, §4.8 ; A15, A16).
  group('raisableCaps', () {
    final catalog = [
      _rune('sharp'),
      _rune('enduring', maxLevel: 1, binary: true),
      _rune('eco', maxLevel: 1),
      _rune('capped', maxLevel: 2),
    ];

    List<(String, int)> candidatesOf(
      List<CardInstance> deck, {
      Map<String, int> capBonus = const {},
    }) =>
        [
          for (final (:rune, :cap)
              in ForgeRuneRules.raisableCaps(deck, catalog, capBonus: capBonus))
            (rune.id, cap),
        ];

    test('les runes portees a leur plafond, sans les binaires ni les runes '
        'sans plafond, une fois chacune, dans l ordre du catalogue', () {
      expect(
        candidatesOf([
          _cardWith(['capped:2', 'sharp:9']),
          _cardWith(['eco:1', 'enduring:1']),
          _cardWith(['eco:1', 'capped:1']),
        ]),
        [('eco', 1), ('capped', 2)],
      );
    });

    test('le plafond effectif compte : une rune relevee n est plus candidate '
        'avant d y remonter', () {
      expect(
        candidatesOf([_cardWith(['eco:1']), _cardWith(['capped:2'])],
            capBonus: {'eco': 1}),
        [('capped', 2)],
      );
      expect(candidatesOf([_cardWith(['eco:2'])], capBonus: {'eco': 1}),
          [('eco', 2)]);
    });
  });

  // Le Puits d'echange (spec P-43 E2, A5, A6, §4.8).
  group('le Puits', () {
    const given = [1, 2, 3, 4, 5, 6, 9, 12];

    test('wellCost : 50 or par niveau de la rune donnee (A6, D39)', () {
      expect([for (final level in given) ForgeRuneRules.wellCost(level)],
          [50, 100, 150, 200, 250, 300, 450, 600]);
    });

    test('wellLevel : les deux tiers, arrondis au plus proche, au moins 1 '
        '(D39)', () {
      expect(
        [for (final level in given) ForgeRuneRules.wellLevel(_rune('x'), level)],
        [1, 1, 2, 3, 3, 4, 6, 8],
      );
    });

    test('wellLevel : borne par le plafond de la rune recue — Tranchant 9 '
        'contre Econome 1', () {
      expect(ForgeRuneRules.wellLevel(_rune('eco', maxLevel: 1), 9), 1);
    });

    test('wellLevel : borne par le plafond effectif — Tranchant 3 contre '
        'Econome, 2 sous un bonus de 1', () {
      expect(ForgeRuneRules.wellLevel(_rune('eco', maxLevel: 1), 3), 1);
      expect(
        ForgeRuneRules.wellLevel(_rune('eco', maxLevel: 1), 3,
            capBonus: {'eco': 1}),
        2,
      );
    });

    // Les runes livrees, par une liste fixe : le cas ne bouge pas quand une
    // rune s'ajoute au catalogue.
    List<String> optionsOf(
      CardInstance card,
      String givenId,
      List<String> ids,
    ) =>
        [
          for (final rune in ForgeRuneRules.wellOptions(
              card, givenId, [for (final id in ids) shippedRune(id)]))
            rune.id,
        ];

    test('wellOptions : toutes les eligibles, la rune donnee exclue', () {
      final strike = CardInstance(
        data: shippedCard('strike_basic'),
        rarity: CardRarity.rare,
        forgeUpgrades: const ['sharp:2'],
      );
      expect(
        optionsOf(
            strike, 'sharp', const ['burning', 'freezing', 'hardened', 'sharp']),
        ['burning', 'freezing'],
      );
    });

    test('wellOptions : jugee sans la rune donnee — Persistant donne, Econome '
        'possible sur une rare', () {
      final potion = CardInstance(
        data: shippedCard('heal_potion'),
        rarity: CardRarity.rare,
        forgeUpgrades: const ['enduring:1'],
      );
      expect(optionsOf(potion, 'enduring', const ['eco', 'enduring', 'quick']),
          ['eco', 'quick']);
    });

    test('wellOptions : au rang de la carte', () {
      final potion = CardInstance(
        data: shippedCard('heal_potion'),
        rarity: CardRarity.uncommon,
        forgeUpgrades: const ['enduring:1'],
      );
      expect(optionsOf(potion, 'enduring', const ['eco', 'enduring', 'quick']),
          isEmpty);
    });
  });
}
