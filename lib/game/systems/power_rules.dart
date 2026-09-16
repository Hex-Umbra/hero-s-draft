import '../../models/data/card_data.dart';
import '../../models/entity_stats.dart';

/// Les règles d'attribution des trois puissances (spec P-41, §4.2) : quelle
/// puissance renforce quel effet, selon la carte qui le porte.
///
/// Règle pure, sans provider : la résolution d'une carte, ses runes, le
/// tutoriel (ADR-081) et l'aperçu des dégâts lisent la même. Elle vit ici et
/// non sur `EntityStats`, partagé avec les ennemis, qui n'en ont pas l'usage.
extension PowerRules on EntityStats {
  /// Bonus ajouté aux dégâts d'un effet `damage`, selon le type de la carte
  /// qui le porte. La Force ne renforce que les cartes Attaque ; une carte
  /// Pouvoir ou Statut ne reçoit rien, par construction.
  int damageBonusFor(CardType type) => switch (type) {
        CardType.attack => effectiveAttackPower,
        CardType.skill => skillPower,
        CardType.power || CardType.status => 0,
      };

  /// Bonus ajouté à l'intensité d'un statut posé par une carte ou par l'une
  /// de ses runes. La puissance d'altération ne renforce qu'un statut posé sur
  /// un ennemi — jamais sa durée, et jamais un buff posé sur soi : sans cette
  /// borne, la Force scalerait avec elle et l'altération se bouclerait.
  int statusBonusFor(CardTarget target) => switch (target) {
        CardTarget.singleEnemy || CardTarget.allEnemies => alterationPower,
        CardTarget.self || CardTarget.none => 0,
      };
}
