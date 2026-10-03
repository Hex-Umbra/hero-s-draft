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
    if (isLevelReward) {
      mythicChance += luck * 0.15;
    }
    final weights = _slotWeights(luck);
    final legendaryChance = weights.legendary;
    final epicChance = weights.epic;
    final rareChance = weights.rare;
    final uncommonChance = weights.uncommon;

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

  /// Les poids, en pourcentage, des quatre raretés au-delà de la commune pour
  /// une Chance donnée : la seule table que lisent le tirage ([rollRarity]) et
  /// la fiche des probabilités ([slotRarityChances]) — sa copie dans la
  /// fiche est précisément ce qui avait divergé (spec P-43 E3, §3.8, C4.7).
  static ({double legendary, double epic, double rare, double uncommon})
      _slotWeights(int luck) => (
            legendary: 2.0 + luck * 0.5,
            epic: 6.0 + luck * 1.5,
            rare: 16.0 + luck * 3.0,
            uncommon: 24.0 + luck * 4.0,
          );

  /// Les chances, en pourcentage, de chaque rareté d'un des trois
  /// emplacements de la montée de niveau — la distribution de
  /// `rollRarity(luck, isLevelReward: false)` —, cinq clés de somme 100, sans
  /// `mythic`, qu'un emplacement ne tire jamais (spec P-43 E3, §3.8, C4.7).
  ///
  /// La troncature suit la cascade de [rollRarity] : de la légendaire à la
  /// peu commune, chaque rareté prend son poids borné entre 0 et ce qui reste
  /// de 100, la commune le reste. Les deux coïncident dès que les quatre
  /// poids sont positifs ou nuls — toute Chance ≥ −4, donc toute Chance d'une
  /// run ; en dessous, que seul le menu de debug atteint, la fiche affiche 0
  /// là où le tirage laisse un poids négatif mordre sur les raretés suivantes.
  /// Lue par la fiche des probabilités.
  static Map<RewardRarity, double> slotRarityChances(int luck) {
    final weights = _slotWeights(luck);
    var remaining = 100.0;
    double take(double weight) {
      final chance = weight.clamp(0.0, remaining);
      remaining -= chance;
      return chance;
    }

    final legendary = take(weights.legendary);
    final epic = take(weights.epic);
    final rare = take(weights.rare);
    final uncommon = take(weights.uncommon);
    return {
      RewardRarity.common: remaining,
      RewardRarity.uncommon: uncommon,
      RewardRarity.rare: rare,
      RewardRarity.epic: epic,
      RewardRarity.legendary: legendary,
    };
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
