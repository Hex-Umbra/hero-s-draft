import '../../../models/data/card_data.dart';
import '../../../models/data/passive_data.dart';
import '../../controllers/run_controller.dart';
import '../stat_gains.dart';
import 'passive_strategy.dart';

/// `gain_armor` : accorde `value` d'armure.
class GainArmorPassive extends PassiveStrategy {
  const GainArmorPassive();

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    run.grant(StatGain(GainResource.armor, passive.value, GainSource.passive));
  }
}

/// `berserker_armor` : `value` d'armure par tranche de 10 PV manquants, rien à
/// pleine vie.
class BerserkerArmorPassive extends PassiveStrategy {
  const BerserkerArmorPassive();

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    final stats = run.currentState.heroStats;
    final tranches = (stats.maxPv - stats.currentPv) ~/ 10;
    final armorGain = tranches * passive.value;
    if (armorGain > 0) {
      run.grant(StatGain(GainResource.armor, armorGain, GainSource.passive));
    }
  }
}

/// `spell_armor` : accorde `value` d'armure quand la carte jouée est une
/// Compétence.
class SpellArmorPassive extends PassiveStrategy {
  const SpellArmorPassive();

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    if (event.card?.data.type == CardType.skill) {
      run.grant(
        StatGain(GainResource.armor, passive.value, GainSource.passive),
      );
    }
  }
}

/// La table `effectType` → stratégie. Une table de code, constante, pas un
/// état : un passif du lot B de P-41 y ajoute une ligne et une classe.
abstract final class PassiveStrategies {
  static const Map<String, PassiveStrategy> byEffectType = {
    'gain_armor': GainArmorPassive(),
    'berserker_armor': BerserkerArmorPassive(),
    'spell_armor': SpellArmorPassive(),
  };
}
