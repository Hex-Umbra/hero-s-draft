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
  /// les tiers d'une rune cumulable s'additionnent, une rune non cumulable est
  /// gardée une fois au tier 1. Une référence mal formée ou de tier nul est
  /// ignorée.
  static List<String> consolidate(Iterable<String> runes) => [
        for (final MapEntry(key: id, value: tier)
            in ForgeUpgradeData.levelsOf(runes).entries)
          '$id:${isStackable(id) ? tier : 1}',
      ];

  /// Fusions que la Forge de Fusion propose pour [card] : une par id de rune
  /// cumulable que la carte porte au moins deux fois, au coût de
  /// `80 × (N - 1)` or.
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
      options.add(FusionOption(
        upgradeId: id,
        originalUpgrades: runes,
        totalTier: runes.fold(
          0,
          (sum, rune) => sum + (ForgeUpgradeData.parseRef(rune)?.$2 ?? 0),
        ),
        cost: 80 * (runes.length - 1),
      ));
    });
    return options;
  }

  /// La rune [rune] peut-elle s'offrir à [card] ? Le prédicat unique de
  /// l'éligibilité (D44, D51, D61, D75 ; spec P-43 E1, A3, §4.6) : une
  /// fonction pure, sur le modèle de `CardData.isOfferableTo` — toute règle
  /// est un champ du fichier de rune, aucune n'est un `case` par id. [catalog]
  /// sert à lire les exclusions des runes que la carte porte déjà. `pools`
  /// n'en est pas une condition : c'est le ciblage par rareté des tirages,
  /// qui le gardent (D68).
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

    // D75 : une rune dont la carte a atteint le plafond ne se repropose pas.
    return rune.boundLevel(1, carried: carried[rune.id] ?? 0) >= 1;
  }
}
