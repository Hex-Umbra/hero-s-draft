import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system_io.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/services/content_editor/entity_draft.dart';
import 'package:roguelike_card_game/services/content_editor/entity_validator.dart';

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
      expect(faults.first.message, contains('existe deja'));
    });

    test('un fichier absent interdit la modification', () {
      final faults =
          validatorWith().validate(fixtureRelicDraft(isModification: true));
      expect(faults, isNotEmpty);
      expect(faults.first.message, contains('aucun fichier a modifier'));
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

  test('le gabarit de chaque categorie franchit les trois premieres familles',
      () {
    // Un gabarit qui ne passerait pas sa propre validation serait un piege
    // servi a l'utilisateur des l'ouverture de l'ecran. Couvre les sept
    // categories, pas seulement la relique : une carte n'a pas les memes
    // cles obligatoires qu'un evenement, et un gabarit fautif pour l'une
    // d'elles passerait inapercu si le test n'en jugeait qu'une seule.
    for (final descriptor in kEntityDescriptors.values) {
      // Les bases bilingues varient par categorie — un evenement porte
      // `title_*`, un ennemi n'a pas de description — d'ou leur lecture sur
      // le descripteur plutot qu'une liste de cles ecrite en dur ici.
      final bilingual = {
        for (final base in descriptor.bilingualBases) ...{
          '${base}_fr': 'x',
          '${base}_en': 'x',
        },
      };
      final draft = EntityDraft(
        descriptor: descriptor,
        id: 'entite_de_test',
        bilingual: bilingual,
        mechanics: descriptor.template,
      );

      final faults = validatorWith().validate(draft);
      expect(
        faults,
        isEmpty,
        reason: '${descriptor.label} (${descriptor.category.name}) : '
            '${faults.join(', ')}',
      );
    }
  });
}
