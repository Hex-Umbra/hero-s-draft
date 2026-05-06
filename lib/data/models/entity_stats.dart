import '../../models/status_effect.dart';

class EntityStats {
  final int maxPv;
  final int currentPv;
  final int maxMana;
  final int currentMana;
  final int armure;
  final int attaque;
  final List<StatusEffect> statuses;

  const EntityStats({
    required this.maxPv,
    required this.currentPv,
    this.maxMana = 0,
    this.currentMana = 0,
    required this.armure,
    required this.attaque,
    this.statuses = const [],
  });

  EntityStats copyWith({
    int? maxPv,
    int? currentPv,
    int? maxMana,
    int? currentMana,
    int? armure,
    int? attaque,
    List<StatusEffect>? statuses,
  }) {
    return EntityStats(
      maxPv: maxPv ?? this.maxPv,
      currentPv: currentPv ?? this.currentPv,
      maxMana: maxMana ?? this.maxMana,
      currentMana: currentMana ?? this.currentMana,
      armure: armure ?? this.armure,
      attaque: attaque ?? this.attaque,
      statuses: statuses ?? this.statuses,
    );
  }

  /// Ajoute ou combine un effet de statut
  EntityStats addStatus(StatusEffect effect) {
    final index = statuses.indexWhere((s) => s.id == effect.id);
    List<StatusEffect> newStatuses = List.from(statuses);
    
    if (index != -1) {
      newStatuses[index] = newStatuses[index].combine(effect);
    } else {
      newStatuses.add(effect);
    }
    
    return copyWith(statuses: newStatuses);
  }

  /// Décrémente la durée des statuts et supprime ceux expirés
  EntityStats tickStatuses() {
    List<StatusEffect> newStatuses = statuses
        .map((s) => s.copyWith(duration: s.duration - 1))
        .where((s) => s.duration > 0)
        .toList();
    
    return copyWith(statuses: newStatuses);
  }

  /// Calcule l'attaque effective en prenant en compte les buffs de force
  int get effectiveAttaque {
    int bonus = 0;
    for (var status in statuses) {
      if (status.id == 'strength') {
        bonus += status.value;
      }
    }
    return attaque + bonus;
  }

  EntityStats takeDamage(int amount) {
    if (amount <= 0) return this;
    
    // 2. Absorption via Armure
    int damageAfterArmor = amount - armure;
    int newArmor = armure;
    int newPv = currentPv;

    if (damageAfterArmor > 0) {
      // L'armure est brisée, le reste va aux PV
      newArmor = 0;
      newPv -= damageAfterArmor;
    } else {
      // L'armure encaisse tout
      newArmor -= amount;
    }

    if (newPv < 0) newPv = 0;

    return copyWith(armure: newArmor, currentPv: newPv);
  }
}
