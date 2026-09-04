// Script de decoupage, a usage UNIQUE. Commite pour etre auditable en revue,
// supprime une fois la migration fusionnee (§8.1 de la spec).
//
// Il ne transforme qu une seule chose : les chemins d images, qui suivent
// leur fichier. Tout le reste est recopie a l identique — c est ce que
// `test/migration/data_equivalence_test.dart` verifie, sur le JSON brut.
//
// Usage : dart run tool/split_catalogues.dart

import 'dart:convert';
import 'dart:io';

const _encoder = JsonEncoder.withIndent('  ');

void main() {
  _splitFlat('cards.json', 'cards');
  _splitFlat('relics.json', 'relics');
  _splitFlat('events.json', 'events');
  _splitFlat('forge_upgrades.json', 'forge_upgrades');
  _splitFlat('passives.json', 'passives');

  _splitClasses();
  _splitClassCards();
  _splitEnemies();

  stdout.writeln('Decoupage termine. Lancer maintenant :');
  stdout.writeln('  dart run tool/sync_assets.dart');
  stdout.writeln('  flutter clean && flutter test');
}

List<Map<String, dynamic>> _read(String catalogue) =>
    (jsonDecode(File('assets/data/$catalogue').readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();

void _write(String path, Map<String, dynamic> entity) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  // LF et retour a la ligne final : ce sont des fichiers neufs, autant leur
  // donner la forme la plus portable. Le contenu JSON est ce qui compte, et
  // l oracle compare des valeurs parsees, pas des octets.
  file.writeAsStringSync('${_encoder.convert(entity)}\n');
  stdout.writeln('  + $path');
}

void _splitFlat(String catalogue, String directory) {
  for (final entity in _read(catalogue)) {
    _write('assets/data/$directory/${entity['id']}.json', entity);
  }
}

void _splitClasses() {
  for (final hero in _read('heroes.json')) {
    final id = hero['id'] as String;
    final source = hero['iconPath'] as String; // 'assets/images/hero_x.png'
    final destination = 'assets/data/classes/$id/icon.png';

    final copy = Map<String, dynamic>.of(hero)..['iconPath'] = destination;
    _write('assets/data/classes/$id/class.json', copy);

    File(destination).parent.createSync(recursive: true);
    File(source).copySync(destination);
    stdout.writeln('  + $destination (copie de $source)');
  }
}

void _splitClassCards() {
  for (final card in _read('hero_cards.json')) {
    final owner = card['heroClass'] as String;
    _write('assets/data/classes/$owner/cards/${card['id']}.json', card);
  }
}

void _splitEnemies() {
  for (final enemy in _read('enemies.json')) {
    final id = enemy['id'] as String;
    final source = enemy['spritePath'] as String; // 'assets/images/enemy_x.png'
    final destination = 'assets/data/enemies/$id/sprite.png';

    final copy = Map<String, dynamic>.of(enemy)..['spritePath'] = destination;
    _write('assets/data/enemies/$id/enemy.json', copy);

    File(destination).parent.createSync(recursive: true);
    File(source).copySync(destination);
    stdout.writeln('  + $destination (copie de $source)');
  }
}
