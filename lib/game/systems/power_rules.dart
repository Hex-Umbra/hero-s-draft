import '../../models/data/card_data.dart';
import '../../models/entity_stats.dart';
import '../../models/might_target.dart';

/// Les règles d'attribution de la Puissance (spec P-41, §7.1) : ce qu'elle
/// renforce, selon la carte qui porte l'effet et selon l'orientation que la
/// classe a déclarée.
///
/// Règle pure, sans provider : la résolution d'une carte, ses runes, le
/// tutoriel (ADR-081) et l'aperçu des dégâts lisent la même. Elle vit ici et
/// non sur `EntityStats`, partagé avec les ennemis : le modèle ne porte que
/// l'orientation.
extension PowerRules on EntityStats {
  /// Bonus ajouté aux dégâts d'un effet `damage`, selon le type de la carte
  /// qui le porte. Une carte Pouvoir ou Statut ne reçoit rien, par
  /// construction.
  int damageBonusFor(CardType type) => switch (type) {
        CardType.attack => _mightFor(MightTarget.attack),
        CardType.skill => _mightFor(MightTarget.skill),
        CardType.power || CardType.status => 0,
      };

  /// Bonus ajouté à l'intensité d'un statut posé par une carte ou par l'une
  /// de ses runes. Il ne renforce qu'un statut posé sur un ennemi — jamais sa
  /// durée, et jamais un buff posé sur soi : sans cette borne, la Puissance
  /// temporaire se nourrirait d'elle-même.
  int statusBonusFor(CardTarget target) => switch (target) {
        CardTarget.singleEnemy ||
        CardTarget.allEnemies =>
          _mightFor(MightTarget.alteration),
        CardTarget.self || CardTarget.none => 0,
      };

  /// La Puissance effective, temporaire comprise, si la classe l'oriente vers
  /// [target] ; 0 sinon.
  int _mightFor(MightTarget target) =>
      mightTargets.contains(target) ? effectiveMight : 0;
}
