// Regenere la section `assets:` de pubspec.yaml depuis le contenu reel de
// `assets/`.
//
// Raison d etre : les declarations d assets de Flutter ne sont recursives a
// aucun niveau (`flutter_tools/lib/src/asset.dart:1178-1180`). Chaque dossier
// de classe et d ennemi exige donc sa propre ligne, et le nombre de lignes
// devient variable. Un dossier present mais non declare ne produit AUCUN
// message : son contenu se charge en developpement et disparait en build.
//
// Usage :
//   dart run tool/sync_assets.dart           regenere la section
//   dart run tool/sync_assets.dart --check   sort en 1 si elle a derive

import 'dart:io';

void main(List<String> args) {
  final checkOnly = args.contains('--check');

  final expected = _directoriesWithFiles(Directory('assets'));
  final pubspec = File('pubspec.yaml');
  final content = pubspec.readAsStringSync();
  final eol = content.contains('\r\n') ? '\r\n' : '\n';

  final lines = content.split(eol);
  final start = lines.indexWhere((l) => l == '  assets:');
  if (start == -1) {
    stderr.writeln('pubspec.yaml : section "  assets:" introuvable.');
    exit(2);
  }

  var end = start + 1;
  while (end < lines.length && lines[end].startsWith('    - ')) {
    end++;
  }

  final current = lines
      .sublist(start + 1, end)
      .map((l) => l.substring('    - '.length))
      .toList();

  if (checkOnly) {
    final missing = expected.where((d) => !current.contains(d)).toList();
    final extra = current.where((d) => !expected.contains(d)).toList();
    if (missing.isEmpty && extra.isEmpty && _sameOrder(current, expected)) {
      exit(0);
    }
    stdout.writeln('pubspec.yaml a derive du contenu de assets/ :');
    for (final d in missing) {
      stdout.writeln('  manquant : $d');
    }
    for (final d in extra) {
      stdout.writeln('  en trop  : $d');
    }
    if (missing.isEmpty && extra.isEmpty) {
      stdout.writeln('  (memes entrees, ordre different — la section doit etre triee)');
    }
    stdout.writeln('Corriger avec : dart run tool/sync_assets.dart');
    exit(1);
  }

  if (_sameOrder(current, expected)) {
    stdout.writeln('pubspec.yaml deja a jour (${expected.length} entrees).');
    exit(0);
  }

  final rebuilt = <String>[
    ...lines.sublist(0, start + 1),
    ...expected.map((d) => '    - $d'),
    ...lines.sublist(end),
  ];
  pubspec.writeAsStringSync(rebuilt.join(eol));
  stdout.writeln('pubspec.yaml regenere : ${expected.length} entrees.');
}

bool _sameOrder(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Tout repertoire sous [root] contenant au moins un fichier *direct*, chemin
/// relatif a la racine du projet, termine par `/`, trie.
///
/// Un repertoire ne contenant que des sous-repertoires n a rien a declarer :
/// la declaration n etant pas recursive, elle n apporterait aucun asset.
List<String> _directoriesWithFiles(Directory root) {
  if (!root.existsSync()) return const [];

  final result = <String>[];

  void walk(Directory directory) {
    final entities = directory.listSync();
    if (entities.whereType<File>().isNotEmpty) {
      result.add('${directory.path.replaceAll(r'\', '/')}/');
    }
    for (final child in entities.whereType<Directory>()) {
      walk(child);
    }
  }

  walk(root);
  result.sort();
  return result;
}
