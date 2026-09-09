import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/class_recipe.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system_io.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/services/content_editor/entity_writer.dart';

void main() {
  ClassRecipe recipe({int cards = 2}) => ClassRecipe(
        id: 'gambler',
        bilingual: const {
          'name_fr': 'Le Parieur',
          'name_en': 'Gambler',
          'description_fr': 'Manipule les probabilites.',
          'description_en': 'Plays the odds.',
        },
        mechanics: '{"maxHp": 90}',
        signatureCards: [
          for (var i = 1; i <= cards; i++)
            SignatureCardInput(id: 'pari_$i', bilingual: const {}),
        ],
      );

  test('la classe vient en premier, ses cartes ensuite', () {
    final drafts = recipe().toDrafts();

    expect(drafts, hasLength(3));
    expect(drafts.first.descriptor.category, EntityCategory.heroClass);
    expect(drafts.first.path, 'assets/data/classes/gambler/class.json');
    // L'inverse leverait StateError : `_registerSignatureCard` exige que le
    // class.json existe avant qu'une de ses cartes ne soit ecrite.
    expect(drafts[1].path, 'assets/data/classes/gambler/cards/pari_1.json');
    expect(drafts[2].path, 'assets/data/classes/gambler/cards/pari_2.json');
  });

  test('la classe ne declare aucun skills : l ecrivain le remplit', () {
    final mechanics =
        jsonDecode(recipe().toDrafts().first.mechanics) as Map<String, dynamic>;
    // Un `skills` complet ecrit d'avance violerait la bijection de la tache 4
    // a chaque etape sauf la derniere.
    expect(mechanics.containsKey('skills'), isFalse);
  });

  test('la saisie prime, le gabarit complete le reste', () {
    final mechanics =
        jsonDecode(recipe().toDrafts().first.mechanics) as Map<String, dynamic>;
    expect(mechanics['maxHp'], 90);
    expect(mechanics['maxMana'], 3);
    expect(mechanics['armorMastery'], 0);
    expect(mechanics['themeColor'], '#FF00FF');
  });

  // Une classe neuve arrive avec son icone deja designee : l'auteur n'aura
  // qu'un fichier a remplacer, pas une cle a se rappeler d'ajouter six mois
  // plus tard.
  test('la classe neuve porte le chemin de son icone', () {
    final mechanics =
        jsonDecode(recipe().toDrafts().first.mechanics) as Map<String, dynamic>;
    expect(mechanics['iconPath'], 'assets/data/classes/gambler/icon.png');
  });

  test('chaque carte appartient a la classe et porte une prose non vide', () {
    final card = recipe().toDrafts()[1];
    expect(card.heroClass, 'gambler');
    expect(card.bilingual['name_fr'], isNotEmpty);
    expect(card.bilingual['name_en'], isNotEmpty);
  });

  test('une classe sans carte de signature ne produit qu un brouillon', () {
    expect(recipe(cards: 0).toDrafts(), hasLength(1));
  });

  group('bout en bout, sur un vrai bac a sable', () {
    late Directory sandbox;
    late String root;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('class_recipe_');
      root = IoContentFileSystem.toSlashes(sandbox.path);

      // Les deux remplacements doivent etre la : sans l'un des deux,
      // `_placeImage` ou `_placeClassIcon` sort sur sa garde de source
      // absente, et ce test passerait pour une raison qui n'est pas celle
      // qu'il annonce.
      Directory('$root/assets/placeholders/images').createSync(recursive: true);
      File('assets/placeholders/images/placeholder_entity.png')
          .copySync('$root/assets/placeholders/images/placeholder_entity.png');
      File('assets/placeholders/images/placeholder_icon.png')
          .copySync('$root/assets/placeholders/images/placeholder_icon.png');
    });

    tearDown(() => sandbox.deleteSync(recursive: true));

    test('la recette produit une classe que la validation accepte', () async {
      final fs = NoProcessFileSystem(); // double des tests voisins
      final drafts = recipe().toDrafts();

      final report = await EntityWriter(fs: fs, rootPath: root).writeAll(drafts);
      // `written` compte chaque ecriture physique, pas chaque brouillon :
      // `_registerSignatureCard` reecrit `class.json` a chaque carte de
      // signature, comme le montre deja `writeAll ecrit tous les brouillons
      // et ne synchronise qu une fois` dans `entity_writer_test.dart`, avec
      // la meme forme d'assertion pour le meme scenario (une classe et deux
      // cartes de classe).
      expect(report.written, hasLength(greaterThanOrEqualTo(3)));

      // L'invariant final : skills == le contenu de cards/.
      final classJson = jsonDecode(
        File('$root/assets/data/classes/gambler/class.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(classJson['skills'], ['pari_1', 'pari_2']);

      final onDisk = Directory('$root/assets/data/classes/gambler/cards')
          .listSync()
          .map((e) => e.uri.pathSegments.last.replaceAll('.json', ''))
          .toSet();
      expect(onDisk, {'pari_1', 'pari_2'});

      // Et les deux images sont la, sous leurs noms respectifs.
      expect(
        File('$root/assets/data/classes/gambler/gambler.png').existsSync(),
        isTrue,
      );
      expect(
        File('$root/assets/data/classes/gambler/icon.png').existsSync(),
        isTrue,
      );
      expect(classJson['iconPath'], 'assets/data/classes/gambler/icon.png');
      expect(classJson['classCard'], 'assets/data/classes/gambler/gambler.png');
    });
  });
}

/// `IoContentFileSystem` moins le lancement de processus.
///
/// Meme role que `_NoProcessFileSystem` dans
/// `test/widget/content_editor_screen_test.dart` : le disque du bac a sable
/// reste reel, seul `sync_assets` n'est pas relance — ni sa duree ni le
/// verrou que `Process.run` poserait sur le repertoire de travail sous
/// Windows n'ont leur place dans ce test, qui ne porte que sur `ClassRecipe`.
class NoProcessFileSystem extends IoContentFileSystem {
  @override
  Future<ProcessOutcome> run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) async =>
      const ProcessOutcome(0, '');
}
