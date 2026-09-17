import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/passive_availability.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';

/// Le point d'accès unique aux passifs d'une classe (spec P-49, §4).
void main() {
  const paladin = HeroData(
    id: 'paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
    baseDamage: 5,
  );
  const mage = HeroData(
    id: 'mage',
    classCard: 'mage.png',
    maxHp: 60,
    maxMana: 3,
    baseDamage: 10,
  );

  PassiveData passive(String id, {List<String>? classes}) => PassiveData(
        id: id,
        trigger: RelicTrigger.startOfTurn,
        effectType: 'gain_armor',
        value: 1,
        classes: classes,
      );

  GameDataRegistry registryOf(List<PassiveData> passives) => GameDataRegistry(
        enemies: const [],
        heroes: const [paladin, mage],
        cards: const [],
        events: const [],
        passives: passives,
        relics: const [],
        forgeUpgrades: const [],
      );

  List<String> idsFor(HeroData hero, GameDataRegistry registry) =>
      availablePassivesFor(hero, registry).map((p) => p.id).toList();

  test('un passif qui declare une classe n est disponible que pour elle', () {
    final registry = registryOf([passive('ward', classes: ['paladin'])]);
    expect(idsFor(paladin, registry), ['ward']);
    expect(idsFor(mage, registry), isEmpty);
  });

  test('un passif sans classes est disponible pour toutes', () {
    final registry = registryOf([passive('aegis')]);
    expect(idsFor(paladin, registry), ['aegis']);
    expect(idsFor(mage, registry), ['aegis']);
  });

  test('un passif partage entre deux classes l est pour les deux', () {
    final registry = registryOf([
      passive('bond', classes: ['paladin', 'mage']),
    ]);
    expect(idsFor(paladin, registry), ['bond']);
    expect(idsFor(mage, registry), ['bond']);
  });

  test('tries par id, pas par ordre de lecture', () {
    final registry = registryOf([
      passive('zeal'),
      passive('aegis'),
      passive('mind', classes: ['paladin']),
    ]);
    expect(idsFor(paladin, registry), ['aegis', 'mind', 'zeal']);
  });

  test('le catalogue du registre n est pas reordonne', () {
    final registry = registryOf([passive('zeal'), passive('aegis')]);
    availablePassivesFor(paladin, registry);
    expect(registry.passives.map((p) => p.id), ['zeal', 'aegis']);
  });
}
