import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/data/forge_upgrade_data.dart';
import '../../../models/data/game_data_registry.dart';
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
  /// absente du registre ou à son plafond effectif — `maxLevel` plus
  /// [capBonus] pour son id (A17) —, ou si l'or manque : l'écriture refusée
  /// ne coûte rien. L'écriture est celle des sources sans or,
  /// `DeckNotifier.raiseRuneLevel` (spec P-43 E3, §4.7, A13). Rend vrai si
  /// l'affûtage a eu lieu.
  bool sharpenRune(
    String cardId,
    String runeId, {
    required Map<String, int> capBonus,
  }) {
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
        !ForgeRuneRules.canSharpen(rune, level, capBonus: capBonus)) {
      return false;
    }
    if (!ref
        .read(inventoryProvider.notifier)
        .spendGold(ForgeRuneRules.sharpenCost(level))) {
      return false;
    }
    // `canSharpen` vient de dire ce que `raiseRuneLevel` vérifie : payée,
    // l'écriture a lieu.
    return ref
        .read(deckProvider.notifier)
        .raiseRuneLevel(cardId, runeId, capBonus: capBonus);
  }

  /// Échange au Puits la rune [givenId] de la carte [cardId] du deck contre
  /// [receivedId] (D6, D39 ; spec P-43 E2, A5, §4.8) : la rune reçue prend
  /// sa place, au niveau `ForgeRuneRules.wellLevel` sous son plafond
  /// effectif ([capBonus], spec P-43 E3, A17), contre
  /// `ForgeRuneRules.wellCost(niveau donné)` or. Refuse — sans rien toucher —
  /// si la carte ne porte pas la rune donnée, si la rune reçue n'est pas
  /// parmi `ForgeRuneRules.wellOptions`, ou si l'or manque. Rend vrai si
  /// l'échange a eu lieu.
  bool exchangeRune(
    String cardId,
    String givenId,
    String receivedId, {
    required Map<String, int> capBonus,
  }) {
    final card = ref
        .read(deckProvider)
        .masterDeck
        .where((c) => c.uniqueId == cardId)
        .firstOrNull;
    final level = card == null
        ? null
        : ForgeUpgradeData.levelsOf(card.forgeUpgrades)[givenId];
    if (card == null || level == null) return false;
    final received = ForgeRuneRules.wellOptions(
      card,
      givenId,
      GameDataRegistry.instance?.forgeUpgrades ?? const [],
    ).where((r) => r.id == receivedId).firstOrNull;
    if (received == null) return false;
    if (!ref
        .read(inventoryProvider.notifier)
        .spendGold(ForgeRuneRules.wellCost(level))) {
      return false;
    }
    ref.read(deckProvider.notifier).setForgeUpgrades(
          cardId,
          ForgeRuneRules.replaceRune(
            card.forgeUpgrades,
            givenId,
            '$receivedId:'
            '${ForgeRuneRules.wellLevel(received, level, capBonus: capBonus)}',
          ),
        );
    return true;
  }
}
