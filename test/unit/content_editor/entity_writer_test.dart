import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system_io.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/services/content_editor/entity_draft.dart';
import 'package:roguelike_card_game/services/content_editor/entity_writer.dart';
import 'package:roguelike_card_game/services/content_editor/pending_import.dart';

import 'fixtures.dart';

void main() {
  late Directory sandbox;
  late String root;
  const fs = IoContentFileSystem();

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('entity_writer_');
    root = IoContentFileSystem.toSlashes(sandbox.path);

    // Le script est invoque depuis le bac a sable : il lui faut une copie, et
    // un pubspec a reecrire. Meme montage que `test/unit/sync_assets_test.dart`.
    Directory('$root/tool').createSync(recursive: true);
    File('tool/sync_assets.dart').copySync('$root/tool/sync_assets.dart');
    Directory('$root/assets/data/relics').createSync(recursive: true);

    // `environment:` evite l avertissement « has no lower-bound SDK
    // constraint » que `dart run` ecrirait sur stdout a chaque invocation.
    File('$root/pubspec.yaml').writeAsStringSync(
      'name: sandbox\r\n'
      'environment:\r\n'
      '  sdk: ^3.11.4\r\n'
      'flutter:\r\n'
      '  uses-material-design: true\r\n'
      '  assets:\r\n'
      '  fonts: []\r\n',
    );
  });

  tearDown(() => sandbox.deleteSync(recursive: true));

  EntityWriter writerHere() => EntityWriter(fs: fs, rootPath: root);

  test('ecrit le fichier au chemin calcule', () async {
    await writerHere().write(fixtureRelicDraft());

    final file = File('$root/assets/data/relics/talisman_de_fer.json');
    expect(file.existsSync(), isTrue);
  });

  test('le document porte l identifiant, la prose puis la mecanique', () async {
    await writerHere().write(fixtureRelicDraft());

    final raw =
        File('$root/assets/data/relics/talisman_de_fer.json').readAsStringSync();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    expect(decoded['id'], 'talisman_de_fer');
    expect(decoded['name_fr'], 'Talisman de fer');
    expect(decoded['trigger'], 'startOfCombat');
    // L'ordre des cles est celui des fichiers existants.
    expect(
      decoded.keys.take(5).toList(),
      ['id', 'name_en', 'name_fr', 'description_en', 'description_fr'],
    );
  });

  test('le JSON est indente de deux espaces et finit par une ligne', () async {
    await writerHere().write(fixtureRelicDraft());

    final raw =
        File('$root/assets/data/relics/talisman_de_fer.json').readAsStringSync();
    expect(raw, contains('\n  "id": "talisman_de_fer"'));
    expect(raw.endsWith('\n'), isTrue);
  });

  test('sync_assets est relance et le pubspec declare le repertoire',
      () async {
    final report = await writerHere().write(fixtureRelicDraft());

    expect(report.sync, isNotNull);
    expect(
      report.sync!.exitCode,
      0,
      reason: report.sync!.output,
    );
    expect(
      File('$root/pubspec.yaml').readAsStringSync(),
      contains('assets/data/relics/'),
    );
  });

  test('une creation est signalee comme telle', () async {
    final report = await writerHere().write(fixtureRelicDraft());
    expect(report.createdEntity, isTrue);
    expect(report.written, ['assets/data/relics/talisman_de_fer.json']);
  });

  test('une modification ne l est pas', () async {
    await writerHere().write(fixtureRelicDraft());
    final report =
        await writerHere().write(fixtureRelicDraft(isModification: true));

    expect(report.createdEntity, isFalse);
  });

  // Les six tests ci-dessus suivent tous le chemin heureux : rien n y fait
  // jamais echouer `fs.writeFile`, donc `_rollback` n y tourne jamais. Les
  // deux tests suivants l arment via un faux systeme de fichiers en memoire,
  // pour prouver que chacune de ses deux branches fait ce qu elle dit.

  test('une creation qui echoue en ecriture ne laisse aucun fichier',
      () async {
    final flaky = _FlakyFileSystem()..failNextWrite = true;
    final writer = EntityWriter(fs: flaky, rootPath: '/root');
    const path = '/root/assets/data/relics/talisman_de_fer.json';

    await expectLater(
      writer.write(fixtureRelicDraft()),
      throwsA(isA<FormatException>()),
    );

    // Le rollback doit avoir appele `deleteFile` : le simple fait que
    // l ecriture ait leve ne suffirait pas a l attester, puisque le faux
    // systeme ecrit avant de lever (comme le ferait un disque qui a deja
    // recu les octets).
    expect(flaky.fileExists(path), isFalse);
  });

  test(
      'une modification qui echoue en ecriture restaure le contenu '
      'precedent a l identique', () async {
    final flaky = _FlakyFileSystem();
    const path = '/root/assets/data/relics/talisman_de_fer.json';
    const original = '{\n  "id": "talisman_de_fer",\n  "trigger": "avant"\n}\n';
    flaky.files[path] = original;
    flaky.failNextWrite = true;
    final writer = EntityWriter(fs: flaky, rootPath: '/root');

    await expectLater(
      writer.write(fixtureRelicDraft(isModification: true)),
      throwsA(isA<FormatException>()),
    );

    // Comparaison de la chaine complete, et non de la seule existence : le
    // faux systeme a bien stocke le nouveau contenu avant de lever, donc si
    // le rollback ne restaurait pas exactement l ancien, ce serait ce
    // nouveau contenu — fautif — qui resterait en place.
    expect(flaky.files[path], original);
  });

  /// Monte une classe minimale dans le bac a sable, comme le depot la porte.
  void seedClass(String id, {List<String> skills = const []}) {
    Directory('$root/assets/data/classes/$id/cards').createSync(recursive: true);
    File('$root/assets/data/classes/$id/class.json').writeAsStringSync(
      jsonEncode({
        'id': id,
        'name_en': 'X',
        'name_fr': 'X',
        'description_en': 'x',
        'description_fr': 'x',
        'classCard': 'assets/data/classes/$id/$id.png',
        'maxHp': 100,
        'maxMana': 3,
        'baseDamage': 5,
        'skills': skills,
      }),
    );
  }

  /// Un brouillon de classe minimal, pour les tests de `writeAll` : le
  /// gabarit ne porte pas `skills`, comme celui livre par le descripteur — la
  /// premiere carte de signature l ajoute.
  EntityDraft classDraft(String id, {bool isModification = false}) {
    final descriptor = kEntityDescriptors[EntityCategory.heroClass]!;
    return EntityDraft(
      descriptor: descriptor,
      id: id,
      isModification: isModification,
      bilingual: const {
        'name_fr': 'Le Flambeur',
        'name_en': 'The Gambler',
        'description_fr': 'Parie tout sur chaque carte.',
        'description_en': 'Bets everything on every card.',
      },
      mechanics: descriptor.template,
    );
  }

  EntityDraft classCardDraft(String id, String heroClass) {
    final descriptor = kEntityDescriptors[EntityCategory.card]!;
    return EntityDraft(
      descriptor: descriptor,
      id: id,
      heroClass: heroClass,
      bilingual: const {
        'name_fr': 'Frappe',
        'name_en': 'Strike',
        'description_fr': 'Inflige 6 degats.',
        'description_en': 'Deal 6 damage.',
      },
      mechanics: descriptor.template,
    );
  }

  group('carte de classe', () {
    test('ecrit la carte ET declare son identifiant dans skills', () async {
      seedClass('paladin', skills: ['smite']);

      final report =
          await writerHere().write(classCardDraft('coup_saint', 'paladin'));

      expect(
        File('$root/assets/data/classes/paladin/cards/coup_saint.json')
            .existsSync(),
        isTrue,
      );
      final classJson = jsonDecode(
        File('$root/assets/data/classes/paladin/class.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(classJson['skills'], ['coup_saint', 'smite']);
      expect(report.written, hasLength(2));
    });

    test('le dossier cards et skills restent en bijection', () async {
      seedClass('paladin');
      await writerHere().write(classCardDraft('un', 'paladin'));
      await writerHere().write(classCardDraft('deux', 'paladin'));

      final onDisk = Directory('$root/assets/data/classes/paladin/cards')
          .listSync()
          .whereType<File>()
          // Meme filtre que `referential_integrity_test` : Windows y laisse
          // trainer Thumbs.db/desktop.ini, non couverts par .gitignore. Sans
          // lui ce test ne serait pas la meme garde que celle qu'il imite.
          .where((f) => f.path.endsWith('.json'))
          .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''))
          .toSet();
      final classJson = jsonDecode(
        File('$root/assets/data/classes/paladin/class.json').readAsStringSync(),
      ) as Map<String, dynamic>;

      // La forme exacte de l'assertion de `referential_integrity_test`.
      expect(onDisk, (classJson['skills'] as List).toSet());
    });

    test('une classe sans class.json ne laisse pas la carte derriere elle',
        () async {
      Directory('$root/assets/data/classes/fantome/cards')
          .createSync(recursive: true);

      await expectLater(
        writerHere().write(classCardDraft('orpheline', 'fantome')),
        throwsA(isA<StateError>()),
      );

      // Les deux fichiers, ou aucun : la carte a ete defaite.
      expect(
        File('$root/assets/data/classes/fantome/cards/orpheline.json')
            .existsSync(),
        isFalse,
      );
    });

    test('modifier une carte ne retouche pas skills', () async {
      seedClass('paladin');
      await writerHere().write(classCardDraft('coup_saint', 'paladin'));

      final before =
          File('$root/assets/data/classes/paladin/class.json').readAsStringSync();
      final report = await writerHere().write(
        EntityDraft(
          descriptor: kEntityDescriptors[EntityCategory.card]!,
          id: 'coup_saint',
          heroClass: 'paladin',
          isModification: true,
          bilingual: const {
            'name_fr': 'Frappe renforcee',
            'name_en': 'Greater Strike',
            'description_fr': 'Inflige 9 degats.',
            'description_en': 'Deal 9 damage.',
          },
          mechanics: '{"cost": 2, "type": "attack", "rarity": "common", '
              '"target": "singleEnemy", "effects": '
              '[{"type": "damage", "value": 9}]}',
        ),
      );

      expect(report.written, hasLength(1));
      expect(
        File('$root/assets/data/classes/paladin/class.json').readAsStringSync(),
        before,
      );
    });

    test('une carte deja declaree n est pas ajoutee deux fois', () async {
      seedClass('paladin', skills: ['coup_saint']);
      await writerHere().write(classCardDraft('coup_saint', 'paladin'));

      final classJson = jsonDecode(
        File('$root/assets/data/classes/paladin/class.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(classJson['skills'], ['coup_saint']);
    });

    test('une classe creee par l outil accueille sa premiere carte', () async {
      // Le premier vrai geste d un utilisateur : creer une classe, puis lui
      // donner sa premiere carte de signature. Le gabarit de la classe ne
      // porte **pas** `skills` — c est le `?? const []` de l ecrivain qui
      // tient ce cas, et rien ne l exercait : `seedClass` ecrit toujours la
      // cle, y compris vide.
      final descriptor = kEntityDescriptors[EntityCategory.heroClass]!;
      await writerHere().write(
        EntityDraft(
          descriptor: descriptor,
          id: 'barde',
          bilingual: const {
            'name_fr': 'Le Barde',
            'name_en': 'The Bard',
            'description_fr': 'Oriente soutien',
            'description_en': 'Support oriented',
          },
          mechanics: descriptor.template,
        ),
      );

      final classJson = File('$root/assets/data/classes/barde/class.json');
      Map<String, dynamic> read() =>
          jsonDecode(classJson.readAsStringSync()) as Map<String, dynamic>;

      // La condition de depart du test, et non un decor : si le gabarit
      // gagnait un `skills`, ce test cesserait de couvrir ce qu il annonce.
      expect(read().containsKey('skills'), isFalse);

      await writerHere().write(classCardDraft('ballade', 'barde'));

      expect(read()['skills'], ['ballade']);
    });
  });

  group('categories en dossier', () {
    test('une classe nait avec un sous-dossier cards vide', () async {
      final descriptor = kEntityDescriptors[EntityCategory.heroClass]!;
      await writerHere().write(
        EntityDraft(
          descriptor: descriptor,
          id: 'barde',
          bilingual: const {
            'name_fr': 'Le Barde',
            'name_en': 'The Bard',
            'description_fr': 'Oriente soutien',
            'description_en': 'Support oriented',
          },
          mechanics: descriptor.template,
        ),
      );

      final cards = Directory('$root/assets/data/classes/barde/cards');
      // Sans ce dossier, `referential_integrity_test` **leve** au lieu
      // d'echouer : `listSync()` y est appele sans garde.
      expect(cards.existsSync(), isTrue);
      expect(cards.listSync(), isEmpty);
    });

    test('un ennemi nait dans son propre dossier', () async {
      final descriptor = kEntityDescriptors[EntityCategory.enemy]!;
      await writerHere().write(
        EntityDraft(
          descriptor: descriptor,
          id: 'troll',
          bilingual: const {'name_fr': 'Troll', 'name_en': 'Troll'},
          mechanics: descriptor.template,
        ),
      );

      final written = File('$root/assets/data/enemies/troll/enemy.json');
      expect(written.existsSync(), isTrue);
      final decoded =
          jsonDecode(written.readAsStringSync()) as Map<String, dynamic>;
      // Le chemin du sprite est calcule, jamais saisi.
      expect(decoded['spritePath'], 'assets/data/enemies/troll/sprite.png');
    });

    test('l image de remplacement est deposee sous le nom attendu', () async {
      // Le bac a sable doit porter une copie du placeholder, comme le depot.
      Directory('$root/assets/placeholders/images').createSync(recursive: true);
      File('assets/placeholders/images/placeholder_entity.png')
          .copySync('$root/assets/placeholders/images/placeholder_entity.png');

      final descriptor = kEntityDescriptors[EntityCategory.enemy]!;
      await writerHere().write(
        EntityDraft(
          descriptor: descriptor,
          id: 'troll',
          bilingual: const {'name_fr': 'Troll', 'name_en': 'Troll'},
          mechanics: descriptor.template,
        ),
      );

      final sprite = File('$root/assets/data/enemies/troll/sprite.png');
      expect(sprite.existsSync(), isTrue);
      expect(sprite.lengthSync(), greaterThan(0));
    });

    test('une image deja presente n est jamais ecrasee', () async {
      Directory('$root/assets/placeholders/images').createSync(recursive: true);
      File('assets/placeholders/images/placeholder_entity.png')
          .copySync('$root/assets/placeholders/images/placeholder_entity.png');
      Directory('$root/assets/data/enemies/troll').createSync(recursive: true);
      File('$root/assets/data/enemies/troll/sprite.png')
          .writeAsStringSync('image peinte a la main');

      final descriptor = kEntityDescriptors[EntityCategory.enemy]!;
      await writerHere().write(
        EntityDraft(
          descriptor: descriptor,
          id: 'troll',
          bilingual: const {'name_fr': 'Troll', 'name_en': 'Troll'},
          mechanics: descriptor.template,
        ),
      );

      expect(
        File('$root/assets/data/enemies/troll/sprite.png').readAsStringSync(),
        'image peinte a la main',
      );
    });

    test('une categorie a plat ne recoit aucune image', () async {
      // Le placeholder doit etre **la**, comme dans les deux tests
      // ci-dessus : sans lui, `_placeImage` sort sur sa garde de source
      // absente quoi que dise le descripteur, et ce test passerait pour une
      // raison qui n est pas celle qu il annonce.
      Directory('$root/assets/placeholders/images').createSync(recursive: true);
      File('assets/placeholders/images/placeholder_entity.png')
          .copySync('$root/assets/placeholders/images/placeholder_entity.png');

      await writerHere().write(fixtureRelicDraft());
      expect(Directory('$root/assets/data/relics').listSync(), hasLength(1));
    });
  });

  group('icone de classe', () {
    test('une classe creee recoit son icone de remplacement', () async {
      Directory('$root/assets/placeholders/images').createSync(recursive: true);
      File('assets/placeholders/images/placeholder_icon.png')
          .copySync('$root/assets/placeholders/images/placeholder_icon.png');

      await EntityWriter(fs: fs, rootPath: root).write(classDraft('gambler'));

      expect(
        File('$root/assets/data/classes/gambler/icon.png').existsSync(),
        isTrue,
      );
    });

    // La garde qui empeche une regression visible par les joueurs : les trois
    // classes livrees n'ont pas d'icone dessinee, et leur en deposer une ferait
    // afficher un carre magenta a la place de leur illustration dans le
    // dialogue de stats. Modifier une classe ne doit donc rien deposer.
    test('modifier une classe ne lui fabrique pas d icone', () async {
      Directory('$root/assets/placeholders/images').createSync(recursive: true);
      File('assets/placeholders/images/placeholder_icon.png')
          .copySync('$root/assets/placeholders/images/placeholder_icon.png');
      Directory('$root/assets/data/classes/paladin/cards')
          .createSync(recursive: true);
      File('$root/assets/data/classes/paladin/class.json')
          .writeAsStringSync('{}');

      await EntityWriter(fs: fs, rootPath: root)
          .write(classDraft('paladin', isModification: true));

      expect(
        File('$root/assets/data/classes/paladin/icon.png').existsSync(),
        isFalse,
      );
    });
  });

  group('writeAll', () {
    // classCardDraft(id, heroClass) : meme ordre que l helper deja present
    // plus haut dans ce fichier.
    test('writeAll ecrit tous les brouillons et ne synchronise qu une fois',
        () async {
      final fs = RecordingFileSystem(root);
      final report = await EntityWriter(fs: fs, rootPath: root).writeAll([
        classDraft('gambler'),
        classCardDraft('bluff', 'gambler'),
        classCardDraft('all_in', 'gambler'),
      ]);

      // Compte exact, verifie par trace : class.json, cards/bluff.json,
      // class.json (skills += bluff), cards/all_in.json, class.json (skills
      // += all_in). `_registerSignatureCard` reecrit class.json a chaque
      // carte de signature, jamais deux fois pour la meme carte.
      expect(report.written, hasLength(5));
      expect(
        fs.syncRuns,
        1,
        reason: 'un dart run par carte serait insupportable',
      );
    });

    // Le point entier de la transaction : sans pile partagee, les deux
    // premieres ecritures resteraient sur le disque et laisseraient une
    // classe a moitie creee — precisement l etat que
    // referential_integrity_test refuse.
    test('un echec en cours de route defait ce qui precede', () async {
      final flaky = FailingOnNthWrite(root, failAt: 3);
      final writer = EntityWriter(fs: flaky, rootPath: root);

      await expectLater(
        writer.writeAll([
          classDraft('gambler'),
          classCardDraft('bluff', 'gambler'),
          classCardDraft('all_in', 'gambler'),
        ]),
        throwsA(anything),
      );

      expect(
        File('$root/assets/data/classes/gambler/class.json').existsSync(),
        isFalse,
      );
      expect(
        File('$root/assets/data/classes/gambler/cards/bluff.json')
            .existsSync(),
        isFalse,
      );
    });

    test('writeAll signale une creation des qu une creation y figure',
        () async {
      final fs = RecordingFileSystem(root);
      final report = await EntityWriter(fs: fs, rootPath: root)
          .writeAll([classDraft('gambler')]);
      expect(report.createdEntity, isTrue);
    });
  });

  group('ressources importees', () {
    const audio = '{\n  "schemaVersion": 1,\n  "sounds": {\n'
        '    "clang": { "file": "sfx/clang.wav" }\n  },\n'
        '  "moments": {},\n  "music": {}\n}\n';

    late String sound;
    late String image;

    setUp(() {
      File('$root/assets/data/audio.json').writeAsStringSync(audio);
      Directory('$root/import').createSync();
      sound = '$root/import/nouveau.wav';
      File(sound).writeAsStringSync('octets du son');
      image = '$root/import/troll.png';
      File(image).writeAsStringSync('nouvelle');

      Directory('$root/assets/data/enemies/troll').createSync(recursive: true);
      File('$root/assets/data/enemies/troll/sprite.png')
          .writeAsStringSync('ancienne');
      File('$root/assets/data/enemies/troll/enemy.json')
          .writeAsStringSync('{}');
    });

    List<String> backups() => Directory('$root/assets')
        .listSync(recursive: true)
        .map((entity) => entity.path)
        .where((path) => path.endsWith('.editor-backup'))
        .toList();

    EntityDraft trollModification() {
      final enemy = kEntityDescriptors[EntityCategory.enemy]!;
      return EntityDraft(
        descriptor: enemy,
        id: 'troll',
        isModification: true,
        bilingual: const {'name_fr': 'Troll', 'name_en': 'Troll'},
        mechanics: enemy.template,
      );
    }

    PendingImport trollSprite() => PendingImport.image(
          descriptor: kEntityDescriptors[EntityCategory.enemy]!,
          id: 'troll',
          key: 'spritePath',
          sourcePath: image,
        );

    test('un son importe est copie et declare', () async {
      final report = await EntityWriter(fs: RecordingFileSystem(root), rootPath: root)
          .writeAll([fixtureRelicDraft()], imports: [
        PendingImport.sound(
            key: 'sfx', sourcePath: sound, soundId: 'talisman_clang'),
      ]);

      expect(
        File('$root/assets/audio/sfx/talisman_clang.wav').readAsStringSync(),
        'octets du son',
      );
      final sounds = (jsonDecode(
        File('$root/assets/data/audio.json').readAsStringSync(),
      ) as Map<String, dynamic>)['sounds'] as Map<String, dynamic>;
      expect(sounds['talisman_clang'], {'file': 'sfx/talisman_clang.wav'});
      expect(report.written, containsAll([
        'assets/audio/sfx/talisman_clang.wav',
        'assets/data/audio.json',
      ]));
    });

    test('une image importee remplace celle du nom impose', () async {
      await EntityWriter(fs: RecordingFileSystem(root), rootPath: root)
          .writeAll([trollModification()], imports: [trollSprite()]);

      expect(
        File('$root/assets/data/enemies/troll/sprite.png').readAsStringSync(),
        'nouvelle',
      );
      expect(backups(), isEmpty, reason: 'la sauvegarde est retiree au succes');
    });

    test('un echec apres les imports defait tout, sauvegarde comprise',
        () async {
      // Ecriture 1 : audio.json. Ecriture 2 : enemy.json, qui leve.
      final flaky = FailingOnNthWrite(root, failAt: 2);

      await expectLater(
        EntityWriter(fs: flaky, rootPath: root).writeAll(
          [trollModification()],
          imports: [
            trollSprite(),
            PendingImport.sound(
                key: 'sfx', sourcePath: sound, soundId: 'troll_cri'),
          ],
        ),
        throwsA(anything),
      );

      expect(
        File('$root/assets/data/enemies/troll/sprite.png').readAsStringSync(),
        'ancienne',
      );
      expect(File('$root/assets/audio/sfx/troll_cri.wav').existsSync(), isFalse);
      expect(File('$root/assets/data/audio.json').readAsStringSync(), audio);
      expect(File('$root/assets/data/enemies/troll/enemy.json').readAsStringSync(),
          '{}');
      expect(backups(), isEmpty);
    });
  });
}

/// Un faux systeme de fichiers en memoire : rien, cote disque reel, ne fait
/// echouer une ecriture a coup sur, alors que celui-ci peut etre arme pour le
/// faire une fois. `writeFile` stocke d abord son contenu — comme le ferait
/// un disque qui a deja recu les octets — puis leve, ce qui laisse au
/// rollback quelque chose de reel a defaire.
class _FlakyFileSystem implements ContentFileSystem {
  final Map<String, String> files = {};

  /// Arme : le prochain appel a [writeFile] leve, une seule fois — pour ne
  /// pas faire aussi echouer l ecriture de restauration du rollback.
  bool failNextWrite = false;

  @override
  String get startDirectory => '/sandbox';

  @override
  bool fileExists(String path) => files.containsKey(path);

  @override
  bool directoryExists(String path) => false;

  @override
  String readFile(String path) => files[path]!;

  @override
  void writeFile(String path, String contents) {
    files[path] = contents;
    if (failNextWrite) {
      failNextWrite = false;
      throw const FormatException('ecriture simulee en echec');
    }
  }

  @override
  void deleteFile(String path) => files.remove(path);

  @override
  void createDirectory(String path) {}

  @override
  void copyFile(String from, String to) => files[to] = files[from]!;

  @override
  List<String> listDirectory(String path) => const [];

  @override
  Future<ProcessOutcome> run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) async =>
      const ProcessOutcome(0, '');
}

