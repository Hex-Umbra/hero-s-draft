import '../../models/entity_stats.dart';

/// Les ressources qu'une carte peut coûter (D40).
enum CostResource { mana, hp, armor }

/// La règle d'accessibilité des coûts combinés (D40 ; spec P-42 T1 et P-44
/// lot 1, §4.1, A10) : la seule écriture des trois bornes.
/// `EffectResolver.canAfford` la lit pour une carte ;
/// `PlayerStatsManager.consumeResource` avant de débiter.
extension CostRules on EntityStats {
  /// Vrai si le héros peut payer [mana], [hp] et [armor] : le mana courant ;
  /// des PV **strictement** supérieurs au coût en PV — une carte ne tue jamais
  /// son porteur ; une Armure au moins égale au coût en Armure.
  bool canPay({int mana = 0, int hp = 0, int armor = 0}) =>
      currentMana >= mana && (hp == 0 || currentPv > hp) && armure >= armor;

  /// Les ressources dont **sa** borne de [canPay] échoue, une à la fois : la
  /// face Flame passe en rouge celle qui manque.
  Set<CostResource> missingFor({int mana = 0, int hp = 0, int armor = 0}) => {
        if (!canPay(mana: mana)) CostResource.mana,
        if (!canPay(hp: hp)) CostResource.hp,
        if (!canPay(armor: armor)) CostResource.armor,
      };
}
