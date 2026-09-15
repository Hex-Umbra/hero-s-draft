import 'content_file_system.dart';
import 'entity_descriptor.dart';

/// Les fichiers d'une categorie, relatifs a la racine du projet.
///
/// Deplace depuis `known_values.dart` : deux appelants en ont desormais besoin,
/// le panneau de valeurs connues et l'arbre de l'editeur.
List<String> entityFiles(
  ContentFileSystem fs,
  String rootPath,
  EntityDescriptor descriptor,
) {
  final base = 'assets/data/${descriptor.directory}';
  final files = <String>[];

  final folderFile = descriptor.folderFile;
  if (folderFile != null) {
    for (final entry in fs.listDirectory('$rootPath/$base')) {
      final candidate = '$base/$entry/$folderFile';
      if (fs.fileExists('$rootPath/$candidate')) files.add(candidate);
    }
    return files;
  }

  for (final name in fs.listDirectory('$rootPath/$base')) {
    if (name.endsWith('.json')) files.add('$base/$name');
  }

  // Une carte vit a plat **et** sous chaque classe. Les deux emplacements
  // portent le meme vocabulaire.
  if (descriptor.supportsHeroClass) {
    for (final heroClass in fs.listDirectory('$rootPath/assets/data/classes')) {
      final cards = 'assets/data/classes/$heroClass/cards';
      for (final name in fs.listDirectory('$rootPath/$cards')) {
        if (name.endsWith('.json')) files.add('$cards/$name');
      }
    }
  }

  return files;
}

/// Les identifiants d'une categorie, groupes par proprietaire.
///
/// La cle `null` porte les entites sans proprietaire — toutes les categories
/// sauf la carte — et les cartes neutres. Les autres cles sont des
/// identifiants de classe. C'est cette carte qui dessine le niveau 2 de
/// l'arbre, et le groupement y **est** le repertoire : dans ce projet, le
/// repertoire porte la propriete.
Map<String?, List<String>> entityIdsByOwner(
  ContentFileSystem fs,
  String rootPath,
  EntityDescriptor descriptor,
) {
  final byOwner = <String?, List<String>>{};

  for (final relative in entityFiles(fs, rootPath, descriptor)) {
    final segments = relative.split('/');
    final String? owner;
    final String id;

    if (descriptor.folderFile != null) {
      // `assets/data/classes/<id>/class.json`
      owner = null;
      id = segments[segments.length - 2];
    } else if (segments.length > 4 && segments[2] == 'classes') {
      // `assets/data/classes/<classe>/cards/<id>.json`
      owner = segments[3];
      id = segments.last.replaceAll('.json', '');
    } else {
      // `assets/data/<repertoire>/<id>.json`
      owner = null;
      id = segments.last.replaceAll('.json', '');
    }

    (byOwner[owner] ??= <String>[]).add(id);
  }

  for (final ids in byOwner.values) {
    ids.sort();
  }
  return byOwner;
}
