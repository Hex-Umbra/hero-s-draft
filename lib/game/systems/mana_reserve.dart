import 'dart:math' show max, min;

import '../../models/data/passive_data.dart';
import '../../models/entity_stats.dart';
import '../controllers/run_controller.dart';

/// Ce que la fin du tour mettrait en réserve : [banked] Mana, et si le
/// plafond en retient ([capped]).
typedef ManaReservePreview = ({int banked, bool capped});

/// La banque de mana de *Canalisation* (D30) : la seule écriture du plafond
/// et de ce qui passe en réserve. La stratégie du passif la lit à la fin du
/// tour, l'interface pendant le tour : le « +n » affiché est le n mis en
/// réserve (plan 2026-11-15, A2).
abstract final class ManaReserve {
  /// L'`effectType` d'un passif qui tient une réserve de Mana.
  static const String effectType = 'mana_reserve';

  /// Ce que la fin du tour mettrait en réserve sous [passive], Maîtrise déjà
  /// appliquée, ou `null` si ce passif ne tient pas de réserve. Le plafond
  /// vaut le Mana max plus la valeur du passif — 0 dans la donnée, +1 par
  /// point de Maîtrise ; tout le mana non dépensé y passe, d'où qu'il
  /// vienne (A3).
  static ManaReservePreview? preview(PassiveData? passive, EntityStats hero) {
    if (passive == null || passive.effectType != effectType) return null;
    final cap = max(0, hero.maxMana + passive.value);
    final unspent = max(0, hero.currentMana);
    return (banked: min(unspent, cap), capped: unspent > cap);
  }

  /// [preview] sous le passif actif de [run], la Maîtrise effective
  /// appliquée comme le fait `TraitSystem.dispatch` : la lecture de
  /// l'interface.
  static ManaReservePreview? forRun(RunState run) => preview(
        run.activePassive?.withMastery(run.heroStats.effectiveMastery),
        run.heroStats,
      );
}
