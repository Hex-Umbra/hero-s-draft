import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/passive_availability.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';

import 'lot_card_fixture.dart';

/// Le point d'accès unique aux passifs d'une classe (spec P-49, §4) :
/// disponible vaut éligible et pourvu d'un lot (spec P-42 T1 et P-44 lot 1,
/// §4.8, O5).
void main() {
  const paladin = HeroData(
    id: 'paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
  );
  const mage = HeroData(
    id: 'mage',
    classCard: 'mage.png',
    maxHp: 60,
    maxMana: 3,
  );

  PassiveData passive(
    String id, {
    List<String>? classes,
    int displayOrder = 0,
  }) =>
      PassiveData(
        id: id,
        trigger: RelicTrigger.startOfTurn,
        effectType: 'gain_armor',
        value: 1,
        classes: classes,
        displayOrder: displayOrder,
      );

  /// Un registre dont chaque passif a son lot, sauf si [cards] est donné.
  GameDataRegistry registryOf(
    List<PassiveData> passives, {
    List<CardData>? cards,
  }) =>
      GameDataRegistry(
        enemies: const [],
        heroes: const [paladin, mage],
        cards: cards ?? [for (final p in passives) lotCardFor(p.id)],
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
    expect(registry.cards.map((c) => c.id), ['lot_zeal', 'lot_aegis']);
  });

  test('le rang d affichage passe avant l id', () {
    final registry = registryOf([
      passive('aegis', displayOrder: 3),
      passive('zeal', displayOrder: 1),
      passive('mind', displayOrder: 2),
    ]);
    expect(idsFor(paladin, registry), ['zeal', 'mind', 'aegis']);
  });

  test('a rang egal, l id tranche : l ordre reste deterministe', () {
    final registry = registryOf([
      passive('zeal', displayOrder: 1),
      passive('aegis', displayOrder: 1),
    ]);
    expect(idsFor(paladin, registry), ['aegis', 'zeal']);
  });

  group('O5 : un passif sans lot n est pas disponible', () {
    test('sans carte de lot, absent ; avec une, present', () {
      final ward = passive('ward', classes: ['paladin']);
      expect(idsFor(paladin, registryOf([ward], cards: const [])), isEmpty);
      expect(
        idsFor(paladin, registryOf([ward], cards: [lotCardFor('ward')])),
        ['ward'],
      );
    });

    test('la carte de lot d un autre passif ne l ouvre pas', () {
      final registry = registryOf(
        [
          passive('ward', classes: ['paladin']),
          passive('zeal', classes: ['paladin']),
        ],
        cards: [lotCardFor('zeal')],
      );
      expect(idsFor(paladin, registry), ['zeal']);
    });

    test('une carte de lot de type quelconque suffit', () {
      for (final type in CardType.values) {
        final registry = registryOf(
          [passive('ward', classes: ['paladin'])],
          cards: [lotCardFor('ward', type: type)],
        );
        expect(idsFor(paladin, registry), ['ward'], reason: type.name);
      }
    });

    test('une neutre n ouvre aucun passif', () {
      const neutral = CardData(
        id: 'strike',
        cost: 1,
        type: CardType.attack,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        effects: [],
      );
      final registry = registryOf(
        [passive('ward', classes: ['paladin'])],
        cards: const [neutral],
      );
      expect(idsFor(paladin, registry), isEmpty);
    });
  });
}
