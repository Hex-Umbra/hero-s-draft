import 'dart:math';

import '../../../models/data/charge_data.dart';
import '../../../models/data/stat_rule.dart';
import '../../../models/entity_stats.dart';
import '../../../models/status_effect.dart';
import '../../systems/charge_rules.dart';
import '../../systems/stat_gains.dart';

class StatusEffectProcessor {
  /// Applique les effets de statut de début de tour sur le joueur.
  /// Retourne les nouvelles statistiques du joueur.
  ///
  /// L'ordre est celui de la spec P-53, §4.10 : son Feu d'abord, puis le
  /// Poison, l'Éveil, le tic, la Métallisation, la Source de Mana et la Source
  /// de Vie, puis les déclins ; un gel en attente devient enfin actif.
  ///
  /// [rules] vient de l'appelant, `RunController.startTurn` : cette méthode ne
  /// reçoit que des stats et ne peut pas les deviner (spec P-41, §4.1).
  static EntityStats processPlayerStatuses(
    EntityStats stats,
    List<StatRule> rules,
    ChargeCatalog charges,
  ) {
    final burned = ChargeRules.resolveOwnFire(stats, charges);
    int poisonDamage = 0;
    int mightGain = 0;
    int armorGain = 0;
    int manaGain = 0;
    int hpGain = 0;

    for (var status in burned.statuses) {
      if (status.id == 'poison') {
        poisonDamage += status.value;
      } else if (status.id == 'might_regen') {
        mightGain += status.value;
      } else if (status.id == 'armor_regen') {
        armorGain += status.value;
      } else if (status.id == 'mana_regen') {
        manaGain += status.value;
      } else if (status.id == 'hp_regen') {
        hpGain += status.value;
      }
    }

    EntityStats updatedStats = burned;
    if (poisonDamage > 0) {
      updatedStats = updatedStats.takeDamage(poisonDamage);
    }
    if (mightGain > 0) {
      updatedStats = updatedStats.addStatus(
        StatusEffect(
          id: 'might',
          name: 'Puissance',
          type: StatusType.buff,
          value: mightGain,
          duration: 3, // 3 tours maximum pour le joueur
          // Le même statut pose à chaque tour : sa Puissance s'additionne
          // comme avant, sans rejoindre celle d'une carte (spec P-43 E0, A2).
          sourceId: StatusSource.status('might_regen'),
        ),
      );
    }
    // La conversion de `armor_regen` en Puissance temporaire a lieu plus bas,
    // après ce tic (bloc `armorGain` ci-dessous) : la Puissance qu'elle crée
    // ne vient donc jamais d'être vieillie le tour même de sa naissance
    // (spec P-41, §7.2).
    //
    // La Puissance issue de `might_regen`, elle, est créée juste au-dessus,
    // avant ce même tic, et **est** vieillie par lui (3 → 2 tours) : c'est
    // délibéré, pour préserver le comportement préexistant de `might_regen`,
    // et non une conséquence du même principe que l'armure. Ne pas aligner
    // `might_regen` sur `armor_regen` sans rouvrir cette décision.
    updatedStats = updatedStats.tickStatuses(charges.ids);

    if (armorGain > 0) {
      updatedStats = StatGains.apply(
        updatedStats,
        StatGain(GainResource.armor, armorGain, GainSource.status),
        rules,
      );
    }
    if (manaGain > 0) {
      updatedStats = StatGains.apply(
        updatedStats,
        StatGain(GainResource.mana, manaGain, GainSource.status),
        rules,
      );
    }
    updatedStats = _heal(updatedStats, hpGain);

    return ChargeRules.startBearerTurn(
      ChargeRules.decay(updatedStats, charges),
    );
  }

  /// Applique les effets de statut de début de tour sur un ennemi, après la
  /// chaîne du Feu (spec P-53, A10) : Poison, Éveil, Métallisation, le tic,
  /// la Source de Vie, puis les déclins. Retourne les nouvelles statistiques de
  /// l'ennemi.
  static EntityStats processEnemyStatuses(
    EntityStats stats,
    ChargeCatalog charges,
  ) {
    int poisonDamage = 0;
    int mightGain = 0;
    int armorGain = 0;
    int hpGain = 0;

    for (var status in stats.statuses) {
      if (status.id == 'poison') {
        poisonDamage += status.value;
      } else if (status.id == 'might_regen') {
        mightGain += status.value;
      } else if (status.id == 'armor_regen') {
        armorGain += status.value;
      } else if (status.id == 'hp_regen') {
        hpGain += status.value;
      }
    }

    EntityStats updatedStats = stats;
    if (poisonDamage > 0) {
      updatedStats = updatedStats.takeDamage(poisonDamage);
    }
    if (mightGain > 0) {
      updatedStats = updatedStats.addStatus(
        StatusEffect(
          id: 'might',
          name: 'Puissance',
          type: StatusType.buff,
          value: mightGain,
          duration: 1, // 1 tour maximum pour l'ennemi
          // Une entrée à part, que le tic final ci-dessous retire dans
          // l'appel même qui la crée : elle ne rejoint plus la Puissance de
          // l'intention Buff (spec P-43 E0, §4.3 ; ADR-097).
          sourceId: StatusSource.status('might_regen'),
        ),
      );
    }
    if (armorGain > 0) {
      updatedStats = StatGains.apply(
        updatedStats,
        StatGain(GainResource.armor, armorGain, GainSource.status),
        // Un ennemi ne porte aucune règle de classe : il ne joue pas de carte
        // et n'a pas d'identité à orienter (spec P-41, §7.1).
        const [],
      );
    }

    updatedStats = _heal(updatedStats.tickStatuses(charges.ids), hpGain);

    return ChargeRules.decay(updatedStats, charges);
  }

  /// Rend [amount] PV au porteur, bornés à ses PV max. Un porteur à 0 PV n'est
  /// pas relevé : le Poison ou le Feu du même début de tour vient de le tuer.
  /// Ni `StatGains`, ni critique, ni vol de vie (spec P-42 tranche 3, A6).
  static EntityStats _heal(EntityStats stats, int amount) {
    if (amount <= 0 || stats.currentPv <= 0) return stats;
    return stats.copyWith(
      currentPv: min(stats.maxPv, stats.currentPv + amount),
    );
  }
}
