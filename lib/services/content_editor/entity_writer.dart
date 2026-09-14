import 'dart:convert';

import 'package:meta/meta.dart';

import 'audio_catalog.dart';
import 'content_file_system.dart';
import 'entity_descriptor.dart';
import 'entity_draft.dart';
import 'pending_import.dart';

/// L'image deposee dans un dossier de classe ou d'ennemi nouvellement cree.
/// Un carre magenta volontairement laid : oublier de le remplacer doit se voir.
const String kPlaceholderImage = 'assets/placeholders/images/placeholder_entity.png';

/// L'icone deposee dans un dossier de classe nouvellement cree. Meme magenta
/// que [kPlaceholderImage], borde pour distinguer la fente d'un coup d'oeil.
const String kPlaceholderIcon =
    'assets/placeholders/images/placeholder_icon.png';

/// Ce qui a ete ecrit, et ce qu'il reste a faire cote humain.
@immutable
class WriteReport {
  const WriteReport({
    required this.written,
    this.sync,
    this.createdEntity = false,
  });

  /// Les chemins ecrits, relatifs a la racine du projet.
  final List<String> written;

  /// Le resultat de `sync_assets`. `null` s'il n'a pas ete lance.
  final ProcessOutcome? sync;

  /// Vrai si le geste a cree au moins une entite. Un redemarrage a chaud
  /// suffit a la charger, `pubspec.yaml` modifie compris — verifie a la main
  /// le 2026-09-14 pour une classe comme pour une relique.
  final bool createdEntity;

  bool get syncFailed => sync != null && !sync!.succeeded;
}

/// Une ecriture, et de quoi la defaire.
@immutable
class WriteStep {
  /// Un fichier texte : [previous] est son contenu d'avant, `null` s'il
  /// n'existait pas.
  const WriteStep(this.relative, this.previous)
      : isAsset = false,
        backup = null;

  /// Une ressource copiee : [backup] est la sauvegarde de l'image ecrasee,
  /// `null` si la destination n'existait pas.
  const WriteStep.asset(this.relative, this.backup)
      : isAsset = true,
        previous = null;

  final String relative;

  /// Le contenu d'avant, ou `null` si le fichier n'existait pas.
  final String? previous;
  final bool isAsset;
  final String? backup;
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

  /// Ecrit un brouillon. Raccourci sur [writeAll].
  Future<WriteReport> write(EntityDraft draft) => writeAll([draft]);

  /// Ecrit plusieurs brouillons, et les ressources importees, comme **un seul
  /// geste**.
  ///
  /// Ordre : dossiers, ressources, `audio.json`, puis chaque entite. Tout
  /// partage une pile de rollback ; une image ecrasee est sauvegardee avant
  /// copie, restauree en cas d'echec, supprimee au succes.
  ///
  /// `sync_assets` ne tourne qu'une fois, a la fin.
  Future<WriteReport> writeAll(
    List<EntityDraft> drafts, {
    List<PendingImport> imports = const [],
  }) async {
    final steps = <WriteStep>[];
    try {
      for (final draft in drafts) {
        _prepareFolder(draft);
      }
      for (final pending in imports) {
        _copyAsset(pending, steps);
      }
      _declareSounds(imports, steps);
      for (final draft in drafts) {
        _writeFiles(draft, steps);
      }
    } catch (_) {
      _rollback(steps);
      rethrow;
    }
    _dropBackups(steps);

    final sync = await _runSyncAssets();

    return WriteReport(
      written: [for (final step in steps) step.relative],
      sync: sync,
      createdEntity: drafts.any((draft) => !draft.isModification),
    );
  }

  void _writeFiles(EntityDraft draft, List<WriteStep> steps) {
    _placeImage(draft);
    _placeClassIcon(draft);
    _writeJson(draft.path, draft.compose(), steps);
    _registerSignatureCard(draft, steps);
  }

  /// Copie un fichier importe a sa destination. Une destination existante est
  /// d'abord sauvegardee : l'etape est empilee **avant** la copie, pour qu'une
  /// copie ratee a mi-chemin se defasse aussi.
  void _copyAsset(PendingImport pending, List<WriteStep> steps) {
    final absolute = '$rootPath/${pending.destination}';
    fs.createDirectory(absolute.substring(0, absolute.lastIndexOf('/')));

    String? backup;
    if (fs.fileExists(absolute)) {
      backup = '${pending.destination}.editor-backup';
      fs.copyFile(absolute, '$rootPath/$backup');
    }
    steps.add(WriteStep.asset(pending.destination, backup));
    fs.copyFile(pending.sourcePath, absolute);
  }

  /// Declare chaque son importe dans `audio.json`, en une ecriture.
  void _declareSounds(List<PendingImport> imports, List<WriteStep> steps) {
    final sounds = [for (final p in imports) if (p.soundId != null) p];
    if (sounds.isEmpty) return;

    final absolute = '$rootPath/$kAudioCatalogPath';
    final before = fs.readFile(absolute);
    var text = before;
    for (final pending in sounds) {
      text = insertSound(text, id: pending.soundId!, file: pending.audioFile);
    }
    steps.add(WriteStep(kAudioCatalogPath, before));
    fs.writeFile(absolute, text);
  }

