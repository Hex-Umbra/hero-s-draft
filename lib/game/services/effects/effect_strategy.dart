import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/card_instance.dart';
import '../../../models/data/card_data.dart';
import '../../controllers/run_controller.dart';
import '../../controllers/deck_controller.dart';
import '../../controllers/combat_controller.dart';
import 'strategies.dart';

abstract class EffectStrategy {
  void resolve({
    required CardInstance card,
    required CardEffect effect,
    required int scaledValue,
    required RunController runController,
    required DeckNotifier deckController,
    required CombatController combatController,
    required String? selectedEnemyId,
  });
}

class EffectRegistry {
  final Map<String, EffectStrategy> _strategies = {};

  void register(String type, EffectStrategy strategy) {
    _strategies[type] = strategy;
  }

  EffectStrategy? get(String type) {
    return _strategies[type];
  }
}

final effectRegistryProvider = Provider<EffectRegistry>((ref) {
  final registry = EffectRegistry();
  registry.register('damage', DamageEffectStrategy());
  registry.register('heal', HealEffectStrategy());
  registry.register('armor', ArmorEffectStrategy());
  registry.register('gain_mana', GainManaEffectStrategy());
  registry.register('draw', DrawEffectStrategy());
  registry.register('apply_status', ApplyStatusEffectStrategy());
  return registry;
});

