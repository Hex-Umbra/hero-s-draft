import '../../../models/data/card_data.dart';
import '../../../models/data/passive_data.dart';
import '../../../models/status_effect.dart';
import '../../controllers/deck_controller.dart';
import '../../controllers/run_controller.dart';
import '../../game_constants.dart';
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

/// `rage` : `value` de Puissance temporaire, plus `value` par tranche de 10 PV
/// manquants.
///
/// La formule de `berserker_armor`, que ce passif remplace, redirigée vers la
/// Puissance — avec le plancher qui corrige son défaut de diagnostic
/// (spec §6.3) : à pleine vie, le passif n'est plus muet.
class RagePassive extends PassiveStrategy {
  const RagePassive();

  /// Les PV manquants qu'il faut pour une tranche. Valeur d'équilibrage,
  /// reprise de `berserker_armor`.
  static const int _pvPerTranche = 10;

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    final stats = run.currentState.heroStats;
    final tranches = (stats.maxPv - stats.currentPv) ~/ _pvPerTranche;
    run.addStatus(
      _temporaryMight(passive.value * (1 + tranches), passive.duration),
    );
  }
}

/// `bloodthirst` : jouer une Attaque arme le Vol de vie pour `duration` tours,
/// d'autant plus fort que les PV sont bas.
///
/// Le passif crée la **source** du statut ; son **hook** de soin vit dans
/// `DamageEffectStrategy` (spec §1.2). La première Attaque du tour arme, les
/// suivantes drainent.
class BloodthirstPassive extends PassiveStrategy {
  const BloodthirstPassive();

  /// Le pourcentage de PV manquants qui vaut un point de plus. En pourcentage
  /// et non en PV absolus : les trois classes n'ont pas le même maximum.
  static const int _percentPerStep = 25;

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    final stats = run.currentState.heroStats;
    final missingPercent =
        (stats.maxPv - stats.currentPv) * 100 ~/ stats.maxPv;
    run.applyLifestealBuff(
      value: passive.value + missingPercent ~/ _percentPerStep,
      duration: passive.duration,
    );
  }
}

/// `frenzy` : chaque ennemi abattu donne `value` de Puissance temporaire et
/// fait piocher `draw` cartes.
///
/// Déclenché une fois par ennemi (`CombatController.cleanDeadEnemies`) : c'est
/// ce qui en fait une boule de neige (spec §6.3).
class FrenzyPassive extends PassiveStrategy {
  const FrenzyPassive();

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    run.addStatus(_temporaryMight(passive.value, passive.duration));
    if (passive.draw > 0) {
      run.ref
          .read(deckProvider.notifier)
          .drawCards(passive.draw, maxHandSize: GameConstants.maxHandSize);
    }
  }
}

/// La table `effectType` → stratégie. Une table de code, constante, pas un
/// état : un passif du lot B de P-41 y ajoute une ligne et une classe.
abstract final class PassiveStrategies {
  static const Map<String, PassiveStrategy> byEffectType = {
    'gain_armor': GainArmorPassive(),
    'spell_armor': SpellArmorPassive(),
    // Paladin (spec P-41, §6.3)
    'fervor': FervorPassive(),
    'blessing': BlessingPassive(),
    // Berserker
    'rage': RagePassive(),
    'bloodthirst': BloodthirstPassive(),
    'frenzy': FrenzyPassive(),
  };
}
