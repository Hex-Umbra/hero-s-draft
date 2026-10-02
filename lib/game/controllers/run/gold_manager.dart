import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/data/forge_upgrade_data.dart';
import '../../services/forge_rune_rules.dart';
import '../deck_controller.dart';
import '../inventory_controller.dart';

/// Les services de forge vendus contre de l'or (spec P-43 E2, A16) : la règle
/// « payer et écrire, ou rien » vit ici ; les formules, dans
/// `ForgeRuneRules`.
class GoldManager {
  final Ref ref;

  GoldManager(this.ref);

  /// Affûte la rune [runeId] de la carte [cardId] du deck : un niveau de plus
  /// (D4), contre `ForgeRuneRules.sharpenCost(niveau)` or (D20). Refuse —
  /// sans rien toucher — si la carte ne porte pas la rune, si la rune est
  /// absente du registre ou à son plafond, ou si l'or manque. Rend vrai si
  /// l'affûtage a eu lieu.
  bool sharpenRune(String cardId, String runeId) {
    final card = ref
        .read(deckProvider)
        .masterDeck
        .where((c) => c.uniqueId == cardId)
        .firstOrNull;
    final level = card == null
        ? null
        : ForgeUpgradeData.levelsOf(card.forgeUpgrades)[runeId];
    final rune = ForgeUpgradeData.getById(runeId);
    if (card == null ||
        level == null ||
        rune == null ||
        !ForgeRuneRules.canSharpen(rune, level)) {
      return false;
    }
    if (!ref
        .read(inventoryProvider.notifier)
        .spendGold(ForgeRuneRules.sharpenCost(level))) {
      return false;
    }
    ref.read(deckProvider.notifier).setForgeUpgrades(
          cardId,
          ForgeRuneRules.replaceRune(
            card.forgeUpgrades,
            runeId,
            '$runeId:${level + 1}',
          ),
        );
    return true;
  }
}
