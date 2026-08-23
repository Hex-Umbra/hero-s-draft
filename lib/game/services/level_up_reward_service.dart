import 'dart:math';

enum RewardRarity { common, uncommon, rare, epic, legendary, mythic }

/// Stable technical identifier for each level-up reward choice, used both to
/// resolve localized display strings and to apply the choice's effect.
/// Replaces matching on the (French, user-facing) display text.
enum LevelUpRewardType {
  vitality,
  sharpening,
  steelForge,
  wisdom,
  luckyClover,
  mirror,
  precision,
  ferocity,
}

class DraftChoice {
  final LevelUpRewardType type;
  final int pvBoost;
  final int atkBoost;
  final int armorBoost;
  final int manaBoost;
  final int luckBoost;
  final bool isCloneOption;
  final RewardRarity rarity;
  final int critChanceBoost;
  final double critDamageBoost;

  const DraftChoice({
    required this.type,
    this.pvBoost = 0,
    this.atkBoost = 0,
    this.armorBoost = 0,
    this.manaBoost = 0,
    this.luckBoost = 0,
    this.isCloneOption = false,
    this.rarity = RewardRarity.common,
    this.critChanceBoost = 0,
    this.critDamageBoost = 0.0,
  });
}

/// Rolls and generates the "level up" reward choices (permanent stat boosts,
/// lucky clover, magic mirror clone) offered on [DraftScreen]. Pure/stateless
/// so it can be unit-tested directly, instead of only through a copy of its
/// formula duplicated in a test file.
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
    required int luck,
    bool forceLegendary = false,
  }) {
    final rng = Random();

    final choices = List.generate(3, (index) {
      RewardRarity rarity;
      if (forceLegendary) {
        if (index == 0) {
          rarity = RewardRarity.uncommon;
        } else if (index == 1) {
          rarity = RewardRarity.epic;
        } else {
          rarity = RewardRarity.legendary;
        }
      } else {
        rarity = rollRarity(luck, canBeLegendary: true, isLevelReward: false);
      }

      // Un `switch` exhaustif, pas une cascade de `if` : l'analyseur refuse
      // alors tout palier de rarete oublie. C'est precisement une cascade de
      // `if` qui avait laisse passer l'absence du palier legendaire sur la
      // Maitrise d'Armure ci-dessous, ou un legendaire retombait sur la
      // valeur d'un commun.
      //
      // `mythic` est inatteignable ici — `rollRarity` ne le rend que pour
      // `isLevelReward: true`, et les deux options mythiques (Trefle, Miroir)
      // sont construites a part, sans passer par ce multiplicateur. On le
      // groupe avec `legendary` pour rester exhaustif sans inventer un palier.
      final double multiplier;
      switch (rarity) {
        case RewardRarity.common:
          multiplier = 1.0;
        case RewardRarity.uncommon:
          multiplier = 1.5;
        case RewardRarity.rare:
          multiplier = 2.0;
        case RewardRarity.epic:
          multiplier = 3.0;
        case RewardRarity.legendary:
        case RewardRarity.mythic:
          multiplier = 4.0;
      }

      int type = rng.nextInt(6);
      if (type == 0) {
        int boost = (5 * multiplier).round();
        return DraftChoice(
          type: LevelUpRewardType.vitality,
          pvBoost: boost,
          rarity: rarity,
        );
      }
      if (type == 1) {
        int boost = (2 * multiplier).round();
        return DraftChoice(
          type: LevelUpRewardType.sharpening,
          atkBoost: boost,
          rarity: rarity,
        );
      }
      if (type == 2) {
        // La Maitrise d'Armure a sa propre courbe : elle s'ajoute a *chaque*
        // gain d'armure du passif, donc a chaque tour pour le Paladin mais a
        // chaque Competence jouee pour le Mage. Elle compose plus fort que
        // les autres recompenses, d'ou une progression distincte.
        final int boost;
        switch (rarity) {
          case RewardRarity.common:
            boost = 1;
          case RewardRarity.uncommon:
            boost = 2;
          case RewardRarity.rare:
            boost = 3;
          case RewardRarity.epic:
            boost = 5;
          case RewardRarity.legendary:
          case RewardRarity.mythic:
            boost = 7;
        }
        return DraftChoice(
          type: LevelUpRewardType.steelForge,
          armorBoost: boost,
          rarity: rarity,
        );
      }
      if (type == 3) {
        int boost = (1 * multiplier).round();
        if (boost < 1) boost = 1;
        return DraftChoice(
          type: LevelUpRewardType.wisdom,
          manaBoost: boost,
          rarity: rarity,
        );
      }
      if (type == 4) {
        int boost;
        switch (rarity) {
          case RewardRarity.common:
            boost = 1;
            break;
          case RewardRarity.uncommon:
            boost = 2;
            break;
          case RewardRarity.rare:
            boost = 3;
            break;
          case RewardRarity.epic:
            boost = 4;
            break;
          case RewardRarity.legendary:
          case RewardRarity.mythic:
            boost = 5;
            break;
        }
        return DraftChoice(
          type: LevelUpRewardType.precision,
          critChanceBoost: boost,
          rarity: rarity,
        );
      }
      double boost;
      switch (rarity) {
        case RewardRarity.common:
          boost = 0.10;
          break;
        case RewardRarity.uncommon:
          boost = 0.20;
          break;
        case RewardRarity.rare:
          boost = 0.30;
          break;
        case RewardRarity.epic:
          boost = 0.40;
          break;
        case RewardRarity.legendary:
        case RewardRarity.mythic:
          boost = 0.50;
          break;
      }
      return DraftChoice(
        type: LevelUpRewardType.ferocity,
        critDamageBoost: boost,
        rarity: rarity,
      );
    });

    if (rollRarity(luck, isLevelReward: true, forceLegendary: forceLegendary) ==
        RewardRarity.mythic) {
      choices.add(
        const DraftChoice(
          type: LevelUpRewardType.luckyClover,
          luckBoost: 1,
          rarity: RewardRarity.mythic,
        ),
      );
    }

    if (rollRarity(luck, isLevelReward: true, forceLegendary: forceLegendary) ==
        RewardRarity.mythic) {
      choices.add(
        const DraftChoice(
          type: LevelUpRewardType.mirror,
          isCloneOption: true,
          rarity: RewardRarity.mythic,
        ),
      );
    }

    return choices;
  }
}
