import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `tool/sync_assets.dart` vit hors de `lib/`, donc n est pas importable par
/// `package:`. On l invoque comme le ferait un humain ou la CI.
///
/// `runInShell: true` est INDISPENSABLE. L hote de `flutter test` est
/// `flutter_tester.exe`, dont l environnement ne resout pas `dart` : sans le
/// shell, `Process.run` leve `ProcessException: Le fichier specifie est
/// introuvable`. Sur `ubuntu-latest` ca passerait — `dart` y est un script a
/// shebang — donc l omission produirait exactement l asymetrie local/CI que
/// ce chantier traque ailleurs, mais inversee : rouge en local, vert en CI.
Future<ProcessResult> _run(List<String> args, {String? cwd}) {
  return Process.run(
    'dart',
    ['run', 'tool/sync_assets.dart', ...args],
    workingDirectory: cwd,
    runInShell: true,
  );
}

void main() {
  test('--check sort en 0 : le pubspec du depot est synchronise', () async {
    final result = await _run(['--check']);
    expect(
      result.exitCode,
      0,
      reason: 'pubspec.yaml a derive du disque :\n${result.stdout}${result.stderr}',
    );
  });

  group('sur une arborescence de test', () {
    late Directory sandbox;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('sync_assets_');
      // Le script est invoque depuis le sandbox : il lui faut une copie.
      Directory('${sandbox.path}/tool').createSync(recursive: true);
      File('tool/sync_assets.dart').copySync('${sandbox.path}/tool/sync_assets.dart');
    });

    tearDown(() => sandbox.deleteSync(recursive: true));

    void write(String relative, String content) {
      final file = File('${sandbox.path}/$relative');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    // `environment:` evite l avertissement « has no lower-bound SDK
    // constraint » que `dart run` ecrirait sur stdout a chaque invocation.
    String pubspecWith(String assetsBlock) =>
        'name: sandbox\r\n'
        'environment:\r\n'
        '  sdk: ^3.11.4\r\n'
        'flutter:\r\n'
        '  uses-material-design: true\r\n'
        '  assets:\r\n'
        '$assetsBlock'
        '  fonts: []\r\n';

    test('seuls les repertoires contenant au moins un fichier sont emis', () async {
      write('assets/data/audio.json', '{}');
      write('assets/data/cards/strike.json', '{}');
      write('assets/images/bg.png', 'x');
      // `assets/data/classes/` ne contient que des dossiers : pas de ligne.
      write('assets/data/classes/paladin/class.json', '{}');
      // Un dossier vide n a rien a declarer.
      Directory('${sandbox.path}/assets/data/vide').createSync(recursive: true);
      write('pubspec.yaml', pubspecWith(''));

      final result = await _run([], cwd: sandbox.path);
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');

      final written = File('${sandbox.path}/pubspec.yaml').readAsStringSync();
      expect(
        written,
        pubspecWith(
          '    - assets/data/\r\n'
          '    - assets/data/cards/\r\n'
          '    - assets/data/classes/paladin/\r\n'
          '    - assets/images/\r\n',
        ),
      );
    });

    test('--check sort en 1 et nomme la ligne manquante', () async {
      write('assets/data/audio.json', '{}');
      write('assets/data/cards/strike.json', '{}');
      write('pubspec.yaml', pubspecWith('    - assets/data/\r\n'));

      final result = await _run(['--check'], cwd: sandbox.path);
      expect(result.exitCode, 1);
      expect(result.stdout.toString(), contains('assets/data/cards/'));
    });

    test('le fichier n est pas reecrit quand il est deja a jour', () async {
      write('assets/images/bg.png', 'x');
      write('pubspec.yaml', pubspecWith('    - assets/images/\r\n'));
      final before = File('${sandbox.path}/pubspec.yaml').readAsStringSync();

      final result = await _run([], cwd: sandbox.path);
      expect(result.exitCode, 0);
      expect(File('${sandbox.path}/pubspec.yaml').readAsStringSync(), before);
    });

    test('refuse et laisse le fichier intact si "  assets:" est dupliquee', () async {
      // Une dependance nommee `assets` produit aussi une ligne "  assets:" :
      // `dependencies:` indente ses enfants de 2 espaces, exactement comme
      // `flutter:`. Le script ne doit pas deviner laquelle des deux lignes
      // est la section a synchroniser.
      const pubspec = 'name: sandbox\r\n'
          'environment:\r\n'
          '  sdk: ^3.11.4\r\n'
          'dependencies:\r\n'
          '  assets:\r\n'
          '    git:\r\n'
          '      url: https://example.com/assets.git\r\n'
          'flutter:\r\n'
          '  uses-material-design: true\r\n'
          '  assets:\r\n'
          '    - assets/images/\r\n'
          '  fonts: []\r\n';
      write('assets/images/bg.png', 'x');
      write('pubspec.yaml', pubspec);

      final result = await _run([], cwd: sandbox.path);
      expect(result.exitCode, 2, reason: '${result.stdout}${result.stderr}');
      expect(result.stderr.toString(), contains('lignes 5, 10'));
      expect(File('${sandbox.path}/pubspec.yaml').readAsStringSync(), pubspec);
    });

    test('refuse et laisse le fichier intact si une entree de liste suit '
        'le bloc a une indentation etrangere', () async {
      write('assets/images/bg.png', 'x');
      // 2 espaces au lieu de 4 : ni lue comme faisant partie du bloc (le
      // while de `main` ne consomme que `'    - '`, 4 espaces), ni reconnue
      // comme une section suivante.
      final pubspec = pubspecWith('  - assets/legacy/\r\n');
      write('pubspec.yaml', pubspec);

      final result = await _run([], cwd: sandbox.path);
      expect(result.exitCode, 2, reason: '${result.stdout}${result.stderr}');
      expect(result.stderr.toString(), contains('assets/legacy/'));
      expect(File('${sandbox.path}/pubspec.yaml').readAsStringSync(), pubspec);
    });
  });
}
