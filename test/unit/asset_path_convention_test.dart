import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Le cache d'images de Flame n'inclut pas le prefixe dans ses cles
/// (`flame/lib/src/cache/images.dart:29-32`). Le jeu tourne donc avec un
/// prefixe vide et des chemins complets : le chemin EST la cle, et deux
/// `icon.png` de classes differentes ne peuvent plus se marcher dessus.
void main() {
  test('tout chemin d image des donnees est complet et designe un fichier existant', () {
    final offenders = <String>[];

    void check(String directory, String field) {
      for (final file in Directory('assets/data/$directory')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))) {
        final entry = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final path = entry[field] as String?;
        if (path == null) continue;
        if (!path.startsWith('assets/')) {
          offenders.add('${file.path} : "$path" n est pas un chemin complet');
        } else if (!File(path).existsSync()) {
          offenders.add('${file.path} : "$path" ne designe aucun fichier');
        }
      }
    }

    check('classes', 'iconPath');
    check('enemies', 'spritePath');

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
