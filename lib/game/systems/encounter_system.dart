import 'dart:math';
import '../../models/data/enemy_data.dart';
import '../../models/map_node.dart';

class EncounterSystem {
  static final Random _rng = Random();

  static const double _hpBracketGrowthRate = 1.35;
  static const double _dmgBracketGrowthRate = 1.25;
  static const double _hpIntraBracketStep = 0.05;
  static const double _dmgIntraBracketStep = 0.03;
  static const int _actBracketSize = 5;
  static const int _tierUnlockBracketSize = 10;
  static const int maxTierAuthored = 3;

  /// Which 5-act difficulty bracket this act falls in (0 for acts 1-5, 1 for acts 6-10, ...).
  static int getActBracket(int act) => ((act - 1) / _actBracketSize).floor();

  /// Position within the current 5-act bracket (0 to 4).
  static int getActPositionInBracket(int act) => (act - 1) % _actBracketSize;

  /// Combined act factor for HP: a geometric jump every 5 acts, plus a gentle
  /// ramp that resets each bracket. Replaces the old direct `(1 + 0.35*(act-1))`
  /// term, which double-counted the act inside `enemyLevel` as well.
  static double getHpActFactor(int act) {
    final bracket = getActBracket(act);
    final positionInBracket = getActPositionInBracket(act);
    final bracketMultiplier = pow(_hpBracketGrowthRate, bracket).toDouble();
    final intraBracketRamp = 1.0 + positionInBracket * _hpIntraBracketStep;
    return bracketMultiplier * intraBracketRamp;
  }

  /// Same as [getHpActFactor] but for damage, using the damage-specific rates.
  static double getDamageActFactor(int act) {
    final bracket = getActBracket(act);
    final positionInBracket = getActPositionInBracket(act);
    final bracketMultiplier = pow(_dmgBracketGrowthRate, bracket).toDouble();
    final intraBracketRamp = 1.0 + positionInBracket * _dmgIntraBracketStep;
    return bracketMultiplier * intraBracketRamp;
  }

  /// Highest enemy tier available at this act: tier 1 through act 10, tier 2
  /// from act 11, tier 3 from act 21, capped at [maxTierAuthored].
  static int getUnlockedTier(int act) {
    final unlocked = 1 + ((act - 1) / _tierUnlockBracketSize).floor();
    return unlocked > maxTierAuthored ? maxTierAuthored : unlocked;
  }

  /// Calculates the enemy level based on player parameters.
  static int getEnemyLevel({
    required int playerLevel,
    required int act,
    required bool isBoss,
    required bool isElite,
  }) {
    int nodeModifier = 0;
    if (isBoss) {
      nodeModifier = 2;
    } else if (isElite) {
      nodeModifier = 1;
    }
    return max(1, playerLevel + (act - 1) * 2 + nodeModifier);
  }

  /// Calculates the HP scaling multiplier.
  static double getHpMultiplier({
    required int enemyLevel,
    required int act,
    required bool isBoss,
    required bool isElite,
    bool isCustomBoss = false,
  }) {
    final double bossHpMultiplier = isBoss ? (isCustomBoss ? 1.0 : 3.0) : (isElite ? 1.5 : 1.0);
    return (1.0 + 0.06 * (enemyLevel - 1)) *
        (1.0 + 0.35 * (act - 1)) *
        bossHpMultiplier;
  }

  /// Calculates the damage scaling multiplier.
  static double getDamageMultiplier({
    required int enemyLevel,
    required int act,
    required bool isBoss,
    required bool isElite,
    bool isCustomBoss = false,
  }) {
    final double bossDmgMultiplier = isBoss ? (isCustomBoss ? 1.0 : 3.0) : (isElite ? 1.5 : 1.0);
    return (1.0 + 0.04 * (enemyLevel - 1)) *
        (1.0 + 0.25 * (act - 1)) *
        bossDmgMultiplier;
  }

