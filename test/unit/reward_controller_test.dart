import 'dart:math';

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
import 'package:roguelike_card_game/models/data/xp_curve_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:flame/extensions.dart';

import 'scripted_random.dart';
import 'shipped_data.dart';

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
      classCard: 'paladin.png',
      maxHp: 100,
      maxMana: 3,
      luck: 0,
      mastery: 0,
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
          might: 5,
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

    /// Le nombre de cartes trouvées à une victoire sur [node], les tirages de
    /// la trouvaille écrits d'avance par [script] (spec P-43 E3, §8).
    int foundOn(MapNode node, List<int> script) {
      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
        currentNode: node,
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
        random: ScriptedRandom(script),
      );
      return rewardController.state.foundCards.length;
    }

    setUp(() {
      // `collectGoldAndXp` appelle `gainXp`, qui lit le palier : un conteneur
      // nu reçoit la courbe surchargée (spec P-43 E3, §8, « Le piège du
      // montage »).
      container = ProviderContainer(
        overrides: [
          xpCurveProvider.overrideWithValue(const XpCurveData([115, 200])),
        ],
      );
      rewardController = container.read(rewardProvider.notifier);
      runController = container.read(runProvider.notifier);
      inventoryController = container.read(inventoryProvider.notifier);
      deckNotifier = container.read(deckProvider.notifier);

      runController.startNewRun(dummyHero);
    });

    tearDown(() {
      container.dispose();
    });

    test('handleVictory sums gold/xp across enemies with per-level scaling, no relic nor boss clone but one found card on a normal combat node', () {
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
      // La trouvaille (spec P-43 E3, §4.1) : `c_normal`, la seule carte que
      // le paladin puisse recevoir — `c_status` est un statut, `c_unique`
      // une signature.
      expect(
        rewardController.state.foundCards.map((c) => c.data.id),
        ['c_normal'],
      );
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

    test('handleVictory ne propose jamais de carte unique au draft de boss', () {
      deckNotifier.addCardToMasterDeck(CardInstance(data: allCards[0]));
      deckNotifier.addCardToMasterDeck(CardInstance(data: allCards[2]));

      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
        currentNode: makeNode(bossRewardType: BossRewardType.cards),
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
      );

      expect(
        rewardController.state.rolledCards.map((c) => c.data.id),
        ['c_normal'],
      );
    });

    test('le bonus de boss d un mage ne tire jamais la signature d une autre classe', () {
      const mageHero = HeroData(
        id: 'mage',
        nameEn: 'Mage',
        nameFr: 'Mage',
        classCard: 'mage.png',
        maxHp: 80,
        maxMana: 4,
        luck: 0,
        mastery: 0,
      );
      runController.startNewRun(mageHero);

      const mixedCards = [
        ...allCards,
        CardData(
          id: 'signature_mage',
          cost: 2,
          type: CardType.attack,
          category: CardCategory.characterSpecific,
          heroClass: 'mage',
          rarity: CardRarity.rare,
          target: CardTarget.singleEnemy,
          effects: [],
        ),
        CardData(
          id: 'signature_paladin',
          cost: 2,
          type: CardType.attack,
          category: CardCategory.characterSpecific,
          heroClass: 'paladin',
          rarity: CardRarity.rare,
          target: CardTarget.singleEnemy,
          effects: [],
        ),
        CardData(
          id: 'signature_berserker',
          cost: 2,
          type: CardType.attack,
          category: CardCategory.characterSpecific,
          heroClass: 'berserker',
          rarity: CardRarity.rare,
          target: CardTarget.singleEnemy,
          effects: [],
        ),
      ];

      final rolled = <String>{};
      for (var i = 0; i < 200; i++) {
        rewardController.handleVictory(
          defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
          currentNode: makeNode(type: MapNodeType.boss, bossRewardType: BossRewardType.doubleXp),
          allRelics: allRelics,
          allCards: mixedCards,
          luck: 0,
          act: 1,
        );
        rolled.add(rewardController.state.rolledBonusCard!.id);
      }

      expect(rolled, isNot(contains('signature_paladin')));
      expect(rolled, isNot(contains('signature_berserker')));
      expect(rolled, contains('signature_mage'));
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

    // La trouvaille (spec P-43 E3, §4.1, §8 ; D1, D31).
    group('la trouvaille', () {
      test('une carte en combat, une ou deux en elite, aucune au boss', () {
        expect(foundOn(makeNode(), [99]), 1);
        expect(foundOn(makeNode(type: MapNodeType.elite), [24]), 2);
        expect(foundOn(makeNode(type: MapNodeType.elite), [25]), 1);
        for (final reward in BossRewardType.values) {
          expect(
            foundOn(
              makeNode(type: MapNodeType.boss, bossRewardType: reward),
              [0],
            ),
            0,
            reason: reward.name,
          );
        }
      });

      test('les cartes trouvees sont communes et sans rune', () {
        const rare = CardData(
          id: 'c_rare',
          cost: 1,
          type: CardType.attack,
          category: CardCategory.global,
          rarity: CardRarity.rare,
          target: CardTarget.singleEnemy,
          effects: [],
        );
        final rng = Random(3);
        final seen = <String>{};

        for (var i = 0; i < 100; i++) {
          rewardController.handleVictory(
            defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
            currentNode: makeNode(),
            allRelics: allRelics,
            allCards: [...allCards, rare],
            luck: 0,
            act: 1,
            random: rng,
          );
          for (final card in rewardController.state.foundCards) {
            expect(card.rarity, CardRarity.common, reason: card.data.id);
            expect(card.forgeUpgrades, isEmpty, reason: card.data.id);
            seen.add(card.data.id);
          }
        }

        // La rare de la donnee est trouvee, et trouvee commune.
        expect(seen, {'c_normal', 'c_rare'});
      });

      test('collectGoldAndXp ajoute les cartes trouvees au deck, une seule '
          'fois', () {
        expect(foundOn(makeNode(type: MapNodeType.elite), [24]), 2);
        final found = rewardController.state.foundCards;

        rewardController.collectGoldAndXp();
        expect(
          container.read(deckProvider).masterDeck.map((c) => c.uniqueId),
          found.map((c) => c.uniqueId),
        );

        // Idempotent : un second appel n'ajoute rien.
        rewardController.collectGoldAndXp();
        expect(container.read(deckProvider).masterDeck, hasLength(2));
      });

      test('la trouvaille ne tire que ce que la classe peut recevoir, jamais '
          'une unique', () {
        const mage = HeroData(
          id: 'mage',
          nameEn: 'Mage',
          nameFr: 'Mage',
          classCard: 'mage.png',
          maxHp: 80,
          maxMana: 4,
          luck: 0,
          mastery: 0,
        );
        runController.startNewRun(mage);

        CardData classCard(String id, String heroClass, CardRarity rarity) =>
            CardData(
              id: id,
              cost: 1,
              type: CardType.attack,
              category: CardCategory.characterSpecific,
              heroClass: heroClass,
              rarity: rarity,
              target: CardTarget.singleEnemy,
              effects: const [],
            );
        final mixedCards = [
          ...allCards,
          classCard('mage_rare', 'mage', CardRarity.rare),
          classCard('paladin_rare', 'paladin', CardRarity.rare),
          classCard('berserker_rare', 'berserker', CardRarity.rare),
          // Une unique de la classe du joueur : sa signature.
          classCard('mage_signature', 'mage', CardRarity.unique),
        ];
        final rng = Random(11);
        final seen = <String>{};

        for (var i = 0; i < 200; i++) {
          rewardController.handleVictory(
            defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
            currentNode: makeNode(),
            allRelics: allRelics,
            allCards: mixedCards,
            luck: 0,
            act: 1,
            random: rng,
          );
          // La donnee de la carte, jamais `card.rarity` : l'instance est
          // construite commune (spec §4.1), l'assertion ne garderait rien.
          for (final card in rewardController.state.foundCards) {
            expect(card.data.heroClass, anyOf(isNull, 'mage'),
                reason: card.data.id);
            expect(card.data.rarity, isNot(CardRarity.unique),
                reason: card.data.id);
            seen.add(card.data.id);
          }
        }

        // Les cartes de la classe du joueur sont admises.
        expect(seen, contains('mage_rare'));
      });

      test('sans carte offerte, la trouvaille ne donne rien, sans lever', () {
        // Seulement un statut et une signature : aucune carte offerte.
        rewardController.handleVictory(
          defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
          currentNode: makeNode(type: MapNodeType.elite),
          allRelics: allRelics,
          allCards: [allCards[1], allCards[2]],
          luck: 0,
          act: 1,
          random: ScriptedRandom([0]),
        );
        expect(rewardController.state.foundCards, isEmpty);

        rewardController.collectGoldAndXp();
        expect(container.read(deckProvider).masterDeck, isEmpty);
      });
    });

    // Les bonus des reliques, lus par `handleVictory` (spec P-43 E3, §4.1) :
    // C ne touche que le combat normal, A que l'élite (D31, D57).
    group('les reliques de la trouvaille', () {
      test('la Sacoche du glaneur ajoute une carte au combat normal, jamais a '
          'l elite', () {
        inventoryController.addRelic(shippedRelic('gleaners_pouch'));

        expect(foundOn(makeNode(), [99]), 2);
        expect(foundOn(makeNode(type: MapNodeType.elite), [25]), 1);
      });

      test('trois Registres des primes portent le jet d elite a 100, jamais '
          'le combat normal', () {
        for (var i = 0; i < 3; i++) {
          inventoryController.addRelic(shippedRelic('bounty_ledger'));
        }
        expect(runController.state.eliteCardChanceBonus, 75);

        // 99 rate a 25, passe a 100.
        expect(foundOn(makeNode(type: MapNodeType.elite), [99]), 2);
        expect(foundOn(makeNode(), [0]), 1);
      });

      test('aucune des deux ne fait trouver une carte au boss', () {
        inventoryController.addRelic(shippedRelic('gleaners_pouch'));
        inventoryController.addRelic(shippedRelic('bounty_ledger'));

        for (final reward in BossRewardType.values) {
          expect(
            foundOn(
              makeNode(type: MapNodeType.boss, bossRewardType: reward),
              [0],
            ),
            0,
            reason: reward.name,
          );
        }
      });
    });
  });
}
