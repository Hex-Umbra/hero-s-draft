import '../../models/card_instance.dart';
import '../../models/data/forge_upgrade_data.dart';

/// Une fusion que propose la Forge de Fusion : toutes les runes d'un même id
/// portées par une carte, réunies en une seule dont le tier est la somme.
class FusionOption {
  final String upgradeId;
  final List<String> originalUpgrades;
  final int totalTier;
  final int cost;

  FusionOption({
    required this.upgradeId,
    required this.originalUpgrades,
    required this.totalTier,
    required this.cost,
  });
}

/// Règles de combinaison des runes de forge, notées `id:tier`.
///
/// La Forge de Fusion et la fusion 3→1 additionnent les tiers des runes de
/// même id. Une rune non cumulable (`ForgeUpgradeData.stackable`) n'a pas de
/// tier qui vaille : elle n'est jamais proposée à la fusion, et une fusion 3→1
/// n'en garde qu'un exemplaire, au tier 1. Les références se lisent par
/// l'analyseur unique du modèle, `ForgeUpgradeData.parseRef` (ADR-094 D5).
class ForgeRuneRules {
  const ForgeRuneRules._();

  /// Une rune absente du registre est traitée comme cumulable, ce qu'étaient
  /// toutes les runes avant l'apparition du champ.
  static bool isStackable(String runeId) =>
      ForgeUpgradeData.getById(runeId)?.stackable ?? true;

  /// Réunit les runes de même id, dans l'ordre de leur première apparition :
  /// les tiers d'une rune cumulable s'additionnent, bornés par son `maxLevel`
  /// — le surplus se perd (spec P-43 E1, A9) ; une rune non cumulable est
  /// gardée une fois au tier 1. Une référence mal formée ou de tier nul est
  /// ignorée. Deux runes qui s'excluent (`excludesRunes`, dans un sens ou
  /// l'autre) ne sont jamais réunies : la première arrivée est gardée, car la
  /// fusion ne doit pas rouvrir ce que ferment D44, D51 et D61.
  static List<String> consolidate(Iterable<String> runes) {
    final kept = <String>[];
    final result = <String>[];
    for (final MapEntry(key: id, value: tier)
        in ForgeUpgradeData.levelsOf(runes).entries) {
      if (kept.any((other) => _exclude(id, other))) continue;
      kept.add(id);
      result.add('$id:${isStackable(id) ? _bounded(id, tier) : 1}');
    }
    return result;
  }

  /// Les runes [a] et [b] s'excluent-elles ? Symétrique, lu dans le registre ;
  /// une rune absente du registre n'exclut rien et n'est exclue par rien.
  static bool _exclude(String a, String b) =>
      (ForgeUpgradeData.getById(a)?.excludesRunes.contains(b) ?? false) ||
      (ForgeUpgradeData.getById(b)?.excludesRunes.contains(a) ?? false);

  /// [tier] borné par le plafond de la rune [id] (D72) ; une rune absente du
  /// registre n'en a pas.
  static int _bounded(String id, int tier) =>
      ForgeUpgradeData.getById(id)?.boundLevel(tier) ?? tier;

  /// Fusions que la Forge de Fusion propose pour [card] : une par id de rune
  /// cumulable que la carte porte au moins deux fois, au coût de
  /// `80 × (N - 1)` or — et seulement si la somme tient sous le plafond de la
  /// rune : une fusion qui perdrait un niveau n'est pas proposée (spec P-43
  /// E1, A10).
  static List<FusionOption> fusionOptionsFor(CardInstance card) {
    final groups = <String, List<String>>{};
    for (final rune in card.forgeUpgrades) {
      final parsed = ForgeUpgradeData.parseRef(rune);
      if (parsed == null) continue;
      groups.putIfAbsent(parsed.$1, () => []).add(rune);
    }

    final options = <FusionOption>[];
    groups.forEach((id, runes) {
      if (runes.length < 2 || !isStackable(id)) return;
      final totalTier = runes.fold(
        0,
        (sum, rune) => sum + (ForgeUpgradeData.parseRef(rune)?.$2 ?? 0),
      );
      if (_bounded(id, totalTier) != totalTier) return;
      options.add(FusionOption(
        upgradeId: id,
        originalUpgrades: runes,
        totalTier: totalTier,
        cost: 80 * (runes.length - 1),
      ));
    });
    return options;
  }

  /// La rune [rune] peut-elle s'offrir à [card] ? Le prédicat unique de
  /// l'éligibilité (D3, D44, D48, D51, D61 ; spec P-43 E1, A3, §4.6 ; spec
  /// P-43 E2, §4.3) : une fonction pure, sur le modèle de
  /// `CardData.isOfferableTo` — toute règle est un champ du fichier de rune,
  /// aucune n'est un `case` par id. [card] est la carte qui reçoit la rune, à
  /// son rang : la carte fusionnée au rang qu'elle atteint, la carte
  /// elle-même en boutique. [catalog] sert à lire les exclusions des runes
  /// que la carte porte déjà. `pools` n'en est pas une condition : c'est le
  /// ciblage par rareté des tirages, qui le gardent (D68).
  static bool isEligible(
    ForgeUpgradeData rune,
    CardInstance card,
    Iterable<ForgeUpgradeData> catalog,
  ) {
    final types = rune.eligibleCardTypes;
    if (types != null && !types.contains(card.data.type.name)) return false;

    // Les effets propres de la carte, jamais ceux qu'une rune lui ajoute.
    final own = {for (final effect in card.data.effects) effect.type};
    final wanted = rune.eligibleEffects;
    if (wanted != null && !wanted.any(own.contains)) return false;
    if (rune.excludesEffects.any(own.contains)) return false;

    if (rune.requiresExhaust && !card.data.isExhaust) return false;
    if (card.currentCost < rune.requiresMinCost) return false;

    // D48 : le rang de la carte qui reçoit la rune ; une commune et une
    // carte `unique`, de rang 0, n'en reçoivent aucune.
    if (rune.minFusionRank > card.rarity.fusionRank) return false;

    // La symétrie des exclusions : une rune portée absente du catalogue est
    // ignorée.
    final carried = ForgeUpgradeData.levelsOf(card.forgeUpgrades);
    for (final id in carried.keys) {
      final other = catalog.where((r) => r.id == id).firstOrNull;
      if (other == null) continue;
      if (rune.excludesRunes.contains(id) ||
          other.excludesRunes.contains(rune.id)) {
        return false;
      }
    }

    // D3 : une seule rune de chaque type par carte — une rune portée ne se
    // repropose jamais, plafond atteint ou non (D75 en est un cas).
    return !carried.containsKey(rune.id);
  }
}
