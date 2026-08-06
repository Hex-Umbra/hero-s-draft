import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/map_node.dart';
import 'package:roguelike_card_game/services/map_generator_service.dart';

void main() {
  group('Relic Exchange Map Generation Tests', () {
    test('No relicExchange nodes generated when act < 5', () {
      for (int act = 1; act < 5; act++) {
        for (int trial = 0; trial < 10; trial++) {
          final nodes = MapGeneratorService.generateMap(act: act);
          final relicExchangeNodes = nodes.where((n) => n.type == MapNodeType.relicExchange).toList();
          expect(relicExchangeNodes, isEmpty, reason: 'act $act should not generate relic exchange nodes');
        }
      }
    });

    test('relicExchange nodes generated when act >= 5 and act % 5 == 0', () {
      final nodes = MapGeneratorService.generateMap(act: 5);
      final relicExchangeNodes = nodes.where((n) => n.type == MapNodeType.relicExchange).toList();
      expect(relicExchangeNodes.length, 1);
      
      final node = relicExchangeNodes.first;
      final parts = node.id.split('_');
      expect(parts.length, greaterThanOrEqualTo(2));
      final y = int.parse(parts[1]);
      expect([2, 3, 4, 6, 7], contains(y));
    });
  });

  group('Relic Exchange Transaction Logic Tests', () {
    late ProviderContainer container;
    late InventoryController inventoryController;
    late RunController runController;

    const dummyHero = HeroData(
      id: 'paladin',
      nameEn: 'Paladin',
      nameFr: 'Paladin',
      iconPath: 'paladin.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
      luck: 0,
      armorMastery: 0,
      passiveTrait: 'regenArmor',
    );

    setUp(() {
      container = ProviderContainer();
      inventoryController = container.read(inventoryProvider.notifier);
      runController = container.read(runProvider.notifier);
      runController.startNewRun(dummyHero);
    });

    test('exchangeRelics removes sacrificed and adds gained relic and handles startOfRun stat changes', () {
      const relic1 = RelicData(
        id: 'relic_1',
        nameEn: 'Relic 1',
        trigger: RelicTrigger.startOfRun,
        effectType: 'gain_strength',
        value: 2,
        rarity: RelicRarity.common,
        emoji: '1️⃣',
      );
      const relic2 = RelicData(
        id: 'relic_2',
        nameEn: 'Relic 2',
        trigger: RelicTrigger.startOfRun,
        effectType: 'gain_luck',
        value: 1,
        rarity: RelicRarity.common,
        emoji: '2️⃣',
      );
      const relic3 = RelicData(
        id: 'relic_3',
        nameEn: 'Relic 3',
        trigger: RelicTrigger.startOfCombat,
        effectType: 'gain_armor',
        value: 5,
        rarity: RelicRarity.common,
        emoji: '3️⃣',
      );

      inventoryController.addRelic(relic1);
      inventoryController.addRelic(relic2);
      inventoryController.addRelic(relic3);

      expect(runController.state.heroStats.attaque, 2);
      expect(runController.state.heroStats.luck, 1);
      expect(inventoryController.state.relics.length, 3);

      const gainedRelic = RelicData(
        id: 'gained_relic',
        nameEn: 'Gained Relic',
        trigger: RelicTrigger.startOfRun,
        effectType: 'gain_strength',
        value: 5,
        rarity: RelicRarity.uncommon,
        emoji: '🌟',
      );

      runController.exchangeRelics([relic1, relic2, relic3], gainedRelic);

      expect(inventoryController.state.relics.length, 1);
      expect(inventoryController.state.relics.first.id, 'gained_relic');

      expect(runController.state.heroStats.attaque, 5);
      expect(runController.state.heroStats.luck, 0);
    });

    test('increase_cards_per_turn s\'applique et se retire symétriquement', () {
      const satchel = RelicData(
        id: 'scholars_satchel',
        nameEn: "Scholar's Satchel",
        nameFr: "Besace de l'Érudit",
        trigger: RelicTrigger.startOfRun,
        effectType: 'increase_cards_per_turn',
        value: 1,
        rarity: RelicRarity.legendary,
        emoji: '🎒',
      );
      const filler = RelicData(
        id: 'filler',
        nameEn: 'Filler',
        nameFr: 'Bouche-trou',
        trigger: RelicTrigger.startOfRun,
        effectType: 'gain_strength',
        value: 1,
        rarity: RelicRarity.common,
        emoji: '⬜',
      );

      expect(runController.state.cardsPerTurn, 5);

      // `addRelic` déclenche lui-même `applyRelicEffect` sur un `startOfRun`.
      inventoryController.addRelic(satchel);
      expect(runController.state.cardsPerTurn, 6);

      // Sacrifice via l'Échange de Reliques : le bonus ne doit pas fuiter.
      runController.exchangeRelics([satchel], filler);
      expect(runController.state.cardsPerTurn, 5);
      expect(
        inventoryController.state.relics.any((r) => r.id == 'scholars_satchel'),
        isFalse,
      );
    });
  });
}