/// Le vrai systeme de fichiers, augmente d un compteur de synchronisations.
///
/// Etend `IoContentFileSystem` plutot que de reimplementer l interface : seul
/// `run` a un comportement different, tout le reste doit rester le vrai
/// disque, comme dans le bac a sable des tests du chemin heureux.
class RecordingFileSystem extends IoContentFileSystem {
  RecordingFileSystem(this.root);

  final String root;

  /// Le nombre de fois ou `run` a ete appele — un `dart run
  /// tool/sync_assets.dart` par appel.
  int syncRuns = 0;

  @override
  String get startDirectory => root;

  @override
  Future<ProcessOutcome> run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) async {
    syncRuns++;
    return super.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
    );
  }
}

/// Le vrai systeme de fichiers, qui leve au n-ieme appel a [writeFile].
///
/// Sert a prouver que la pile de rollback de `writeAll` est **partagee**
/// entre brouillons : sans elle, un echec sur la carte de signature d une
/// classe fraichement creee laisserait le `class.json` deja ecrit sur le
/// disque, et `referential_integrity_test` refuse precisement cet etat.
class FailingOnNthWrite extends IoContentFileSystem {
  FailingOnNthWrite(this.root, {required this.failAt});

  final String root;
  final int failAt;
  int _writes = 0;

  @override
  String get startDirectory => root;

  @override
  void writeFile(String path, String contents) {
    _writes++;
    // Comme _FlakyFileSystem : le contenu est ecrit avant de lever, comme le
    // ferait un disque qui a deja recu les octets — pour que le rollback ait
    // quelque chose de reel a defaire.
    super.writeFile(path, contents);
    if (_writes == failAt) {
      throw StateError('ecriture simulee en echec au $failAt-ieme appel');
    }
  }
}
