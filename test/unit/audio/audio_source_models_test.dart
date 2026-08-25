import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/services/audio/audio_source.dart';

void main() {
  group('Modeles porteurs de son', () {
    test('CardData expose sfx et animation comme AudioSource', () {
      final card = CardData.fromJson({
        'id': 'test_card',
        'nameEn': 'Test',
        'nameFr': 'Test',
        'descriptionEn': '',
        'descriptionFr': '',
        'cost': 1,
        'type': 'attack',
        'category': 'global',
        'rarity': 'common',
        'target': 'singleEnemy',
        'animation': 'fire',
        'sfx': 'card_play_fire',
        'effects': <dynamic>[],
      });

      expect(card, isA<AudioSource>());
      expect(card.sfx, 'card_play_fire');
      expect(card.animation, 'fire');
    });

    test('le champ sfx est optionnel et vaut null par defaut', () {
      final card = CardData.fromJson({
        'id': 'test_card',
        'nameEn': 'Test',
        'nameFr': 'Test',
        'descriptionEn': '',
        'descriptionFr': '',
        'cost': 1,
        'type': 'attack',
        'category': 'global',
        'rarity': 'common',
        'target': 'singleEnemy',
        'effects': <dynamic>[],
      });

      expect(card.sfx, isNull);
    });

    test('EnemyData expose sfx comme AudioSource et animation vaut null', () {
      final enemy = EnemyData.fromJson({
        'id': 'test_enemy',
        'maxHp': 10,
        'baseDamage': 5,
        'spritePath': 'enemies/test.png',
        'sfx': 'enemy_attack',
      });

      expect(enemy, isA<AudioSource>());
      expect(enemy.sfx, 'enemy_attack');
      expect(enemy.animation, isNull);
    });

    test('RelicData expose sfx comme AudioSource et animation vaut null', () {
      final relic = RelicData.fromJson({
        'id': 'test_relic',
        'trigger': 'startOfCombat',
        'effectType': 'gain_energy',
        'value': 1,
        'rarity': 'common',
        'sfx': 'mana_gain',
      });

      expect(relic, isA<AudioSource>());
      expect(relic.sfx, 'mana_gain');
      expect(relic.animation, isNull);
    });
  });
}
