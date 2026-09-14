import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/field_path.dart';

void main() {
  test('le motif efface les indices, le libelle les garde', () {
    const path = <Object>['choices', 1, 'actions', 0, 'type'];
    expect(patternOf(path), 'choices[].actions[].type');
    expect(labelOf(path), 'choices[1].actions[0].type');
    expect(patternOf(const ['rarity']), 'rarity');
  });

  group('valuesMatching', () {
    final document = <String, dynamic>{
      'rarity': 'common',
      'effects': [
        {'type': 'damage', 'value': 6},
        {'type': 'apply_status', 'statusId': 'burn', 'value': 2},
      ],
      'choices': [
        {
          'actions': [
            {'type': 'heal'},
          ],
        },
      ],
    };

    // Les chemins sont des listes : `==` n'y compare que l'identite, on
    // compare donc leurs libelles.
    test('une cle de premier niveau', () {
      final found = valuesMatching(document, 'rarity');
      expect(found.map((e) => labelOf(e.$1)), ['rarity']);
      expect(found.map((e) => e.$2), ['common']);
    });

    test('chaque element d une liste, avec son indice', () {
      final found = valuesMatching(document, 'effects[].type');
      expect(found.map((e) => labelOf(e.$1)),
          ['effects[0].type', 'effects[1].type']);
      expect(found.map((e) => e.$2), ['damage', 'apply_status']);
    });

    test('une cle absente d un element ne rend rien pour lui', () {
      expect(valuesMatching(document, 'effects[].statusId').map((e) => e.$2),
          ['burn']);
    });

    test('deux niveaux de listes', () {
      expect(
        valuesMatching(document, 'choices[].actions[].type')
            .map((e) => labelOf(e.$1)),
        ['choices[0].actions[0].type'],
      );
    });

    test('un motif sans correspondance rend une liste vide', () {
      expect(valuesMatching(document, 'intents[].type'), isEmpty);
    });
  });
}
