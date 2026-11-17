import 'package:meta/meta.dart';

import 'data/charge_data.dart';

/// L'état de rupture d'une charge sur un porteur (spec P-53, §4.1).
enum ChargeState {
  /// Pas de rupture en cours.
  none,

  /// La rupture a eu lieu ; son effet attend la prochaine action ou le
  /// prochain tour du porteur.
  brokenPending,

  /// L'effet de la rupture joue.
  brokenActive,
}

/// Un coup reçu qui a eu un bonus de Foudre : le bonus qu'il a reçu (spec
/// P-53, Q-P2 (c)).
@immutable
class ChargeHit {
  final int bonus;

  const ChargeHit(this.bonus);

  @override
  bool operator ==(Object other) => other is ChargeHit && other.bonus == bonus;

  @override
  int get hashCode => bonus.hashCode;
}

/// La piste d'une charge sur un porteur : ce que les points seuls ne disent
/// pas — le seuil courant, le nombre de ruptures du combat, l'état, et la
/// rupture en vigueur pour ce porteur (spec P-53, §4.1). Hors sauvegarde : une
/// piste meurt avec les statuts du combat.
@immutable
class ChargeTrack {
  final int threshold;
  final int ruptures;
  final ChargeState state;
  final ChargeRupture rupture;

  const ChargeTrack({
    required this.threshold,
    required this.ruptures,
    required this.state,
    required this.rupture,
  });

  /// La piste d'un porteur qui n'a encore rien reçu : le seuil de départ de
  /// son genre, aucune rupture.
  factory ChargeTrack.start(ChargeData charge, ChargeBearer bearer) =>
      ChargeTrack(
        threshold: charge.startThreshold(bearer),
        ruptures: 0,
        state: ChargeState.none,
        rupture: charge.ruptureFor(bearer),
      );

  ChargeTrack copyWith({int? threshold, int? ruptures, ChargeState? state}) =>
      ChargeTrack(
        threshold: threshold ?? this.threshold,
        ruptures: ruptures ?? this.ruptures,
        state: state ?? this.state,
        rupture: rupture,
      );

  @override
  bool operator ==(Object other) =>
      other is ChargeTrack &&
      other.threshold == threshold &&
      other.ruptures == ruptures &&
      other.state == state &&
      other.rupture == rupture;

  @override
  int get hashCode => Object.hash(threshold, ruptures, state, rupture);
}
