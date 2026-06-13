import '../../../models/entity_stats.dart';
import '../../../models/status_effect.dart';

class StatusEffectProcessor {
  /// Applique les effets de statut de début de tour sur le joueur.
  /// Retourne les nouvelles statistiques du joueur.
  static EntityStats processPlayerStatuses(EntityStats stats) {
    int poisonDamage = 0;
    int strengthGain = 0;
    int armorGain = 0;

    for (var status in stats.statuses) {
      if (status.id == 'poison') {
        poisonDamage += status.value;
      } else if (status.id == 'strength_regen') {
        strengthGain += status.value;
      } else if (status.id == 'armor_regen') {
        armorGain += status.value;
      }
    }

    EntityStats updatedStats = stats;
    if (poisonDamage > 0) {
      updatedStats = updatedStats.takeDamage(poisonDamage);
    }
    if (strengthGain > 0) {
      updatedStats = updatedStats.addStatus(
        StatusEffect(
          id: 'strength',
          name: 'Attaque',
          type: StatusType.buff,
          value: strengthGain,
          duration: 3, // 3 tours maximum pour le joueur
        ),
      );
    }
    if (armorGain > 0) {
      updatedStats = updatedStats.copyWith(
        armure: updatedStats.armure + armorGain,
      );
    }

    return updatedStats.tickStatuses();
  }

  /// Applique les effets de statut de début de tour sur un ennemi.
  /// Retourne les nouvelles statistiques de l'ennemi.
  static EntityStats processEnemyStatuses(EntityStats stats) {
    int poisonDamage = 0;
    int strengthGain = 0;
    int armorGain = 0;
    int burnDamage = 0;

    for (var status in stats.statuses) {
      if (status.id == 'poison') {
        poisonDamage += status.value;
      } else if (status.id == 'strength_regen') {
        strengthGain += status.value;
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
    if (strengthGain > 0) {
      updatedStats = updatedStats.addStatus(
        StatusEffect(
          id: 'strength',
          name: 'Attaque',
          type: StatusType.buff,
          value: strengthGain,
          duration: 1, // 1 tour maximum pour l'ennemi
        ),
      );
    }
    if (armorGain > 0) {
      updatedStats = updatedStats.copyWith(
        armure: updatedStats.armure + armorGain,
      );
    }

    return updatedStats.tickStatuses();
  }
}
