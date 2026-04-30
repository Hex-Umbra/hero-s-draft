class EntityStats {
  final int maxPv;
  final int currentPv;
  final int maxMana;
  final int currentMana;
  final int armure;
  final int attaque;
  const EntityStats({
    required this.maxPv,
    required this.currentPv,
    this.maxMana = 0,
    this.currentMana = 0,
    required this.armure,
    required this.attaque,
  });

  EntityStats copyWith({
    int? maxPv,
    int? currentPv,
    int? maxMana,
    int? currentMana,
    int? armure,
    int? attaque,
  }) {
    return EntityStats(
      maxPv: maxPv ?? this.maxPv,
      currentPv: currentPv ?? this.currentPv,
      maxMana: maxMana ?? this.maxMana,
      currentMana: currentMana ?? this.currentMana,
      armure: armure ?? this.armure,
      attaque: attaque ?? this.attaque,
    );
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
