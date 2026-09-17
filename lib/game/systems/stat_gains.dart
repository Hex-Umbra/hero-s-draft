import '../../models/entity_stats.dart';

/// La ressource qu'un gain augmente.
enum GainResource { armor, mana, attackPower, skillPower, alterationPower }

/// D'où vient un gain : l'étiquette qu'une règle peut viser — les règles de
/// classe du lot B de P-41. La Maîtrise n'en est plus une : elle agit sur le
/// passif avant qu'il ne calcule son gain (spec P-49, §6.3).
enum GainSource {
  card,
  rune,
  passive,
  relic,
  status,

  /// Montée permanente d'une stat : récompense de niveau, événement, relique
  /// de début de run et son retrait (un gain négatif) — tout ce qui passe par
  /// `applyHeroStatModifier`.
  progression,
  enemyIntent,
}

/// Un gain décrit, pas encore appliqué.
class StatGain {
  final GainResource resource;
  final int amount;
  final GainSource source;

  const StatGain(this.resource, this.amount, this.source);
}

/// Le point de passage unique des gains d'armure, de mana et de puissance
/// (spec P-41, §4.1).
///
/// Aucun code n'accorde plus lui-même un gain à ces stats : il le décrit et le
/// confie à [apply], seul endroit à savoir quelles règles s'y appliquent. Une
/// seule exception, voulue par la spec : la remontée du mana courant qui suit
/// une hausse de `maxMana`, dans `applyHeroStatModifier`. Fonction pure, sans
/// provider : le tutoriel l'appelle comme le jeu (ADR-081).
/// `test/unit/stat_gain_single_passage_test.dart` refuse toute addition écrite
/// en ligne ailleurs.
abstract final class StatGains {
  static EntityStats apply(EntityStats stats, StatGain gain) {
    return switch (gain.resource) {
      GainResource.armor => stats.copyWith(
          armure: stats.armure + gain.amount,
        ),
      GainResource.mana => stats.copyWith(
          currentMana: stats.currentMana + gain.amount,
        ),
      GainResource.attackPower => stats.copyWith(
          attackPower: stats.attackPower + gain.amount,
        ),
      GainResource.skillPower => stats.copyWith(
          skillPower: stats.skillPower + gain.amount,
        ),
      GainResource.alterationPower => stats.copyWith(
          alterationPower: stats.alterationPower + gain.amount,
        ),
    };
  }
}
