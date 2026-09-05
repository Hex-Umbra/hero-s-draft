import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/save_service.dart';
import 'debug_taint_controller.dart';

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
/// Une run touchée par le menu de debug ne se sauvegarde plus : la sauvegarde
/// déjà présente sur le disque reste celle d'avant.
final autosaveOrchestratorProvider = Provider<void>((ref) {
  ref.listen<int>(checkpointProvider, (previous, next) {
    if (ref.read(debugTaintProvider)) return;
    SaveService.save(ref.read);
  });
});
