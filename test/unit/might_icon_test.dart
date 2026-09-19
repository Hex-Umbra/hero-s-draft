import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// L'icône de la Puissance (spec P-41, §7.4).
///
/// Un garde-fou de source, comme `stat_gain_single_passage_test.dart` : ce
/// qu'on vérifie ici n'est pas un rendu mais une **absence** — celle de l'épée
/// partout où la Puissance est affichée. Un test de widget ne la verrait pas
/// revenir dans un écran qu'il ne monte pas.
void main() {
  Iterable<File> dartFilesOf(String directory) => Directory(directory)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  String normalized(File file) => file.path.replaceAll(r'\', '/');

  test('l epee n a plus aucun usage', () {
    // `baseDamage` est parti au lot C (spec §8.3), et avec lui le dernier
    // badge qui montrait une epee pour une stat de puissance.
    expect(File('lib/ui/widgets/sword_icon.dart').existsSync(), isFalse);

    for (final file in dartFilesOf('lib')) {
      expect(
        file.readAsStringSync().contains('SwordIcon'),
        isFalse,
        reason: normalized(file),
      );
    }
  });

  test('FlameSwordIcon n existe plus', () {
    expect(
      File('lib/game/components/widgets/flame_sword_icon.dart').existsSync(),
      isFalse,
    );
    for (final file in dartFilesOf('lib')) {
      expect(
        file.readAsStringSync().contains('FlameSwordIcon'),
        isFalse,
        reason: normalized(file),
      );
    }
  });

  test('le statut de Puissance porte l eclair', () {
    final source =
        File('lib/game/components/entities/status_indicator.dart')
            .readAsStringSync();
    expect(source.contains('⚡'), isTrue);
    expect(source.contains('💪'), isFalse);
  });
}
