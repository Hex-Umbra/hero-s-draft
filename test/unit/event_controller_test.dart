import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/event_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/models/data/event_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

void main() {
  group('EventController Unit Tests', () {
    late ProviderContainer container;
    late EventController eventController;
    late RunController runController;
    late InventoryController inventoryController;

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

    final EventData testEvent = EventData(
      id: 'test_event',
      titleEn: 'Mysterious Shrine',
      titleFr: 'Sanctuaire Mystérieux',
      descriptionEn: 'You find a glowing shrine.',
      descriptionFr: 'Vous trouvez un sanctuaire brillant.',
      choices: [
        EventChoice(
          textEn: 'Pray for strength (+2 Strength, -10 HP)',
          textFr: 'Prier pour la force (+2 Force, -10 PV)',
          actions: [
            EventAction(type: 'gain_strength', value: 2),
            EventAction(type: 'take_damage', value: 10),
          ],
        ),
        EventChoice(
          textEn: 'Search for gold (+50 Gold)',
          textFr: 'Chercher de l\'or (+50 Or)',
          actions: [
            EventAction(type: 'gain_gold', value: 50),
          ],
        ),
        EventChoice(
          textEn: 'Touch the altar (Gain a random Relic)',
          textFr: 'Toucher l\'autel (Gagner une relique aléatoire)',
          actions: [
            EventAction(type: 'gain_relic', value: 1),
          ],
        ),
      ],
    );

    final List<RelicData> testRelicPool = [
      const RelicData(
        id: 'r_common',
        nameEn: 'Common Ring',
        nameFr: 'Anneau Commun',
        descriptionEn: 'Gain 2 armor at turn start',
        descriptionFr: 'Gagne 2 armure en début de tour',
        trigger: RelicTrigger.startOfTurn,
        effectType: 'gain_armor',
        value: 2,
        rarity: RelicRarity.common,
        emoji: '🪙',
      ),
      const RelicData(
        id: 'r_rare',
        nameEn: 'Rare Sword',
        nameFr: 'Épée Rare',
        descriptionEn: 'Gain 2 Strength at run start',
        descriptionFr: 'Gagne 2 Force au début de la run',
        trigger: RelicTrigger.startOfRun,
        effectType: 'gain_strength',
        value: 2,
        rarity: RelicRarity.rare,
        emoji: '⚔️',
      ),
      const RelicData(
        id: 'r_legendary',
        nameEn: 'Crown',
        nameFr: 'Couronne',
        descriptionEn: '+1 Luck at run start',
        descriptionFr: '+1 Chance au début de la run',
        trigger: RelicTrigger.startOfRun,
        effectType: 'gain_luck',
        value: 1,
        rarity: RelicRarity.legendary,
        emoji: '👑',
      ),
    ];

    setUp(() {
      container = ProviderContainer();
      eventController = container.read(eventProvider.notifier);
      runController = container.read(runProvider.notifier);
      inventoryController = container.read(inventoryProvider.notifier);

      runController.startNewRun(dummyHero);
    });

    test('initializeEvent sets state with a random event from list', () {
      eventController.initializeEvent([testEvent]);
      expect(eventController.state.activeEvent?.id, testEvent.id);
      expect(eventController.state.isResolved, false);
      expect(eventController.state.selectedChoice, null);
    });

    test('selectChoice resolves simple actions correctly (strength and damage)', () {
      eventController.setEvent(testEvent);
      final choice = testEvent.choices[0]; // Pray Choice

      eventController.selectChoice(choice, runController, inventoryController, []);

      expect(eventController.state.isResolved, true);
      expect(eventController.state.selectedChoice, choice);
      // Hero stats update: strength + 2
      expect(runController.state.heroStats.attaque, 2);
      // HP decreases by 10
      expect(runController.state.heroStats.currentPv, 90);
    });

    test('selectChoice resolves gold choice', () {
      eventController.setEvent(testEvent);
      final choice = testEvent.choices[1]; // Gold Choice
      final initialGold = inventoryController.state.gold;

      eventController.selectChoice(choice, runController, inventoryController, []);

      expect(inventoryController.state.gold, initialGold + 50);
    });

    test('selectChoice selects relic based on luck and mockRoll (legendary)', () {
      eventController.setEvent(testEvent);
      final choice = testEvent.choices[2]; // Relic Choice

      // Roll is 0.5, which is < legChance (1.0 + 0 * 0.5 = 1.0)
      // This should pick a Legendary relic from our pool
      final chosen = eventController.selectChoice(
        choice,
        runController,
        inventoryController,
        testRelicPool,
        mockRoll: 0.5,
      );

      expect(chosen, isNotNull);
      expect(chosen!.rarity, RelicRarity.legendary);
      expect(chosen.id, 'r_legendary');
      // Verify the relic is added to inventory state
      expect(inventoryController.state.relics.contains(chosen), true);
    });

    test('selectChoice selects relic based on luck and mockRoll (common)', () {
      eventController.setEvent(testEvent);
      final choice = testEvent.choices[2]; // Relic Choice

      // Roll is 50.0, which is > any high rarity chance, so it should fallback to common
      final chosen = eventController.selectChoice(
        choice,
        runController,
        inventoryController,
        testRelicPool,
        mockRoll: 50.0,
      );

      expect(chosen, isNotNull);
      expect(chosen!.rarity, RelicRarity.common);
      expect(chosen.id, 'r_common');
      expect(inventoryController.state.relics.contains(chosen), true);
    });
  });
}
