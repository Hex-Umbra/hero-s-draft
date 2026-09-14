import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system_io.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/services/content_editor/entity_draft.dart';
import 'package:roguelike_card_game/services/content_editor/entity_validator.dart';
import 'package:roguelike_card_game/services/content_editor/pending_import.dart';

import 'fixtures.dart';

void main() {
  late Directory sandbox;
  late String root;
  const fs = IoContentFileSystem();

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('validator_');
    root = IoContentFileSystem.toSlashes(sandbox.path);
    Directory('$root/assets/data/relics').createSync(recursive: true);
  });

  tearDown(() => sandbox.deleteSync(recursive: true));

  EntityValidator validatorWith({dynamic registry}) => EntityValidator(
        fs: fs,
        rootPath: root,
        registry: registry ?? fixtureRegistry(),
      );

  group('famille 1 — identite', () {
    test('un identifiant vide est refuse', () {
      final faults = validatorWith().validate(fixtureRelicDraft(id: ''));
      expect(faults, isNotEmpty);
      expect(faults.first.field, 'id');
    });

    test('les majuscules et les accents sont refuses', () {
      for (final bad in ['Talisman', 'talisman-de-fer', 'épée', 'talisman ']) {
        final faults = validatorWith().validate(fixtureRelicDraft(id: bad));
        expect(faults, isNotEmpty, reason: 'accepte a tort : "$bad"');
        expect(faults.first.field, 'id');
      }
    });

    test('un fichier deja present interdit la creation', () {
      File('$root/assets/data/relics/talisman_de_fer.json')
          .writeAsStringSync('{}');

      final faults = validatorWith().validate(fixtureRelicDraft());
      expect(faults, isNotEmpty);
      expect(faults.first.message, contains('existe déjà'));
    });

    test('un fichier absent interdit la modification', () {
      final faults =
          validatorWith().validate(fixtureRelicDraft(isModification: true));
      expect(faults, isNotEmpty);
      expect(faults.first.message, contains('aucun fichier à modifier'));
    });

    test('un identifiant deja dans le registre est refuse, chemin libre', () {
      // Le cas que le controle disque **ne peut pas** voir : une carte neutre
      // homonyme d'une carte de classe. Le chargeur, lui, le rejette.
      final descriptor = kEntityDescriptors[EntityCategory.card]!;
      final draft = EntityDraft(
        descriptor: descriptor,
        id: 'smite',
        bilingual: const {
          'name_fr': 'x',
          'name_en': 'x',
          'description_fr': 'x',
          'description_en': 'x',
        },
        mechanics: descriptor.template,
      );

      // Le chemin `assets/data/cards/smite.json` est libre…
      expect(File('$root/${draft.path}').existsSync(), isFalse);
      // …mais le registre porte deja `smite`, sous le dossier du paladin.
      final faults = validatorWith(
        registry: fixtureRegistry(cards: [fixtureCard('smite')]),
      ).validate(draft);

      expect(faults, isNotEmpty);
      expect(faults.first.message, contains('smite'));
    });
  });

  group('famille 2 — syntaxe', () {
    test('un corps illisible est refuse en nommant la cause', () {
      final faults =
          validatorWith().validate(fixtureRelicDraft(mechanics: '{ "a": }'));
      expect(faults, hasLength(1));
      expect(faults.first.message, contains('JSON invalide'));
    });

    test('un tableau n est pas un document d entite', () {
      final faults =
          validatorWith().validate(fixtureRelicDraft(mechanics: '[1, 2]'));
      expect(faults, hasLength(1));
      expect(faults.first.message, contains('objet JSON'));
    });
  });

  group('famille 3 — cles', () {
    test('une cle obligatoire absente est nommee', () {
      final faults = validatorWith().validate(
        fixtureRelicDraft(
          mechanics: '{"trigger": "startOfCombat", "rarity": "common"}',
        ),
      );
      // `effectType` et `value` manquent.
      expect(faults.map((f) => f.field), containsAll(['effectType', 'value']));
    });

    test('un champ impose par le repertoire est refuse', () {
      final descriptor = kEntityDescriptors[EntityCategory.card]!;
      final faults = validatorWith().validate(
        EntityDraft(
          descriptor: descriptor,
          id: 'coup_bas',
          bilingual: const {
            'name_fr': 'x',
            'name_en': 'x',
            'description_fr': 'x',
            'description_en': 'x',
          },
          mechanics: '{"cost": 1, "type": "attack", "heroClass": "paladin"}',
        ),
      );
      expect(faults.map((f) => f.field), contains('heroClass'));
    });

    test('id peut etre redeclare, mais seulement a l identique', () {
      final ok = validatorWith().validate(
        fixtureRelicDraft(
          mechanics: '{"id": "talisman_de_fer", "trigger": "startOfCombat", '
              '"effectType": "gain_armor", "value": 5, "rarity": "common"}',
        ),
      );
      expect(ok, isEmpty);

      final ko = validatorWith().validate(
        fixtureRelicDraft(
          mechanics: '{"id": "autre_chose", "trigger": "startOfCombat", '
              '"effectType": "gain_armor", "value": 5, "rarity": "common"}',
        ),
      );
      expect(ko.map((f) => f.field), contains('id'));
    });
  });

  group('famille 4 — enumerations', () {
    test('une rarete inconnue est refusee, et les valeurs admises listees', () {
      final faults = validatorWith().validate(
        fixtureRelicDraft(
          mechanics: '{"trigger": "startOfCombat", "effectType": "gain_armor", '
              '"value": 5, "rarity": "commune"}',
        ),
      );
      expect(faults, hasLength(1));
      expect(faults.first.field, 'rarity');
      expect(faults.first.message, contains('legendary'));
    });

    test('c est bien ce que fromJson laisse passer', () {
      // Le point de la famille 4. Le meme document construit sans lever :
      // `RelicRarity.values.firstWhere` n'a pas d'`orElse` pour `rarity`, mais
      // `CardRarity` en a un — la carte retombe en silence sur `common`.
      final descriptor = kEntityDescriptors[EntityCategory.card]!;
      final draft = EntityDraft(
        descriptor: descriptor,
        id: 'coup_bas',
        bilingual: const {
          'name_fr': 'x',
          'name_en': 'x',
          'description_fr': 'x',
          'description_en': 'x',
        },
        mechanics: '{"cost": 1, "type": "attack", "rarity": "commune"}',
      );

      // `fromJson` accepte, donc la famille 7 seule ne verrait rien…
      expect(() => descriptor.construct(draft.compose()), returnsNormally);
      // …et pourtant la famille 4 refuse.
      final faults = validatorWith().validate(draft);
      expect(faults, hasLength(1));
      expect(faults.first.field, 'rarity');
    });

    test('une liste enumeree est verifiee element par element', () {
      final descriptor = kEntityDescriptors[EntityCategory.forgeUpgrade]!;
      final faults = validatorWith().validate(
        EntityDraft(
          descriptor: descriptor,
          id: 'affutage',
          bilingual: const {
            'name_fr': 'x',
            'name_en': 'x',
            'description_fr': 'x',
            'description_en': 'x',
          },
          mechanics: '{"pools": ["common"], '
              '"eligibleCardTypes": ["attack", "sortilege"]}',
        ),
      );
      expect(faults, hasLength(1));
      expect(faults.first.field, 'eligibleCardTypes');
      expect(faults.first.message, contains('sortilege'));
    });
  });

  group('famille 5 — bilingue', () {
    test('une variante absente est refusee', () {
      final faults = validatorWith().validate(
        fixtureRelicDraft(
          bilingual: const {
            'name_fr': 'Talisman',
            'name_en': 'Talisman',
            'description_fr': 'Donne 5 armure.',
          },
        ),
      );
      expect(faults.map((f) => f.field), contains('description_en'));
    });

    test('une variante vide ou blanche est refusee', () {
      final faults = validatorWith().validate(
        fixtureRelicDraft(
          bilingual: const {
            'name_fr': 'Talisman',
            'name_en': '   ',
            'description_fr': 'Donne 5 armure.',
            'description_en': 'Gain 5 armor.',
          },
        ),
      );
      expect(faults.map((f) => f.field), contains('name_en'));
    });

    test('c est bien ce que fromJson laisse passer', () {
      // `RelicData.fromJson` retombe sur la chaine vide : la relique existe,
      // et elle est sans nom en jeu.
      final draft = fixtureRelicDraft(
        bilingual: const {
          'name_fr': 'Talisman',
          'name_en': 'Talisman',
          'description_fr': 'Donne 5 armure.',
        },
      );
      expect(
        () => draft.descriptor.construct(draft.compose()),
        returnsNormally,
      );
      expect(validatorWith().validate(draft), isNotEmpty);
    });

    test('un ennemi n exige pas de description', () {
      // La preuve que les bases bilingues sont par categorie et non
      // universelles : `EnemyData` n'a que des noms.
      final descriptor = kEntityDescriptors[EntityCategory.enemy]!;
      final faults = validatorWith().validate(
        EntityDraft(
          descriptor: descriptor,
          id: 'troll',
          bilingual: const {'name_fr': 'Troll', 'name_en': 'Troll'},
          mechanics: descriptor.template,
        ),
      );
      expect(faults, isEmpty);
    });
  });

  group('famille 6 — references', () {
    test('un passiveTrait pendant est refuse', () {
      final descriptor = kEntityDescriptors[EntityCategory.heroClass]!;
      final faults = validatorWith(
        registry: fixtureRegistry(passives: [fixturePassive('regen_armor')]),
      ).validate(
        EntityDraft(
          descriptor: descriptor,
          id: 'barde',
          bilingual: const {
            'name_fr': 'Le Barde',
            'name_en': 'The Bard',
            'description_fr': 'Oriente soutien',
            'description_en': 'Support oriented',
          },
          mechanics: '{"maxHp": 90, "maxMana": 3, "baseDamage": 4, '
              '"passiveTrait": "chant_inexistant"}',
        ),
      );
      expect(faults, hasLength(1));
      expect(faults.first.field, 'passiveTrait');
    });

    test('un passiveTrait resolu passe', () {
      final descriptor = kEntityDescriptors[EntityCategory.heroClass]!;
      final faults = validatorWith(
        registry: fixtureRegistry(passives: [fixturePassive('regen_armor')]),
      ).validate(
        EntityDraft(
          descriptor: descriptor,
          id: 'barde',
          bilingual: const {
            'name_fr': 'Le Barde',
            'name_en': 'The Bard',
            'description_fr': 'Oriente soutien',
            'description_en': 'Support oriented',
          },
          mechanics: '{"maxHp": 90, "maxMana": 3, "baseDamage": 4, '
              '"passiveTrait": "regen_armor"}',
        ),
      );
      expect(faults, isEmpty);
    });
  });

  group('famille couleur hex — themeColor', () {
    EntityDraft classDraftWithColor(String? hex) {
      final mechanics = <String, dynamic>{
        'maxHp': 90,
        'maxMana': 3,
        'baseDamage': 4,
      };
      if (hex != null) mechanics['themeColor'] = hex;
      return EntityDraft(
        descriptor: kEntityDescriptors[EntityCategory.heroClass]!,
        id: 'barde',
        bilingual: const {
          'name_fr': 'Le Barde',
          'name_en': 'The Bard',
          'description_fr': 'Oriente soutien',
          'description_en': 'Support oriented',
        },
        mechanics: jsonEncode(mechanics),
      );
    }

    test('un hex valide est accepte', () {
      final faults = validatorWith().validate(classDraftWithColor('#B71C1C'));
      expect(faults, isEmpty);
    });

    test('un hex malforme est refuse', () {
      final faults = validatorWith().validate(classDraftWithColor('#XYZ'));
      expect(faults, isNotEmpty);
      expect(faults.first.field, 'themeColor');
    });

    test('themeColor absent est accepte : la cle est optionnelle', () {
      final faults = validatorWith().validate(classDraftWithColor(null));
      expect(faults, isEmpty);
    });
  });

  group('bijection skills <-> cards/', () {
    /// Une classe sur le disque, avec deux cartes dans son dossier.
    void seedClassWithTwoCards() {
      Directory('$root/assets/data/classes/gambler/cards')
          .createSync(recursive: true);
      for (final id in const ['bluff', 'all_in']) {
        File('$root/assets/data/classes/gambler/cards/$id.json')
            .writeAsStringSync('{}');
      }
      File('$root/assets/data/classes/gambler/class.json')
          .writeAsStringSync('{}');
      // `classCard` est une image obligatoire : la modification exige qu elle
      // soit deja sur le disque (famille ressources).
      File('$root/assets/data/classes/gambler/gambler.png')
          .writeAsBytesSync(const []);
    }

    EntityDraft classDraft(String skillsJson) => EntityDraft(
          descriptor: kEntityDescriptors[EntityCategory.heroClass]!,
          id: 'gambler',
          bilingual: const {
            'name_fr': 'Le Parieur',
            'name_en': 'Gambler',
            'description_fr': 'Manipule les probabilites.',
            'description_en': 'Plays the odds.',
          },
          mechanics: '{"maxHp": 100, "maxMana": 3, "baseDamage": 5, '
              '"skills": $skillsJson}',
          isModification: true,
        );

    test('un skills exact est accepte', () {
      seedClassWithTwoCards();
      final faults =
          validatorWith().validate(classDraft('["all_in", "bluff"]'));
      expect(faults, isEmpty);
    });

    test('une carte declaree mais absente du dossier est refusee', () {
      seedClassWithTwoCards();
      final faults = validatorWith()
          .validate(classDraft('["all_in", "bluff", "fantome"]'));
      expect(faults.map((f) => f.toString()).join(), contains('fantome'));
    });

    // L'autre sens compte autant : une carte presente et non declaree serait
    // chargee dans le pool de la classe sans que rien ne le dise, et
    // referential_integrity_test rougirait bien plus tard.
    test('une carte presente mais absente de skills est refusee', () {
      seedClassWithTwoCards();
      final faults = validatorWith().validate(classDraft('["bluff"]'));
      expect(faults.map((f) => f.toString()).join(), contains('all_in'));
    });

    test('une classe creee, sans dossier cards/ ni skills, passe', () {
      final faults = validatorWith().validate(
        EntityDraft(
          descriptor: kEntityDescriptors[EntityCategory.heroClass]!,
          id: 'nouveau',
          bilingual: const {
            'name_fr': 'Nouveau',
            'name_en': 'New',
            'description_fr': 'Rien.',
            'description_en': 'Nothing.',
          },
          mechanics: '{"maxHp": 100, "maxMana": 3, "baseDamage": 5}',
        ),
      );
      expect(faults, isEmpty);
    });
  });

  group('famille 7 — construction', () {
    test('un type de mauvaise nature est attrape par le modele', () {
      final faults = validatorWith().validate(
        fixtureRelicDraft(
          mechanics: '{"trigger": "startOfCombat", "effectType": "gain_armor", '
              '"value": "cinq", "rarity": "common"}',
        ),
      );
      expect(faults, hasLength(1));
      expect(faults.first.message, contains('refuse'));
    });
  });

  test('tous les gabarits franchissent les sept familles', () {
    // Chaque categorie est testee avec sa prose minimale : un gabarit qui ne
    // passerait pas sa propre validation serait un piege servi a l'ouverture.
    for (final descriptor in kEntityDescriptors.values) {
      final draft = EntityDraft(
        descriptor: descriptor,
        id: 'entite_de_test',
        bilingual: {
          for (final base in descriptor.bilingualBases) ...{
            '${base}_fr': 'texte',
            '${base}_en': 'text',
          },
        },
        mechanics: descriptor.template,
      );
      expect(
        validatorWith().validate(draft),
        isEmpty,
        reason: '${descriptor.label} : ${validatorWith().validate(draft)}',
      );
    }
  });

  group('vocabulaires et enumerations imbriquees', () {
    const prose = {
      'name_fr': 'x',
      'name_en': 'x',
      'description_fr': 'x',
      'description_en': 'x',
    };

    EntityDraft cardDraft(String mechanics) => EntityDraft(
          descriptor: kEntityDescriptors[EntityCategory.card]!,
          id: 'coup',
          bilingual: prose,
          mechanics: mechanics,
        );

    test('une valeur employee par un fichier passe', () {
      File('$root/assets/data/relics/amulette.json')
          .writeAsStringSync('{"effectType": "heal"}');
      final faults = validatorWith().validate(fixtureRelicDraft(
        mechanics: '{"trigger": "startOfCombat", "effectType": "heal", '
            '"value": 5, "rarity": "common"}',
      ));
      expect(faults, isEmpty);
    });

    test('une valeur inconnue du disque et du gabarit est refusee', () {
      final faults = validatorWith().validate(fixtureRelicDraft(
        mechanics: '{"trigger": "startOfCombat", "effectType": "heall", '
            '"value": 5, "rarity": "common"}',
      ));
      expect(faults.single.field, 'effectType');
    });

    test('la valeur du gabarit passe dans une arborescence vide', () {
      expect(validatorWith().validate(fixtureRelicDraft()), isEmpty);
    });

    test('un type d effet de carte inconnu est refuse, avec son chemin', () {
      final faults = validatorWith().validate(cardDraft(
        '{"cost": 1, "type": "attack", '
        '"effects": [{"type": "skill", "value": 3}]}',
      ));
      expect(faults.single.field, 'effects[0].type');
    });

    test('un type d intention inconnu est refuse', () {
      final enemy = kEntityDescriptors[EntityCategory.enemy]!;
      final faults = validatorWith().validate(EntityDraft(
        descriptor: enemy,
        id: 'troll',
        bilingual: const {'name_fr': 'Troll', 'name_en': 'Troll'},
        mechanics: '{"maxHp": 30, "baseDamage": 5, '
            '"intents": [{"type": "fly", "value": 5}]}',
      ));
      expect(faults.single.field, 'intents[0].type');
    });

    test('un nom de couleur de forge inconnu du moteur est refuse', () {
      final forge = kEntityDescriptors[EntityCategory.forgeUpgrade]!;
      EntityDraft withColor(String color) => EntityDraft(
            descriptor: forge,
            id: 'eclat',
            bilingual: prose,
            mechanics: '{"pools": ["common"], "color": "$color"}',
          );

      expect(validatorWith().validate(withColor('orange')).single.field,
          'color');
      // Le nom du gabarit passe dans une arborescence vide.
      expect(validatorWith().validate(withColor('amberAccent')), isEmpty);
    });
  });

  group('famille ressources', () {
    void seedAudio() => File('$root/assets/data/audio.json')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('{"sounds": {"clang": {"file": "sfx/clang.wav"}}}');

    EntityDraft relicWithSfx(Object? sfx) => fixtureRelicDraft(
          mechanics: jsonEncode({
            ...kEntityDescriptors[EntityCategory.relic]!.decodeTemplate(),
            'sfx': sfx,
          }),
        );

    String sourceFile(String name) {
      final file = File('$root/import/$name')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('octets');
      return IoContentFileSystem.toSlashes(file.path);
    }

    EntityValidator withImports(List<PendingImport> imports) => EntityValidator(
          fs: fs,
          rootPath: root,
          registry: fixtureRegistry(),
          imports: imports,
        );

    test('un son declare passe', () {
      seedAudio();
      expect(validatorWith().validate(relicWithSfx('clang')), isEmpty);
    });

    test('un son non declare est refuse', () {
      seedAudio();
      expect(validatorWith().validate(relicWithSfx('inconnu')).single.field,
          'sfx');
    });

    test('un son vide est refuse', () {
      seedAudio();
      expect(validatorWith().validate(relicWithSfx('')).single.field, 'sfx');
    });

    test('un son en attente d import passe', () {
      seedAudio();
      final faults = withImports([
        PendingImport.sound(
            key: 'sfx', sourcePath: sourceFile('neuf.wav'), soundId: 'neuf'),
      ]).validate(relicWithSfx('neuf'));
      expect(faults, isEmpty);
    });

    test('un import de son deja declare est refuse', () {
      seedAudio();
      final faults = withImports([
        PendingImport.sound(
            key: 'sfx', sourcePath: sourceFile('clang.wav'), soundId: 'clang'),
      ]).validate(relicWithSfx('clang'));
      expect(faults.map((f) => f.message).join(), contains('existe déjà'));
    });

    test('une extension refusee est refusee', () {
      seedAudio();
      final faults = withImports([
        PendingImport.sound(
            key: 'sfx', sourcePath: sourceFile('notes.txt'), soundId: 'notes'),
      ]).validate(relicWithSfx('notes'));
      expect(faults.map((f) => f.message).join(), contains('extension'));
    });

    test('un fichier source absent est refuse', () {
      seedAudio();
      final faults = withImports([
        PendingImport.sound(
            key: 'sfx', sourcePath: '$root/import/absent.wav', soundId: 'absent'),
      ]).validate(relicWithSfx('absent'));
      expect(faults.map((f) => f.message).join(), contains('introuvable'));
    });

    test('une image obligatoire absente est refusee en modification', () {
      final enemy = kEntityDescriptors[EntityCategory.enemy]!;
      File('$root/assets/data/enemies/troll/enemy.json')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('{}');
      final faults = validatorWith().validate(EntityDraft(
        descriptor: enemy,
        id: 'troll',
        isModification: true,
        bilingual: const {'name_fr': 'Troll', 'name_en': 'Troll'},
        mechanics: enemy.template,
      ));
      expect(faults.single.field, 'spritePath');
    });
  });
}
