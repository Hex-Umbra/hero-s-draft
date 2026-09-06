import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system_io.dart';
import 'package:roguelike_card_game/services/content_editor/entity_writer.dart';

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

  test('une creation conseille de relancer flutter run', () async {
    final report = await writerHere().write(fixtureRelicDraft());
    expect(report.relaunchAdvised, isTrue);
    expect(report.written, ['assets/data/relics/talisman_de_fer.json']);
  });

  test('une modification ne le conseille pas', () async {
    await writerHere().write(fixtureRelicDraft());
    final report =
        await writerHere().write(fixtureRelicDraft(isModification: true));

    expect(report.relaunchAdvised, isFalse);
  });

}
