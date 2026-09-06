import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/content_editor_providers.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system_io.dart';
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
        contentFileSystemProvider.overrideWithValue(const IoContentFileSystem()),
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
}
