import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/data/relic_data.dart';
import '../../models/data/card_data.dart';
import '../../models/card_instance.dart';
import '../../models/map_node.dart';
import '../../models/enemy_instance.dart';
import 'inventory_controller.dart';
import 'run_controller.dart';
import 'deck_controller.dart';

class RewardState {
  final int goldGained;
  final int xpGained;
  final RelicData? rolledRelic;
  final List<CardData> rolledCards;
  
  final bool isGoldXpCollected;
  final bool isRelicCollected;
  final bool isRelicSkipped;
  final bool isCardsProcessed;
  final List<CardData> selectedCards;
  final bool isResolved;

  const RewardState({
    this.goldGained = 0,
    this.xpGained = 0,
    this.rolledRelic,
    this.rolledCards = const [],
    this.isGoldXpCollected = false,
    this.isRelicCollected = false,
    this.isRelicSkipped = false,
    this.isCardsProcessed = false,
    this.selectedCards = const [],
    this.isResolved = false,
  });

  RewardState copyWith({
    int? goldGained,
    int? xpGained,
    RelicData? rolledRelic,
    List<CardData>? rolledCards,
    bool? isGoldXpCollected,
    bool? isRelicCollected,
    bool? isRelicSkipped,
    bool? isCardsProcessed,
    List<CardData>? selectedCards,
    bool? isResolved,
  }) {
    return RewardState(
      goldGained: goldGained ?? this.goldGained,
      xpGained: xpGained ?? this.xpGained,
      rolledRelic: rolledRelic ?? this.rolledRelic,
      rolledCards: rolledCards ?? this.rolledCards,
      isGoldXpCollected: isGoldXpCollected ?? this.isGoldXpCollected,
      isRelicCollected: isRelicCollected ?? this.isRelicCollected,
      isRelicSkipped: isRelicSkipped ?? this.isRelicSkipped,
      isCardsProcessed: isCardsProcessed ?? this.isCardsProcessed,
      selectedCards: selectedCards ?? this.selectedCards,
      isResolved: isResolved ?? this.isResolved,
    );
  }
}

class RewardController extends StateNotifier<RewardState> {
  final Ref ref;

  RewardController(this.ref) : super(const RewardState());

