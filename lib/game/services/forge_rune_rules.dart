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
/// n'en garde qu'un exemplaire, au tier 1.
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
  static List<String> consolidate(Iterable<String> runes) {
    final tiers = <String, int>{};
    for (final rune in runes) {
      final parts = rune.split(':');
      if (parts.length != 2) continue;
      final tier = int.tryParse(parts[1]) ?? 0;
      if (tier <= 0) continue;
      final id = parts[0];
      tiers[id] = isStackable(id) ? (tiers[id] ?? 0) + tier : 1;
    }
    return [for (final entry in tiers.entries) '${entry.key}:${entry.value}'];
  }

  /// Fusions que la Forge de Fusion propose pour [card] : une par id de rune
  /// cumulable que la carte porte au moins deux fois, au coût de
  /// `80 × (N - 1)` or.
  static List<FusionOption> fusionOptionsFor(CardInstance card) {
    final groups = <String, List<String>>{};
    for (final rune in card.forgeUpgrades) {
      groups.putIfAbsent(rune.split(':')[0], () => []).add(rune);
    }

    final options = <FusionOption>[];
    groups.forEach((id, runes) {
      if (runes.length < 2 || !isStackable(id)) return;
      var totalTier = 0;
      for (final rune in runes) {
        final parts = rune.split(':');
        totalTier += parts.length > 1 ? (int.tryParse(parts[1]) ?? 1) : 1;
      }
      options.add(FusionOption(
        upgradeId: id,
        originalUpgrades: runes,
        totalTier: totalTier,
        cost: 80 * (runes.length - 1),
      ));
    });
    return options;
  }
}
