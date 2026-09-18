import '../../../models/data/passive_data.dart';
import '../../../models/status_effect.dart';
import '../../controllers/combat_controller.dart';
import '../../controllers/deck_controller.dart';
import '../../controllers/run_controller.dart';
import '../../game_constants.dart';
import '../../services/effect_resolver.dart';
import '../stat_gains.dart';
import 'passive_counters.dart';
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

/// `channeling` : à la fin du tour, chaque point de mana non dépensé devient
/// `value` d'armure.
///
/// Le mana n'est pas consommé : il est remis au maximum au début du tour
/// suivant de toute façon. Le coût du passif est de **ne pas avoir joué**
/// (spec §6.3) — l'exact opposé de `mana_flux`, et c'est voulu.
class ChannelingPassive extends PassiveStrategy {
  const ChannelingPassive();

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    final mana = run.currentState.heroStats.currentMana;
    if (mana <= 0) return;
    run.grant(
      StatGain(GainResource.armor, mana * passive.value, GainSource.passive),
    );
  }
}

/// `mage_mark` : la première Attaque de chaque tour rend sa cible
/// `vulnerable`, pendant `duration` tours.
///
/// Première source de `vulnerable` du jeu : le statut était pleinement
/// consommé par `DamagePipeline` sans qu'aucune donnée ne l'applique
/// (spec §6.3). Le passif ne dépend d'aucune carte : R4 est satisfaite dès
/// aujourd'hui.
///
/// L'intensité n'est pas lue par le pipeline, qui applique `vulnerable` en
/// tout ou rien (+50 %) : c'est la **durée** qui grandit avec la Maîtrise, et
/// `value` reste l'intensité pour le jour où le pipeline la lira.
class MageMarkPassive extends PassiveStrategy {
  const MageMarkPassive();

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    final enemyId = event.enemyId;
    if (enemyId == null) return;

    final combat = run.ref.read(combatProvider.notifier);
    final index =
        combat.currentState.enemies.indexWhere((e) => e.id == enemyId);
    // La cible peut être morte de la carte qui vient d'être jouée, ou d'une
    // sélection restée en place au-delà de sa mort : dans les deux cas, la
    // marque ne peut pas s'appliquer, et le compteur ne doit donc pas être
    // consommé sur rien (finding 3 de la revue finale).
    if (index == -1) return;

    if (PassiveCounters.bump(run, passive, scope: CounterScope.turn) > 1) {
      return;
    }

    final status = EffectResolver.createStatus(
      'vulnerable',
      passive.value,
      passive.duration,
    );
    if (status == null) return;

    combat.updateEnemyStats(
      enemyId,
      combat.currentState.enemies[index].stats.addStatus(status),
    );
  }
}

/// `mana_flux` : toutes les `threshold` Compétences jouées dans un combat,
/// `value` de mana pour le tour en cours.
class ManaFluxPassive extends PassiveStrategy {
  const ManaFluxPassive();

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    // La Maîtrise fait baisser le seuil (`perPoint` négatif) : le borner est
    // l'affaire de la stratégie qui le lit (spec P-49, §6.2). Une Compétence
    // sur une, jamais moins.
    final threshold = passive.threshold < 1 ? 1 : passive.threshold;
    final count =
        PassiveCounters.bump(run, passive, scope: CounterScope.combat);
    if (count < threshold) return;

    PassiveCounters.clear(run, passive);
    run.grant(StatGain(GainResource.mana, passive.value, GainSource.passive));
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
    // Paladin (spec P-41, §6.3)
    'fervor': FervorPassive(),
    'blessing': BlessingPassive(),
    // Berserker
    'rage': RagePassive(),
    'bloodthirst': BloodthirstPassive(),
    'frenzy': FrenzyPassive(),
    // Mage
    'channeling': ChannelingPassive(),
    'mage_mark': MageMarkPassive(),
    'mana_flux': ManaFluxPassive(),
  };
}