  void handleVictory({
    required List<EnemyInstance> defeatedEnemies,
    required MapNode currentNode,
    required List<RelicData> allRelics,
    required List<CardData> allCards,
    required int luck,
    required int act,
  }) {
    // 1. Calculate XP from defeated enemies
    int totalXp = 0;
    for (var enemy in defeatedEnemies) {
      final double levelMultiplier = 1.0 + 0.10 * (enemy.stats.level - 1);
      totalXp += (enemy.data.xp * levelMultiplier).round();
    }
    if (currentNode.bossRewardType == BossRewardType.doubleXp) {
      totalXp *= 2;
    }

    // 2. Calculate Gold from defeated enemies
    int totalGold = 0;
    for (var enemy in defeatedEnemies) {
      final double levelMultiplier = 1.0 + 0.10 * (enemy.stats.level - 1);
      totalGold += (enemy.data.gold * levelMultiplier).round();
    }
    if (currentNode.bossRewardType == BossRewardType.doubleXp) {
      totalGold *= 2;
    }

    // 3. Roll Relic
    RelicData? rolledRelic;
    final bool isImprovedRelic = currentNode.bossRewardType == BossRewardType.improvedRelic;
    if (currentNode.type == MapNodeType.elite || (currentNode.type == MapNodeType.boss && isImprovedRelic)) {
      if (allRelics.isNotEmpty) {
        final rand = Random().nextDouble() * 100;
        final double legChance;
        final double epicChance;
        final double rareChance;
        final double uncommonChance;

        if (isImprovedRelic) {
          legChance = 10.0 + luck * 0.5;
          final double commonChance = max(0.0, 40.0 - (act - 1) * 10.0);
          if (commonChance > 0.0) {
            final double baseRemaining = 90.0 - commonChance;
            uncommonChance = (20.0 / 85.0) * baseRemaining + luck * 3.0;
            rareChance = (35.0 / 85.0) * baseRemaining + luck * 2.0;
            epicChance = (30.0 / 85.0) * baseRemaining + luck * 1.0;
          } else {
            final double maxUncommonBase = (20.0 / 85.0) * 90.0;
            final double baseUncommonChance = max(0.0, maxUncommonBase - (act - 5) * 10.0);
            if (baseUncommonChance > 0.0) {
              final double baseRemaining = 90.0 - baseUncommonChance;
              rareChance = (35.0 / 65.0) * baseRemaining + luck * 2.0;
              epicChance = (30.0 / 65.0) * baseRemaining + luck * 1.0;
              uncommonChance = baseUncommonChance + luck * 3.0;
            } else {
              rareChance = (35.0 / 65.0) * 90.0 + luck * 2.0;
              epicChance = (30.0 / 65.0) * 90.0 + luck * 1.0;
              uncommonChance = 0.0;
            }
          }
        } else {
          legChance = 1.0 + luck * 0.5;
          epicChance = 5.0 + luck * 1.0;
          rareChance = 14.0 + luck * 2.0;
          uncommonChance = 20.0 + luck * 3.0;
        }

        RelicRarity rarity;
        double roll = rand;
        if (roll < legChance) {
          rarity = RelicRarity.legendary;
        } else if (roll < legChance + epicChance) {
          rarity = RelicRarity.epic;
        } else if (roll < legChance + epicChance + rareChance) {
          rarity = RelicRarity.rare;
        } else if (roll < legChance + epicChance + rareChance + uncommonChance) {
          rarity = RelicRarity.uncommon;
        } else {
          rarity = RelicRarity.common;
        }

        var filtered = allRelics.where((r) => r.rarity == rarity).toList();
        if (filtered.isEmpty) {
          filtered = allRelics.where((r) => r.rarity == RelicRarity.common).toList();
          if (filtered.isEmpty) {
            filtered = allRelics;
          }
        }
        rolledRelic = filtered[Random().nextInt(filtered.length)];
      }
    }

    // 4. Roll Cards
    List<CardData> rolledCards = [];
    if (currentNode.bossRewardType == BossRewardType.cards) {
      rolledCards = allCards.where((c) => c.type != CardType.status).toList();
    }

    state = RewardState(
      goldGained: totalGold,
      xpGained: totalXp,
      rolledRelic: rolledRelic,
      rolledCards: rolledCards,
      isGoldXpCollected: false,
      isRelicCollected: false,
      isRelicSkipped: false,
      isCardsProcessed: false,
      selectedCards: const [],
      isResolved: false,
    );
  }

  bool collectGoldAndXp() {
    if (state.isGoldXpCollected) return false;

    ref.read(inventoryProvider.notifier).gainGold(state.goldGained);
    final leveledUp = ref.read(runProvider.notifier).gainXp(state.xpGained);

    state = state.copyWith(isGoldXpCollected: true);
    _checkResolution();

    return leveledUp;
  }

  void collectRelic() {
    if (state.rolledRelic == null || state.isRelicCollected || state.isRelicSkipped) return;

    ref.read(inventoryProvider.notifier).addRelic(state.rolledRelic!);
    state = state.copyWith(isRelicCollected: true);
    _checkResolution();
  }

  void skipRelic() {
    if (state.rolledRelic == null || state.isRelicCollected || state.isRelicSkipped) return;

    state = state.copyWith(isRelicSkipped: true);
    _checkResolution();
  }

  void chooseCards(List<CardData> cards) {
    if (state.isCardsProcessed) return;

    for (var card in cards) {
      ref.read(deckProvider.notifier).addCardToMasterDeck(CardInstance(data: card));
    }
    state = state.copyWith(
      isCardsProcessed: true,
      selectedCards: cards,
    );
    _checkResolution();
  }

  void skipCards() {
    if (state.isCardsProcessed) return;

    state = state.copyWith(isCardsProcessed: true);
    _checkResolution();
  }

  void _checkResolution() {
    final needsRelic = state.rolledRelic != null;
    final relicDone = !needsRelic || state.isRelicCollected || state.isRelicSkipped;

    final needsCards = state.rolledCards.isNotEmpty;
    final cardsDone = !needsCards || state.isCardsProcessed;

    if (state.isGoldXpCollected && relicDone && cardsDone) {
      state = state.copyWith(isResolved: true);
    }
  }
}

final rewardProvider = StateNotifierProvider<RewardController, RewardState>((ref) {
  return RewardController(ref);
});
