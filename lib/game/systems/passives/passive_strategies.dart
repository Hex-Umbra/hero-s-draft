import '../../../models/data/card_data.dart';
import '../../../models/data/passive_data.dart';
import '../../../models/status_effect.dart';
import '../../controllers/run_controller.dart';
import '../stat_gains.dart';
import 'passive_strategy.dart';

/// La Puissance temporaire qu'un passif accorde. Le nom est celui que voient
/// le panneau des statuts et la carte du héros ; l'identifiant `might` est ce
/// que lit `effectiveMight`.
StatusEffect _temporaryMight(int value, int duration) => StatusEffect(
      id: 'might',
      name: 'Puissance',
      type: StatusType.buff,
      value: value,
      duration: duration,
    );

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

/// `fervor` : l'armure qui encaisse des dégâts octroie `value` de Puissance
/// temporaire, pendant `duration` tours.
///
/// Chez le Paladin, encaisser devient une ressource offensive : il tape parce
/// qu'il tient, là où le Berserker tape parce qu'il meurt (spec §6.3). Le gain
/// est temporaire, comme l'exige R5 (§7.2) : l'armure est éphémère.
class FervorPassive extends PassiveStrategy {
  const FervorPassive();

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    if ((event.absorbedDamage ?? 0) <= 0) return;
    run.addStatus(_temporaryMight(passive.value, passive.duration));
  }
}

/// `blessing` : chaque tranche de 5 points d'armure survivante devient `value`
/// PV.
///
/// L'armure est remise à zéro au début de chaque tour (spec §1.1) : la valeur
/// vient de `PassiveEvent.survivingArmor`, que `RunController.startTurn`
/// capture avant cette remise à zéro. La stratégie ne lit donc jamais
/// `heroStats.armure`, qui vaut 0 quand elle s'exécute.
class BlessingPassive extends PassiveStrategy {
  const BlessingPassive();

  /// L'armure qu'il faut pour une tranche. Valeur d'équilibrage : les gains
  /// d'armure du jeu vont de 5 à 15 points.
  static const int _armorPerTranche = 5;

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    final tranches = (event.survivingArmor ?? 0) ~/ _armorPerTranche;
    if (tranches <= 0) return;
    // `heal` borne déjà le résultat aux PV max.
    run.heal(tranches * passive.value);
  }
}

/// La table `effectType` → stratégie. Une table de code, constante, pas un
/// état : un passif du lot B de P-41 y ajoute une ligne et une classe.
abstract final class PassiveStrategies {
  static const Map<String, PassiveStrategy> byEffectType = {
    'gain_armor': GainArmorPassive(),
    'berserker_armor': BerserkerArmorPassive(),
    'spell_armor': SpellArmorPassive(),
    // Paladin (spec P-41, §6.3)
    'fervor': FervorPassive(),
    'blessing': BlessingPassive(),
  };
}
