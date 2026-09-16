import '../controllers/run_controller.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../../models/data/relic_data.dart';
import 'stat_gains.dart';

class TraitSystem {
  /// Appelé au début du tour du joueur
  static void onTurnStart(RunController controller) {
    final passive = controller.currentState.activePassive;
    if (passive == null) return;
    final stats = controller.currentState.heroStats;

    if (passive.trigger == RelicTrigger.startOfTurn) {
      if (passive.effectType == 'berserker_armor') {
        // Gagne X d'Armure (+Maîtrise) pour chaque tranche de 10 PV manquants
        final missingHp = stats.maxPv - stats.currentPv;
        final multiplier = missingHp ~/ 10;
        final armorGain = multiplier * passive.value;
        if (armorGain > 0) {
          controller.grant(
            StatGain(GainResource.armor, armorGain, GainSource.passive),
          );
        }
      } else if (passive.effectType == 'gain_armor') {
        controller.grant(
          StatGain(GainResource.armor, passive.value, GainSource.passive),
        );
      }
    }
  }

  /// Appelé à la fin du tour du joueur
  static void onTurnEnd(RunController controller) {
    final passive = controller.currentState.activePassive;
    if (passive == null) return;

    if (passive.trigger == RelicTrigger.endOfTurn) {
      if (passive.effectType == 'gain_armor') {
        controller.grant(
          StatGain(GainResource.armor, passive.value, GainSource.passive),
        );
      }
    }
  }

  /// Appelé lorsqu'une carte est jouée avec succès
  static void onCardPlayed(RunController controller, CardInstance card) {
    final passive = controller.currentState.activePassive;
    if (passive == null) return;

    if (passive.trigger == RelicTrigger.onCardPlayed) {
      if (passive.effectType == 'spell_armor') {
        if (card.data.type == CardType.skill) {
          controller.grant(
            StatGain(GainResource.armor, passive.value, GainSource.passive),
          );
        }
      }
    }
  }
}
