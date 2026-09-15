import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system_io.dart';
import 'package:roguelike_card_game/services/content_editor/project_root.dart';

void main() {
  late Directory sandbox;
  late String root;
  const fs = IoContentFileSystem();

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('project_root_');
    root = IoContentFileSystem.toSlashes(sandbox.path);
    File('$root/pubspec.yaml').writeAsStringSync('name: test\n');
    Directory('$root/assets/data').createSync(recursive: true);
  });

  tearDown(() => sandbox.deleteSync(recursive: true));

  test('remonte depuis le repertoire de build jusqu a la racine', () {
    final deep = '$root/build/windows/x64/runner/Debug';
    Directory(deep).createSync(recursive: true);

    expect(ProjectRoot.findFrom(fs, deep), root);
  });

  test('rend la racine elle-meme quand on y est deja', () {
    expect(ProjectRoot.findFrom(fs, root), root);
  });

  test('un pubspec sans assets/data n est pas une racine', () {
    final decoy = Directory('$root/decoy')..createSync();
    File('${decoy.path}/pubspec.yaml').writeAsStringSync('name: decoy\n');

    // La remontee ne s'arrete pas sur le leurre : elle continue jusqu'a la
    // vraie racine, qui porte les deux marqueurs.
    expect(
      ProjectRoot.findFrom(fs, IoContentFileSystem.toSlashes(decoy.path)),
      root,
    );
  });

  test('rend null quand aucun parent ne porte les deux marqueurs', () {
    final orphan = Directory.systemTemp.createTempSync('orphan_');
    addTearDown(() => orphan.deleteSync(recursive: true));

    expect(
      ProjectRoot.findFrom(fs, IoContentFileSystem.toSlashes(orphan.path)),
      isNull,
    );
  });

  test('les antislash de Windows sont normalises a l entree', () {
    final deep = '$root/build/windows';
    Directory(deep).createSync(recursive: true);

    expect(ProjectRoot.findFrom(fs, deep.replaceAll('/', '\\')), root);
  });
}
