import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

/// L'échelle de fusion, écrite en toutes lettres : la déduire de l'ordre de
/// déclaration de l'enum est précisément l'erreur que ces tests gardent.
const _ladder = [
  CardRarity.common,
  CardRarity.uncommon,
  CardRarity.rare,
  CardRarity.epic,
  CardRarity.legendary,
];

void main() {
  group('CardRarity.next', () {
    test('chaque rarete de l echelle mene a la suivante', () {
      expect(CardRarity.common.next, CardRarity.uncommon);
      expect(CardRarity.uncommon.next, CardRarity.rare);
      expect(CardRarity.rare.next, CardRarity.epic);
      expect(CardRarity.epic.next, CardRarity.legendary);
    });

    test('legendaire est le sommet de l echelle', () {
      expect(CardRarity.legendary.next, isNull);
    });
  });

  group('CardRarity.fusionRank', () {
    test('le nombre de fusions qui menent a la rarete', () {
      expect([for (final rarity in _ladder) rarity.fusionRank], [0, 1, 2, 3, 4]);
    });
  });

  group('CardRarity.multiplier', () {
    test('un multiplicateur par palier', () {
      expect(
        [for (final rarity in _ladder) rarity.multiplier],
        [1.0, 1.2, 1.4, 1.6, 2.0],
      );
    });
  });

  group('CardRarity.values', () {
    test('CardRarity porte exactement les cinq paliers de l echelle', () {
      expect(CardRarity.values, _ladder);
    });
  });
}
