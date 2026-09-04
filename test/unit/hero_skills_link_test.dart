import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/hero_skills_link.dart';

void main() {
  test('une carte de signature introuvable leve au lieu d etre avalee', () {
    final registry = GameDataRegistry(
      enemies: const [],
      heroes: const [],
      cards: const [],
      events: const [],
      passives: const [],
      relics: const [],
      forgeUpgrades: const [],
    );

    const hero = HeroData(
      id: 'paladin',
      iconPath: 'hero_paladin.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
      skills: ['carte_absente'],
    );

    expect(() => hero.getHeroCards(registry), throwsStateError);
  });
}
