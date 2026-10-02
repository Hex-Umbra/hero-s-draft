import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/forge_rune_rules.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';

ForgeUpgradeData _rune(
  String id, {
  List<String>? eligibleCardTypes,
  List<String>? eligibleEffects,
  List<String> excludesEffects = const [],
  bool requiresExhaust = false,
  int requiresMinCost = 0,
  List<String> excludesRunes = const [],
  int? maxLevel,
  int minFusionRank = 1,
  List<CardDelta> deltas = const [],
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
      eligibleCardTypes: eligibleCardTypes,
      eligibleEffects: eligibleEffects,
      excludesEffects: excludesEffects,
      requiresExhaust: requiresExhaust,
      requiresMinCost: requiresMinCost,
      excludesRunes: excludesRunes,
      maxLevel: maxLevel,
      minFusionRank: minFusionRank,
      deltas: deltas,
    );

/// Une carte de test, peu commune par défaut : le rang 1 qu'atteint une
/// première fusion, où toute rune de `minFusionRank` 1 peut s'offrir (spec
/// P-43 E2, §8).
CardInstance _card({
  CardType type = CardType.attack,
  CardRarity rarity = CardRarity.uncommon,
  int cost = 1,
  bool isExhaust = false,
  List<CardEffect> effects = const [CardEffect(type: 'damage', value: 6)],
  List<String> runes = const [],
}) =>
    CardInstance(
      data: CardData(
        id: 'test_card',
        cost: cost,
        type: type,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        isExhaust: isExhaust,
        effects: effects,
      ),
      rarity: rarity,
      forgeUpgrades: runes,
    );

bool _eligible(
  ForgeUpgradeData rune,
  CardInstance card, [
  List<ForgeUpgradeData> others = const [],
]) =>
    ForgeRuneRules.isEligible(rune, card, [rune, ...others]);

/// Le prédicat d'éligibilité, condition par condition (spec P-43 E1, §4.6).
void main() {
  test('le type de carte', () {
    final rune = _rune('burning', eligibleCardTypes: const ['attack']);
    expect(_eligible(rune, _card()), isTrue);
    expect(_eligible(rune, _card(type: CardType.skill)), isFalse);
  });

  test('un effet propre du type vise', () {
    final rune = _rune('hardened', eligibleEffects: const ['armor']);
    expect(_eligible(rune, _card()), isFalse);
    expect(
      _eligible(
        rune,
        _card(effects: const [
          CardEffect(type: 'damage', value: 4),
          CardEffect(type: 'armor', value: 4),
        ]),
      ),
      isTrue,
    );
  });

  test('un effet exclu', () {
    final rune = _rune('enduring', excludesEffects: const ['draw']);
    expect(_eligible(rune, _card()), isTrue);
    expect(
      _eligible(
        rune,
        _card(effects: const [
          CardEffect(type: 'damage', value: 3),
          CardEffect(type: 'draw', value: 1),
        ]),
      ),
      isFalse,
    );
  });

  test('l epuisement', () {
    final rune = _rune('enduring', requiresExhaust: true);
    expect(_eligible(rune, _card()), isFalse);
    expect(_eligible(rune, _card(isExhaust: true)), isTrue);
  });

  test('le cout courant atteint le minimum', () {
    final rune = _rune('eco', requiresMinCost: 1);
    expect(_eligible(rune, _card(cost: 0)), isFalse);
    expect(_eligible(rune, _card(cost: 1)), isTrue);
  });

  group('la symetrie des exclusions (D51, D61)', () {
    final eco = _rune('eco');
    final enduring = _rune('enduring', excludesRunes: const ['eco']);

    test('une rune portee qui exclut la candidate la refuse', () {
      expect(_eligible(eco, _card(runes: const ['enduring:1']), [enduring]),
          isFalse);
    });

    test('une candidate qui exclut une rune portee est refusee', () {
      expect(_eligible(enduring, _card(runes: const ['eco:1']), [eco]),
          isFalse);
    });
  });

  // D3 : une seule rune de chaque type par carte (spec P-43 E2, §4.3,
  // condition 8) ; le plafond atteint d'E1 (D75) en est un cas.
  test('une rune portee sous son plafond ne se repropose pas', () {
    final rune = _rune('capped', maxLevel: 2);
    expect(_eligible(rune, _card()), isTrue);
    expect(_eligible(rune, _card(runes: const ['capped:1'])), isFalse);
  });

  test('une rune sans plafond portee ne se repropose pas', () {
    expect(_eligible(_rune('sharp'), _card(runes: const ['sharp:5'])), isFalse);
  });

  // D48 : la condition 7, contre le rang de la carte qui recoit la rune.
  test('minFusionRank contre le rang de la carte qui recoit la rune', () {
    final rank1 = _rune('sharp');
    final rank2 = _rune('quick', minFusionRank: 2);
    expect(_eligible(rank1, _card(rarity: CardRarity.common)), isFalse);
    expect(_eligible(rank1, _card(rarity: CardRarity.unique)), isFalse);
    expect(_eligible(rank1, _card()), isTrue);
    expect(_eligible(rank2, _card()), isFalse);
    expect(_eligible(rank2, _card(rarity: CardRarity.rare)), isTrue);
  });

  test('un effet ajoute par une rune ne compte pas', () {
    // Veloce fait piocher la carte, mais la pioche n'est pas un effet propre.
    final quick = _rune('quick', deltas: const [
      AddEffectDelta(effect: 'draw', valuePerLevel: 1),
    ]);
    final card = _card(runes: const ['quick:1']);
    expect(_eligible(_rune('enduring', excludesEffects: const ['draw']), card,
        [quick]), isTrue);
    expect(_eligible(_rune('scribe', eligibleEffects: const ['draw']), card,
        [quick]), isFalse);
  });

  test('une rune portee absente du catalogue est ignoree', () {
    final rune = _rune('enduring', excludesRunes: const ['legacy']);
    expect(_eligible(rune, _card(runes: const ['legacy:1'])), isTrue);
  });

  // Review Focus 2 : une sauvegarde d'avant 0.5.3 peut porter eco:3.
  test('une carte deja au-dela du plafond ne se voit pas reproposer la rune',
      () {
    expect(_eligible(_rune('eco', maxLevel: 1), _card(runes: const ['eco:3'])),
        isFalse);
  });
}
