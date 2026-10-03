import 'dart:math';

import '../game_constants.dart';

/// Le tirage de la trouvaille (spec P-43 E3, §4.1 ; D1, D31, D57) : combien
/// de cartes un combat gagné fait trouver. Fonction pure ; lesquelles, c'est
/// `RewardController.handleVictory` qui les tire.
abstract final class CardDrops {
  /// [rule] nulle — un type de nœud absent de `GameConstants.cardDrops`, le
  /// boss — : aucune carte. Sinon `guaranteed + extraGuaranteed`, puis un
  /// jet par chance de `extraChances`, la première augmentée de
  /// [firstExtraBonus] : une carte de plus si `rng.nextInt(100) < chance`,
  /// l'arrêt au premier raté.
  static int roll(
    CardDropRule? rule, {
    int extraGuaranteed = 0,
    int firstExtraBonus = 0,
    required Random rng,
  }) {
    if (rule == null) return 0;
    var count = rule.guaranteed + extraGuaranteed;
    for (var i = 0; i < rule.extraChances.length; i++) {
      final chance = rule.extraChances[i] + (i == 0 ? firstExtraBonus : 0);
      if (rng.nextInt(100) >= chance) break;
      count++;
    }
    return count;
  }
}
