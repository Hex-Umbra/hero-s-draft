import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/forge_rune_rules.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

const _threePools = ['common', 'uncommon', 'rare'];
const _allTypes = ['attack', 'skill', 'power'];

/// Ce que déclare une rune, sous une forme comparable.
Map<String, Object?> _declared(ForgeUpgradeData rune) => {
      'pools': rune.pools,
      'minFusionRank': rune.minFusionRank,
      'eligibleCardTypes': rune.eligibleCardTypes,
      'eligibleEffects': rune.eligibleEffects,
      'excludesEffects': rune.excludesEffects,
      'requiresExhaust': rune.requiresExhaust,
      'requiresMinCost': rune.requiresMinCost,
      'excludesRunes': rune.excludesRunes,
      'stackable': rune.stackable,
      'maxLevel': rune.maxLevel,
      'deltas': [for (final delta in rune.deltas) delta.toJson()],
      'weight': rune.weight,
    };

Map<String, Object?> _rune({
  List<String> pools = _threePools,
  int minFusionRank = 1,
  List<String>? eligibleCardTypes,
  List<String>? eligibleEffects,
  List<String> excludesEffects = const [],
  bool requiresExhaust = false,
  int requiresMinCost = 0,
  List<String> excludesRunes = const [],
  bool stackable = true,
  required int? maxLevel,
  required List<Map<String, Object?>> deltas,
  required int weight,
}) =>
    {
      'pools': pools,
      'minFusionRank': minFusionRank,
      'eligibleCardTypes': eligibleCardTypes,
      'eligibleEffects': eligibleEffects,
      'excludesEffects': excludesEffects,
      'requiresExhaust': requiresExhaust,
      'requiresMinCost': requiresMinCost,
      'excludesRunes': excludesRunes,
      'stackable': stackable,
      'maxLevel': maxLevel,
      'deltas': deltas,
      'weight': weight,
    };

Map<String, Object?> _status(String statusId) => {
      'type': 'addEffect',
      'effect': 'apply_status',
      'valuePerLevel': 1,
      'statusId': statusId,
      'durationPerLevel': 1,
    };

/// Les huit runes, telles que les specs P-43 E1 (§3.2) et E2 (§3.2) les
/// fixent : `minFusionRank` 2 pour `quick` et `eco` (D48), 1 pour les six
/// autres (A7). Les `weight` et les `eligibleCardTypes` sont ceux que la
/// simulation lit : ils ne bougent pas (spec P-43 E2, §9).
final _expected = <String, Map<String, Object?>>{
  'sharp': _rune(
    eligibleEffects: const ['damage'],
    maxLevel: null,
    deltas: const [
      {'type': 'percentBonus', 'effect': 'damage', 'valuePercentPerLevel': 15},
    ],
    weight: 100,
  ),
  'hardened': _rune(
    eligibleEffects: const ['armor'],
    maxLevel: null,
    deltas: const [
      {'type': 'percentBonus', 'effect': 'armor', 'valuePercentPerLevel': 15},
    ],
    weight: 100,
  ),
  'quick': _rune(
    pools: const ['uncommon', 'rare'],
    minFusionRank: 2,
    eligibleCardTypes: _allTypes,
    maxLevel: 1,
    deltas: const [
      {'type': 'addEffect', 'effect': 'draw', 'valuePerLevel': 1},
    ],
    weight: 60,
  ),
  'eco': _rune(
    pools: const ['rare'],
    minFusionRank: 2,
    eligibleCardTypes: _allTypes,
    requiresMinCost: 1,
    maxLevel: 1,
    deltas: const [
      {'type': 'addEffect', 'effect': 'gain_mana', 'valuePerLevel': 1},
    ],
    weight: 40,
  ),
  'burning': _rune(
    eligibleCardTypes: const ['attack'],
    maxLevel: null,
    deltas: [_status('burn')],
    weight: 80,
  ),
  'freezing': _rune(
    eligibleCardTypes: const ['attack'],
    maxLevel: 1,
    deltas: [_status('freeze')],
    weight: 80,
  ),
  'shocking': _rune(
    eligibleCardTypes: const ['attack'],
    maxLevel: null,
    deltas: [_status('shock')],
    weight: 80,
  ),
  'enduring': _rune(
    pools: const ['rare'],
    eligibleCardTypes: _allTypes,
    excludesEffects: const ['gain_mana', 'draw'],
    requiresExhaust: true,
    excludesRunes: const ['eco', 'quick'],
    stackable: false,
    maxLevel: 1,
    deltas: const [
      {'type': 'removeExhaust'},
    ],
    weight: 30,
  ),
};

