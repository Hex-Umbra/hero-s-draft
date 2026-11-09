import '../../l10n/app_localizations.dart';
import '../../models/data/card_data.dart';
import 'effect_resolver.dart';

/// La seule écriture des lignes de coût, de coups et de croissance d'une carte
/// (spec P-44 lot 1, §6.1) : l'infobulle Flutter et l'infobulle Flame la lisent
/// toutes deux.
abstract final class CardRuleTexts {
  /// Les coûts autres que le mana : PV puis Armure, chacun s'il est non nul.
  static List<String> extraCosts(AppLocalizations l10n, CardData card) => [
        if (card.hpCost > 0) l10n.cardCostHp(card.hpCost),
        if (card.armorCost > 0) l10n.cardCostArmor(card.armorCost),
      ];

  /// La ligne d'un effet `damage` : à coups dès deux coups, quelle que soit la
  /// cible (aucune clé de zone à coups — aucune carte n'en porte).
  static String damage(
    AppLocalizations l10n, {
    required int amount,
    required int hits,
    required bool allEnemies,
  }) {
    if (hits >= 2) return l10n.cardDescDamageHits(amount, hits);
    return allEnemies
        ? l10n.cardDescDamageAll(amount)
        : l10n.cardDescDamage(amount);
  }

  /// La ligne de croissance : sous 1, en tranches de `1 / ratio` ; au moins
  /// 1, le ratio tel quel (A11).
  static String scale(AppLocalizations l10n, ScaleWith scale) {
    final ratio = scale.ratio;
    if (ratio < 1) {
      final per = (1 / ratio).round();
      return switch (scale.source) {
        ScaleSource.armor => l10n.cardScaleArmorPer(per),
        ScaleSource.missingHp => l10n.cardScaleMissingHpPer(per),
        ScaleSource.cardsPlayedThisTurn => l10n.cardScaleCardsPlayedPer(per),
        ScaleSource.enemiesAlive => l10n.cardScaleEnemiesAlivePer(per),
        ScaleSource.targetStatus =>
          l10n.cardScaleTargetStatusPer(per, _statusName(scale)),
        ScaleSource.targetMissingHp => l10n.cardScaleTargetMissingHpPer(per),
      };
    }
    final text = _ratioText(l10n, ratio);
    return switch (scale.source) {
      ScaleSource.armor => l10n.cardScaleArmor(text),
      ScaleSource.missingHp => l10n.cardScaleMissingHp(text),
      ScaleSource.cardsPlayedThisTurn => l10n.cardScaleCardsPlayed(text),
      ScaleSource.enemiesAlive => l10n.cardScaleEnemiesAlive(text),
      ScaleSource.targetStatus =>
        l10n.cardScaleTargetStatus(text, _statusName(scale)),
      ScaleSource.targetMissingHp => l10n.cardScaleTargetMissingHp(text),
    };
  }

  /// Le ratio sans décimale inutile, la virgule en français.
  static String _ratioText(AppLocalizations l10n, double ratio) {
    final text = ratio == ratio.roundToDouble()
        ? '${ratio.round()}'
        : '$ratio';
    return l10n.localeName == 'fr' ? text.replaceAll('.', ',') : text;
  }

  /// Le nom du statut lu, celui que le jeu lui donne ; l'id à défaut.
  static String _statusName(ScaleWith scale) {
    final id = scale.statusId!;
    return EffectResolver.createStatus(id, 0, 0)?.name ?? id;
  }
}
