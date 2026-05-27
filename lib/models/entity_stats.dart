import 'status_effect.dart';

class EntityStats {
  final int maxPv;
  final int currentPv;
  final int maxMana;
  final int currentMana;
  final int armure;
  final int armorMastery; // Bonus permanent ajouté à chaque gain d'armure
  final int attaque;
  final int luck;
  final List<StatusEffect> statuses;

  const EntityStats({
    required this.maxPv,
    required this.currentPv,
    this.maxMana = 0,
    this.currentMana = 0,
    required this.armure,
    this.armorMastery = 0,
    required this.attaque,
    this.luck = 0,
    this.statuses = const [],
  });

  EntityStats copyWith({
    int? maxPv,
    int? currentPv,
    int? maxMana,
    int? currentMana,
    int? armure,
    int? armorMastery,
    int? attaque,
    int? luck,
    List<StatusEffect>? statuses,
  }) {
    return EntityStats(
      maxPv: maxPv ?? this.maxPv,
      currentPv: currentPv ?? this.currentPv,
      maxMana: maxMana ?? this.maxMana,
      currentMana: currentMana ?? this.currentMana,
      armure: armure ?? this.armure,
      armorMastery: armorMastery ?? this.armorMastery,
      attaque: attaque ?? this.attaque,
      luck: luck ?? this.luck,
      statuses: statuses ?? this.statuses,
    );
  }

  factory EntityStats.fromJson(Map<String, dynamic> json) {
    var statusesJson = json['statuses'] as List?;
    List<StatusEffect> parsedStatuses = [];
    if (statusesJson != null) {
      parsedStatuses = statusesJson
          .map((e) => StatusEffect.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return EntityStats(
      maxPv: json['maxPv'] as int,
      currentPv: json['currentPv'] as int,
      maxMana: json['maxMana'] as int? ?? 0,
      currentMana: json['currentMana'] as int? ?? 0,
      armure: json['armure'] as int,
      armorMastery: json['armorMastery'] as int? ?? 0,
      attaque: json['attaque'] as int,
      luck: json['luck'] as int? ?? 0,
      statuses: parsedStatuses,
    );
  }

  Map<String, dynamic> toJson() => {
        'maxPv': maxPv,
        'currentPv': currentPv,
        'maxMana': maxMana,
        'currentMana': currentMana,
        'armure': armure,
        'armorMastery': armorMastery,
        'attaque': attaque,
        'luck': luck,
        'statuses': statuses.map((s) => s.toJson()).toList(),
      };

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
