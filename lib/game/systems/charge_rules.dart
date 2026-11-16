import 'dart:math' show min;

import 'package:meta/meta.dart';

import '../../models/charge_track.dart';
import '../../models/data/charge_data.dart';
import '../../models/enemy_instance.dart';
import '../../models/entity_stats.dart';
import '../../models/status_effect.dart';

/// Une ligne de charge telle que le joueur la lit : les points, le seuil
/// courant, l'état et la valeur de la rupture en vigueur (spec P-53, §5.1).
@immutable
class ChargeLine {
  final String chargeId;
  final int points;
  final int threshold;
  final ChargeState state;
  final RuptureKind kind;

  /// La valeur de la rupture en vigueur : le pourcentage pour `weakenDealt`,
  /// `points × bonusPerPoint` pour `amplifyHits`, 0 sinon — et 0 tant que la
  /// charge n'est pas rompue.
  final int value;

  const ChargeLine(
    this.chargeId,
    this.points,
    this.threshold,
    this.state,
    this.kind,
    this.value,
  );

  @override
  bool operator ==(Object other) =>
      other is ChargeLine &&
      other.chargeId == chargeId &&
      other.points == points &&
      other.threshold == threshold &&
      other.state == state &&
      other.kind == kind &&
      other.value == value;

  @override
  int get hashCode =>
      Object.hash(chargeId, points, threshold, state, kind, value);
}

/// Les règles des charges élémentaires, fonctions pures sur des
/// [EntityStats] (spec P-53, §4). Le contrôleur les appelle ; aucune ne lit
/// de provider.
abstract final class ChargeRules {
  /// Les points d'une charge : la somme des entrées de statut de même id.
  static int points(EntityStats stats, String chargeId) => stats.statuses
      .where((s) => s.id == chargeId)
      .fold(0, (sum, s) => sum + s.value);

  /// Le genre de porteur d'un ennemi : un boss ou un ennemi.
  static ChargeBearer bearerOf(EnemyInstance enemy) =>
      enemy.isBoss ? ChargeBearer.boss : ChargeBearer.enemy;

  /// Pose [points] de [charge] sur [stats], dans l'ordre de la spec §4.2 :
  /// rien sur un porteur rompu sans surcharge, plafond au restant, une seule
  /// entrée à la somme, rupture au seuil. Rend [stats] elle-même quand rien
  /// n'est posé.
  static EntityStats pose(
    EntityStats stats,
    ChargeData charge,
    int points,
    ChargeBearer bearer,
  ) {
    final track = stats.charges[charge.id] ?? ChargeTrack.start(charge, bearer);
    if (!charge.overcharge && track.state != ChargeState.none) return stats;

    final held = ChargeRules.points(stats, charge.id);
    final placed =
        charge.overcharge ? points : min(points, track.threshold - held);
    if (placed <= 0) return stats;

    final total = held + placed;
    final others = [
      for (final s in stats.statuses)
        if (s.id != charge.id) s,
    ];
    var entries = [
      ...others,
      StatusEffect(
        id: charge.id,
        name: charge.nameFr,
        type: StatusType.debuff,
        value: total,
        duration: 1,
      ),
    ];
    var written = track;

    if (charge.breaksOn == ChargeBreaksOn.threshold &&
        track.state == ChargeState.none &&
        total >= track.threshold) {
      final lasting = track.rupture.kind == RuptureKind.amplifyHits;
      written = track.copyWith(
        ruptures: track.ruptures + 1,
        threshold: track.threshold + charge.thresholdGrowth,
        state: ChargeState.brokenPending,
      );
      if (lasting) {
        written = written.copyWith(state: ChargeState.brokenActive);
      } else {
        entries = others;
      }
    }

    return stats.copyWith(
      statuses: entries,
      charges: {...stats.charges, charge.id: written},
    );
  }

  /// Le pourcentage de dégâts que l'attaquant perd : celui de sa piste
  /// `weakenDealt` rompue et active, 0 sinon. Une rupture en attente ne
  /// réduit rien (spec P-53, §4.9).
  static int weakenPercent(EntityStats attacker) {
    for (final track in attacker.charges.values) {
      if (track.rupture.kind == RuptureKind.weakenDealt &&
          track.state == ChargeState.brokenActive) {
        return track.rupture.percent;
      }
    }
    return 0;
  }

  /// Le bonus que le défenseur ajoute à chaque coup reçu : pour chaque charge
  /// dont la rupture en vigueur (celle de la piste, à défaut celle du
  /// catalogue) est `amplifyHits`, `points × bonusPerPoint` une fois la
  /// charge rompue, et `belowThresholdPercent` de cela, la demie vers le
  /// haut, en dessous du seuil (spec P-53, §4.9).
  static int hitBonus(EntityStats defender, ChargeCatalog charges) {
    var bonus = 0;
    for (final charge in charges.all) {
      final track = defender.charges[charge.id];
      final rupture = track?.rupture ?? charge.rupture;
      if (rupture.kind != RuptureKind.amplifyHits) continue;
      final full = points(defender, charge.id) * rupture.bonusPerPoint;
      bonus += track?.state == ChargeState.brokenActive
          ? full
          : halfUp(full, charge.belowThresholdPercent!);
    }
    return bonus;
  }

  /// Une ligne par piste dont les points dépassent 0 ou dont l'état n'est pas
  /// « aucun » ; une charge à 0 non rompue n'a pas de ligne.
  static List<ChargeLine> linesFor(EntityStats stats) => [
        for (final MapEntry(key: id, value: track) in stats.charges.entries)
          if (points(stats, id) > 0 || track.state != ChargeState.none)
            ChargeLine(
              id,
              points(stats, id),
              track.threshold,
              track.state,
              track.rupture.kind,
              track.state == ChargeState.none
                  ? 0
                  : switch (track.rupture.kind) {
                      RuptureKind.weakenDealt => track.rupture.percent,
                      RuptureKind.amplifyHits =>
                        points(stats, id) * track.rupture.bonusPerPoint,
                      _ => 0,
                    },
            ),
      ];
}
