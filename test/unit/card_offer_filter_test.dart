import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

CardData _card({
  required String id,
  CardType type = CardType.attack,
  CardCategory category = CardCategory.global,
  String? heroClass,
  CardRarity rarity = CardRarity.common,
}) {
  return CardData(
    id: id,
    cost: 1,
    type: type,
    category: category,
    heroClass: heroClass,
    rarity: rarity,
    target: CardTarget.singleEnemy,
    effects: const [],
  );
}

void main() {
  group('CardData.isOfferableTo', () {
    test('une carte globale est proposable a n importe quelle classe', () {
      final carte = _card(id: 'strike');
      expect(carte.isOfferableTo('mage'), isTrue);
      expect(carte.isOfferableTo('paladin'), isTrue);
    });

    test('une carte de signature n est proposable qu a sa propre classe', () {
      final carte = _card(
        id: 'fireball',
        category: CardCategory.characterSpecific,
        heroClass: 'mage',
        rarity: CardRarity.rare,
      );
      expect(carte.isOfferableTo('mage'), isTrue);
      expect(carte.isOfferableTo('paladin'), isFalse);
      expect(carte.isOfferableTo('berserker'), isFalse);
    });

    test('une carte de statut n est proposable a personne', () {
      final carte = _card(id: 'wound', type: CardType.status);
      expect(carte.isOfferableTo('mage'), isFalse);
    });

    test('une carte unique n est proposable a personne, pas meme a sa classe', () {
      final carte = _card(
        id: 'holy_shield',
        category: CardCategory.characterSpecific,
        heroClass: 'paladin',
        rarity: CardRarity.unique,
      );
      expect(carte.isOfferableTo('paladin'), isFalse);
    });
  });
}
