import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/inventory_state.dart';
import '../../models/data/relic_data.dart';
import 'run_controller.dart';

class InventoryController extends StateNotifier<InventoryState> {
  final Ref ref;

  InventoryController(this.ref) : super(const InventoryState());

  void gainGold(int amount) {
    state = state.copyWith(gold: state.gold + amount);
  }

  bool spendGold(int amount) {
    if (state.gold < amount) return false;
    state = state.copyWith(gold: state.gold - amount);
    return true;
  }

  void addRelic(RelicData relic) {
    state = state.copyWith(relics: [...state.relics, relic]);
    if (relic.trigger == RelicTrigger.startOfRun) {
      ref.read(runProvider.notifier).applyRelicEffect(relic);
    }
  }

  void buyShopExpansion() {
    state = state.copyWith(bonusShopCards: state.bonusShopCards + 1);
  }

  void reset({int initialGold = 50, List<RelicData> initialRelics = const [], int initialBonusShopCards = 0}) {
    state = InventoryState(
      gold: initialGold,
      relics: initialRelics,
      bonusShopCards: initialBonusShopCards,
    );
  }
}

final inventoryProvider = StateNotifierProvider<InventoryController, InventoryState>((ref) {
  return InventoryController(ref);
});
