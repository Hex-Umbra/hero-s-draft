import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/enemy_intent.dart';
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

  test('seules la classe et l ennemi portent des emplacements image', () {
    final withImage = kEntityDescriptors.values
        .where((d) => d.imageKeys.isNotEmpty)
        .map((d) => d.category)
        .toSet();
    expect(withImage, {EntityCategory.heroClass, EntityCategory.enemy});
    for (final category in withImage) {
      expect(kEntityDescriptors[category]!.folderFile, isNotNull);
    }
  });

  test('la classe : classCard obligatoire, iconPath optionnel', () {
    final hero = kEntityDescriptors[EntityCategory.heroClass]!;
    expect(hero.imagePathOf('gambler', 'classCard'),
        'assets/data/classes/gambler/gambler.png');
    expect(hero.imagePathOf('gambler', 'iconPath'),
        'assets/data/classes/gambler/icon.png');
    expect(hero.isComputedImage('classCard'), isTrue);
    expect(hero.isComputedImage('iconPath'), isFalse);
  });

  test('le sprite d un ennemi garde un nom constant', () {
    final enemy = kEntityDescriptors[EntityCategory.enemy]!;
    expect(enemy.imagePathOf('gobelin', 'spritePath'),
        'assets/data/enemies/gobelin/sprite.png');
    expect(enemy.imagePathOf('gobelin', 'sfx'), isNull,
        reason: 'un son n est pas une image');
  });

  // `mastery` est lu par `startNewRun` : c'est la Maitrise de depart de la
  // classe. Absent du gabarit, il etait invisible dans l editeur et
  // valait 0 pour les trois classes sans que personne l ait decide.
  test('le gabarit de classe expose toutes les stats que le modele lit', () {
    final template =
        kEntityDescriptors[EntityCategory.heroClass]!.decodeTemplate();
    for (final key in const [
      'maxHp',
      'maxMana',
      'baseDamage',
      'luck',
      'mastery',
      'critChance',
      'mightTargets',
      'displayOrder',
      'themeColor',
    ]) {
      expect(template.containsKey(key), isTrue, reason: 'clé absente : $key');
    }
  });

  // **Gabarit superset-du-modele, pour les sept categories.**
  //
  // En creation, le formulaire est infere du gabarit : un champ par cle du
  // gabarit, plus les `assetKeys` et les `referenceKeys` qu'il ne porte pas
  // (spec §4.2). Une cle que le modele lit sans figurer a aucune de ces
  // places n'a pas de champ : seule la vue JSON brute l'atteint, a condition
  // de la connaitre — c'est ainsi que `sfx`, `isExhaust`, `spritePath`,
  // `requiresExhaust` et `eligibleCardTypes` avaient disparu de la creation.
  //
  // **Ce que cette table ne fait pas.** Elle est tenue a la main : elle
  // rougit si un gabarit **perd** une cle ou en gagne une qui n'est pas
  // declaree ici, mais elle ne voit pas un `fromJson` qui se met a lire une
  // cle nouvelle. La spec §7.2 voulait lire le source du modele au motif
  // regulier `json['...']` ; ce mecanisme-la se tait des qu'un modele change
  // de forme, ce qui est un silence pire qu'une table honnete. Le prix a
  // payer est donc explicite : **en ajoutant une cle a un `fromJson` de
  // `lib/models/data/`, ajoutez-la ici et au gabarit.**
  //
  // Ne figurent pas au gabarit, et c'est la §5.3 de la spec :
  // - `id`, saisi dans le triangle d'identite ;
  // - `sfx`, ressource son de la carte, de la relique et de l'ennemi : le
  //   formulaire le rend en liste de sons (`assetKeys`), jamais en texte ;
  // - `spritePath` d'une carte : lu par `CardData`, reserve aux illustrations
  //   a venir, sans lecteur a l'ecran. Exclusion nommee, test ci-dessous ;
  // - `classCard` / `spritePath` d'une classe et d'un ennemi, calcules par
  //   `EntityWriter` a partir de l'identifiant ;
  // - `iconPath`, derive de l'identifiant par `ClassRecipe` ;
  // - `skills`, alimente carte par carte par `_registerSignatureCard` ;
  // - `heroClass` et `category`, imposes par le repertoire ;
  // - `classes` d'un passif, qui est une `referenceListKeys` : absente, elle
  //   ouvre le passif a toutes les classes (spec P-49, §3.2). L'assertion
  //   qui suit la table le verifie.
  test('chaque gabarit porte exactement les cles attendues', () {
    const expected = <EntityCategory, Set<String>>{
      EntityCategory.card: {
        'cost',
        'type',
        'rarity',
        'target',
        'animation',
        'isExhaust',
        'effects',
        'baseMaxForgeUpgrades',
      },
      EntityCategory.relic: {
        'trigger',
        'effectType',
        'value',
        'rarity',
        'emoji',
      },
      EntityCategory.passive: {
        'trigger',
        'effectType',
        'value',
        'duration',
        'threshold',
        'draw',
        'displayOrder',
        'mastery',
      },
      // Un evenement n'a qu'une cle de mecanique : le texte de ses choix est
      // imbrique dans `choices`, et le gabarit en montre un exemplaire complet.
      EntityCategory.event: {'choices'},
      EntityCategory.forgeUpgrade: {
        'icon',
        'color',
        'pools',
        'eligibleCardTypes',
        'requiresExhaust',
        'stackable',
        'valueMultiplier',
        'weight',
        'emoji',
      },
      EntityCategory.heroClass: {
        'maxHp',
        'maxMana',
        'baseDamage',
        'luck',
        'mastery',
        'critChance',
        'mightTargets',
        'displayOrder',
        'themeColor',
      },
      EntityCategory.enemy: {
        'maxHp',
        'baseDamage',
        'tier',
        'xp',
        'critChance',
        'gold',
        'intents',
      },
    };

    expect(
      expected.keys.toSet(),
      EntityCategory.values.toSet(),
      reason: 'la table doit couvrir les sept categories',
    );

    expected.forEach((category, keys) {
      expect(
        kEntityDescriptors[category]!.decodeTemplate().keys.toSet(),
        keys,
        reason: '${kEntityDescriptors[category]!.label} : gabarit divergent',
      );
    });
  });

  test('classes est atteignable par le catalogue, pas par le gabarit', () {
    final descriptor = kEntityDescriptors[EntityCategory.passive]!;
    expect(descriptor.decodeTemplate().containsKey('classes'), isFalse);
    expect(descriptor.referenceListKeys, {'classes': EntityCategory.heroClass});
  });

  test('mastery.field propose les parametres que le modele accepte', () {
    final descriptor = kEntityDescriptors[EntityCategory.passive]!;
    expect(descriptor.enumKeys['mastery.field'], PassiveMastery.fields);
  });

  test('sfx est une ressource son des trois categories qui le lisent', () {
    for (final category in const [
      EntityCategory.card,
      EntityCategory.relic,
      EntityCategory.enemy,
    ]) {
      final descriptor = kEntityDescriptors[category]!;
      expect(descriptor.assetKeys['sfx']?.kind, AssetKind.sound,
          reason: descriptor.label);
      expect(descriptor.decodeTemplate().containsKey('sfx'), isFalse,
          reason: descriptor.label);
    }
  });

  // Exclusion nommee (spec §3.4) : le modele lit la cle, le gabarit ne
  // l'ecrit pas. Si `CardData` cesse de la lire, retirer ce test ; si un ecran
  // affiche un jour l'illustration, la cle revient au gabarit avec son champ.
  test('spritePath de carte : lu par le modele, absent du gabarit', () {
    final card = kEntityDescriptors[EntityCategory.card]!;
    expect(card.decodeTemplate().containsKey('spritePath'), isFalse);
    expect(card.assetKeys.containsKey('spritePath'), isFalse);

    final read = CardData.fromJson({
      'id': 'x',
      'cost': 1,
      'type': 'attack',
      'spritePath': 'assets/illustration.png',
    });
    expect(read.spritePath, 'assets/illustration.png');
  });

  test('les vocabulaires fermes cote moteur sont declares', () {
    expect(kEntityDescriptors[EntityCategory.card]!.vocabularyKeys,
        {'animation', 'effects[].type', 'effects[].statusId'});
    expect(kEntityDescriptors[EntityCategory.relic]!.vocabularyKeys,
        {'effectType'});
    expect(kEntityDescriptors[EntityCategory.passive]!.vocabularyKeys,
        {'effectType'});
    expect(kEntityDescriptors[EntityCategory.event]!.vocabularyKeys,
        {'choices[].actions[].type'});
  });

  test('le type d intention d un ennemi est une enumeration imbriquee', () {
    // `EnemyIntent.fromJson` retombe en silence sur `attack` : sans cette
    // declaration, une faute de frappe devient une attaque.
    expect(
      kEntityDescriptors[EntityCategory.enemy]!.enumKeys['intents[].type'],
      IntentType.values.map((e) => e.name).toList(),
    );
  });

  // `forge_slot_row.dart` lit `color` et `icon` par leur nom (`amberAccent`,
  // `flash_on_rounded`) et retombe en silence sur du gris et
  // `Icons.help_outline` : ce sont des vocabulaires du moteur, pas un hex.
  test('la couleur et l icone d une amelioration de forge sont des noms du '
      'moteur', () {
    final forge = kEntityDescriptors[EntityCategory.forgeUpgrade]!;
    expect(forge.vocabularyKeys, {'color', 'icon'});
    expect(forge.hexColorKeys, isEmpty);
  });
}
