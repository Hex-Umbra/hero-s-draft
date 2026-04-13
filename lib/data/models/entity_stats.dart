class EntityStats {
  final int maxPv;
  final int currentPv;
  final int armure;
  final int attaque;
  final double defense; // Réduction en % (ex: 0.1 pour 10%)

  const EntityStats({
    required this.maxPv,
    required this.currentPv,
    required this.armure,
    required this.attaque,
    required this.defense,
  });

  EntityStats copyWith({
    int? maxPv,
    int? currentPv,
    int? armure,
    int? attaque,
    double? defense,
  }) {
    return EntityStats(
      maxPv: maxPv ?? this.maxPv,
      currentPv: currentPv ?? this.currentPv,
      armure: armure ?? this.armure,
      attaque: attaque ?? this.attaque,
      defense: defense ?? this.defense,
    );
  }

  EntityStats takeDamage(int amount) {
    if (amount <= 0) return this;
    
    // 1. Réduction via la Défense : Formule -> Dégâts finaux = (Attaque - Défense) absorbés par Armure puis PV
    int damageAfterDefense = (amount * (1.0 - defense)).round();
    if (damageAfterDefense <= 0) return this;

    // 2. Absorption via Armure
    int damageAfterArmor = damageAfterDefense - armure;
    int newArmor = armure;
    int newPv = currentPv;

    if (damageAfterArmor > 0) {
      // L'armure est brisée, le reste va aux PV
      newArmor = 0;
      newPv -= damageAfterArmor;
    } else {
      // L'armure encaisse tout
      newArmor -= damageAfterDefense;
    }

    if (newPv < 0) newPv = 0;

    return copyWith(armure: newArmor, currentPv: newPv);
  }
}
