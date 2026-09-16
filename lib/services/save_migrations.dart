/// Une étape de migration : reçoit le blob décodé d'une version N et rend
/// celui de la version N + 1. Fonction pure, sans provider ; elle peut
/// modifier la map reçue et la rendre.
typedef SaveMigrationStep = Map<String, dynamic> Function(
  Map<String, dynamic> save,
);

/// Levée par [SaveMigrator.migrate] pour une sauvegarde écrite par un build
/// plus récent que celui-ci. Ce n'est pas une sauvegarde corrompue : elle est
/// refusée sans être effacée, pour que le build qui sait la lire la retrouve
/// (spec P-41, §4.3).
class SaveFromNewerBuildException implements Exception {
  final int version;

  const SaveFromNewerBuildException(this.version);

  @override
  String toString() => 'SaveFromNewerBuildException: schemaVersion $version';
}

/// Amène un blob de sauvegarde, lu à n'importe quelle version connue, à la
/// version courante (spec P-41, §4.3).
///
/// [steps] associe à chaque version l'étape qui la quitte : `steps[1]` fait
/// passer la version 1 à 2. La version courante est **déclarée**, jamais
/// déduite du nombre d'étapes : une étape supprimée, ou deux branches qui
/// ajoutent chacune la leur, font échouer `test/unit/save_migrations_test.dart`
/// ou la fusion, au lieu de renuméroter la chaîne en silence.
class SaveMigrator {
  final int currentVersion;
  final Map<int, SaveMigrationStep> steps;

  const SaveMigrator({required this.currentVersion, required this.steps});

  /// Une version absente, non entière ou inférieure à 1 lève une
  /// [FormatException] : `SaveService` traite la sauvegarde comme corrompue.
  /// Une version supérieure à [currentVersion] lève une
  /// [SaveFromNewerBuildException] : `SaveService` la conserve.
  Map<String, dynamic> migrate(Map<String, dynamic> save) {
    final version = save['schemaVersion'];
    if (version is! int || version < 1) {
      throw FormatException('Unsupported or missing schemaVersion: $version');
    }
    if (version > currentVersion) {
      throw SaveFromNewerBuildException(version);
    }
    var migrated = save;
    for (var from = version; from < currentVersion; from++) {
      final step = steps[from];
      if (step == null) {
        throw StateError('No save migration step from version $from');
      }
      migrated = step(migrated);
      migrated['schemaVersion'] = from + 1;
    }
    return migrated;
  }
}

/// La chaîne de production. Monter `currentVersion` et ajouter l'étape qui
/// quitte l'ancienne version vont toujours ensemble.
const saveMigrator = SaveMigrator(currentVersion: 1, steps: {});
