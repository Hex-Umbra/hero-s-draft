// test/unit/notifier_hydrate_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/skill_controller.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/skill_state.dart';
import 'package:roguelike_card_game/models/inventory_state.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

void main() {
  group('Notifier.hydrate', () {
    test('RunController.hydrate replaces the state wholesale', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(runProvider.notifier);

      final hydrated = RunState(
        currentLevel: 9,
        act: 3,
        heroClassId: 'berserker',
        heroStats: EntityStats(maxPv: 50, currentPv: 10, armure: 0, attaque: 5),
      );
      controller.hydrate(hydrated);

      expect(container.read(runProvider).currentLevel, 9);
      expect(container.read(runProvider).heroClassId, 'berserker');
    });

    test('DeckNotifier.hydrate replaces the state wholesale', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(deckProvider.notifier);

      const testCard = CardData(
        id: 'strike_test',
        nameFr: 'Frappe Test',
        nameEn: 'Strike Test',
        cost: 1,
        type: CardType.attack,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        effects: [],
      );
      final cardInstance = CardInstance(
        uniqueId: 'test-card-1',
        data: testCard,
      );
      final hydratedState = DeckState(masterDeck: [cardInstance]);

      controller.hydrate(hydratedState);

      expect(container.read(deckProvider).masterDeck, hasLength(1));
      expect(container.read(deckProvider).masterDeck.first.uniqueId, 'test-card-1');
    });

    test('InventoryController.hydrate replaces the state wholesale', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(inventoryProvider.notifier);

      controller.hydrate(const InventoryState(gold: 999));
      expect(container.read(inventoryProvider).gold, 999);
    });

    test('SkillController.hydrate replaces the state wholesale', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(skillProvider.notifier);

      controller.hydrate(const SkillState(skill1Cooldown: 3));
      expect(container.read(skillProvider).skill1Cooldown, 3);
    });
  });
}
