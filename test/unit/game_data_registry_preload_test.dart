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
            classCard: 'hero_paladin.png',
            maxHp: 100,
            maxMana: 3,
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
            classCard: '',
            maxHp: 1,
            maxMana: 1,
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

    // Sans cette assertion, un retour de `imagesToPreload` a l'ancien champ
    // passerait inapercu : Flame ne prechargerait plus la seule grande image
    // qu'il prechargeait, et rien n'echouerait avant l'affichage.
    test('imagesToPreload prend la carte de classe, pas l icone', () {
      final registry = GameDataRegistry(
        cards: const [],
        relics: const [],
        events: const [],
        passives: const [],
        forgeUpgrades: const [],
        heroes: const [
          HeroData(
            id: 'gambler',
            classCard: 'assets/data/classes/gambler/gambler.png',
            iconPath: 'assets/data/classes/gambler/icon.png',
            maxHp: 100,
            maxMana: 3,
          ),
        ],
        enemies: const [],
      );

      expect(
        registry.imagesToPreload,
        contains('assets/data/classes/gambler/gambler.png'),
      );
      expect(
        registry.imagesToPreload,
        isNot(contains('assets/data/classes/gambler/icon.png')),
      );
    });
  });
}
