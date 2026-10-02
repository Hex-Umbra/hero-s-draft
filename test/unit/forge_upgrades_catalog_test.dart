import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/forge_rune_rules.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

const _threePools = ['common', 'uncommon', 'rare'];
const _allTypes = ['attack', 'skill', 'power'];

/// Ce que déclare une rune, sous une forme comparable.
Map<String, Object?> _declared(ForgeUpgradeData rune) => {
      'pools': rune.pools,
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

/// Les huit runes, telles que la spec P-43 E1 les fixe (§3.2). Les `weight`
/// et les `eligibleCardTypes` des six runes autres que `sharp` et `hardened`
/// sont ceux que la simulation lit : ils ne bougent pas (§9).
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
    eligibleCardTypes: _allTypes,
    maxLevel: 1,
    deltas: const [
      {'type': 'addEffect', 'effect': 'draw', 'valuePerLevel': 1},
    ],
    weight: 60,
  ),
  'eco': _rune(
    pools: const ['rare'],
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

const _attack = {'sharp', 'burning', 'freezing', 'shocking', 'quick', 'eco'};

/// La matrice de l'offre sur les 23 cartes livrées, sans rune, à leur rareté de
/// donnée — `pools` mis à part, que les tirages appliquent ensuite (§4.8).
const _offers = <String, Set<String>>{
  'strike_basic': _attack,
  'heavy_strike': _attack,
  'fireball': _attack,
  'ice_bolt': _attack,
  'poison_stab': _attack,
  'quick_attack': _attack,
  'sweep': _attack,
  'thunder_clap': _attack,
  'reckless_strike': _attack,
  'magic_missile': _attack,
  'warcry': {..._attack, 'hardened'},
  'smite': {..._attack, 'hardened'},
  'awakening': {'hardened', 'quick', 'eco'},
  'defend_basic': {'hardened', 'quick', 'eco'},
  'iron_wall': {'hardened', 'quick', 'eco'},
  'holy_shield': {'hardened', 'quick', 'eco', 'enduring'},
  'heal_potion': {'quick', 'eco', 'enduring'},
  'demon_form': {'quick', 'eco'},
  'metallicize': {'quick', 'eco'},
  'rage_form': {'quick', 'eco'},
  'concentration': {'quick'},
  'focus': {'quick'},
  'mana_surge': {'quick'},
};

/// Les huit runes livrées, et l'offre qu'elles font aux 23 cartes livrées
/// (spec P-43 E1, §3.2, §4.8, §8).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;

  setUpAll(() async {
    registry = await loadGameDataRegistry(rootBundle);
  });

  // `maxLevel` est obligatoire au chargement (A8) : une rune chargée porte la
  // clé, `null` compris.
  for (final MapEntry(key: id, value: expected) in _expected.entries) {
    test('$id declare ce que la spec fixe', () {
      final rune = registry.forgeUpgrades.singleWhere((r) => r.id == id);
      expect(_declared(rune), expected);
    });
  }

  test('la matrice couvre les 23 cartes livrees', () {
    expect(registry.cards.map((c) => c.id).toSet(), _offers.keys.toSet());
  });

  for (final MapEntry(key: cardId, value: runes) in _offers.entries) {
    test('$cardId recoit ${runes.length} rune(s)', () {
      final card =
          CardInstance(data: registry.cards.singleWhere((c) => c.id == cardId));
      expect(
        {
          for (final rune in registry.forgeUpgrades)
            if (ForgeRuneRules.isEligible(rune, card, registry.forgeUpgrades))
              rune.id,
        },
        runes,
      );
    });
  }
}
