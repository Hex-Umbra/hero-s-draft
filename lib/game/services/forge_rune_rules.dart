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

  /// Tier d'une référence `id:tier`, ou `null` si elle est mal formée ou de
  /// tier nul : les deux combinaisons l'ignorent alors de la même façon.
  static int? _tierOf(String rune) {
    final parts = rune.split(':');
    if (parts.length != 2) return null;
    final tier = int.tryParse(parts[1]);
    return tier != null && tier > 0 ? tier : null;
  }

  /// Réunit les runes de même id, dans l'ordre de leur première apparition :
  /// les tiers d'une rune cumulable s'additionnent, une rune non cumulable est
  /// gardée une fois au tier 1.
  static List<String> consolidate(Iterable<String> runes) {
    final tiers = <String, int>{};
    for (final rune in runes) {
      final tier = _tierOf(rune);
      if (tier == null) continue;
      final id = rune.split(':').first;
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
      if (_tierOf(rune) == null) continue;
      groups.putIfAbsent(rune.split(':').first, () => []).add(rune);
    }

    final options = <FusionOption>[];
    groups.forEach((id, runes) {
      if (runes.length < 2 || !isStackable(id)) return;
      options.add(FusionOption(
        upgradeId: id,
        originalUpgrades: runes,
        totalTier: runes.fold(0, (sum, rune) => sum + (_tierOf(rune) ?? 0)),
        cost: 80 * (runes.length - 1),
      ));
    });
    return options;
  }
}
