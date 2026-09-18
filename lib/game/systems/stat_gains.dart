import '../../models/data/stat_rule.dart';
import '../../models/entity_stats.dart';
import '../../models/status_effect.dart';

/// La ressource qu'un gain augmente.
enum GainResource { armor, mana, might }

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
  /// Applique [gain] à [stats] sous les [rules] de son porteur : celles de la
  /// classe pour le héros, `const []` pour un ennemi.
  ///
  /// Le paramètre est obligatoire à dessein (spec P-41, §4.1) : une valeur par
  /// défaut laisserait un site de gain oublié échapper aux règles sans que
  /// rien ne le dise, et c'est exactement ce qui est arrivé à la Maîtrise
  /// d'Armure (§1.3).
  static EntityStats apply(
    EntityStats stats,
    StatGain gain,
    List<StatRule> rules,
  ) {
    final converted = _convert(stats, gain, rules);
    if (converted != null) return converted;

    return switch (gain.resource) {
      GainResource.armor => stats.copyWith(
          armure: stats.armure + gain.amount,
        ),
      GainResource.mana => stats.copyWith(
          currentMana: stats.currentMana + gain.amount,
        ),
      GainResource.might => stats.copyWith(
          might: stats.might + gain.amount,
        ),
    };
  }

  /// Le gain converti par une règle qui le vise, ou `null` s'il n'y en a pas.
  ///
  /// Un gain nul ou négatif n'est jamais converti : il n'y a rien à
  /// transformer, et un statut de valeur négative n'a pas de sens.
  static EntityStats? _convert(
    EntityStats stats,
    StatGain gain,
    List<StatRule> rules,
  ) {
    if (gain.amount <= 0) return null;
    final stat = switch (gain.resource) {
      GainResource.armor => RuleStat.armor,
      GainResource.mana => RuleStat.mana,
      // La Puissance n'est jamais une `stat` de `statRules` : `HeroData` le
      // refuse au chargement (spec §7.1).
      GainResource.might => null,
    };
    if (stat == null) return null;

    for (final rule in rules) {
      if (rule.stat != stat || rule.mode != RuleMode.convert) continue;
      return switch (rule.to) {
        // R5 (spec §7.2) : la cible est la Puissance **temporaire**. Convertir
        // en Puissance permanente ferait gagner de la puissance définitive à
        // chaque `iron_wall` jouée, et casserait le jeu au troisième combat.
        RuleTarget.statusMight => stats.addStatus(
            StatusEffect(
              id: 'might',
              name: 'Puissance',
              type: StatusType.buff,
              value: gain.amount,
              duration: rule.duration,
            ),
          ),
      };
    }
    return null;
  }
}
