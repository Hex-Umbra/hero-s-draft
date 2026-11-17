import 'dart:math' show max, min;

import 'package:meta/meta.dart';

import '../../models/charge_track.dart';
import '../../models/data/charge_data.dart';
import '../../models/enemy_instance.dart';
import '../../models/entity_stats.dart';
import '../../models/fire_wave_report.dart';
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
    var entries = _entriesWith(stats, charge, total);
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
        entries = _entriesWith(stats, charge, 0);
      }
    }

    return stats.copyWith(
      statuses: entries,
      charges: {...stats.charges, charge.id: written},
    );
  }

  /// Les statuts de [stats], l'entrée de [charge] remplacée par une seule à
  /// [total] points — retirée à 0 : la forme fixe d'une charge (spec P-53, A4).
  static List<StatusEffect> _entriesWith(
    EntityStats stats,
    ChargeData charge,
    int total,
  ) =>
      [
        for (final s in stats.statuses)
          if (s.id != charge.id) s,
        if (total > 0)
          StatusEffect(
            id: charge.id,
            name: charge.nameFr,
            type: StatusType.debuff,
            value: total,
            duration: 1,
          ),
      ];

  /// La résolution d'une charge `explode` de [points] points au seuil
  /// [threshold] : `n` tranches complètes, et les dégâts du porteur —
  /// `n × seuil × damagePerPoint` plus le reste à [belowThresholdPercent], la
  /// demie vers le haut (spec P-53, §4.7, A15).
  static (int tranches, int selfDamage) explosion(
    int points,
    int threshold,
    ChargeRupture rupture,
    int belowThresholdPercent,
  ) {
    final tranches = points ~/ threshold;
    final rest = points - tranches * threshold;
    return (
      tranches,
      tranches * threshold * rupture.damagePerPoint +
          halfUp(rest * rupture.damagePerPoint, belowThresholdPercent),
    );
  }

  /// Les charges du catalogue qui explosent au tour de leur porteur.
  static Iterable<ChargeData> _exploding(ChargeCatalog charges) =>
      charges.all.where((c) => c.rupture.kind == RuptureKind.explode);

  /// Résout toute la charge [charge] de [stats], sans appliquer les dégâts :
  /// l'entrée retirée, une rupture comptée si une tranche au moins explose.
  static ({
    EntityStats spent,
    int tranches,
    int selfDamage,
    ChargeRupture rupture,
  }) _spend(EntityStats stats, ChargeData charge, ChargeBearer bearer) {
    final track = stats.charges[charge.id] ?? ChargeTrack.start(charge, bearer);
    final (tranches, selfDamage) = explosion(
      points(stats, charge.id),
      track.threshold,
      track.rupture,
      charge.belowThresholdPercent!,
    );
    final written = tranches >= 1
        ? track.copyWith(
            ruptures: track.ruptures + 1,
            threshold: track.threshold + charge.thresholdGrowth,
          )
        : track;
    return (
      spent: stats.copyWith(
        statuses: _entriesWith(stats, charge, 0),
        charges: {...stats.charges, charge.id: written},
      ),
      tranches: tranches,
      selfDamage: selfDamage,
      rupture: track.rupture,
    );
  }

  /// Une vague de la chaîne du Feu sur la rangée [row] (spec P-53, §4.7,
  /// A11) : les porteurs vivants — ceux de [bearerIds] s'il n'est pas nul —
  /// se résolvent ensemble sur l'état du début de la vague ; les dégâts
  /// s'appliquent dans l'ordre de la rangée, l'Armure absorbant, hors
  /// pipeline (P-d) ; puis le Feu des explosions se pose, sans bonus de
  /// Puissance, sur les seuls vivants. Les morts gardent leur place. Rend la
  /// rangée et le compte rendu de la vague [wave], `null` sans porteur.
  static (List<EnemyInstance>, FireWaveReport?) fireWave(
    List<EnemyInstance> row, {
    required Set<String>? bearerIds,
    required int wave,
    required ChargeCatalog charges,
  }) {
    bool alive(EnemyInstance e) => e.stats.currentPv > 0;

    final working = [...row];
    final hits = List.filled(row.length, 0);
    final blasts = <({
      int bearer,
      ChargeData charge,
      int tranches,
      int splashCharge,
      List<int> neighbours,
    })>[];

    for (var i = 0; i < row.length; i++) {
      final enemy = row[i];
      if (!alive(enemy)) continue;
      if (bearerIds != null && !bearerIds.contains(enemy.id)) continue;
      for (final charge in _exploding(charges)) {
        if (points(enemy.stats, charge.id) <= 0) continue;
        final resolved =
            _spend(working[i].stats, charge, bearerOf(enemy));
        working[i] = working[i].copyWith(stats: resolved.spent);
        hits[i] += resolved.selfDamage;

        final n = resolved.tranches;
        final neighbours = n >= 1
            ? [
                for (final j in [i - 1, i + 1])
                  if (j >= 0 && j < row.length && alive(row[j])) j,
              ]
            : <int>[];
        final splashDamage = n * resolved.rupture.explosionDamage;
        for (final j in neighbours) {
          hits[j] += splashDamage;
        }
        blasts.add((
          bearer: i,
          charge: charge,
          tranches: n,
          splashCharge: n * resolved.rupture.chargePerNeighbour,
          neighbours: neighbours,
        ));
      }
    }

    if (blasts.isEmpty) return (row, null);

    for (var i = 0; i < working.length; i++) {
      if (hits[i] > 0) {
        working[i] =
            working[i].copyWith(stats: working[i].stats.takeDamage(hits[i]));
      }
    }

    final nextBearerIds = <String>{};
    final resolved = <FireResolution>[];
    for (final blast in blasts) {
      final splashes = <FireSplash>[];
      for (final j in blast.neighbours) {
        final target = working[j];
        var received = 0;
        if (alive(target)) {
          final before = points(target.stats, blast.charge.id);
          final posed = pose(
            target.stats,
            blast.charge,
            blast.splashCharge,
            bearerOf(target),
          );
          received = points(posed, blast.charge.id) - before;
          working[j] = target.copyWith(stats: posed);
          if (received > 0) nextBearerIds.add(target.id);
        }
        splashes.add(FireSplash(
          targetId: target.id,
          charge: received,
        ));
      }
      resolved.add(FireResolution(
        bearerId: row[blast.bearer].id,
        chargeId: blast.charge.id,
        tranches: blast.tranches,
        splashes: splashes,
      ));
    }

    return (
      working,
      FireWaveReport(
        wave: wave,
        resolved: resolved,
        nextBearerIds: nextBearerIds,
      ),
    );
  }

  /// Le Feu du héros à son tour : sa part seule, sans voisin (spec P-53,
  /// §4.7). L'Armure absorbe, hors pipeline.
  static EntityStats resolveOwnFire(EntityStats stats, ChargeCatalog charges) {
    var result = stats;
    for (final charge in _exploding(charges)) {
      if (points(result, charge.id) <= 0) continue;
      final resolved = _spend(result, charge, ChargeBearer.hero);
      result = resolved.spent.takeDamage(resolved.selfDamage);
    }
    return result;
  }

  /// Le déclin au tour du porteur (spec P-53, §4.4) : chaque charge à
  /// `decay > 0` dont l'état est « aucun » perd `decay` points, sans
  /// descendre sous 0 ; l'entrée est retirée à 0.
  static EntityStats decay(EntityStats stats, ChargeCatalog charges) {
    var result = stats;
    for (final charge in charges.all.where((c) => c.decay > 0)) {
      final state = result.charges[charge.id]?.state ?? ChargeState.none;
      if (state != ChargeState.none) continue;
      final held = points(result, charge.id);
      if (held == 0) continue;
      result = result.copyWith(
        statuses: _entriesWith(result, charge, max(0, held - charge.decay)),
      );
    }
    return result;
  }

  /// Une fermeture de phase (spec P-53, A9), chez un porteur : une charge
  /// `amplifyHits` rompue retombe à 0 et à « aucun » ; à la fin du tour du
  /// joueur seulement ([endsPlayerTurn]), un `weakenDealt` actif prend fin. Un
  /// `weakenDealt` en attente reste.
  static EntityStats closePhase(
    EntityStats stats, {
    required bool endsPlayerTurn,
  }) {
    var result = stats;
    for (final MapEntry(key: id, value: track) in stats.charges.entries) {
      if (track.state != ChargeState.brokenActive) continue;
      switch (track.rupture.kind) {
        case RuptureKind.amplifyHits:
          result = result.copyWith(
            statuses: [
              for (final s in result.statuses)
                if (s.id != id) s,
            ],
            charges: {
              ...result.charges,
              id: track.copyWith(state: ChargeState.none),
            },
          );
        case RuptureKind.weakenDealt when endsPlayerTurn:
          result = result.copyWith(charges: {
            ...result.charges,
            id: track.copyWith(state: ChargeState.none),
          });
        default:
          break;
      }
    }
    return result;
  }

  /// Le début du tour du porteur : un `weakenDealt` en attente devient actif
  /// (spec P-53, §4.6).
  static EntityStats startBearerTurn(EntityStats stats) => stats.copyWith(
        charges: {
          for (final MapEntry(key: id, value: track) in stats.charges.entries)
            id: track.rupture.kind == RuptureKind.weakenDealt &&
                    track.state == ChargeState.brokenPending
                ? track.copyWith(state: ChargeState.brokenActive)
                : track,
        },
      );

  /// Le gel est dépensé : la piste `skipAction` rompue et en attente de
  /// [stats] revient à « aucun » (spec P-53, A13).
  static EntityStats consumeSkip(EntityStats stats) => stats.copyWith(
        charges: {
          for (final MapEntry(key: id, value: track) in stats.charges.entries)
            id: track.rupture.kind == RuptureKind.skipAction &&
                    track.state == ChargeState.brokenPending
                ? track.copyWith(state: ChargeState.none)
                : track,
        },
      );

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

  /// Note le coup que [defender] va recevoir : une entrée de plus à son
  /// journal, du bonus que [hitBonus] lit sur son état d'avant le coup. Sans
  /// bonus, [defender] elle-même.
  static EntityStats noteHit(EntityStats defender, ChargeCatalog charges) {
    final bonus = hitBonus(defender, charges);
    if (bonus <= 0) return defender;
    return defender.copyWith(
      chargeHits: [...defender.chargeHits, ChargeHit(bonus)],
    );
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
