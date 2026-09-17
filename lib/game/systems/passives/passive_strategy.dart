import '../../../models/card_instance.dart';
import '../../../models/data/passive_data.dart';
import '../../../models/data/relic_data.dart';
import '../../controllers/run_controller.dart';

/// Ce qui déclenche un passif : le moment, et la carte jouée s'il y en a une.
class PassiveEvent {
  final RelicTrigger trigger;

  /// Renseignée pour `onCardPlayed`, `null` sinon.
  final CardInstance? card;

  const PassiveEvent(this.trigger, {this.card});
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
