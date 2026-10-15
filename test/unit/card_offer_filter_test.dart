import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

CardData _card({
  required String id,
  CardType type = CardType.attack,
  CardRarity rarity = CardRarity.common,
}) {
  return CardData(
    id: id,
    cost: 1,
    type: type,
    rarity: rarity,
    target: CardTarget.singleEnemy,
    effects: const [],
  );
}

Map<String, dynamic> _json() => {
      'id': 'strike',
      'cost': 1,
      'type': 'attack',
      'rarity': 'common',
      'target': 'singleEnemy',
      'effects': <dynamic>[],
    };

Matcher _refusing(String key) => throwsA(
      isA<FormatException>().having((e) => e.message, 'message', contains(key)),
    );

void main() {
  group('CardData.isOfferable', () {
    test('toute carte qui n est pas un statut est offerte, a toute rarete', () {
      for (final type in [CardType.attack, CardType.skill, CardType.power]) {
        for (final rarity in CardRarity.values) {
          expect(_card(id: 'c', type: type, rarity: rarity).isOfferable, isTrue,
              reason: '$type $rarity');
        }
      }
    });

    test('une carte de statut n est jamais offerte', () {
      expect(_card(id: 'wound', type: CardType.status).isOfferable, isFalse);
    });

    test('CardData.fromJson refuse heroClass, en le nommant', () {
      expect(() => CardData.fromJson(_json()..['heroClass'] = 'mage'),
          _refusing('heroClass'));
    });

    test('CardData.fromJson refuse category, en le nommant', () {
      expect(() => CardData.fromJson(_json()..['category'] = 'global'),
          _refusing('category'));
    });

    test('toJson n ecrit ni heroClass ni category, et une CardInstance sauvee se relit',
        () {
      final data = CardData.fromJson(_json());
      expect(data.toJson().containsKey('heroClass'), isFalse);
      expect(data.toJson().containsKey('category'), isFalse);

      final instance = CardInstance(data: data, rarity: CardRarity.rare);
      final restored = CardInstance.fromJson(instance.toJson());
      expect(restored.data.id, instance.data.id);
      expect(restored.rarity, instance.rarity);
      expect(restored.forgeUpgrades, instance.forgeUpgrades);
    });
  });
}
