import 'dart:math';
import '../../models/data/charge_data.dart';
import '../../models/entity_stats.dart';
import '../systems/charge_rules.dart';
import 'proportional_status.dart';

class DamagePipeline {
  /// [critChanceBonus] : les points de pourcentage de critique que la carte
  /// jouée ajoute à ceux de l'attaquant — ses runes (`critBonus`, spec P-43
  /// E2, §4.2) ; 0 pour un ennemi.
  static (int damage, bool isCrit) calculate({
    required int initialDamage,
    required EntityStats attackerStats,
    required EntityStats defenderStats,
    required ChargeCatalog charges,
    bool canCrit = true,
    int critChanceBonus = 0,
  }) {
    int totalDamage = initialDamage;

    // 1. Weakness (faiblesse) de l'attaquant : réduit les dégâts selon ses
    // points, au barème de [ProportionalStatus.weakness] (arrondi)
    final weaknessPercent = ProportionalStatus.weakness.percentOn(attackerStats);
    if (weaknessPercent > 0) {
      totalDamage = (totalDamage * (100 - weaknessPercent) / 100).round();
    }

    // 1 bis. Héros gelé (piste `weakenDealt` active) : réduit les dégâts de
    // son pourcentage, au même arrondi
    final weakenPercent = ChargeRules.weakenPercent(attackerStats);
    if (weakenPercent > 0) {
      totalDamage = (totalDamage * (100 - weakenPercent) / 100).round();
    }

    // 2. Coup critique de l'attaquant : multiplie les dégâts par critMultiplier
    bool isCrit = false;
    if (canCrit) {
      final random = Random();
      if (random.nextInt(100) <
          attackerStats.effectiveCritChance + critChanceBonus) {
        totalDamage = (totalDamage * attackerStats.critMultiplier).round();
        isCrit = true;
      }
    }

    // 3. Charges du défenseur qui amplifient les coups (la Foudre) : un bonus
    // par coup, après le critique
    totalDamage += ChargeRules.hitBonus(defenderStats, charges);

    // 4. Vulnerable (vulnérabilité) du défenseur : augmente les dégâts selon
    // ses points, au barème de [ProportionalStatus.vulnerable] (arrondi)
    final vulnerablePercent =
        ProportionalStatus.vulnerable.percentOn(defenderStats);
    if (vulnerablePercent > 0) {
      totalDamage = (totalDamage * (100 + vulnerablePercent) / 100).round();
    }

    // Garde-fou pour éviter des dégâts négatifs
    if (totalDamage < 0) {
      totalDamage = 0;
    }

    return (totalDamage, isCrit);
  }
}
