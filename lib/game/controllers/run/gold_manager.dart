import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../inventory_controller.dart';
import '../run_controller.dart';

class GoldManager {
  final RunController controller;
  final Ref ref;

  GoldManager(this.controller, this.ref);

  /// Achète un slot de forge bonus si possible. Retourne true si l'achat a réussi.
  bool buyBonusForgeSlot() {
    if (controller.currentState.bonusForgeSlots >= 4) return false;
    final costs = [50, 80, 120, 175];
    final cost = costs[controller.currentState.bonusForgeSlots];
    final success = ref.read(inventoryProvider.notifier).spendGold(cost);
    if (!success) return false;

    controller.updateState(
      controller.currentState.copyWith(
        bonusForgeSlots: controller.currentState.bonusForgeSlots + 1,
      ),
    );
    return true;
  }
}
