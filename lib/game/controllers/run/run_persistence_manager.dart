import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../run_controller.dart';

class RunPersistenceManager {
  final RunController controller;
  final Ref ref;

  RunPersistenceManager(this.controller, this.ref);

  /// Sauvegarde la partie en cours
  Future<void> saveRun() async {
    // Squelette prêt pour l'intégration de SharedPreferences ou d'une base de données locale
  }

  /// Charge une partie sauvegardée
  Future<RunState?> loadRun() async {
    // Squelette prêt pour l'intégration de SharedPreferences ou d'une base de données locale
    return null;
  }

  /// Supprime la sauvegarde en cours (mort du héros, fin de run)
  Future<void> clearSavedRun() async {
    // Squelette prêt pour l'intégration
  }
}
