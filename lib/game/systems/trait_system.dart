import '../controllers/run_controller.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';

class TraitSystem {
  /// Appelé au début du tour du joueur
  static void onTurnStart(RunController controller) {
    final trait = controller.currentState.passiveTrait;
    final stats = controller.currentState.heroStats;
    if (trait == 'berserkerArmor') {
      // Gagne 1 d'Armure (+Maîtrise) pour chaque tranche de 10 PV manquants
      final missingHp = stats.maxPv - stats.currentPv;
      int armorGain = missingHp ~/ 10;
      if (armorGain > 0) {
        controller.setHeroStats(armure: stats.armure + armorGain + stats.armorMastery);
      }
    }
  }

  /// Appelé à la fin du tour du joueur
  static void onTurnEnd(RunController controller) {
    final trait = controller.currentState.passiveTrait;
    if (trait == 'regenArmor') {
      // Gagne 2 d'Armure (+Maîtrise) à la fin de chaque tour
      final stats = controller.currentState.heroStats;
      controller.setHeroStats(armure: stats.armure + 2 + stats.armorMastery);
    }
  }

  /// Appelé lorsqu'une carte est jouée avec succès
  static void onCardPlayed(RunController controller, CardInstance card) {
    final trait = controller.currentState.passiveTrait;
    if (trait == 'spellArmor') {
      // Gagne 1 d'Armure (+Maîtrise) chaque fois que vous jouez une carte Compétence (Skill)
      if (card.data.type == CardType.skill) {
        final stats = controller.currentState.heroStats;
        controller.setHeroStats(armure: stats.armure + 1 + stats.armorMastery);
      }
    }
  }
}
