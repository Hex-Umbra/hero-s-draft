import 'card_data.dart';
import 'hero_data.dart';
import 'passive_data.dart';
import 'passive_feeds.dart';
import 'stat_rule.dart';

/// Les règles d'une carte de lot (spec §3.3), lues par le test du catalogue et
/// par le validateur de l'éditeur.
abstract final class LotRules {
  /// A7 : la classe convertit son Armure, lu sur la règle et non sur l'id.
  static bool convertsArmor(HeroData hero) => hero.statRules.any(
        (r) => r.stat == RuleStat.armor && r.mode == RuleMode.convert,
      );

  /// Les fautes de [card] comme carte du lot de [passive] ; vide si elle est
  /// bonne. D45 : elle touche une entrée de `feeds`. A7 : elle ne coûte pas
  /// d'Armure sous [heroClass] si celle-ci convertit la sienne. Aucune règle
  /// sur `hpCost` (D40).
  static List<String> faultsOf(
    CardData card, {
    required PassiveData passive,
    HeroData? heroClass,
  }) =>
      [
        if (!PassiveFeeds.touches(card, passive.feeds))
          'ne touche aucune entree de feeds de ${passive.id}',
        if (card.armorCost > 0 &&
            heroClass != null &&
            convertsArmor(heroClass))
          'coute de l\'Armure sous ${heroClass.id}, qui convertit son Armure',
      ];
}
