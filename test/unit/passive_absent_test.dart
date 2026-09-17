import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/systems/passives/passive_strategy.dart';
import 'package:roguelike_card_game/game/systems/trait_system.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';

void main() {
  test('un passif absent n applique aucun effet', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Un héros démarré sans passif actif.
    const orphan = HeroData(
      id: 'orphan',
      classCard: 'hero_paladin.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
    );

    final controller = container.read(runProvider.notifier);
    controller.startNewRun(orphan);

    final armorBefore = controller.currentState.heroStats.armure;
    TraitSystem.dispatch(
      controller,
      const PassiveEvent(RelicTrigger.startOfTurn),
    );
    TraitSystem.dispatch(controller, const PassiveEvent(RelicTrigger.endOfTurn));

    expect(controller.currentState.activePassive, isNull);
    expect(controller.currentState.heroStats.armure, armorBefore);
  });
}
