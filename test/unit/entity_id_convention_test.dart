import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Le nom de fichier EST l id (§6.1 de la spec), sauf pour `class.json` et
/// `enemy.json`, dont l id vient du repertoire parent.
///
/// La casse compte : le poste de dev est Windows (NTFS insensible a la
/// casse), la CI est `ubuntu-latest`, et les cibles web/Android sont
/// sensibles a la casse. Un fichier commite avec une casse divergente passe
/// en local et echoue en CI — et un renommage de pure casse est invisible
/// pour git sous Windows.
const _pattern = r'^[a-z0-9_]+$';

Iterable<File> _entityFiles() sync* {
  for (final entity in Directory('assets/data').listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.json')) continue;
    final name = entity.uri.pathSegments.last;
    // Les deux documents de configuration ne sont pas des entites.
    if (name == 'patch_notes.json' || name == 'audio.json') continue;
    yield entity;
  }
}

String _idOf(File file) {
  final segments = file.uri.pathSegments;
  final name = segments.last;
  if (name == 'class.json' || name == 'enemy.json') {
    return segments[segments.length - 2];
  }
  return name.substring(0, name.length - '.json'.length);
}

void main() {
  test('tous les ids d entites sont en snake_case ASCII minuscule', () {
    final regex = RegExp(_pattern);
    final offenders = <String>[];

    for (final file in _entityFiles()) {
      final id = _idOf(file);
      if (!regex.hasMatch(id)) offenders.add('${file.path} → $id');
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('le nom de fichier est l id, ou le repertoire parent pour class/enemy', () {
    final offenders = <String>[];

    for (final file in _entityFiles()) {
      final declared =
          (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>)['id'];
      if (declared == null) continue; // l injection le fournira
      if (declared != _idOf(file)) {
        offenders.add('${file.path} : declare "$declared", attendu "${_idOf(file)}"');
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('il y a bien 71 fichiers d entite', () {
    // 17 cartes neutres + 25 reliques + 5 evenements + 8 ameliorations de
    // forge + 3 passifs + 3 class.json + 6 cartes de classe + 4 enemy.json.
    expect(_entityFiles().length, 71);
  });
}