/// Ce que la première fusion d'une attaque de dégâts lui offre (rang 1), puis
/// la deuxième (rang 2).
const _attackRank1 = {'sharp', 'burning', 'freezing', 'shocking'};
const _attackRank2 = {..._attackRank1, 'quick', 'eco'};

/// La matrice de l'offre aux 17 cartes neutres livrées, sans rune, au rang
/// qu'atteint leur première fusion (peu commune), puis leur deuxième (rare) :
/// la table de la spec P-43 E2, §4.12, sans les trois runes de la partie 2.
/// `pools` mis à part, que le tirage de la boutique applique encore.
const _offers = <String, (Set<String>, Set<String>)>{
  'strike_basic': (_attackRank1, _attackRank2),
  'heavy_strike': (_attackRank1, _attackRank2),
  'fireball': (_attackRank1, _attackRank2),
  'ice_bolt': (_attackRank1, _attackRank2),
  'poison_stab': (_attackRank1, _attackRank2),
  'quick_attack': (_attackRank1, _attackRank2),
  'sweep': (_attackRank1, _attackRank2),
  'thunder_clap': (_attackRank1, _attackRank2),
  'warcry': ({..._attackRank1, 'hardened'}, {..._attackRank2, 'hardened'}),
  'awakening': ({'hardened'}, {'hardened', 'quick', 'eco'}),
  'defend_basic': ({'hardened'}, {'hardened', 'quick', 'eco'}),
  'iron_wall': ({'hardened'}, {'hardened', 'quick', 'eco'}),
  'heal_potion': ({'enduring'}, {'enduring', 'quick', 'eco'}),
  'demon_form': (<String>{}, {'quick', 'eco'}),
  'metallicize': (<String>{}, {'quick', 'eco'}),
  'concentration': (<String>{}, {'quick'}),
  'focus': (<String>{}, {'quick'}),
};

/// Les six signatures, `unique` : rang 0, elles ne fusionnent jamais et
/// aucune rune ne s'offre à elles (spec P-43 E2, §4.12).
const _signatures = {
  'reckless_strike',
  'rage_form',
  'magic_missile',
  'mana_surge',
  'smite',
  'holy_shield',
};

/// Les huit runes livrées, et l'offre qu'elles font aux 23 cartes livrées
/// (spec P-43 E1, §3.2, §4.8 ; spec P-43 E2, §3.2, §4.12, §8).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;

  setUpAll(() async {
    registry = await loadGameDataRegistry(rootBundle);
  });

  CardData cardOf(String id) => registry.cards.singleWhere((c) => c.id == id);

  Set<String> offeredTo(CardInstance card) => {
        for (final rune in registry.forgeUpgrades)
          if (ForgeRuneRules.isEligible(rune, card, registry.forgeUpgrades))
            rune.id,
      };

  // `maxLevel` et `minFusionRank` sont obligatoires au chargement : une rune
  // chargée porte les deux clés.
  for (final MapEntry(key: id, value: expected) in _expected.entries) {
    test('$id declare ce que la spec fixe', () {
      final rune = registry.forgeUpgrades.singleWhere((r) => r.id == id);
      expect(_declared(rune), expected);
    });
  }

  test('la matrice couvre les 23 cartes livrees', () {
    expect(registry.cards.map((c) => c.id).toSet(),
        {..._offers.keys, ..._signatures});
  });

  for (final MapEntry(key: cardId, value: (rank1, rank2)) in _offers.entries) {
    for (final (rarity, runes) in [
      (CardRarity.uncommon, rank1),
      (CardRarity.rare, rank2),
    ]) {
      test('$cardId ${rarity.name} recoit ${runes.length} rune(s)', () {
        expect(
          offeredTo(CardInstance(data: cardOf(cardId), rarity: rarity)),
          runes,
        );
      });
    }
  }

  for (final cardId in _signatures) {
    test('$cardId, unique, ne recoit aucune rune', () {
      final card = CardInstance(data: cardOf(cardId));
      expect(card.rarity, CardRarity.unique);
      expect(offeredTo(card), isEmpty);
    });
  }
}
