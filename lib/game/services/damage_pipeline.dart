import 'dart:math';
import '../../models/entity_stats.dart';
import '../../models/status_effect.dart';

class DamagePipeline {
  static (int damage, bool isCrit) calculate({
    required int initialDamage,
    required EntityStats attackerStats,
    required EntityStats defenderStats,
    bool canCrit = true,
  }) {
    int totalDamage = initialDamage;

    // 1. Weakness (faiblesse) de l'attaquant : réduit les dégâts de 25% (arrondi)
    final hasWeakness = attackerStats.statuses.any((s) => s.id == 'weakness');
    if (hasWeakness) {
      totalDamage = (totalDamage * 0.75).round();
    }

    // 2. Coup critique de l'attaquant : multiplie les dégâts par critMultiplier
    bool isCrit = false;
    if (canCrit) {
      final random = Random();
      if (random.nextInt(100) < attackerStats.effectiveCritChance) {
        totalDamage = (totalDamage * attackerStats.critMultiplier).round();
        isCrit = true;
      }
    }

    // 3. Shock (choc) du défenseur : ajoute la valeur de shock au total
    final shockStatus = defenderStats.statuses.firstWhere(
      (s) => s.id == 'shock',
      orElse: () => const StatusEffect(
        id: '',
        name: '',
        type: StatusType.debuff,
        value: 0,
        duration: 0,
      ),
    );
    if (shockStatus.id.isNotEmpty) {
      totalDamage += shockStatus.value;
    }

    // 4. Vulnerable (vulnérabilité) du défenseur : augmente les dégâts de 50% (arrondi)
    final hasVulnerable = defenderStats.statuses.any((s) => s.id == 'vulnerable');
    if (hasVulnerable) {
      totalDamage = (totalDamage * 1.5).round();
    }

    // Garde-fou pour éviter des dégâts négatifs
    if (totalDamage < 0) {
      totalDamage = 0;
    }

    return (totalDamage, isCrit);
  }
}
