import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/save_migrations.dart';

Map<String, dynamic> _addA(Map<String, dynamic> save) => {...save, 'a': true};

Map<String, dynamic> _addB(Map<String, dynamic> save) =>
    {...save, 'b': save['a'] == true};

void main() {
  group('SaveMigrator', () {
    const migrator = SaveMigrator(
      currentVersion: 3,
      steps: {1: _addA, 2: _addB},
    );

    test('une sauvegarde a la version courante ressort intacte', () {
      final save = <String, dynamic>{'schemaVersion': 3, 'x': 1};
      expect(migrator.migrate(save), {'schemaVersion': 3, 'x': 1});
    });

    test('une sauvegarde ancienne traverse chaque etape dans l ordre', () {
      final migrated = migrator.migrate(<String, dynamic>{'schemaVersion': 1});

      expect(migrated['a'], isTrue);
      expect(migrated['b'], isTrue, reason: '_addB doit voir le travail de _addA');
      expect(migrated['schemaVersion'], 3);
    });

    test('une sauvegarde intermediaire ne rejoue pas les etapes passees', () {
      final migrated = migrator.migrate(<String, dynamic>{'schemaVersion': 2});

      expect(migrated.containsKey('a'), isFalse);
      expect(migrated['b'], isFalse);
      expect(migrated['schemaVersion'], 3);
    });

    for (final version in <Object?>[null, 0, '1']) {
      test('la version $version est une sauvegarde corrompue', () {
        expect(
          () => migrator.migrate(<String, dynamic>{'schemaVersion': version}),
          throwsFormatException,
        );
      });
    }

    test('une version plus recente est refusee, pas corrompue', () {
      expect(
        () => migrator.migrate(<String, dynamic>{'schemaVersion': 4}),
        throwsA(
          isA<SaveFromNewerBuildException>()
              .having((e) => e.version, 'version', 4),
        ),
      );
    });

    test('une etape manquante est une erreur de programmation', () {
      const holed = SaveMigrator(currentVersion: 3, steps: {1: _addA});

      expect(
        () => holed.migrate(<String, dynamic>{'schemaVersion': 1}),
        throwsStateError,
      );
    });
  });

  group('saveMigrator (production)', () {
    test('une etape existe pour chaque version anterieure, et aucune autre', () {
      expect(
        saveMigrator.steps.keys.toSet(),
        {for (var v = 1; v < saveMigrator.currentVersion; v++) v},
      );
    });
  });
}
