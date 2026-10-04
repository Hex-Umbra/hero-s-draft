import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/data/relic_data.dart';
import '../../models/data/card_data.dart';
import '../../models/data/forge_upgrade_data.dart';
import '../../models/data/game_data_registry.dart';
import '../../models/card_instance.dart';
import '../../models/map_node.dart';
import '../../models/enemy_instance.dart';
import '../game_constants.dart';
import '../services/forge_rune_rules.dart';
import '../systems/card_drops.dart';
import 'inventory_controller.dart';
import 'run_controller.dart';
import 'deck_controller.dart';

/// Une rune montée par le boss « XP » : l'exemplaire qui la porte, son id, et
/// le niveau qu'elle atteint (spec P-43 E3, §3.8).
typedef SharpenedRune = ({String cardUniqueId, String runeId, int level});

class RewardState {
  final int goldGained;
  final int xpGained;
  final RelicData? rolledRelic;
  final List<CardInstance> rolledCards;
  
  final bool isGoldXpCollected;
  final bool isRelicCollected;
  final bool isRelicSkipped;
  final bool isCardsProcessed;
  final List<CardInstance> selectedCards;
  final bool isResolved;

  /// Les cartes trouvées à la victoire (spec P-43 E3, §4.1 ; D1) : tirées
  /// par `handleVictory`, toujours communes, elles rejoignent le deck à
  /// `collectGoldAndXp`, sans refus.
  final List<CardInstance> foundCards;

  /// Les runes que le boss « XP » a montées (spec P-43 E3, §4.6 ; D42(a),
  /// C1.1), une entrée par rune, au niveau atteint, écrites par
  /// `collectGoldAndXp`. `null` hors d'un boss « XP » ; vide pour un boss
  /// « XP » dont aucune rune ne pouvait monter (A5) — le discriminant que lit
  /// l'écran.
  final List<SharpenedRune>? sharpenedRunes;

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
    this.foundCards = const [],
    this.sharpenedRunes,
  });

  RewardState copyWith({
    int? goldGained,
    int? xpGained,
    RelicData? rolledRelic,
    List<CardInstance>? rolledCards,
    bool? isGoldXpCollected,
    bool? isRelicCollected,
    bool? isRelicSkipped,
    bool? isCardsProcessed,
    List<CardInstance>? selectedCards,
    bool? isResolved,
    List<CardInstance>? foundCards,
    List<SharpenedRune>? sharpenedRunes,
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
      foundCards: foundCards ?? this.foundCards,
      sharpenedRunes: sharpenedRunes ?? this.sharpenedRunes,
    );
  }
}

class RewardController extends Notifier<RewardState> {
  @override
  RewardState build() {
    return const RewardState();
  }

