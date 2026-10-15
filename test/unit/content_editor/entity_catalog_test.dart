import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system_io.dart';
import 'package:roguelike_card_game/services/content_editor/entity_catalog.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';

void main() {
  late Directory sandbox;
  late String root;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('entity_catalog_');
    root = IoContentFileSystem.toSlashes(sandbox.path);
  });

  tearDown(() => sandbox.deleteSync(recursive: true));

  test('une categorie simple rend ses identifiants sous la cle null', () {
    Directory('$root/assets/data/relics').createSync(recursive: true);
    File('$root/assets/data/relics/talisman.json').writeAsStringSync('{}');
    File('$root/assets/data/relics/amulette.json').writeAsStringSync('{}');

    final byOwner = entityIdsByOwner(
      const IoContentFileSystem(),
      root,
      kEntityDescriptors[EntityCategory.relic]!,
    );

    expect(byOwner.keys, [null]);
    expect(byOwner[null], ['amulette', 'talisman'], reason: 'triés');
  });

  /// Une carte neutre a plat, et une signature sous le dossier du paladin.
  void seedCardAndSignature() {
    Directory('$root/assets/data/cards').createSync(recursive: true);
    File('$root/assets/data/cards/frappe.json').writeAsStringSync('{}');
    Directory('$root/assets/data/classes/paladin/skills')
        .createSync(recursive: true);
    File('$root/assets/data/classes/paladin/skills/smite.json')
        .writeAsStringSync('{}');
  }

  test('les signatures sont groupees par classe', () {
    seedCardAndSignature();

    final byOwner = entityIdsByOwner(
      const IoContentFileSystem(),
      root,
      kEntityDescriptors[EntityCategory.signature]!,
    );

    // Aucune cle nulle : une signature a toujours une classe, et la carte
    // neutre a plat n'est pas une signature.
    expect(byOwner, {
      'paladin': ['smite'],
    });
  });

  test('les cartes vivent a plat, sans proprietaire', () {
    seedCardAndSignature();

    final byOwner = entityIdsByOwner(
      const IoContentFileSystem(),
      root,
      kEntityDescriptors[EntityCategory.card]!,
    );

    // La signature du paladin n'apparait pas parmi les cartes.
    expect(byOwner, {
      null: ['frappe'],
    });
  });

  test('une classe est listee par son dossier, pas par un fichier a plat', () {
    Directory('$root/assets/data/classes/mage').createSync(recursive: true);
    File('$root/assets/data/classes/mage/class.json').writeAsStringSync('{}');

    final byOwner = entityIdsByOwner(
      const IoContentFileSystem(),
      root,
      kEntityDescriptors[EntityCategory.heroClass]!,
    );

    expect(byOwner[null], ['mage']);
  });

  // Un dossier de classe sans `class.json` n'est pas une classe. Sans ce
  // filtre, un dossier laisse par une creation avortee apparaitrait comme une
  // entite modifiable, et « Charger » echouerait sur un fichier absent.
  test('un dossier sans son fichier n est pas une entite', () {
    Directory('$root/assets/data/classes/fantome').createSync(recursive: true);

    final byOwner = entityIdsByOwner(
      const IoContentFileSystem(),
      root,
      kEntityDescriptors[EntityCategory.heroClass]!,
    );

    expect(byOwner[null] ?? const [], isEmpty);
  });
}
