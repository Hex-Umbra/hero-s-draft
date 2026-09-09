import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Le cache d'images de Flame n'inclut pas le prefixe dans ses cles
/// (`flame/lib/src/cache/images.dart:29-32`). Le jeu tourne donc avec un
/// prefixe vide et des chemins complets : le chemin EST la cle, et deux
/// cartes de classe de classes differentes ne peuvent plus se marcher dessus.
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
        // `as String?` + `continue` : un champ absent est ignore ici, pas
        // signale — ce n est donc pas une garde complete a soi seule. Elle
        // est compensee deux fois ailleurs : `HeroData.fromJson` caste
        // `classCard` en non-nullable (`hero_data.dart:73`), ce qui fait
        // echouer le chargement si le champ manque, et
        // `referential_integrity_test.dart:83` compare `classCard` a sa
        // valeur exacte attendue. Ce test-ci ne verifie qu une chose : un
        // chemin present est complet et designe un fichier existant.
        if (path == null) continue;
        if (!path.startsWith('assets/')) {
          offenders.add('${file.path} : "$path" n est pas un chemin complet');
        } else if (!File(path).existsSync()) {
          offenders.add('${file.path} : "$path" ne designe aucun fichier');
        }
      }
    }

    check('classes', 'classCard');
    // `iconPath` est optionnel — les trois classes livrees n'en portent pas,
    // et la garde `path == null` ci-dessus les laisse donc passer. Ce qui est
    // controle ici, c'est le cas d'une classe **creee par l'outil** :
    // `ClassRecipe` ecrit toujours la cle, tandis que
    // `EntityWriter._placeClassIcon` sort en silence si le placeholder source
    // manque. Le `class.json` designerait alors un fichier inexistant, que
    // rien d'autre ne surveillait.
    check('classes', 'iconPath');
    check('enemies', 'spritePath');

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
