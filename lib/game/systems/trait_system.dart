import '../controllers/run_controller.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../../models/data/relic_data.dart';
import '../../models/data/passive_data.dart';

class TraitSystem {
  /// Appelé au début du tour du joueur
  static void onTurnStart(RunController controller) {
    final passive =
        controller.currentState.activePassive ??
        PassiveData.fallback(controller.currentState.passiveTrait ?? '');
    final stats = controller.currentState.heroStats;

    if (passive.trigger == RelicTrigger.startOfTurn) {
      if (passive.effectType == 'berserker_armor') {
        // Gagne X d'Armure (+Maîtrise) pour chaque tranche de 10 PV manquants
        final missingHp = stats.maxPv - stats.currentPv;
        final multiplier = missingHp ~/ 10;
        final armorGain = multiplier * passive.value;
        if (armorGain > 0) {
          controller.setHeroStats(
            armure: stats.armure + armorGain + stats.effectiveArmorMastery,
          );
        }
      } else if (passive.effectType == 'gain_armor') {
        controller.setHeroStats(
          armure: stats.armure + passive.value + stats.effectiveArmorMastery,
        );
      }
    }
  }

  /// Appelé à la fin du tour du joueur
  static void onTurnEnd(RunController controller) {
    final passive =
        controller.currentState.activePassive ??
        PassiveData.fallback(controller.currentState.passiveTrait ?? '');
    final stats = controller.currentState.heroStats;

    if (passive.trigger == RelicTrigger.endOfTurn) {
      if (passive.effectType == 'gain_armor') {
        controller.setHeroStats(
          armure: stats.armure + passive.value + stats.effectiveArmorMastery,
        );
      }
    }
  }

  /// Appelé lorsqu'une carte est jouée avec succès
  static void onCardPlayed(RunController controller, CardInstance card) {
    final passive =
        controller.currentState.activePassive ??
        PassiveData.fallback(controller.currentState.passiveTrait ?? '');
    final stats = controller.currentState.heroStats;

    if (passive.trigger == RelicTrigger.onCardPlayed) {
      if (passive.effectType == 'spell_armor') {
        if (card.data.type == CardType.skill) {
          controller.setHeroStats(
            armure: stats.armure + passive.value + stats.effectiveArmorMastery,
          );
        }
      }
    }
  }
}
