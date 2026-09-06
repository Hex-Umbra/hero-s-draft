import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/content_editor_providers.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system_io.dart';
import 'package:roguelike_card_game/ui/screens/content_editor_screen.dart';

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
    expect(find.text('Ecrire'), findsNothing);
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
}
