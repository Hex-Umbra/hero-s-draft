import '../../../models/data/passive_data.dart';
import '../../../models/status_effect.dart';
import '../../controllers/run_controller.dart';

/// La portée d'un compteur de passif.
enum CounterScope {
  /// Remis à zéro au début du tour suivant : « la 1ʳᵉ attaque du tour ».
  turn,

  /// Tenu jusqu'à la fin du combat : « toutes les N Compétences ».
  combat,
}

/// Les compteurs d'un passif (spec P-41, §6.4).
///
/// Portés par un statut caché du héros, comme les charges de reliques
/// (`shuriken_charge`, `pen_nib_charge`, `incense_charge`) : la portée vient de
/// la durée du statut — 1 tour, ou 99 pour le combat entier —, les statuts sont
/// décrémentés au début de chaque tour et vidés à la fin de chaque combat
/// (`map_progression_manager.dart`). **Aucun état nouveau n'est à sérialiser**,
/// et un compteur ne survit jamais à son combat.
abstract final class PassiveCounters {
  /// L'identifiant du statut compteur d'un passif. Un passif par run étant
  /// actif, il n'y a jamais deux compteurs à distinguer, mais le nom porte
  /// l'id : une sauvegarde chargée avec un autre passif ne relit pas le
  /// compteur d'un précédent.
  static String idOf(PassiveData passive) => '${passive.id}_count';

  /// La valeur du compteur, 0 s'il n'y en a pas.
  static int valueOf(RunController run, PassiveData passive) {
    final id = idOf(passive);
    var total = 0;
    for (final status in run.currentState.heroStats.statuses) {
      if (status.id == id) total += status.value;
    }
    return total;
  }

  /// Incrémente le compteur de 1 et rend sa nouvelle valeur.
  static int bump(
    RunController run,
    PassiveData passive, {
    required CounterScope scope,
  }) {
    run.addStatus(
      StatusEffect(
        id: idOf(passive),
        name: 'Compteur',
        type: StatusType.buff,
        value: 1,
        duration: scope == CounterScope.turn ? 1 : 99,
      ),
    );
    return valueOf(run, passive);
  }

  /// Remet le compteur à zéro — ce que fait un passif à seuil quand il se
  /// déclenche.
  static void clear(RunController run, PassiveData passive) {
    run.removeStatus(idOf(passive));
  }
}
