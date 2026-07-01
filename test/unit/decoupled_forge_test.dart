import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';

void main() {
  group('Decoupled Forge Unit Tests', () {
    // Initialise le registre statique avec de fausses améliorations pour les tests
    setUp(() {
      GameDataRegistry(
        enemies: [],
        heroes: [],
        skills: [],
        cards: [],
        events: [],
        passives: [],
        relics: [],
        forgeUpgrades: [
          const ForgeUpgradeData(
            id: 'sharp',
            nameEn: 'Sharp',
            nameFr: 'Tranchant',
            descriptionEn: '+{val} Damage',
            descriptionFr: '+{val} Dégâts',
            icon: 'hardware_rounded',
            color: 'redAccent',
            pools: ['common'],
            valueMultiplier: 2,
            weight: 100,
          ),
          const ForgeUpgradeData(
            id: 'hardened',
            nameEn: 'Hardened',
            nameFr: 'Endurci',
            descriptionEn: '+{val} Block',
            descriptionFr: '+{val} Armure',
            icon: 'shield_rounded',
            color: 'blueAccent',
            pools: ['common'],
            valueMultiplier: 2,
            weight: 80,
          ),
        ],
      );
    });

    test('Capacity limit calculation works as expected based on rarity', () {
      final baseCard = CardData(
        id: 'test_card',
        cost: 1,
        type: CardType.attack,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        baseMaxForgeUpgrades: 2,
        effects: [],
      );

      // Common card capacity = 2 + 0 = 2
      final commonInstance = CardInstance(data: baseCard, rarity: CardRarity.common);
      final commonCapacity = commonInstance.data.baseMaxForgeUpgrades + commonInstance.rarity.index;
      expect(commonCapacity, 2);

      // Epic card capacity = 2 + 3 = 5
      final epicInstance = CardInstance(data: baseCard, rarity: CardRarity.epic);
      final epicCapacity = epicInstance.data.baseMaxForgeUpgrades + epicInstance.rarity.index;
      expect(epicCapacity, 5);
    });

    test('addForgeUpgrade correctly adds an upgrade to the master deck card', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cardData = CardData(
        id: 'strike',
        cost: 1,
        type: CardType.attack,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        effects: [],
      );

      final card = CardInstance(data: cardData);
      final deckNotifier = container.read(deckProvider.notifier);

      deckNotifier.initializeStarterDeck([card]);

      // Initially no upgrades
      expect(container.read(deckProvider).masterDeck.first.forgeUpgrades, isEmpty);

      // Add a sharp:1 upgrade
      deckNotifier.addForgeUpgrade(card.uniqueId, 'sharp:1');

      final updatedCard = container.read(deckProvider).masterDeck.first;
      expect(updatedCard.forgeUpgrades, contains('sharp:1'));
      expect(updatedCard.forgeUpgrades.length, 1);
    });

    test('ForgeUpgradeData resolves correct translations and calculated values', () {
      final sharp = ForgeUpgradeData.getById('sharp');
      expect(sharp, isNotNull);
      expect(sharp!.getName('fr'), 'Tranchant');
      expect(sharp.getName('en'), 'Sharp');
      expect(sharp.getDescription(3, 'fr'), '+6 Dégâts');
      expect(sharp.getDescription(3, 'en'), '+6 Damage');
    });

    test('setForgeUpgrades updates master deck card upgrades directly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cardData = CardData(
        id: 'strike',
        cost: 1,
        type: CardType.attack,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        effects: [],
      );

      final card = CardInstance(data: cardData, forgeUpgrades: ['sharp:1', 'sharp:2']);
      final deckNotifier = container.read(deckProvider.notifier);

      deckNotifier.initializeStarterDeck([card]);

      // Initially sharp:1 and sharp:2
      expect(container.read(deckProvider).masterDeck.first.forgeUpgrades, equals(['sharp:1', 'sharp:2']));

      // Set to fused sharp:3
      deckNotifier.setForgeUpgrades(card.uniqueId, ['sharp:3']);

      final updatedCard = container.read(deckProvider).masterDeck.first;
      expect(updatedCard.forgeUpgrades, equals(['sharp:3']));
    });

    test('Identical upgrades fusion simulation calculations and costs', () {
      final cardData = CardData(
        id: 'strike',
        cost: 1,
        type: CardType.attack,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        effects: [],
      );

      // Card with 2x sharp (tier 1 and tier 2) and 1x hardened (tier 1)
      final card = CardInstance(data: cardData, forgeUpgrades: ['sharp:1', 'sharp:2', 'hardened:1']);

      // Simulating _getFusionsForCard logic
      final Map<String, List<String>> groups = {};
      for (final upg in card.forgeUpgrades) {
        final id = upg.split(':')[0];
        groups.putIfAbsent(id, () => []).add(upg);
      }

      final fusions = <Map<String, dynamic>>[];
      groups.forEach((id, list) {
        if (list.length >= 2) {
          int totalTier = 0;
          for (final upg in list) {
            totalTier += int.parse(upg.split(':')[1]);
          }
          final cost = 80 * (list.length - 1);
          fusions.add({
            'id': id,
            'totalTier': totalTier,
            'cost': cost,
          });
        }
      });

      // We expect only 1 fusion option: sharp, with total tier 3, cost 80 gold.
      expect(fusions.length, 1);
      expect(fusions.first['id'], 'sharp');
      expect(fusions.first['totalTier'], 3);
      expect(fusions.first['cost'], 80);

      // Simulate fusion implementation
      final fusionTargetId = fusions.first['id'] as String;
      final fusionTotalTier = fusions.first['totalTier'] as int;

      final updatedUpgrades = <String>[];
      bool addedFused = false;
      for (final upg in card.forgeUpgrades) {
        final id = upg.split(':')[0];
        if (id == fusionTargetId) {
          if (!addedFused) {
            updatedUpgrades.add('$fusionTargetId:$fusionTotalTier');
            addedFused = true;
          }
        } else {
          updatedUpgrades.add(upg);
        }
      }

      expect(updatedUpgrades, equals(['sharp:3', 'hardened:1']));
    });
  });
}
