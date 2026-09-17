import '../../models/entity_stats.dart';

/// La ressource qu'un gain augmente.
enum GainResource { armor, mana, attackPower, skillPower, alterationPower }

/// D'où vient un gain. C'est ce qui permet à une règle de ne viser qu'une
/// provenance : la Maîtrise d'Armure ne s'ajoute qu'aux gains `passive`.
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
          armure: stats.armure + gain.amount + _masteryFor(stats, gain),
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

  /// La Maîtrise d'Armure ne s'ajoute qu'aux gains des passifs : c'est sur ce
  /// périmètre qu'est calibrée la récompense *Forge d'Acier*
  /// (`level_up_reward_service.dart`). Sa refonte en bonus de passif est une
  /// décision de P-49 (spec P-41, §5.4).
  static int _masteryFor(EntityStats stats, StatGain gain) =>
      gain.source == GainSource.passive ? stats.effectiveMastery : 0;
}
