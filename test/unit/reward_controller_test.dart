import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/reward_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/map_node.dart';
import 'package:flame/extensions.dart';

void main() {
  group('RewardController Unit Tests', () {
    late ProviderContainer container;
    late RewardController rewardController;
    late RunController runController;
    late InventoryController inventoryController;
    late DeckNotifier deckNotifier;

    const dummyHero = HeroData(
      id: 'paladin',
      nameEn: 'Paladin',
      nameFr: 'Paladin',
      iconPath: 'paladin.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
      luck: 0,
      armorMastery: 0,
      passiveTrait: 'regenArmor',
    );

    EnemyInstance makeEnemy({
      required int xp,
      required int gold,
      int level = 1,
    }) {
      return EnemyInstance(
        data: EnemyData(
          id: 'slime',
          maxHp: 20,
          baseDamage: 5,
          spritePath: 'slime.png',
          xp: xp,
          gold: gold,
        ),
        stats: EntityStats(
          maxPv: 20,
          currentPv: 0,
          armure: 0,
          attaque: 5,
          level: level,
        ),
      );
    }

    MapNode makeNode({
      MapNodeType type = MapNodeType.combat,
      BossRewardType? bossRewardType,
    }) {
      return MapNode(
        id: 'node_0_0',
        floor: 0,
        type: type,
        connections: const [],
        position: Vector2.zero(),
        bossRewardType: bossRewardType,
      );
    }

    const allRelics = [
      RelicData(id: 'r_common', rarity: RelicRarity.common, trigger: RelicTrigger.startOfTurn, effectType: 'gain_armor', value: 1, emoji: '🪙'),
      RelicData(id: 'r_uncommon', rarity: RelicRarity.uncommon, trigger: RelicTrigger.startOfTurn, effectType: 'gain_armor', value: 1, emoji: '🪙'),
      RelicData(id: 'r_rare', rarity: RelicRarity.rare, trigger: RelicTrigger.startOfTurn, effectType: 'gain_armor', value: 1, emoji: '🪙'),
      RelicData(id: 'r_epic', rarity: RelicRarity.epic, trigger: RelicTrigger.startOfTurn, effectType: 'gain_armor', value: 1, emoji: '🪙'),
      RelicData(id: 'r_legendary', rarity: RelicRarity.legendary, trigger: RelicTrigger.startOfTurn, effectType: 'gain_armor', value: 1, emoji: '🪙'),
    ];

    const allCards = [
      CardData(
        id: 'c_normal',
        cost: 1,
        type: CardType.attack,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        effects: [],
      ),
      CardData(
        id: 'c_status',
        cost: 1,
        type: CardType.status,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.self,
        effects: [],
      ),
      CardData(
        id: 'c_unique',
        cost: 1,
        type: CardType.attack,
        category: CardCategory.characterSpecific,
        rarity: CardRarity.unique,
        target: CardTarget.singleEnemy,
        heroClass: 'paladin',
        effects: [],
      ),
    ];

    setUp(() {
      container = ProviderContainer();
      rewardController = container.read(rewardProvider.notifier);
      runController = container.read(runProvider.notifier);
      inventoryController = container.read(inventoryProvider.notifier);
      deckNotifier = container.read(deckProvider.notifier);

      runController.startNewRun(dummyHero);
    });

    tearDown(() {
      container.dispose();
    });

    test('handleVictory sums gold/xp across enemies with per-level scaling, no relic/cards on a normal combat node', () {
      rewardController.handleVictory(
        defeatedEnemies: [
          makeEnemy(xp: 20, gold: 10, level: 1),
          makeEnemy(xp: 20, gold: 10, level: 3), // level 3 -> x(1 + 0.10*2) = x1.20
        ],
        currentNode: makeNode(),
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
      );

      // enemy1: 20*1.0 = 20 xp, 10*1.0 = 10 gold
      // enemy2: 20*1.2 = 24 xp, 10*1.2 = 12 gold
      expect(rewardController.state.xpGained, 44);
      expect(rewardController.state.goldGained, 22);
      expect(rewardController.state.rolledRelic, isNull);
      expect(rewardController.state.rolledCards, isEmpty);
      expect(rewardController.state.rolledBonusCard, isNull);
    });

    test('handleVictory triples gold and xp for a doubleXp boss reward node', () {
      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 20, gold: 10, level: 1)],
        currentNode: makeNode(type: MapNodeType.boss, bossRewardType: BossRewardType.doubleXp),
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
      );

      expect(rewardController.state.xpGained, 60);
      expect(rewardController.state.goldGained, 30);
    });

    test('handleVictory rolls a relic on an elite node but not on a plain combat node', () {
      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
        currentNode: makeNode(type: MapNodeType.elite),
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
      );
      expect(rewardController.state.rolledRelic, isNotNull);

      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
        currentNode: makeNode(),
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
      );
      expect(rewardController.state.rolledRelic, isNull);
    });

    test('handleVictory only rolls a relic on a boss node when bossRewardType is improvedRelic', () {
      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
        currentNode: makeNode(type: MapNodeType.boss, bossRewardType: BossRewardType.improvedRelic),
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
      );
      expect(rewardController.state.rolledRelic, isNotNull);

      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
        currentNode: makeNode(type: MapNodeType.boss, bossRewardType: BossRewardType.cards),
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
      );
      expect(rewardController.state.rolledRelic, isNull);

      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
        currentNode: makeNode(type: MapNodeType.boss, bossRewardType: BossRewardType.doubleXp),
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
      );
      expect(rewardController.state.rolledRelic, isNull);
    });

    test('handleVictory relic roll never crashes and can land on any rarity across acts / improvedRelic branches', () {
      final seenRarities = <RelicRarity>{};
      for (var act = 1; act <= 6; act++) {
        for (var i = 0; i < 60; i++) {
          rewardController.handleVictory(
            defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
            currentNode: makeNode(type: MapNodeType.boss, bossRewardType: BossRewardType.improvedRelic),
            allRelics: allRelics,
            allCards: allCards,
            luck: 0,
            act: act,
          );
          final relic = rewardController.state.rolledRelic;
          expect(relic, isNotNull);
          seenRarities.add(relic!.rarity);
        }
      }
      // With commonChance decaying to 0 by act 5 and every tier present in the
      // pool, a wide sweep across acts should surface more than a single rarity.
      expect(seenRarities.length, greaterThan(1));
    });

    test('handleVictory rolls up to 5 cards from the master deck only when bossRewardType is cards', () {
      for (var i = 0; i < 7; i++) {
        deckNotifier.addCardToMasterDeck(CardInstance(data: allCards[0]));
      }

      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
        currentNode: makeNode(bossRewardType: BossRewardType.cards),
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
      );
      expect(rewardController.state.rolledCards.length, 5);

      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
        currentNode: makeNode(),
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
      );
      expect(rewardController.state.rolledCards, isEmpty);
    });

    test('handleVictory rolls a bonus card excluding status/unique cards, only for a doubleXp boss node', () {
      for (var i = 0; i < 30; i++) {
        rewardController.handleVictory(
          defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
          currentNode: makeNode(type: MapNodeType.boss, bossRewardType: BossRewardType.doubleXp),
          allRelics: allRelics,
          allCards: allCards,
          luck: 0,
          act: 1,
        );
        final bonus = rewardController.state.rolledBonusCard;
        expect(bonus, isNotNull);
        expect(bonus!.type, isNot(CardType.status));
        expect(bonus.rarity, isNot(CardRarity.unique));
      }

      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
        currentNode: makeNode(),
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
      );
      expect(rewardController.state.rolledBonusCard, isNull);
    });

    test('collectGoldAndXp applies gold/xp once, resolves immediately with nothing else pending, and is idempotent', () {
      final initialGold = inventoryController.state.gold;

      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 10, gold: 15)],
        currentNode: makeNode(),
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
      );

      rewardController.collectGoldAndXp();
      expect(inventoryController.state.gold, initialGold + 15);
      expect(rewardController.state.isGoldXpCollected, isTrue);
      expect(rewardController.state.isResolved, isTrue);

      // Idempotent: calling again must not double-grant gold.
      final leveledUpAgain = rewardController.collectGoldAndXp();
      expect(leveledUpAgain, isFalse);
      expect(inventoryController.state.gold, initialGold + 15);
    });

    test('collectGoldAndXp reports whether the player leveled up and adds the bonus card', () {
      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 500, gold: 0)],
        currentNode: makeNode(type: MapNodeType.boss, bossRewardType: BossRewardType.doubleXp),
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
      );

      final deckSizeBefore = container.read(deckProvider).masterDeck.length;
      final leveledUp = rewardController.collectGoldAndXp();

      expect(leveledUp, isTrue);
      expect(container.read(runProvider).heroStats.level, greaterThan(1));
      expect(container.read(deckProvider).masterDeck.length, deckSizeBefore + 1);
    });

    test('resolution stays pending until the rolled relic is collected or skipped', () {
      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
        currentNode: makeNode(type: MapNodeType.elite),
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
      );

      rewardController.collectGoldAndXp();
      expect(rewardController.state.isResolved, isFalse);

      rewardController.collectRelic();
      expect(rewardController.state.isRelicCollected, isTrue);
      expect(rewardController.state.isResolved, isTrue);
      expect(
        container.read(inventoryProvider).relics.map((r) => r.id),
        contains(rewardController.state.rolledRelic!.id),
      );

      // Idempotent: collecting again must not duplicate the relic in inventory.
      final relicCountBefore = container.read(inventoryProvider).relics.length;
      rewardController.collectRelic();
      expect(container.read(inventoryProvider).relics.length, relicCountBefore);
    });

    test('skipRelic resolves without granting the relic, and is mutually exclusive with collectRelic', () {
      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
        currentNode: makeNode(type: MapNodeType.elite),
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
      );
      rewardController.collectGoldAndXp();

      rewardController.skipRelic();
      expect(rewardController.state.isRelicSkipped, isTrue);
      expect(rewardController.state.isResolved, isTrue);
      expect(container.read(inventoryProvider).relics, isEmpty);

      // Once skipped, collecting must no-op (mutually exclusive guard).
      rewardController.collectRelic();
      expect(rewardController.state.isRelicCollected, isFalse);
      expect(container.read(inventoryProvider).relics, isEmpty);
    });

    test('chooseCards clones only the selected cards into the master deck and resolves; skipCards leaves the deck untouched', () {
      for (var i = 0; i < 5; i++) {
        deckNotifier.addCardToMasterDeck(CardInstance(data: allCards[0]));
      }
      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
        currentNode: makeNode(bossRewardType: BossRewardType.cards),
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
      );
      rewardController.collectGoldAndXp();
      expect(rewardController.state.isResolved, isFalse);

      final deckSizeBefore = container.read(deckProvider).masterDeck.length;
      final rolled = rewardController.state.rolledCards;
      rewardController.chooseCards([rolled[0], rolled[1]]);

      expect(container.read(deckProvider).masterDeck.length, deckSizeBefore + 2);
      expect(rewardController.state.isCardsProcessed, isTrue);
      expect(rewardController.state.isResolved, isTrue);

      // Idempotent: a second call must not add more clones.
      rewardController.chooseCards([rolled[2]]);
      expect(container.read(deckProvider).masterDeck.length, deckSizeBefore + 2);
    });

    test('skipCards resolves the cards step without adding any card to the deck', () {
      for (var i = 0; i < 5; i++) {
        deckNotifier.addCardToMasterDeck(CardInstance(data: allCards[0]));
      }
      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
        currentNode: makeNode(bossRewardType: BossRewardType.cards),
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
      );
      rewardController.collectGoldAndXp();

      final deckSizeBefore = container.read(deckProvider).masterDeck.length;
      rewardController.skipCards();

      expect(container.read(deckProvider).masterDeck.length, deckSizeBefore);
      expect(rewardController.state.isCardsProcessed, isTrue);
      expect(rewardController.state.isResolved, isTrue);
    });
  });
}
