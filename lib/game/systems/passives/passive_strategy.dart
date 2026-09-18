import '../../../models/card_instance.dart';
import '../../../models/data/passive_data.dart';
import '../../../models/data/relic_data.dart';
import '../../controllers/run_controller.dart';

/// Ce qui déclenche un passif : le moment, et ce que ce moment seul sait.
///
/// Une charge utile plutôt qu'une lecture par la stratégie, à chaque fois pour
/// la même raison : la valeur n'existe plus quand la stratégie s'exécute.
/// L'armure survivante a été remise à zéro, les dégâts encaissés ont été
/// absorbés, et la cible d'une carte n'est connue que de l'écran de combat.
class PassiveEvent {
  final RelicTrigger trigger;

  /// Renseignée pour `onCardPlayed` et les déclencheurs par type de carte,
  /// `null` sinon.
  final CardInstance? card;

  /// L'ennemi que visait la carte jouée, `null` s'il n'y en avait pas ou si la
  /// carte visait tout le monde.
  final String? enemyId;

  /// Ce que l'armure a réellement absorbé, pour `onDamageTaken`. Jamais
  /// renseigné pour des dégâts qui sont allés droit aux PV.
  final int? absorbedDamage;

  /// L'armure que le tour précédent a laissée, capturée par `startTurn` avant
  /// sa remise à zéro (spec §1.1, §6.3).
  final int? survivingArmor;

  const PassiveEvent(
    this.trigger, {
    this.card,
    this.enemyId,
    this.absorbedDamage,
    this.survivingArmor,
  });
}

/// L'effet d'un `effectType` de passif (spec P-49, §5.1), sur le modèle des
/// effets de cartes (ADR-061).
///
/// `TraitSystem.dispatch` n'appelle une stratégie qu'une fois le déclencheur
/// vérifié : elle n'a pas à le tester.
abstract class PassiveStrategy {
  const PassiveStrategy();

  void resolve(PassiveData passive, PassiveEvent event, RunController run);
}
