import 'dart:math' as math;

/// Le voile d'armure d'une barre de PV ennemie : la part de la barre que
/// couvre l'armure, rapportée au plus haut montant atteint depuis qu'elle
/// est tombée à 0 (spec P-05, §4.1). Les PV n'entrent dans aucun calcul.
abstract final class ArmorVeil {
  /// Le plein du voile après qu'un état est passé de [oldArmor] à [newArmor].
  static int nextPeak({
    required int peak,
    required int oldArmor,
    required int newArmor,
  }) {
    if (newArmor <= 0) return 0;
    if (newArmor > oldArmor) return newArmor;
    return math.max(peak, newArmor);
  }

  /// La part de la barre que couvre le voile, entre 0 et 1.
  static double fraction({required int armor, required int peak}) {
    if (peak <= 0) return 0;
    return (armor / peak).clamp(0.0, 1.0).toDouble();
  }
}
