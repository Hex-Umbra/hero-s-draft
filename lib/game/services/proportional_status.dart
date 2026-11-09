import '../../models/entity_stats.dart';

/// Un statut qui compte ses points : chaque point pèse [percentPerPoint] %,
/// jusqu'à [maxPoints] points (spec P-42/P-44 lot 1, §4.4, réponse P-1).
///
/// Ces trois constantes sont les seules valeurs du barème : le pipeline de
/// dégâts, l'intention effective et tous les textes qui le chiffrent les
/// lisent ici.
class ProportionalStatus {
  final String id;
  final int percentPerPoint;
  final int maxPoints;

  const ProportionalStatus._(this.id, this.percentPerPoint, this.maxPoints);

  /// +25 % de dégâts subis par point, 4 points au plus.
  static const vulnerable = ProportionalStatus._('vulnerable', 25, 4);

  /// -25 % de dégâts infligés par point, 2 points au plus.
  static const weakness = ProportionalStatus._('weakness', 25, 2);

  /// -25 % à la prochaine attaque par point, 3 points au plus.
  static const freeze = ProportionalStatus._('freeze', 25, 3);

  int get maxPercent => percentPerPoint * maxPoints;

  /// Les points du statut : la somme des entrées de même id, bornée à
  /// `[0, maxPoints]`.
  int pointsOn(EntityStats stats) {
    final total = stats.statuses
        .where((s) => s.id == id)
        .fold<int>(0, (sum, s) => sum + s.value);
    return total.clamp(0, maxPoints);
  }

  int percentOn(EntityStats stats) => percentPerPoint * pointsOn(stats);
}
