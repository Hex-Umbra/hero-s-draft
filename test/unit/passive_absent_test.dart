import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/systems/trait_system.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

void main() {
  test('un passif absent n applique aucun effet', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Un héros dont le passiveTrait ne désigne aucun passif chargé.
    const orphan = HeroData(
      id: 'orphan',
      iconPath: 'hero_paladin.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
      passiveTrait: 'inexistant',
    );

    final controller = container.read(runProvider.notifier);
    controller.startNewRun(orphan);

    final armorBefore = controller.currentState.heroStats.armure;
    TraitSystem.onTurnStart(controller);
    TraitSystem.onTurnEnd(controller);

    expect(controller.currentState.activePassive, isNull);
    expect(controller.currentState.heroStats.armure, armorBefore);
  });
}
