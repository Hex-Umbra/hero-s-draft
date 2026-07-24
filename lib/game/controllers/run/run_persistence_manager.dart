import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/save_service.dart';
import '../run_controller.dart';

class RunPersistenceManager {
  final RunController controller;
  final Ref ref;

  RunPersistenceManager(this.controller, this.ref);

  /// Sauvegarde manuelle immédiate de la run en cours
  Future<void> saveRun() => SaveService.save(ref.read);

  /// Charge la sauvegarde existante, le cas échéant
  Future<SaveLoadResult> loadRun() => SaveService.load(ref.read);

  /// Supprime la sauvegarde en cours (mort du héros)
  Future<void> clearSavedRun() => SaveService.clear();
}
