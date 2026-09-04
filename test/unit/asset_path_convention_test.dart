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

    void check(String catalogue, String field) {
      final raw = File('assets/data/$catalogue').readAsStringSync();
      for (final entry in jsonDecode(raw) as List) {
        final path = (entry as Map<String, dynamic>)[field] as String;
        final id = entry['id'] as String;
        if (!path.startsWith('assets/')) {
          offenders.add('$catalogue → $id : "$path" n est pas un chemin complet');
        } else if (!File(path).existsSync()) {
          offenders.add('$catalogue → $id : "$path" ne designe aucun fichier');
        }
      }
    }

    check('heroes.json', 'iconPath');
    check('enemies.json', 'spritePath');

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
