import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/content_editor_providers.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system_io.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/ui/screens/content_editor_screen.dart';

/// L'etat de `assets/data`, a plat comme en profondeur, trie pour une
/// comparaison stable. Sert a prouver qu'une ecriture refusee n'a rien
/// laisse sur le disque — pas seulement qu'un message d'erreur s'affiche.
List<String> _dataTreeSnapshot(String root) => Directory('$root/assets/data')
    .listSync(recursive: true)
    .map((entity) => IoContentFileSystem.toSlashes(entity.path))
    .toList()
  ..sort();

void main() {
  late Directory sandbox;
  late String root;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('editor_screen_');
    root = IoContentFileSystem.toSlashes(sandbox.path);
    Directory('$root/assets/data/relics').createSync(recursive: true);
    File('$root/pubspec.yaml').writeAsStringSync('name: sandbox\n');
  });

  tearDown(() => sandbox.deleteSync(recursive: true));

  Widget harness({required String? projectRoot}) {
    return ProviderScope(
      overrides: [
        contentFileSystemProvider
            .overrideWithValue(const _NoProcessFileSystem()),
        projectRootProvider.overrideWithValue(projectRoot),
      ],
      child: const MaterialApp(home: ContentEditorScreen()),
    );
  }

  testWidgets('sans racine, l ecran refuse et explique pourquoi',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: null));

    expect(find.textContaining('arborescence source'), findsOneWidget);
    expect(find.text('Écrire'), findsNothing);
  });

  testWidgets('le chemin calcule est affiche et suit la categorie',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));

    await tester.enterText(find.byKey(const Key('editeur-id')), 'talisman');
    await tester.pump();

    expect(
      find.textContaining('assets/data/cards/talisman.json'),
      findsOneWidget,
    );
  });

  testWidgets('un brouillon fautif est refuse sans rien ecrire',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));

    // Identifiant en majuscules : la famille 1 doit le refuser.
    await tester.enterText(find.byKey(const Key('editeur-id')), 'Talisman');
    await tester.tap(find.text('Valider'));
    await tester.pump();

    expect(find.textContaining('minuscules'), findsOneWidget);
    expect(Directory('$root/assets/data').listSync(), hasLength(1));
  });

  testWidgets('un brouillon fautif est aussi refuse par Ecrire, sans rien ecrire',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));

    // `cards/` doit exister pour que l'ecriture soit *capable* de reussir si
    // la porte E6 venait a manquer : sans dossier cible, l'absence d'effet
    // ne prouverait qu'une erreur d'E/S sans rapport, pas que la validation a
    // retenu la main. Voir la carte de signature (Task 6) pour la meme
    // exigence cote ecrivain.
    Directory('$root/assets/data/cards').createSync(recursive: true);
    final before = _dataTreeSnapshot(root);

    // Meme brouillon fautif que ci-dessus — identifiant en majuscules — mais
    // tape sur le vrai controle d'ecriture. C'est lui, et non Valider, que la
    // decision E6 doit tenir : Valider n'appelle jamais EntityWriter.
    await tester.enterText(find.byKey(const Key('editeur-id')), 'Talisman');
    await tester.tap(find.text('Écrire'));
    // `_write` est async (valide puis, si la porte le permet, ecrit et lance
    // sync_assets) : un `pump()` seul pourrait conclure avant la fin de la
    // future, et un test qui verifie trop tot serait le meme defaut sous un
    // autre habit.
    await tester.pumpAndSettle();

    expect(find.textContaining('minuscules'), findsOneWidget);
    expect(_dataTreeSnapshot(root), equals(before));
  });

  group('mode Modifier', () {
    /// Une relique deja sur le disque, portant **une cle que le gabarit n a
    /// pas** et des valeurs enumerees differentes des siennes. C est ce que
    /// « Modifier » doit conserver : sans relecture du fichier, `compose()`
    /// ecrit la mecanique du gabarit par-dessus, et tout ce qui n y figure
    /// pas disparait — validation passee, ecriture reussie, aucun signal.
    void seedRelic() {
      File('$root/assets/data/relics/talisman_de_fer.json').writeAsStringSync(
        jsonEncode(const {
          'id': 'talisman_de_fer',
          'name_en': 'Iron Talisman',
          'name_fr': 'Talisman de fer',
          'description_en': 'Gain 5 armor when an enemy dies.',
          'description_fr': 'Donne 5 armure a la mort d un ennemi.',
          'trigger': 'onEnemyKilled',
          'effectType': 'gain_armor',
          'value': 5,
          'rarity': 'legendary',
          'sfx': 'clang_distinctif',
        }),
      );
    }

    /// Amene l ecran sur la relique semee, en mode Modifier.
    Future<void> aimAtSeededRelic(WidgetTester tester) async {
      await tester.tap(find.byType(DropdownButton<EntityCategory>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Relique').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('editeur-id')),
        'talisman_de_fer',
      );
      await tester.pump();
    }

    testWidgets('Charger relit la cible, et ce qu elle porte survit a Ecrire',
        (tester) async {
      seedRelic();
      await tester.pumpWidget(harness(projectRoot: root));
      await aimAtSeededRelic(tester);

      await tester.tap(find.text('Charger'));
      await tester.pump();

      await tester.tap(find.text('Écrire'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Écrit :'), findsOneWidget);
      final written = jsonDecode(
        File('$root/assets/data/relics/talisman_de_fer.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;

      // La cle que le gabarit ignore : la preuve directe de la relecture.
      expect(written['sfx'], 'clang_distinctif');
      // Les valeurs que le gabarit aurait ramenees aux siennes.
      expect(written['trigger'], 'onEnemyKilled');
      expect(written['rarity'], 'legendary');
      // La prose vient elle aussi du fichier : restee vide, elle aurait fait
      // echouer la famille 5 avant meme d ecrire.
      expect(written['name_fr'], 'Talisman de fer');
      expect(written['description_en'], 'Gain 5 armor when an enemy dies.');
    });

    testWidgets('Ecrire sans avoir charge est refuse, sans rien ecrire',
        (tester) async {
      seedRelic();
      final before = _dataTreeSnapshot(root);
      await tester.pumpWidget(harness(projectRoot: root));
      await aimAtSeededRelic(tester);

      // Le geste que le bouton Charger rend indispensable : la boite JSON
      // porte encore le gabarit, et l ecrire serait la perte de donnees que
      // tout ce mode doit empecher.
      await tester.tap(find.text('Écrire'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Charger'), findsWidgets);
      expect(find.textContaining('Écrit :'), findsNothing);
      expect(
        jsonDecode(
          File('$root/assets/data/relics/talisman_de_fer.json')
              .readAsStringSync(),
        ),
        containsPair('sfx', 'clang_distinctif'),
      );
      expect(_dataTreeSnapshot(root), equals(before));
    });

    testWidgets('une cible absente est signalee, sans vider le formulaire',
        (tester) async {
      await tester.pumpWidget(harness(projectRoot: root));
      await aimAtSeededRelic(tester); // rien n a ete seme cette fois

      await tester.tap(find.text('Charger'));
      await tester.pump();

      expect(find.textContaining('aucun fichier à charger'), findsOneWidget);
      // Le formulaire tient : la boite JSON porte toujours le gabarit.
      expect(find.textContaining('startOfCombat'), findsOneWidget);
    });

    testWidgets('la categorie reste choisissable apres la bascule',
        (tester) async {
      // Le geste reel : on bascule d'abord, on choisit ensuite. La categorie
      // par defaut etant « Carte », une liste gelee rend toute entite qui
      // n'est pas une carte **inatteignable** — Charger cherche alors
      // `cards/<id>.json` et signale une absence parfaitement exacte, ce qui
      // se lit comme un bouton casse.
      Directory('$root/assets/data/classes/gambler/cards')
          .createSync(recursive: true);
      File('$root/assets/data/classes/gambler/class.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'id': 'gambler',
          'name_en': 'Gambler',
          'name_fr': 'Parieur',
          'description_en': 'Plays with the odds.',
          'description_fr': 'Manipule les probabilites.',
          'maxHp': 100,
          'maxMana': 3,
          'baseDamage': 5,
          'displayOrder': 99,
          'iconPath': 'assets/data/classes/gambler/icon.png',
        }),
      );

      await tester.pumpWidget(harness(projectRoot: root));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<DropdownButton<EntityCategory>>(
              find.byType(DropdownButton<EntityCategory>),
            )
            .onChanged,
        isNotNull,
        reason: 'sans cette liste, la cible ne peut pas etre designee',
      );

      await tester.tap(find.byType(DropdownButton<EntityCategory>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Classe').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editeur-id')), 'gambler');
      await tester.pump();
      await tester.tap(find.text('Charger'));
      await tester.pumpAndSettle();

      expect(find.textContaining('aucun fichier à charger'), findsNothing);
      expect(find.textContaining('Parieur'), findsOneWidget);
      expect(find.textContaining('"maxHp": 100'), findsOneWidget);
    });
  });
}

/// `IoContentFileSystem` moins le lancement de processus.
///
/// Le disque reste reel — c est tout l interet d un bac a sable — mais
/// `sync_assets` n est pas relance. Deux raisons : sa duree, un `dart run`
/// par ecriture ; et surtout le fait que `Process.run` prend le bac a sable
/// comme repertoire de travail, que Windows refuse ensuite de supprimer tant
/// que le processus vit. Le `tearDown` echouerait par intermittence.
/// L enchainement reel avec `sync_assets` est couvert par
/// `test/unit/content_editor/entity_writer_test.dart`.
class _NoProcessFileSystem implements ContentFileSystem {
  const _NoProcessFileSystem();

  static const ContentFileSystem _disk = IoContentFileSystem();

  @override
  String get startDirectory => _disk.startDirectory;

  @override
  bool fileExists(String path) => _disk.fileExists(path);

  @override
  bool directoryExists(String path) => _disk.directoryExists(path);

  @override
  String readFile(String path) => _disk.readFile(path);

  @override
  void writeFile(String path, String contents) =>
      _disk.writeFile(path, contents);

  @override
  void deleteFile(String path) => _disk.deleteFile(path);

  @override
  void createDirectory(String path) => _disk.createDirectory(path);

  @override
  void copyFile(String from, String to) => _disk.copyFile(from, to);

  @override
  List<String> listDirectory(String path) => _disk.listDirectory(path);

  @override
  Future<ProcessOutcome> run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) async =>
      const ProcessOutcome(0, '');
}
