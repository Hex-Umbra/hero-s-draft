import '../../../models/data/stat_rule.dart';
import '../../../models/entity_stats.dart';
import '../../../models/status_effect.dart';
import '../../systems/stat_gains.dart';

class StatusEffectProcessor {
  /// Applique les effets de statut de début de tour sur le joueur.
  /// Retourne les nouvelles statistiques du joueur.
  ///
  /// [rules] vient de l'appelant, `RunController.startTurn` : cette méthode ne
  /// reçoit que des stats et ne peut pas les deviner (spec P-41, §4.1).
  static EntityStats processPlayerStatuses(
    EntityStats stats,
    List<StatRule> rules,
  ) {
    int poisonDamage = 0;
    int mightGain = 0;
    int armorGain = 0;

    for (var status in stats.statuses) {
      if (status.id == 'poison') {
        poisonDamage += status.value;
      } else if (status.id == 'might_regen') {
        mightGain += status.value;
      } else if (status.id == 'armor_regen') {
        armorGain += status.value;
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
          duration: 3, // 3 tours maximum pour le joueur
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
    updatedStats = updatedStats.tickStatuses();

    if (armorGain > 0) {
      updatedStats = StatGains.apply(
        updatedStats,
        StatGain(GainResource.armor, armorGain, GainSource.status),
        rules,
      );
    }

    return updatedStats;
  }

  /// Applique les effets de statut de début de tour sur un ennemi.
  /// Retourne les nouvelles statistiques de l'ennemi.
  static EntityStats processEnemyStatuses(EntityStats stats) {
    int poisonDamage = 0;
    int mightGain = 0;
    int armorGain = 0;
    int burnDamage = 0;

    for (var status in stats.statuses) {
      if (status.id == 'poison') {
        poisonDamage += status.value;
      } else if (status.id == 'might_regen') {
        mightGain += status.value;
      } else if (status.id == 'armor_regen') {
        armorGain += status.value;
      } else if (status.id == 'burn') {
        burnDamage += status.value;
      }
    }

    EntityStats updatedStats = stats;
    if (poisonDamage > 0) {
      updatedStats = updatedStats.takeDamage(poisonDamage);
    }
    if (burnDamage > 0) {
      updatedStats = updatedStats.takeDamage(burnDamage);
    }
    if (mightGain > 0) {
      updatedStats = updatedStats.addStatus(
        StatusEffect(
          id: 'might',
          name: 'Puissance',
          type: StatusType.buff,
          value: mightGain,
          duration: 1, // 1 tour maximum pour l'ennemi
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

    return updatedStats.tickStatuses();
  }
}
