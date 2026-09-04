import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

void main() {
  group('GameDataRegistry.imagesToPreload', () {
    test('collects hero icons and enemy sprites without duplicates', () {
      final registry = GameDataRegistry(
        enemies: const [
          EnemyData(
            id: 'slime',
            maxHp: 18,
            baseDamage: 4,
            spritePath: 'enemy_slime.png',
          ),
          EnemyData(
            id: 'slime_clone',
            maxHp: 18,
            baseDamage: 4,
            spritePath: 'enemy_slime.png',
          ),
        ],
        heroes: const [
          HeroData(
            id: 'paladin',
            iconPath: 'hero_paladin.png',
            maxHp: 100,
            maxMana: 3,
            baseDamage: 5,
          ),
        ],
        cards: const [],
        events: const [],
        passives: const [],
        relics: const [],
        forgeUpgrades: const [],
      );

      expect(
        registry.imagesToPreload,
        unorderedEquals(['hero_paladin.png', 'enemy_slime.png']),
      );
    });

    test('skips empty paths', () {
      final registry = GameDataRegistry(
        enemies: const [
          EnemyData(id: 'ghost', maxHp: 1, baseDamage: 1, spritePath: ''),
        ],
        heroes: const [
          HeroData(
            id: 'nobody',
            iconPath: '',
            maxHp: 1,
            maxMana: 1,
            baseDamage: 1,
          ),
        ],
        cards: const [],
        events: const [],
        passives: const [],
        relics: const [],
        forgeUpgrades: const [],
      );

      expect(registry.imagesToPreload, isEmpty);
    });
  });
}
