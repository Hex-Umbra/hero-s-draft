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

      controller.hydrate(const DeckState());
      expect(container.read(deckProvider).masterDeck, isEmpty);
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
