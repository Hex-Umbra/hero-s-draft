import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system_io.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/services/content_editor/known_values.dart';

void main() {
  late Directory sandbox;
  late String root;
  const fs = IoContentFileSystem();

  void write(String relative, String content) {
    final file = File('$root/$relative');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('known_values_');
    root = IoContentFileSystem.toSlashes(sandbox.path);
  });

  tearDown(() => sandbox.deleteSync(recursive: true));

  test('rassemble les valeurs distinctes, triees', () {
    write('assets/data/relics/a.json',
        '{"trigger": "startOfRun", "effectType": "heal"}');
    write('assets/data/relics/b.json',
        '{"trigger": "startOfCombat", "effectType": "heal"}');

    final values =
        knownValues(fs, root, kEntityDescriptors[EntityCategory.relic]!);

    expect(values['trigger'], ['startOfCombat', 'startOfRun']);
    expect(values['effectType'], ['heal']);
  });

  test('les cles de prose et l identifiant sont ecartes', () {
    write('assets/data/relics/a.json',
        '{"id": "a", "name_fr": "Amulette", "effectType": "heal"}');

    final values =
        knownValues(fs, root, kEntityDescriptors[EntityCategory.relic]!);

    expect(values.containsKey('id'), isFalse);
    expect(values.containsKey('name_fr'), isFalse);
    expect(values['effectType'], ['heal']);
  });

  test('les listes de chaines sont aplaties', () {
    write('assets/data/forge_upgrades/a.json',
        '{"pools": ["common", "rare"]}');
    write('assets/data/forge_upgrades/b.json', '{"pools": ["rare"]}');

    final values =
        knownValues(fs, root, kEntityDescriptors[EntityCategory.forgeUpgrade]!);

    expect(values['pools'], ['common', 'rare']);
  });

  test('une carte est cherchee a plat ET sous chaque classe', () {
    write('assets/data/cards/neutre.json', '{"animation": "melee"}');
    write('assets/data/classes/paladin/cards/smite.json',
        '{"animation": "buff"}');

    final values =
        knownValues(fs, root, kEntityDescriptors[EntityCategory.card]!);

    expect(values['animation'], ['buff', 'melee']);
  });

  test('une categorie en dossier lit le fichier que le dossier porte', () {
    write('assets/data/enemies/gobelin/enemy.json', '{"sfx": "hit_small"}');
    write('assets/data/enemies/orc/enemy.json', '{"sfx": "hit_big"}');
    // Un fichier egare a la racine de la categorie n'est pas une entite.
    write('assets/data/enemies/notes.txt', 'rien');

    final values =
        knownValues(fs, root, kEntityDescriptors[EntityCategory.enemy]!);

    expect(values['sfx'], ['hit_big', 'hit_small']);
  });

  test('un fichier illisible ne prive pas du panneau entier', () {
    write('assets/data/relics/bon.json', '{"effectType": "heal"}');
    write('assets/data/relics/casse.json', '{ pas du json');

    final values =
        knownValues(fs, root, kEntityDescriptors[EntityCategory.relic]!);

    expect(values['effectType'], ['heal']);
  });

  test('un repertoire absent rend une table vide, sans lever', () {
    expect(
      knownValues(fs, root, kEntityDescriptors[EntityCategory.event]!),
      isEmpty,
    );
  });

  test('les valeurs imbriquees sont rangees sous leur motif', () {
    write('assets/data/cards/a.json',
        '{"effects": [{"type": "damage", "value": 6}, '
        '{"type": "apply_status", "statusId": "burn", "value": 2}]}');
    write('assets/data/events/e.json',
        '{"choices": [{"text_fr": "Oui", "text_en": "Yes", '
        '"actions": [{"type": "heal", "value": 5}]}]}');

    final cards =
        knownValues(fs, root, kEntityDescriptors[EntityCategory.card]!);
    expect(cards['effects[].type'], ['apply_status', 'damage']);
    expect(cards['effects[].statusId'], ['burn']);

    final events =
        knownValues(fs, root, kEntityDescriptors[EntityCategory.event]!);
    expect(events['choices[].actions[].type'], ['heal']);
    expect(events.keys.where((key) => key.contains('text_')), isEmpty,
        reason: 'la prose imbriquee n est pas un vocabulaire');
  });

  test('vocabularyOf ajoute les valeurs du gabarit a celles du disque', () {
    final relic = kEntityDescriptors[EntityCategory.relic]!;
    expect(vocabularyOf(relic, const {'effectType': ['heal']})['effectType'],
        ['gain_armor', 'heal']);
    expect(vocabularyOf(relic, const {})['effectType'], ['gain_armor']);
  });
}