  void _dropBackups(List<WriteStep> steps) {
    for (final step in steps) {
      final backup = step.backup;
      if (backup != null && fs.fileExists('$rootPath/$backup')) {
        fs.deleteFile('$rootPath/$backup');
      }
    }
  }

  /// Une classe et un ennemi sont des **dossiers**, qu'il faut creer avant
  /// d'y ecrire.
  ///
  /// Celui d'une classe porte en outre un sous-dossier `cards/`, **meme
  /// vide** : `referential_integrity_test` y appelle `listSync()` sans garde,
  /// et un dossier absent le fait *lever*. Ce n'est alors pas ce test qui
  /// echoue, c'est toute la suite qui tombe.
  ///
  /// [_rollback] ne defait pas ces dossiers, et c'est sans consequence : une
  /// ecriture ratee laisse un repertoire **vide**, que git ne suit pas.
  void _prepareFolder(EntityDraft draft) {
    final descriptor = draft.descriptor;
    if (descriptor.folderFile == null || draft.isModification) return;

    final folder = '$rootPath/assets/data/${descriptor.directory}/${draft.id}';
    fs.createDirectory(folder);
    if (descriptor.category == EntityCategory.heroClass) {
      fs.createDirectory('$folder/cards');
    }
  }

  /// Depose l'image de remplacement de chaque emplacement **obligatoire**, si
  /// et seulement si aucune n'est deja la. Une image peinte a la main ne doit
  /// jamais etre ecrasee par un carre magenta.
  ///
  /// Elle n'est deliberement pas defaite par [_rollback] : un placeholder
  /// laisse dans un dossier neuf est sans consequence, la ou une suppression
  /// pourrait emporter une image legitime.
  void _placeImage(EntityDraft draft) {
    final descriptor = draft.descriptor;
    for (final key in descriptor.imageKeys.where(descriptor.isComputedImage)) {
      final absolute = '$rootPath/${descriptor.imagePathOf(draft.id, key)}';
      if (fs.fileExists(absolute)) continue;

      final source = '$rootPath/$kPlaceholderImage';
      if (!fs.fileExists(source)) return; // rien a copier : on n'invente pas
      fs.copyFile(source, absolute);
    }
  }

  /// Depose l'icone de remplacement d'une classe **neuve**.
  ///
  /// Jamais en modification : les trois classes livrees n'ont pas d'icone
  /// dessinee, et leur en deposer une ferait afficher un carre magenta a la
  /// place de leur illustration dans le dialogue de stats. Le repli de
  /// `ClassIdentity.imageOf` sur la carte de classe n'a de sens que tant que
  /// `iconPath` reste absent de leur JSON.
  ///
  /// Comme [_placeImage], elle n'ecrase jamais une image deja la, et n'est pas
  /// defaite par [_rollback] : un placeholder laisse dans un dossier neuf est
  /// sans consequence.
  void _placeClassIcon(EntityDraft draft) {
    if (draft.descriptor.category != EntityCategory.heroClass ||
        draft.isModification) {
      return;
    }

    final absolute = '$rootPath/${draft.descriptor.imagePathOf(draft.id, 'iconPath')}';
    if (fs.fileExists(absolute)) return;

    final source = '$rootPath/$kPlaceholderIcon';
    if (!fs.fileExists(source)) return; // rien a copier : on n'invente pas
    fs.copyFile(source, absolute);
  }

  /// Une carte de classe **est** une carte de signature.
  ///
  /// `referential_integrity_test` exige que le contenu du dossier `cards/`
  /// soit exactement egal au tableau `skills` de la classe. Une carte ajoutee
  /// seule y serait orpheline et ferait rougir la suite — a tous les coups, et
  /// jamais au moment de l'ecriture. Les deux fichiers, ou aucun.
  void _registerSignatureCard(EntityDraft draft, List<WriteStep> steps) {
    final heroClass = draft.heroClass;
    if (heroClass == null || draft.isModification) return;

    final relative = 'assets/data/classes/$heroClass/class.json';
    final absolute = '$rootPath/$relative';
    if (!fs.fileExists(absolute)) {
      throw StateError(
        'la classe "$heroClass" n\'a pas de class.json : sa carte de signature '
        'ne peut pas y être déclarée',
      );
    }

    final document = jsonDecode(fs.readFile(absolute)) as Map<String, dynamic>;
    final skills = List<String>.from(document['skills'] as List? ?? const []);
    if (skills.contains(draft.id)) return;

    skills.add(draft.id);
    // Trie pour que l'ordre ne depende pas de celui des ajouts : le diff d'une
    // classe reste lisible d'une carte a l'autre.
    skills.sort();
    document['skills'] = skills;
    _writeJson(relative, document, steps);
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
      if (step.isAsset) {
        final backup = step.backup;
        if (backup != null) {
          fs.copyFile('$rootPath/$backup', absolute);
          fs.deleteFile('$rootPath/$backup');
        } else if (fs.fileExists(absolute)) {
          fs.deleteFile(absolute);
        }
        continue;
      }
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
