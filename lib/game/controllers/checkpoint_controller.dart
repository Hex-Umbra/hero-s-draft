import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/save_service.dart';
import 'run_controller.dart';

class CheckpointNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Signale qu'un nœud de la carte vient d'être résolu (combat, boutique,
  /// repos, event, forge, échange de reliques, ou draft de Level Up).
  void bump() => state = state + 1;
}

final checkpointProvider =
    NotifierProvider<CheckpointNotifier, int>(CheckpointNotifier.new);

/// Écoute checkpointProvider et déclenche une sauvegarde à chaque bump().
/// Doit être lu une fois au démarrage de l'app pour s'activer (voir main.dart).
///
/// Efface aussi la sauvegarde à l'instant où le héros meurt. Attendre un clic
/// sur `DeathOverlay` laissait une porte ouverte : recharger la page, fermer
/// l'app ou revenir en arrière sur l'écran de mort, puis « Continuer »,
/// rechargeait le dernier checkpoint — celui d'avant le combat — et annulait
/// la mort. On écoute `isDead`, l'état dérivé, et non les dégâts : les PV
/// peuvent tomber à 0 par un statut comme par une écriture directe des stats.
/// `select` ne notifie qu'un changement de valeur : passer à `true` est donc
/// toujours la transition vivant → mort.
///
/// Aucune condition ici : c'est `SaveService` qui refuse de persister — ou
/// d'effacer — une run debug, pour que la garantie tienne aussi sur les
/// autres appelants.
final autosaveOrchestratorProvider = Provider<void>((ref) {
  ref.listen<int>(checkpointProvider, (previous, next) {
    SaveService.save(ref.read);
  });
  ref.listen<bool>(runProvider.select((run) => run.isDead), (wasDead, isDead) {
    if (isDead) SaveService.clear(ref.read);
  });
});
