import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// L oracle de la migration. Son sujet est le **JSON brut**, jamais un modele
/// Dart.
///
/// Comparer des Map produites par `toJson()` serait auto-referentiel : un
/// champ lu par `fromJson` et omis par `toJson` serait invisible des DEUX
/// cotes du diff. Ce n est pas theorique — `CardData.toJson()`
/// (`card_data.dart:134-151`) omet deja `sfx`, que `fromJson:123` lit. Aucune
/// carte ne porte `sfx` aujourd hui, mais P-47 « seconde passe audio » est le
/// chantier ouvert, et son objet est precisement de sonoriser du contenu.
///
/// Ce fichier et son repertoire sont supprimes une fois la migration fusionnee.
List<Map<String, dynamic>> _reference(String catalogue) =>
    (jsonDecode(File('test/migration/reference/$catalogue').readAsStringSync())
            as List)
        .cast<Map<String, dynamic>>();

Map<String, dynamic> _file(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// Les seuls champs que la migration a le droit de changer, et la regle
/// exacte qu ils doivent suivre.
const _transformed = {'iconPath', 'spritePath'};

void _expectSameEntities(
  List<Map<String, dynamic>> reference,
  Map<String, Map<String, dynamic>> migrated,
  String label,
) {
  final referenceIds = reference.map((e) => e['id'] as String).toSet();
  expect(
    migrated.keys.toSet(),
    referenceIds,
    reason: '$label : la liste des entites a change entre les deux mondes',
  );
}

void _expectSameFields(
  List<Map<String, dynamic>> reference,
  Map<String, Map<String, dynamic>> migrated,
  String label,
  List<String> injected,
) {
  final differences = <String>[];

  for (final before in reference) {
    final id = before['id'] as String;
    final after = migrated[id]!;

    for (final entry in before.entries) {
      if (_transformed.contains(entry.key)) continue;
      if (!after.containsKey(entry.key)) {
        differences.add('$label/$id : champ "${entry.key}" perdu');
        continue;
      }
      if (jsonEncode(after[entry.key]) != jsonEncode(entry.value)) {
        differences.add(
          '$label/$id : champ "${entry.key}" — avant ${jsonEncode(entry.value)}, '
          'apres ${jsonEncode(after[entry.key])}',
        );
      }
    }

    for (final key in after.keys) {
      if (before.containsKey(key)) continue;
      if (injected.contains(key)) continue;
      differences.add('$label/$id : champ "$key" apparu de nulle part');
    }
  }

  expect(differences, isEmpty, reason: differences.join('\n'));
}

Map<String, Map<String, dynamic>> _flatCategory(String directory) {
  final files = Directory('assets/data/$directory')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'));
  return {
    for (final f in files)
      f.uri.pathSegments.last.replaceAll('.json', ''): _file(f.path),
  };
}

void main() {
  group('Equivalence de la migration — categories a plat', () {
    const plain = {
      'cards.json': 'cards',
      'relics.json': 'relics',
      'events.json': 'events',
      'forge_upgrades.json': 'forge_upgrades',
      'passives.json': 'passives',
    };

    test('meme population, memes champs, memes valeurs', () {
      plain.forEach((catalogue, directory) {
        final reference = _reference(catalogue);
        final migrated = _flatCategory(directory);
        _expectSameEntities(reference, migrated, directory);
        _expectSameFields(reference, migrated, directory, const []);
      });
    });
  });

  group('Equivalence de la migration — dossiers auto-suffisants', () {
    test('les classes : class.json plus le pool de cartes de la classe', () {
      final reference = _reference('heroes.json');
      final migrated = <String, Map<String, dynamic>>{
        for (final d in Directory('assets/data/classes').listSync().whereType<Directory>())
          d.uri.pathSegments[d.uri.pathSegments.length - 2]:
              _file('${d.path}/class.json'),
      };
      _expectSameEntities(reference, migrated, 'classes');
      _expectSameFields(reference, migrated, 'classes', const []);
    });

    test('les cartes de classe sont rangees sous leur classe', () {
      final reference = _reference('hero_cards.json');
      final migrated = <String, Map<String, dynamic>>{};
      final owner = <String, String>{};

      for (final d in Directory('assets/data/classes').listSync().whereType<Directory>()) {
        final className = d.uri.pathSegments[d.uri.pathSegments.length - 2];
        for (final f in Directory('${d.path}/cards').listSync().whereType<File>()) {
          final id = f.uri.pathSegments.last.replaceAll('.json', '');
          migrated[id] = _file(f.path);
          owner[id] = className;
        }
      }

      _expectSameEntities(reference, migrated, 'hero_cards');
      _expectSameFields(reference, migrated, 'hero_cards', const []);

      // Le repertoire doit dire la meme chose que le champ qu il remplacera.
      for (final before in reference) {
        final id = before['id'] as String;
        expect(owner[id], before['heroClass'],
            reason: '$id est range sous ${owner[id]} mais declare ${before['heroClass']}');
      }
    });

    test('les ennemis : enemy.json dans son dossier', () {
      final reference = _reference('enemies.json');
      final migrated = <String, Map<String, dynamic>>{
        for (final d in Directory('assets/data/enemies').listSync().whereType<Directory>())
          d.uri.pathSegments[d.uri.pathSegments.length - 2]:
              _file('${d.path}/enemy.json'),
      };
      _expectSameEntities(reference, migrated, 'enemies');
      _expectSameFields(reference, migrated, 'enemies', const []);
    });
  });

  group('Equivalence de la migration — les chemins d images', () {
    test('les images sont renommees selon la regle, et les fichiers existent', () {
      for (final before in _reference('heroes.json')) {
        final id = before['id'] as String;
        final after = _file('assets/data/classes/$id/class.json');
        expect(after['iconPath'], 'assets/data/classes/$id/icon.png');
        expect(File('assets/data/classes/$id/icon.png').existsSync(), isTrue);
      }
      for (final before in _reference('enemies.json')) {
        final id = before['id'] as String;
        final after = _file('assets/data/enemies/$id/enemy.json');
        expect(after['spritePath'], 'assets/data/enemies/$id/sprite.png');
        expect(File('assets/data/enemies/$id/sprite.png').existsSync(), isTrue);
      }
    });

    test('les octets de l image copiee sont identiques a l original', () {
      // La comparaison porte sur la copie figee de `reference/images/`, pas
      // sur `assets/images/` : la tache 7 y supprime les originaux, et un
      // oracle qui lirait la source qu on est en train de retirer deviendrait
      // rouge pour une raison qui n a rien a voir avec l equivalence.
      const icons = {
        'paladin': 'hero_paladin.png',
        'berserker': 'hero_berserker.png',
        'mage': 'hero_mage.png',
      };
      icons.forEach((id, original) {
        expect(
          File('assets/data/classes/$id/icon.png').readAsBytesSync(),
          File('test/migration/reference/images/$original').readAsBytesSync(),
        );
      });

      const sprites = {
        'slime': 'enemy_slime.png',
        'gobelin': 'enemy_goblin.png',
        'squelette': 'enemy_skeleton.png',
        'orc': 'enemy_orc.png',
      };
      sprites.forEach((id, original) {
        expect(
          File('assets/data/enemies/$id/sprite.png').readAsBytesSync(),
          File('test/migration/reference/images/$original').readAsBytesSync(),
        );
      });
    });
  });
}
