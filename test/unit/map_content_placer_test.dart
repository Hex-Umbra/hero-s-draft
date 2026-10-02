import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/map_node.dart';
import 'package:roguelike_card_game/services/map_generator_service.dart';

/// Le placement du Puits d'échange (D22 ; spec P-43 E2, §4.8), sur le modèle
/// de `relic_exchange_test.dart` : la carte réelle, tirée plusieurs fois.
void main() {
  test('aux actes 3, 6 et 9 : un Puits, etage 3 a 7, ancien combat ou '
      'evenement', () {
    for (final act in const [3, 6, 9]) {
      for (var trial = 0; trial < 10; trial++) {
        final wells = MapGeneratorService.generateMap(act: act)
            .where((n) => n.type == MapNodeType.forgeFusion)
            .toList();
        expect(wells, hasLength(1), reason: 'acte $act');
        final well = wells.single;
        expect(well.floor, inInclusiveRange(3, 7), reason: 'acte $act');
        expect(well.originalType, isIn([MapNodeType.combat, MapNodeType.event]),
            reason: 'acte $act');
      }
    }
  });

  test('aux actes 1, 2, 4, 5 et 7 : aucun Puits', () {
    for (final act in const [1, 2, 4, 5, 7]) {
      for (var trial = 0; trial < 10; trial++) {
        expect(
          MapGeneratorService.generateMap(act: act)
              .where((n) => n.type == MapNodeType.forgeFusion),
          isEmpty,
          reason: 'acte $act',
        );
      }
    }
  });
}
