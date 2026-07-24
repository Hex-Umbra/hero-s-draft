import 'package:flutter/foundation.dart';
import '../../../models/data/enemy_data.dart';
import '../../../models/map_node.dart';
import '../systems/encounter_system.dart';

/// Service responsible for logging combat initialization details with formatted output.
class CombatDebugLogger {
  /// Logs the combat initialization mathematics and parameters.
  static void logCombatInitialization({
    required int playerLevel,
    required int act,
    required MapNodeType? nodeType,
    required int playerMaxHp,
    required int playerAttaque,
    required int playerMaxMana,
    required int playerRelicsCount,
    required double playerPower,
    required double expectedPower,
    required double baseBudget,
    required double powerRatio,
    required double powerModifier,
    required double nodeMultiplier,
    required double finalBudget,
    required int enemyLevel,
    required double hpMultiplier,
    required double damageMultiplier,
    required List<EnemyData> enemyDataList,
    required bool isBoss,
    required bool isElite,
  }) {
    if (!kDebugMode) return;

    // ANSI Escape codes
    const reset = '\x1B[0m';
    const bold = '\x1B[1m';
    const cyan = '\x1B[36m';
    const yellow = '\x1B[33m';
    const green = '\x1B[32m';
    const magenta = '\x1B[35m';
    const red = '\x1B[31m';

    final nodeTypeString = nodeType?.name ?? 'normal';

    final buffer = StringBuffer();
    
    // Helper to build a line with fixed width of 76 characters inside borders
    String buildLine(String content, {String prefix = '', String suffix = ''}) {
      const totalWidth = 76;
      final paddedContent = content.padRight(totalWidth);
      return '$cyan│$reset $prefix$paddedContent$suffix $cyan│$reset';
    }

    buffer.writeln('$cyan┌──────────────────────────────────────────────────────────────────────────────┐$reset');
    buffer.writeln(buildLine('⚔️  COMBAT INITIALIZATION MATHEMATICS', prefix: '$bold$red', suffix: reset));
    buffer.writeln('$cyan├──────────────────────────────────────────────────────────────────────────────┤$reset');
    
    // Player Stats Section
    buffer.writeln(buildLine('👤 PLAYER STATS:', prefix: '$bold$yellow', suffix: reset));
    buffer.writeln(buildLine('  • Level: ${playerLevel.toString().padRight(4)} Act: ${act.toString().padRight(4)} Node Type: ${nodeTypeString.padRight(36)}'));
    buffer.writeln(buildLine('  • Max HP: ${playerMaxHp.toString().padRight(4)} Attack: ${playerAttaque.toString().padRight(4)} Max Mana: ${playerMaxMana.toString().padRight(4)} Relics: ${playerRelicsCount.toString().padRight(12)}'));
    buffer.writeln(buildLine(''));

    // Formulas & Calculations Section
    buffer.writeln(buildLine('📊 FORMULAS & CALCULATIONS:', prefix: '$bold$yellow', suffix: reset));
    
    // PlayerPower
    buffer.writeln(buildLine('  • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5)'));
    final pPowerCalc = '    $playerMaxHp + ($playerAttaque * 10) + ($playerMaxMana * 15) + ($playerRelicsCount * 5) = $playerPower';
    buffer.writeln(buildLine(pPowerCalc, prefix: green, suffix: reset));
    
    // ExpectedPower
    buffer.writeln(buildLine('  • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20]'));
    final ePowerCalc = '    145 + [($playerLevel - 1) * 15] + [($act - 1) * 20] = $expectedPower';
    buffer.writeln(buildLine(ePowerCalc, prefix: green, suffix: reset));

    // BaseBudget
    buffer.writeln(buildLine('  • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]'));
    final bBudgetCalc = '    40 + [($playerLevel - 1) * 10] + [($act - 1) * 25] = $baseBudget';
    buffer.writeln(buildLine(bBudgetCalc, prefix: green, suffix: reset));

    // PowerRatio & PowerModifier
    buffer.writeln(buildLine('  • PowerRatio calculation: PlayerPower / ExpectedPower'));
    final pRatioCalc = '    $playerPower / $expectedPower = $powerRatio';
    buffer.writeln(buildLine(pRatioCalc, prefix: green, suffix: reset));

    buffer.writeln(buildLine('  • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5'));
    final pModCalc = '    1.0 + ($powerRatio - 1.0) * 0.5 = $powerModifier';
    buffer.writeln(buildLine(pModCalc, prefix: green, suffix: reset));

    // Multipliers & Budget
    buffer.writeln(buildLine('  • NodeMultiplier: $nodeMultiplier (Boss = 2.0, Elite = 1.5, Normal = 1.0)'));
    buffer.writeln(buildLine('  • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier'));
    final fBudgetCalc = '    $baseBudget * $powerModifier * $nodeMultiplier = $finalBudget';
    buffer.writeln(buildLine(fBudgetCalc, prefix: green, suffix: reset));
    buffer.writeln(buildLine(''));

    // Scaling Details Section
    buffer.writeln(buildLine('⚙️  SCALING DETAILS:', prefix: '$bold$yellow', suffix: reset));
    buffer.writeln(buildLine('  • Enemy Level: max(1, playerLevel + nodeModifier) = $enemyLevel'));
    buffer.writeln(buildLine('  • HP scaling multiplier: $hpMultiplier'));
    buffer.writeln(buildLine('  • Damage scaling multiplier: $damageMultiplier'));
    buffer.writeln(buildLine(''));

    // Generated Enemies Section
    buffer.writeln(buildLine('👾 GENERATED ENEMIES (Count: ${enemyDataList.length}):', prefix: '$bold$yellow', suffix: reset));
    for (var data in enemyDataList) {
      final rating = EncounterSystem.calculateCombatRating(
        data: data,
        enemyLevel: enemyLevel,
        act: act,
        isBoss: isBoss,
        isElite: isElite,
      );
      final enemyLine = '  - Enemy: ${data.nameEn} (Tier: ${data.tier}), HP: ${(data.maxHp * hpMultiplier).round()}, Dmg: ${(data.baseDamage * damageMultiplier).round()}, CR: $rating';
      buffer.writeln(buildLine(enemyLine, prefix: magenta, suffix: reset));
    }
    
    buffer.writeln('$cyan└──────────────────────────────────────────────────────────────────────────────┘$reset');

    debugPrint(buffer.toString());
  }
}
