import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';

void main() {
  test('les descripteurs couvrent les sept categories chargeables', () {
    // `loadGameDataRegistry` declare sept categories d'entites (l'audio n'en
    // est pas une). Une source ajoutee la-bas sans descripteur ici rendrait
    // une categorie du jeu ineditable sans que rien ne le signale.
    expect(kEntityDescriptors.keys.toSet(), EntityCategory.values.toSet());
    expect(EntityCategory.values, hasLength(7));
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
