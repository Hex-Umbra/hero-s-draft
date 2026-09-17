import '../controllers/run_controller.dart';
import 'passives/passive_strategies.dart';
import 'passives/passive_strategy.dart';

/// Le répartiteur des passifs (spec P-49, §5.3).
///
/// Il ne connaît aucun passif : il vérifie que l'événement est celui qu'attend
/// le passif actif, lui applique la Maîtrise du héros, puis confie l'effet à
/// la stratégie de son `effectType` — qui ne lit donc jamais la stat
/// (spec P-49, §6.2). Un `effectType` sans stratégie ne fait rien — jamais
/// d'exception en plein combat ; `referential_integrity_test` refuse qu'un
/// passif livré soit dans ce cas.
abstract final class TraitSystem {
  static void dispatch(RunController run, PassiveEvent event) {
    final passive = run.currentState.activePassive;
    if (passive == null || passive.trigger != event.trigger) return;
    PassiveStrategies.byEffectType[passive.effectType]?.resolve(
      passive.withMastery(run.currentState.heroStats.effectiveMastery),
      event,
      run,
    );
  }
}