  /// Calculates the combat rating for a given enemy under specific parameters.
  static double calculateCombatRating({
    required EnemyData data,
    required int enemyLevel,
    required int act,
    required bool isBoss,
    required bool isElite,
  }) {
    final bool isCustomBoss = data.id.startsWith('boss_');

    final double hpMultiplier = getHpMultiplier(
      enemyLevel: enemyLevel,
      act: act,
      isBoss: isBoss,
      isElite: isElite,
      isCustomBoss: isCustomBoss,
    );

    final double damageMultiplier = getDamageMultiplier(
      enemyLevel: enemyLevel,
      act: act,
      isBoss: isBoss,
      isElite: isElite,
      isCustomBoss: isCustomBoss,
    );

    final int hpScale = (data.maxHp * hpMultiplier).round();
    final int damageScale = (data.baseDamage * damageMultiplier).round();

    return (data.tier * 15.0) + (hpScale / 4.0) + (damageScale * 2.0) * (1.0 + data.critChance / 100.0);
  }

  static List<EnemyData> generateEnemiesForLevel(
    int level,
    List<EnemyData> availableEnemies, {
    MapNodeType? nodeType,
    int playerLevel = 1,
    int act = 1,
    int playerMaxHp = 100,
    int playerAttaque = 0,
    int playerMaxMana = 3,
    int playerRelicsCount = 0,
    int playerCardsCount = 0,
    String? bossEnemyId,
  }) {
    if (availableEnemies.isEmpty) return [];
 
    final bool isBoss = nodeType == MapNodeType.boss || (nodeType == null && level > 0 && level % 10 == 0);
    final bool isElite = nodeType == MapNodeType.elite;




    // 1. Calculate player power, expected power, base budget
    final double playerPower = playerMaxHp +
        (playerAttaque * 10.0) +
        (playerMaxMana * 15.0) +
        (playerRelicsCount * 5.0) +
        (playerCardsCount * 2.0);

    final double expectedPower =
        145.0 + ((playerLevel - 1) * 15.0) + ((act - 1) * 20.0);

    final double baseBudget =
        40.0 + ((playerLevel - 1) * 10.0) + ((act - 1) * 25.0);

    // 2. Power ratio and power modifier
    final double powerRatio = playerPower / expectedPower;
    final double powerModifier = 1.0 + (powerRatio - 1.0) * 0.5;

    // 3. Node multiplier
    double nodeMultiplier = 1.0;
    if (isBoss) {
      nodeMultiplier = 2.0;
    } else if (isElite) {
      nodeMultiplier = 1.5;
    }

    // 4. Final budget
    final double finalBudget = baseBudget * powerModifier * nodeMultiplier + (act - 1) * 10.0;

    // Determine enemy level for combat rating calculation
    final int enemyLevel = getEnemyLevel(
      playerLevel: playerLevel,
      act: act,
      isBoss: isBoss,
      isElite: isElite,
    );

    double calculateCombatRatingForEnemy(EnemyData data) {
      return calculateCombatRating(
        data: data,
        enemyLevel: enemyLevel,
        act: act,
        isBoss: isBoss,
        isElite: isElite,
      );
    }

    final List<EnemyData> generatedEnemies = [];
    double remainingBudget = finalBudget;

    // Choose enemies without exceeding remaining budget
    while (remainingBudget > 0 && generatedEnemies.length < 10) {
      final candidates = availableEnemies.where((enemy) {
        final rating = calculateCombatRatingForEnemy(enemy);
        return rating <= remainingBudget;
      }).toList();

      if (candidates.isEmpty) {
        break;
      }

      final chosen = candidates[_rng.nextInt(candidates.length)];
      generatedEnemies.add(chosen);
      remainingBudget -= calculateCombatRatingForEnemy(chosen);
    }

    // Fallback if no enemies could fit into budget: choose the one with the lowest combat rating
    if (generatedEnemies.isEmpty && availableEnemies.isNotEmpty) {
      EnemyData lowest = availableEnemies.first;
      double lowestRating = calculateCombatRatingForEnemy(lowest);
      for (int i = 1; i < availableEnemies.length; i++) {
        final r = calculateCombatRatingForEnemy(availableEnemies[i]);
        if (r < lowestRating) {
          lowestRating = r;
          lowest = availableEnemies[i];
        }
      }
      generatedEnemies.add(lowest);
    }

    return generatedEnemies;
  }
}
