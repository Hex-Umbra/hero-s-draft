import 'dart:convert';

import 'package:meta/meta.dart';

import 'content_file_system.dart';
import 'entity_draft.dart';

/// Ce qui a ete ecrit, et ce qu'il reste a faire cote humain.
@immutable
class WriteReport {
  const WriteReport({
    required this.written,
    this.sync,
    this.relaunchAdvised = false,
  });

  /// Les chemins ecrits, relatifs a la racine du projet.
  final List<String> written;

  /// Le resultat de `sync_assets`. `null` s'il n'a pas ete lance.
  final ProcessOutcome? sync;

  /// Vrai apres une creation : le manifeste d'assets est produit a la
  /// compilation, et un fichier nouveau ne s'y trouve pas.
  final bool relaunchAdvised;

  bool get syncFailed => sync != null && !sync!.succeeded;
}

/// Une ecriture, et de quoi la defaire.
@immutable
class WriteStep {
  const WriteStep(this.relative, this.previous);

  final String relative;

  /// Le contenu d'avant, ou `null` si le fichier n'existait pas.
  final String? previous;
}

/// Ecrit une entite, puis enchaine ses effets de bord.
///
/// **Ne valide rien** : l'appelant valide, l'ecrivain ecrit. La separation
/// tient la decision E6 — rien n'est ecrit avant que la validation entiere
/// passe, et c'est a l'appelant de ne pas appeler.
@immutable
class EntityWriter {
  const EntityWriter({required this.fs, required this.rootPath});

  final ContentFileSystem fs;
  final String rootPath;

  /// Deux espaces, comme les fichiers existants. `Map` et `jsonDecode`
  /// preservant l'ordre d'insertion, une modification produit un diff minimal.
  static const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

  Future<WriteReport> write(EntityDraft draft) async {
    final steps = <WriteStep>[];
    try {
      _writeFiles(draft, steps);
    } catch (_) {
      _rollback(steps);
      rethrow;
    }

    final sync = await _runSyncAssets();

    return WriteReport(
      written: [for (final step in steps) step.relative],
      sync: sync,
      relaunchAdvised: !draft.isModification,
    );
  }

  /// Empile les ecritures dans [steps]. Les tâches suivantes l'etendent : la
  /// carte de classe y ajoute `class.json`, la classe et l'ennemi leur dossier
  /// et leur image.
  void _writeFiles(EntityDraft draft, List<WriteStep> steps) {
    _writeJson(draft.path, draft.compose(), steps);
  }

  void _writeJson(
    String relative,
    Map<String, dynamic> document,
    List<WriteStep> steps,
  ) {
    final absolute = '$rootPath/$relative';
    // L'etape est empilee **avant** l'ecriture : une ecriture qui echoue a
    // mi-chemin doit elle aussi pouvoir etre defaite.
    steps.add(
      WriteStep(relative, fs.fileExists(absolute) ? fs.readFile(absolute) : null),
    );
    // Une ligne finale, comme tous les fichiers du depot.
    fs.writeFile(absolute, '${_encoder.convert(document)}\n');
  }

  /// Defait ce qui vient d'etre ecrit : un fichier **cree** est supprime, un
  /// fichier **modifie** retrouve son contenu d'avant.
  ///
  /// La distinction n'est pas cosmetique. Une modification ecrase un fichier
  /// existant, et l'ecriture couplee de la carte de classe touche un
  /// `class.json` deja la : le supprimer au motif qu'on « defait » serait bien
  /// pire que la panne qu'on rattrape.
  void _rollback(List<WriteStep> steps) {
    for (final step in steps.reversed) {
      final absolute = '$rootPath/${step.relative}';
      final previous = step.previous;
      if (previous == null) {
        if (fs.fileExists(absolute)) fs.deleteFile(absolute);
      } else {
        fs.writeFile(absolute, previous);
      }
    }
    steps.clear();
  }

  /// Les declarations d'assets de Flutter ne sont recursives a aucun niveau :
  /// un repertoire non declare se charge en developpement puis disparait
  /// silencieusement d'un build.
  ///
  /// Un echec n'annule pas l'ecriture — le fichier est bon — mais il est
  /// rapporte : `pubspec.yaml` est alors en retard.
  Future<ProcessOutcome> _runSyncAssets() => fs.run(
        'dart',
        const ['run', 'tool/sync_assets.dart'],
        workingDirectory: rootPath,
      );
}
