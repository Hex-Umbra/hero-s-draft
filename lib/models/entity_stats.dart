import 'package:meta/meta.dart';
import 'status_effect.dart';

@immutable
class EntityStats {
  final int maxPv;
  final int currentPv;
  final int maxMana;
  final int currentMana;
  final int armure;
  final int armorMastery; // Bonus permanent ajouté à chaque gain d'armure
  final int attackPower; // Dégâts des cartes Attaque — la Force s'y ajoute
  final int skillPower; // Dégâts des cartes Compétence
  final int alterationPower; // Intensité des statuts posés sur un ennemi
  final int luck;
  final int level;
  final int xp;
  final int xpToNextLevel;
  final int critChance;
  final double critMultiplier;
  final List<StatusEffect> statuses;
  final bool lastActionWasCrit;

  EntityStats({
    required this.maxPv,
    required this.currentPv,
    this.maxMana = 0,
    this.currentMana = 0,
    required this.armure,
    this.armorMastery = 0,
    required this.attackPower,
    this.skillPower = 0,
    this.alterationPower = 0,
    this.luck = 0,
    this.level = 1,
    this.xp = 0,
    this.xpToNextLevel = 100,
    this.critChance = 0,
    this.critMultiplier = 1.5,
    List<StatusEffect> statuses = const [],
    this.lastActionWasCrit = false,
  }) : statuses = List.unmodifiable(statuses);

  EntityStats copyWith({
    int? maxPv,
    int? currentPv,
    int? maxMana,
    int? currentMana,
    int? armure,
    int? armorMastery,
    int? attackPower,
    int? skillPower,
    int? alterationPower,
    int? luck,
    int? level,
    int? xp,
    int? xpToNextLevel,
    int? critChance,
    double? critMultiplier,
    List<StatusEffect>? statuses,
    bool? lastActionWasCrit,
  }) {
    return EntityStats(
      maxPv: maxPv ?? this.maxPv,
      currentPv: currentPv ?? this.currentPv,
      maxMana: maxMana ?? this.maxMana,
      currentMana: currentMana ?? this.currentMana,
      armure: armure ?? this.armure,
      armorMastery: armorMastery ?? this.armorMastery,
      attackPower: attackPower ?? this.attackPower,
      skillPower: skillPower ?? this.skillPower,
      alterationPower: alterationPower ?? this.alterationPower,
      luck: luck ?? this.luck,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      critChance: critChance ?? this.critChance,
      critMultiplier: critMultiplier ?? this.critMultiplier,
      statuses: statuses ?? this.statuses,
      lastActionWasCrit: lastActionWasCrit ?? this.lastActionWasCrit,
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
      attackPower: json['attackPower'] as int,
      skillPower: json['skillPower'] as int? ?? 0,
      alterationPower: json['alterationPower'] as int? ?? 0,
      luck: json['luck'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      xpToNextLevel: json['xpToNextLevel'] as int? ?? 100,
      critChance: json['critChance'] as int? ?? 0,
      critMultiplier: (json['critMultiplier'] as num?)?.toDouble() ?? 1.5,
      statuses: parsedStatuses,
      lastActionWasCrit: json['lastActionWasCrit'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'maxPv': maxPv,
    'currentPv': currentPv,
    'maxMana': maxMana,
    'currentMana': currentMana,
    'armure': armure,
    'armorMastery': armorMastery,
    'attackPower': attackPower,
    'skillPower': skillPower,
    'alterationPower': alterationPower,
    'luck': luck,
    'level': level,
    'xp': xp,
    'xpToNextLevel': xpToNextLevel,
    'critChance': critChance,
    'critMultiplier': critMultiplier,
    'statuses': statuses.map((s) => s.toJson()).toList(),
    'lastActionWasCrit': lastActionWasCrit,
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
        .map((s) {
          if (s.id == 'freeze') {
            return s;
          }
          if (s.id == 'burn') {
            return s.copyWith(
              value: s.value - 1,
              duration: s.duration - 1,
            );
          }
          return s.copyWith(duration: s.duration - 1);
        })
        .where((s) => s.duration > 0 && (s.id != 'burn' || s.value > 0))
        .toList();

    return copyWith(statuses: newStatuses);
  }

  int get effectiveArmorMastery {
    int bonus = 0;
    for (var status in statuses) {
      if (status.id == 'armor_mastery') {
        bonus += status.value;
      }
    }
    return armorMastery + bonus;
  }

  /// Calcule l'attaque effective en prenant en compte les buffs de force
  int get effectiveAttackPower {
    int bonus = 0;
    for (var status in statuses) {
      if (status.id == 'strength') {
        bonus += status.value;
      }
    }
    return attackPower + bonus;
  }

  int get effectiveCritChance {
    int bonus = 0;
    for (var status in statuses) {
      if (status.id == 'crit_chance') {
        bonus += status.value;
      }
    }
    return critChance + bonus;
  }

  EntityStats takeDamage(int amount, {bool isCrit = false}) {
    if (amount <= 0) return copyWith(lastActionWasCrit: isCrit);

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

    return copyWith(armure: newArmor, currentPv: newPv, lastActionWasCrit: isCrit);
  }
}
