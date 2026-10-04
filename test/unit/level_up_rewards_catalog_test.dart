import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/level_up_reward_data.dart';
import 'package:roguelike_card_game/models/reward_rarity.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Le catalogue des récompenses de niveau, lu depuis le vrai bundle
/// (spec P-41, §8.1).
///
/// Ce test regarde la **donnée** ; `level_up_reward_values_test.dart` regarde
/// ce que le tirage en fait. Les deux verrouillent la même table : l'un au
/// chargement, l'autre à l'usage.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// La table des cinq récompenses tirables, à valeurs identiques (spec
  /// P-41, §8.1 : « à valeurs identiques »). *Sagesse* n'en est plus :
  /// mythique depuis D11, son plateau a disparu avec ses paliers (spec P-43
  /// E3, §3.5).
  const attendu = <String, Map<RewardRarity, int>>{
    'vitality': {
      RewardRarity.common: 5,
      RewardRarity.uncommon: 8,
      RewardRarity.rare: 10,
      RewardRarity.epic: 15,
      RewardRarity.legendary: 20,
    },
    'sharpening': {
      RewardRarity.common: 2,
      RewardRarity.uncommon: 3,
      RewardRarity.rare: 4,
      RewardRarity.epic: 6,
      RewardRarity.legendary: 8,
    },
    'affinity': {
      RewardRarity.common: 1,
      RewardRarity.uncommon: 2,
      RewardRarity.rare: 3,
      RewardRarity.epic: 5,
      RewardRarity.legendary: 7,
    },
    'precision': {
      RewardRarity.common: 1,
      RewardRarity.uncommon: 2,
      RewardRarity.rare: 3,
      RewardRarity.epic: 4,
      RewardRarity.legendary: 5,
    },
    'ferocity': {
      RewardRarity.common: 10,
      RewardRarity.uncommon: 20,
      RewardRarity.rare: 30,
      RewardRarity.epic: 40,
      RewardRarity.legendary: 50,
    },
  };

  test('les neuf récompenses se chargent depuis le vrai bundle', () async {
    final registry = await loadGameDataRegistry(rootBundle);

    expect(registry.levelUpRewards, hasLength(9));
    expect(
      registry.levelUpRewards.map((r) => r.id).toSet(),
      {...attendu.keys, 'wisdom', 'lucky_clover', 'mirror', 'transcendence'},
    );
  });

  test('les cinq récompenses tirables portent la table d aujourd hui', () async {
    final registry = await loadGameDataRegistry(rootBundle);
    final byId = {for (final r in registry.levelUpRewards) r.id: r};

    for (final entree in attendu.entries) {
      final reward = byId[entree.key];
      expect(reward, isNotNull, reason: entree.key);
      expect(reward!.pool, RewardPool.draft, reason: entree.key);
      for (final palier in entree.value.entries) {
        expect(
          reward.amountFor(palier.key),
          palier.value,
          reason: '${entree.key} en ${palier.key.name}',
        );
      }
    }
  });

  test('les quatre mythiques sont hors du tirage des trois emplacements', () async {
    final registry = await loadGameDataRegistry(rootBundle);
    final mythiques = registry.levelUpRewards
        .where((r) => r.pool == RewardPool.mythic)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    expect(mythiques.map((r) => r.id),
        ['wisdom', 'lucky_clover', 'mirror', 'transcendence']);
    // Par id, et non par place : la place change avec le catalogue.
    final byId = {for (final r in mythiques) r.id: r};
    expect(byId['wisdom']!.stat, RewardStat.maxMana);
    expect(byId['wisdom']!.amountFor(RewardRarity.mythic), 1);
    expect(byId['lucky_clover']!.amountFor(RewardRarity.mythic), 1);
    expect(byId['mirror']!.effect, RewardEffect.cloneCard);
    expect(byId['transcendence']!.effect, RewardEffect.raiseRuneCap);
  });

  test('les neuf récompenses portent leurs deux langues', () async {
    // La règle de `CLAUDE.md`, vérifiée sur les vrais fichiers : les libellés
    // quittent les ARB, les traductions les suivent. `fromJson` refuse déjà un
    // `_fr` sans son `_en` ; ce test-ci vérifie que le catalogue livré n'a pas
    // de texte français recopié tel quel côté anglais.
    final registry = await loadGameDataRegistry(rootBundle);

    for (final reward in registry.levelUpRewards) {
      expect(reward.nameFr, isNotEmpty, reason: reward.id);
      expect(reward.nameEn, isNotEmpty, reason: reward.id);
      expect(
        reward.describe('fr', amount: 1),
        isNot(reward.describe('en', amount: 1)),
        reason: '${reward.id} : la description anglaise n\'est pas traduite',
      );
    }
  });

  test('le rang de tirage est déclaré, unique et sans trou', () async {
    final registry = await loadGameDataRegistry(rootBundle);
    final rangs = registry.levelUpRewards.map((r) => r.displayOrder).toList()
      ..sort();

    // L'ancien `rng.nextInt(6)` tirait un index : l'ordre des valeurs de
    // l'enum EN ETAIT la sémantique. En donnée, ce rang doit être déclaré,
    // pas hérité de l'ordre de lecture du disque.
    expect(rangs, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
  });
}
