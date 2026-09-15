import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

CardData _cardData({
  CardRarity rarity = CardRarity.common,
  int baseMaxForgeUpgrades = 1,
}) =>
    CardData(
      id: 'test_card',
      cost: 1,
      type: CardType.attack,
      category: CardCategory.global,
      rarity: rarity,
      target: CardTarget.singleEnemy,
      effects: const [],
      baseMaxForgeUpgrades: baseMaxForgeUpgrades,
    );

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

    test('unique est hors de l echelle, bien que declaree apres legendaire', () {
      expect(CardRarity.unique.next, isNull);
    });
  });

  group('Capacite de forge', () {
    test('une carte globale gagne un emplacement par palier de rarete', () {
      final data = _cardData();
      expect(
        [for (final rarity in CardRarity.values.take(5)) data.forgeCapacityAt(rarity)],
        [1, 2, 3, 4, 5],
      );
    });

    test('une carte de classe garde sa capacite fixe de 5 (ADR-026)', () {
      final data = _cardData(rarity: CardRarity.unique, baseMaxForgeUpgrades: 5);
      expect(CardInstance(data: data).forgeCapacity, 5);
    });

    test('forgeCapacity lit la rarete de l instance, pas celle du modele', () {
      final data = _cardData(baseMaxForgeUpgrades: 2);
      expect(CardInstance(data: data, rarity: CardRarity.epic).forgeCapacity, 5);
    });
  });

  group('CardRarity.isAcquirable', () {
    test('une carte de classe n entre dans le deck qu au draft de depart', () {
      expect(CardRarity.unique.isAcquirable, isFalse);
    });

    test('toute rarete de l echelle s acquiert en cours de run', () {
      for (final rarity in CardRarity.values.take(5)) {
        expect(rarity.isAcquirable, isTrue, reason: rarity.name);
      }
    });
  });
}
