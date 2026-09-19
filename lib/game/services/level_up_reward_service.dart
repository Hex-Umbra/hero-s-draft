import 'dart:math';

import '../../models/data/level_up_reward_data.dart';
import '../../models/data/passive_data.dart';
import '../../models/reward_rarity.dart';

/// Une récompense tirée : ce qu'elle est, à quel palier, et pour combien.
///
/// Avant P-41 lot C, cette classe portait sept accumulateurs (`pvBoost`,
/// `mightBoost`, …) dont un seul était non nul à la fois, plus un `type`
/// d'énumération. La récompense étant devenue de la donnée, elle porte la
/// donnée.
class DraftChoice {
  final LevelUpRewardData data;
  final RewardRarity rarity;

  /// La valeur du gain à ce palier. Pour `RewardStat.critDamage`, en points de
  /// pourcentage : c'est l'application qui divise par 100.
  final int amount;

  const DraftChoice({
    required this.data,
    required this.rarity,
    required this.amount,
  });

  /// Le Miroir : la seule récompense qui ouvre une modale au lieu de monter
  /// une stat.
  bool get isCloneOption => data.effect == RewardEffect.cloneCard;
}

/// Tire les choix de récompense offerts à la montée de niveau, depuis le
/// catalogue de `assets/data/level_up_rewards/` (spec P-41, §8.1). Pur et sans
/// état, pour se tester directement.
class LevelUpRewardService {
  const LevelUpRewardService._();

  static RewardRarity rollRarity(
    int luck, {
    bool canBeLegendary = true,
    bool isLevelReward = false,
    bool forceLegendary = false,
  }) {
    if (forceLegendary) {
      if (isLevelReward) {
        return RewardRarity.mythic;
      }
    }
    final rng = Random();
    double mythicChance = isLevelReward ? 0.5 : 0.0;
    double legendaryChance = 2.0;
    double epicChance = 6.0;
    double rareChance = 16.0;
    double uncommonChance = 24.0;

    if (isLevelReward) {
      mythicChance += luck * 0.15;
    }
    legendaryChance += luck * 0.5;
    epicChance += luck * 1.5;
    rareChance += luck * 3.0;
    uncommonChance += luck * 4.0;

    double roll = rng.nextDouble() * 100;

    if (isLevelReward && roll < mythicChance) {
      return RewardRarity.mythic;
    }
    if (isLevelReward) {
      roll -= mythicChance;
    }

    if (canBeLegendary && roll < legendaryChance) return RewardRarity.legendary;
    if (!canBeLegendary) {
      roll = (rng.nextDouble() * (100 - legendaryChance)) + legendaryChance;
    } else {
      roll -= legendaryChance;
    }

    if (roll < epicChance) return RewardRarity.epic;
    roll -= epicChance;
    if (roll < rareChance) return RewardRarity.rare;
    roll -= rareChance;
    if (roll < uncommonChance) return RewardRarity.uncommon;

    return RewardRarity.common;
  }

  static List<DraftChoice> generateChoices({
    required List<LevelUpRewardData> rewards,
    required int luck,
    bool forceLegendary = false,
    PassiveData? activePassive,
  }) {
    final rng = Random();
    // Le filtre s'applique à la table des trois emplacements comme aux
    // mythiques : une exigence est une propriété de la récompense, pas du
    // groupe de tirage (spec P-41, §8.2).
    final eligible =
        rewards.where((reward) => reward.isAvailableWith(activePassive)).toList();
    final draftable = LevelUpRewardData.inPool(eligible, RewardPool.draft);
    // Un registre sans récompense tirable : aucun choix à générer, liste
    // vide — pas d'exception au milieu d'une montée de niveau. L'écran de
    // draft affiche alors un plateau vide plutôt que de planter dessus.
    if (draftable.isEmpty) return const [];

    final choices = List.generate(3, (index) {
      final RewardRarity rarity;
      if (forceLegendary) {
        rarity = switch (index) {
          0 => RewardRarity.uncommon,
          1 => RewardRarity.epic,
          _ => RewardRarity.legendary,
        };
      } else {
        rarity = rollRarity(luck, canBeLegendary: true, isLevelReward: false);
      }

      final reward = draftable[rng.nextInt(draftable.length)];
      return DraftChoice(
        data: reward,
        rarity: rarity,
        amount: reward.amountFor(rarity),
      );
    });

    // Un jet indépendant par récompense mythique, dans l'ordre déclaré — c'est
    // exactement ce que faisaient les deux blocs écrits en dur, Trèfle puis
    // Miroir. Une troisième mythique n'est plus qu'un fichier.
    for (final mythic in LevelUpRewardData.inPool(eligible, RewardPool.mythic)) {
      final rolled = rollRarity(
        luck,
        isLevelReward: true,
        forceLegendary: forceLegendary,
      );
      if (rolled == RewardRarity.mythic) {
        choices.add(
          DraftChoice(
            data: mythic,
            rarity: RewardRarity.mythic,
            amount: mythic.amountFor(RewardRarity.mythic),
          ),
        );
      }
    }

    return choices;
  }
}
