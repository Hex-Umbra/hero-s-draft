import 'dart:math';
import '../../models/data/enemy_data.dart';
import '../../models/map_node.dart';

/// Breakdown of the combat budget calculation — see [EncounterSystem.calculateBudget].
typedef BudgetBreakdown = ({
  double playerPower,
  double expectedPower,
  double baseBudget,
  double powerRatio,
  double powerModifier,
  double nodeMultiplier,
  double finalBudget,
});

class EncounterSystem {
  static final Random _rng = Random();

  static const double _hpBracketGrowthRate = 1.35;
  static const double _dmgBracketGrowthRate = 1.25;
  static const double _hpIntraBracketStep = 0.05;
  static const double _dmgIntraBracketStep = 0.03;
  static const int _actBracketSize = 2;
  static const int _tierUnlockBracketSize = 5;
  static const int maxTierAuthored = 3;

  /// Which 2-act difficulty bracket this act falls in (0 for acts 1-2, 1 for acts 3-4, ...).
  static int getActBracket(int act) => ((act - 1) / _actBracketSize).floor();

  /// Position within the current 2-act bracket (0 to 1).
  static int getActPositionInBracket(int act) => (act - 1) % _actBracketSize;

  /// Combined act factor for HP: a geometric jump every 2 acts, plus a gentle
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

  /// Highest enemy tier available at this act: tier 1 through act 5, tier 2
  /// from act 6, tier 3 from act 11, capped at [maxTierAuthored].
  static int getUnlockedTier(int act) {
    final unlocked = 1 + ((act - 1) / _tierUnlockBracketSize).floor();
    return unlocked > maxTierAuthored ? maxTierAuthored : unlocked;
  }

  static const int _normalCombatEnemyStep = 1;
  static const int _eliteEnemyStep = 2;
  static const int _bossEnemyStep = 5;

  /// Shared step formula: 1 enemy at act 1, +1 every [stepSize] acts,
  /// unbounded (no ceiling — see spec §3.4 for why this stays safe long-term).
  static int _maxEnemiesFromStep(int act, int stepSize) =>
      1 + ((act - 1) / stepSize).floor();

  /// Max enemies generated for a normal combat node: +1 every act.
  static int getMaxEnemiesForNormalCombat(int act) =>
      _maxEnemiesFromStep(act, _normalCombatEnemyStep);

  /// Max enemies generated for an elite node: +1 every 2 acts.
  static int getMaxEnemiesForElite(int act) =>
      _maxEnemiesFromStep(act, _eliteEnemyStep);

  /// Max enemies generated for a boss node: +1 every 5 acts.
  static int getMaxEnemiesForBoss(int act) =>
      _maxEnemiesFromStep(act, _bossEnemyStep);

  /// Computes the combat budget breakdown (player power vs. expected power,
  /// base/final budget) from player stats and node type. This is the single
  /// source of truth for these values — callers that only need them for
  /// display (e.g. the debug logger) must call this rather than
  /// re-deriving their own copy, to avoid the two calculations drifting.
  static BudgetBreakdown calculateBudget({
    required int playerLevel,
    required int act,
    required int playerMaxHp,
    required int playerAttaque,
    required int playerMaxMana,
    required int playerRelicsCount,
    required int playerCardsCount,
    required bool isBoss,
    required bool isElite,
  }) {
    final double playerPower = playerMaxHp +
        (playerAttaque * 10.0) +
        (playerMaxMana * 15.0) +
        (playerRelicsCount * 5.0) +
        (playerCardsCount * 2.0);

    final double expectedPower =
        145.0 + ((playerLevel - 1) * 15.0) + ((act - 1) * 20.0);

    final double baseBudget =
        40.0 + ((playerLevel - 1) * 10.0) + ((act - 1) * 25.0);

    final double powerRatio = playerPower / expectedPower;
    final double powerModifier = 1.0 + (powerRatio - 1.0) * 0.5;

    double nodeMultiplier = 1.0;
    if (isBoss) {
      nodeMultiplier = 2.0;
    } else if (isElite) {
      nodeMultiplier = 1.5;
    }

    final double finalBudget =
        baseBudget * powerModifier * nodeMultiplier + (act - 1) * 10.0;

    return (
      playerPower: playerPower,
      expectedPower: expectedPower,
      baseBudget: baseBudget,
      powerRatio: powerRatio,
      powerModifier: powerModifier,
      nodeMultiplier: nodeMultiplier,
      finalBudget: finalBudget,
    );
  }

  /// Calculates the enemy level based on player level and node type only.
  /// Act no longer contributes here — it is handled exclusively by
  /// [getHpActFactor]/[getDamageActFactor] to avoid double-counting.
  static int getEnemyLevel({
    required int playerLevel,
    required bool isBoss,
    required bool isElite,
  }) {
    int nodeModifier = 0;
    if (isBoss) {
      nodeModifier = 2;
    } else if (isElite) {
      nodeModifier = 1;
    }
    return max(1, playerLevel + nodeModifier);
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
        getHpActFactor(act) *
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
        getDamageActFactor(act) *
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

    final double finalBudget = calculateBudget(
      playerLevel: playerLevel,
      act: act,
      playerMaxHp: playerMaxHp,
      playerAttaque: playerAttaque,
      playerMaxMana: playerMaxMana,
      playerRelicsCount: playerRelicsCount,
      playerCardsCount: playerCardsCount,
      isBoss: isBoss,
      isElite: isElite,
    ).finalBudget;

    // Determine enemy level for combat rating calculation
    final int enemyLevel = getEnemyLevel(
      playerLevel: playerLevel,
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

    // Restrict the candidate pool to enemies whose tier is unlocked at this
    // act. Fall back to the unfiltered list if that would leave nothing to
    // pick from (e.g. only high-tier content was passed in for a low act).
    final int unlockedTier = getUnlockedTier(act);
    final eligibleEnemies =
        availableEnemies.where((enemy) => enemy.tier <= unlockedTier).toList();
    final List<EnemyData> enemyPool =
        eligibleEnemies.isNotEmpty ? eligibleEnemies : availableEnemies;

    final int maxEnemies = isBoss
        ? getMaxEnemiesForBoss(act)
        : (isElite ? getMaxEnemiesForElite(act) : getMaxEnemiesForNormalCombat(act));

    final List<EnemyData> generatedEnemies = [];
    double remainingBudget = finalBudget;

    // Choose enemies without exceeding remaining budget or the act-scaled cap
    while (remainingBudget > 0 && generatedEnemies.length < maxEnemies) {
      final candidates = enemyPool.where((enemy) {
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
    if (generatedEnemies.isEmpty && enemyPool.isNotEmpty) {
      EnemyData lowest = enemyPool.first;
      double lowestRating = calculateCombatRatingForEnemy(lowest);
      for (int i = 1; i < enemyPool.length; i++) {
        final r = calculateCombatRatingForEnemy(enemyPool[i]);
        if (r < lowestRating) {
          lowestRating = r;
          lowest = enemyPool[i];
        }
      }
      generatedEnemies.add(lowest);
    }

    return generatedEnemies;
  }
}
