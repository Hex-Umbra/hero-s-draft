import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vrai des qu'une action du menu de debug a touche la run en cours.
///
/// Une run trafiquee ne doit pas produire de sauvegarde : rechargee plus tard,
/// elle serait indistinguable d'une run legitime. Le drapeau est donc
/// volontairement sans retour arriere pour la run courante — seul
/// `RunController.startNewRun` le rabaisse, pour qu'une run neuve reparte
/// propre.
///
/// Ce drapeau vit a l'ecart de `DebugActions` pour que
/// `checkpoint_controller.dart`, qui le lit, ne depende pas de tout
/// l'outillage de debug.
class DebugTaintNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void taint() => state = true;

  /// Reserve au demarrage d'une nouvelle run.
  void clear() => state = false;
}

final debugTaintProvider =
    NotifierProvider<DebugTaintNotifier, bool>(DebugTaintNotifier.new);
