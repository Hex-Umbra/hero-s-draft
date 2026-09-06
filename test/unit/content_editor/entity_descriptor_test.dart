import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';

void main() {
  test('la table couvre toutes les valeurs de EntityCategory', () {
    // Ce que cette assertion prouve, exactement : la table est complete au
    // regard de l'enumeration. Les deux symboles vivent dans le **meme**
    // fichier, a cent lignes l'un de l'autre ; elle ne dit donc rien de
    // `loadGameDataRegistry`, dont c'est le test suivant qui s'occupe.
    expect(kEntityDescriptors.keys.toSet(), EntityCategory.values.toSet());
    expect(EntityCategory.values, hasLength(7));
  });

  test('aucune source de chargement n a ete ajoutee sans descripteur', () {
    // Le fil de detente que la §9 de la spec promettait, et qui n'existait
    // pas : rien, dans le code, ne relie les descripteurs aux sources du
    // chargeur. Faute d'API commune, on compte les declarations dans le
    // texte du fichier. Instrument grossier, mais honnete.
    //
    // **Si ce test rougit apres l'ajout d'une `EntitySource` :** ajouter la
    // categorie a `EntityCategory`, son descripteur a `kEntityDescriptors`,
    // puis relever le compte ci-dessous. Huit sources pour sept categories —
    // la carte en a deux, neutre et de classe, pour un seul descripteur.
    final declared = 'EntitySource('
        .allMatches(File('lib/services/game_data_service.dart').readAsStringSync());
    expect(declared, hasLength(8));
  });

  test('chaque descripteur est indexe sous sa propre categorie', () {
    kEntityDescriptors.forEach((key, descriptor) {
      expect(descriptor.category, key);
    });
  });

  group('pathOf', () {
    test('une carte neutre va dans cards/', () {
      expect(
        kEntityDescriptors[EntityCategory.card]!.pathOf('coup_bas'),
        'assets/data/cards/coup_bas.json',
      );
    });

    test('une carte de classe va dans le dossier de sa classe', () {
      expect(
        kEntityDescriptors[EntityCategory.card]!
            .pathOf('smite', heroClass: 'paladin'),
        'assets/data/classes/paladin/cards/smite.json',
      );
    });

    test('une relique va dans relics/', () {
      expect(
        kEntityDescriptors[EntityCategory.relic]!.pathOf('talisman'),
        'assets/data/relics/talisman.json',
      );
    });

    test('une classe est un dossier portant class.json', () {
      expect(
        kEntityDescriptors[EntityCategory.heroClass]!.pathOf('barde'),
        'assets/data/classes/barde/class.json',
      );
    });

    test('un ennemi est un dossier portant enemy.json', () {
      expect(
        kEntityDescriptors[EntityCategory.enemy]!.pathOf('troll'),
        'assets/data/enemies/troll/enemy.json',
      );
    });
  });

  test('les cles enumerees viennent des enumerations reelles', () {
    // Le point de la decision E3 : si `CardRarity` gagne une valeur, le
    // descripteur la connait sans qu'on l'ait recopiee.
    expect(
      kEntityDescriptors[EntityCategory.card]!.enumKeys['rarity'],
      CardRarity.values.map((e) => e.name).toList(),
    );
  });

  test('la carte interdit les champs que le repertoire impose', () {
    expect(
      kEntityDescriptors[EntityCategory.card]!.forbiddenKeys,
      {'heroClass', 'category'},
    );
  });

  test('les gabarits sont du JSON valide et ne portent aucun champ interdit',
      () {
    for (final descriptor in kEntityDescriptors.values) {
      final decoded = descriptor.decodeTemplate();
      for (final forbidden in descriptor.forbiddenKeys) {
        expect(
          decoded.containsKey(forbidden),
          isFalse,
          reason: '${descriptor.label} : gabarit portant "$forbidden"',
        );
      }
    }
  });

  test('seule la carte accepte une classe', () {
    final withClass = kEntityDescriptors.values
        .where((d) => d.supportsHeroClass)
        .map((d) => d.category)
        .toList();
    expect(withClass, [EntityCategory.card]);
  });

  test('seules la classe et l ennemi sont des dossiers a image', () {
    final withImage = kEntityDescriptors.values
        .where((d) => d.imageName != null)
        .map((d) => d.category)
        .toSet();
    expect(withImage, {EntityCategory.heroClass, EntityCategory.enemy});

    for (final category in withImage) {
      final descriptor = kEntityDescriptors[category]!;
      expect(descriptor.folderFile, isNotNull);
      expect(descriptor.imagePathKey, isNotNull);
    }
  });
}
