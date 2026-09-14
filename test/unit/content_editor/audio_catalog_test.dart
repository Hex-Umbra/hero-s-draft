import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/audio_catalog.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system_io.dart';

void main() {
  group('soundIds', () {
    late Directory sandbox;
    late String root;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('audio_catalog_');
      root = IoContentFileSystem.toSlashes(sandbox.path);
    });

    tearDown(() => sandbox.deleteSync(recursive: true));

    test('lit les cles de sounds, triees', () {
      File('$root/$kAudioCatalogPath')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('{"sounds": {"zap": {}, "clang": {}}}');
      expect(soundIds(const IoContentFileSystem(), root), ['clang', 'zap']);
    });

    test('rend une liste vide sans audio.json', () {
      expect(soundIds(const IoContentFileSystem(), root), isEmpty);
    });

    test('rend une liste vide si audio.json ne se lit pas', () {
      expect(soundIds(_FailingReadFileSystem(), root), isEmpty);
    });
  });

  group('insertSound', () {
    test('ajoute une ligne en fin de bloc, sans toucher aux autres', () {
      final source = File('assets/data/audio.json').readAsStringSync();
      final result =
          insertSound(source, id: 'clang_test', file: 'sfx/clang_test.wav');

      final before = source.split('\n');
      final after = result.split('\n');
      expect(after, hasLength(before.length + 1));

      String bare(String line) =>
          line.trimRight().replaceAll(RegExp(r',$'), '');
      final kept = after.map(bare).toSet();
      for (final line in before) {
        expect(kept, contains(bare(line)));
      }

      final sounds = (jsonDecode(result) as Map<String, dynamic>)['sounds']
          as Map<String, dynamic>;
      expect(sounds['clang_test'], {'file': 'sfx/clang_test.wav'});
    });

    test('suit les fins de ligne CRLF', () {
      const source = '{\r\n  "sounds": {\r\n    "a": { "file": "sfx/a.wav" }\r\n'
          '  },\r\n  "music": {}\r\n}\r\n';
      expect(
        insertSound(source, id: 'b', file: 'sfx/b.wav'),
        '{\r\n  "sounds": {\r\n    "a": { "file": "sfx/a.wav" },\r\n'
        '    "b": { "file": "sfx/b.wav" }\r\n  },\r\n  "music": {}\r\n}\r\n',
      );
    });

    test('remplit un bloc vide', () {
      const source = '{\n  "sounds": {},\n  "music": {}\n}\n';
      expect(
        insertSound(source, id: 'b', file: 'sfx/b.wav'),
        '{\n  "sounds": {\n    "b": { "file": "sfx/b.wav" }\n  },\n'
        '  "music": {}\n}\n',
      );
    });

    test('refuse un identifiant deja declare', () {
      const source = '{"sounds": {"a": {"file": "sfx/a.wav"}}}';
      expect(() => insertSound(source, id: 'a', file: 'sfx/a.wav'),
          throwsStateError);
    });

    test('refuse un document sans bloc sounds', () {
      expect(() => insertSound('{"music": {}}', id: 'a', file: 'sfx/a.wav'),
          throwsStateError);
    });
  });
}

class _FailingReadFileSystem extends IoContentFileSystem {
  const _FailingReadFileSystem();

  @override
  bool fileExists(String path) => true;

  @override
  String readFile(String path) =>
      throw const FileSystemException('lecture simulee en echec');
}