  /// [random] : le tirage de la trouvaille — combien de cartes, lesquelles.
  /// Passé par les tests pour connaître ses jets (spec P-43 E3, §4.1) ; en
  /// jeu, un `Random` neuf. Les autres tirages de la victoire n'en dépendent
  /// pas.
  void handleVictory({
    required List<EnemyInstance> defeatedEnemies,
    required MapNode currentNode,
    required List<RelicData> allRelics,
    required List<CardData> allCards,
    required int luck,
    required int act,
    Random? random,
  }) {
    // 1. Calculate XP from defeated enemies
    int totalXp = 0;
    for (var enemy in defeatedEnemies) {
      final double levelMultiplier = 1.0 + 0.10 * (enemy.stats.level - 1);
      totalXp += (enemy.data.xp * levelMultiplier).round();
    }
    if (currentNode.bossRewardType == BossRewardType.doubleXp) {
      totalXp *= 3;
    }

    // 2. Calculate Gold from defeated enemies
    int totalGold = 0;
    for (var enemy in defeatedEnemies) {
      final double levelMultiplier = 1.0 + 0.10 * (enemy.stats.level - 1);
      totalGold += (enemy.data.gold * levelMultiplier).round();
    }
    if (currentNode.bossRewardType == BossRewardType.doubleXp) {
      totalGold *= 3;
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
    List<CardInstance> rolledCards = [];
    if (currentNode.bossRewardType == BossRewardType.cards) {
      final candidates = ref.read(deckProvider).copyableCards;
      if (candidates.isNotEmpty) {
        final random = Random();
        candidates.shuffle(random);
        final toTake = min(5, candidates.length);
        for (int i = 0; i < toTake; i++) {
          rolledCards.add(CardInstance(
            data: candidates[i].data,
            rarity: candidates[i].rarity,
            forgeUpgrades: candidates[i].forgeUpgrades,
          ));
        }
      }
    }

    // 5. La trouvaille (spec P-43 E3, §4.1 ; D1, D31) : des cartes tirées
    // uniformément, avec remise, parmi celles que la classe peut recevoir —
    // le prédicat d'offre unique (ADR-101) —, toujours communes, donc sans
    // rune. Pool vide : aucune carte, sans repli (ADR-101 D4).
    final run = ref.read(runProvider);
    final rng = random ?? Random();
    final offerable =
        allCards.where((c) => c.isOfferableTo(run.heroClassId)).toList();
    final foundCards = <CardInstance>[];
    if (offerable.isNotEmpty) {
      // Les deux règles des reliques : C (+1 carte garantie) au seul combat
      // normal, A (+N points au premier jet) à la seule élite — jamais l'une
      // sur le nœud de l'autre, ni sur un boss (D31, D57).
      final count = CardDrops.roll(
        GameConstants.cardDrops[currentNode.type],
        extraGuaranteed:
            currentNode.type == MapNodeType.combat ? run.extraCombatCards : 0,
        firstExtraBonus:
            currentNode.type == MapNodeType.elite ? run.eliteCardChanceBonus : 0,
        rng: rng,
      );
      for (var i = 0; i < count; i++) {
        foundCards.add(CardInstance(
          data: offerable[rng.nextInt(offerable.length)],
          rarity: CardRarity.common,
        ));
      }
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
      foundCards: foundCards,
      // Le boss « XP » monte ses runes à la collecte : une liste vide ici le
      // désigne (C1.1).
      sharpenedRunes: currentNode.bossRewardType == BossRewardType.doubleXp
          ? const []
          : null,
    );
  }

  bool collectGoldAndXp() {
    if (state.isGoldXpCollected) return false;

    ref.read(inventoryProvider.notifier).gainGold(state.goldGained);
    final leveledUp = ref.read(runProvider.notifier).gainXp(state.xpGained);

    // Les cartes trouvées rejoignent le deck, sans refus (spec P-43 E3, §4.1).
    final deck = ref.read(deckProvider.notifier);
    for (final card in state.foundCards) {
      deck.addCardToMasterDeck(card);
    }

    state = state.copyWith(
      isGoldXpCollected: true,
      sharpenedRunes:
          state.sharpenedRunes == null ? null : _sharpenRandomRunes(),
    );
    _checkResolution();

    return leveledUp;
  }

  /// La récompense du boss « XP » (spec P-43 E3, §4.6 ; D42(a), A5, A14) :
  /// [GameConstants.bossXpRuneSharpens] tirages, plus un par *Meule*
  /// (`RunState.extraBossRuneSharpens`, A3), chacun une paire (carte, rune)
  /// au hasard parmi celles du deck dont la rune peut encore monter, montée
  /// d'un niveau, sans or ; chaque tirage voit le précédent. Sans paire,
  /// rien ne monte.
  List<SharpenedRune> _sharpenRandomRunes() {
    final deck = ref.read(deckProvider.notifier);
    final catalog = GameDataRegistry.instance?.forgeUpgrades ??
        const <ForgeUpgradeData>[];
    final rng = Random();
    final sharpened = <SharpenedRune>[];
    final draws = GameConstants.bossXpRuneSharpens +
        ref.read(runProvider).extraBossRuneSharpens;
    for (var i = 0; i < draws; i++) {
      final pairs = ForgeRuneRules.sharpenablePairs(
        ref.read(deckProvider).masterDeck,
        catalog,
      );
      if (pairs.isEmpty) break;
      final pair = pairs[rng.nextInt(pairs.length)];
      if (deck.raiseRuneLevel(pair.card.uniqueId, pair.rune.id)) {
        sharpened.add((
          cardUniqueId: pair.card.uniqueId,
          runeId: pair.rune.id,
          level: pair.level + 1,
        ));
      }
    }
    return sharpened;
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

  void chooseCards(List<CardInstance> cards) {
    if (state.isCardsProcessed) return;

    for (var card in cards) {
      ref.read(deckProvider.notifier).addCardToMasterDeck(CardInstance(
        data: card.data,
        rarity: card.rarity,
        forgeUpgrades: card.forgeUpgrades,
      ));
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

final rewardProvider = NotifierProvider<RewardController, RewardState>(RewardController.new);
