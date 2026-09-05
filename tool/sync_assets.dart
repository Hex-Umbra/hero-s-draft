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
//
// Le script refuse de travailler (exit 2, stderr, fichier intact) plutot que
// de deviner face a un pubspec.yaml ambigu : cle "  assets:" dupliquee
// (_checkNoDuplicateAssetsLine) ou entree de liste juste apres le bloc a une
// indentation etrangere (_checkTrailingIndentation). Les deux gardes
// s appliquent aussi en mode --check, avant tout diagnostic.

import 'dart:io';

void main(List<String> args) {
  final checkOnly = args.contains('--check');

  final expected = _directoriesWithFiles(Directory('assets'));
  final pubspec = File('pubspec.yaml');
  final content = pubspec.readAsStringSync();
  final eol = content.contains('\r\n') ? '\r\n' : '\n';

  final lines = content.split(eol);
  _checkNoDuplicateAssetsLine(lines);
  final start = lines.indexWhere((l) => l == '  assets:');
  if (start == -1) {
    stderr.writeln('pubspec.yaml : section "  assets:" introuvable.');
    exit(2);
  }

  var end = start + 1;
  while (end < lines.length && lines[end].startsWith('    - ')) {
    end++;
  }
  _checkTrailingIndentation(lines, end);

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

/// Refuse de continuer si "  assets:" apparait plus d une fois dans le
/// fichier : un pubspec.yaml peut porter une dependance nommee `assets` (les
/// enfants de `dependencies:` sont eux aussi indentes de 2 espaces), et
/// deviner laquelle est la bonne reecrirait silencieusement la mauvaise
/// section.
void _checkNoDuplicateAssetsLine(List<String> lines) {
  final matches = [
    for (var i = 0; i < lines.length; i++)
      if (lines[i] == '  assets:') i,
  ];
  if (matches.length <= 1) return;

  final lineNumbers = matches.map((i) => i + 1).join(', ');
  stderr.writeln(
    'pubspec.yaml : plusieurs lignes "  assets:" trouvees (lignes '
    '$lineNumbers) ; impossible de determiner laquelle est la section '
    'assets de flutter: a synchroniser.',
  );
  exit(2);
}

/// Refuse de continuer si une entree de liste suit immediatement le bloc
/// `assets:` a une indentation autre que 4 espaces. Une telle ligne n a ete
/// comptee ni dans le bloc (elle a arrete la boucle qui calcule [end]) ni
/// reconnue comme une section suivante : la laisser en l etat ferait
/// inserer le nouveau bloc par-dessus, doublons sous deux indentations. Le
/// balayage s arrete a la premiere ligne qui n est pas une entree de liste,
/// pour ne pas confondre avec une section `fonts:` legitime qui suivrait.
void _checkTrailingIndentation(List<String> lines, int end) {
  final listEntry = RegExp(r'^(\s*)- ');
  final rogueLines = <int>[];

  for (var i = end; i < lines.length; i++) {
    final match = listEntry.firstMatch(lines[i]);
    if (match == null) break;
    if (match.group(1)!.length != 4) {
      rogueLines.add(i);
    }
  }
  if (rogueLines.isEmpty) return;

  for (final i in rogueLines) {
    stderr.writeln(
      'pubspec.yaml ligne ${i + 1} : "${lines[i]}" — entree de liste a '
      'une indentation inattendue (4 espaces requis) ; corriger '
      'l indentation.',
    );
  }
  exit(2);
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
