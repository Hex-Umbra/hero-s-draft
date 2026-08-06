import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/enemy_intent.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/status_effect.dart';
import 'package:roguelike_card_game/models/map_node.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/data/skill_data.dart';
import 'package:roguelike_card_game/game/game_constants.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';

void main() {
  group('CombatController Tests', () {
    final goblinData = EnemyData(
      id: 'goblin',
      nameEn: 'Goblin',
      nameFr: 'Gobelin',
      maxHp: 20,
      baseDamage: 5,
      spritePath: 'goblin.png',
      tier: 1,
      intents: [
        EnemyIntent(type: IntentType.attack, value: 5),
        EnemyIntent(type: IntentType.defend, value: 6),
      ],
    );

    final orcData = EnemyData(
      id: 'orc',
      nameEn: 'Orc',
      nameFr: 'Orque',
      maxHp: 30,
      baseDamage: 8,
      spritePath: 'orc.png',
      tier: 2,
      intents: [EnemyIntent(type: IntentType.attack, value: 8)],
    );

    final paladinHero = HeroData(
      id: 'paladin',
      nameEn: 'Paladin',
      nameFr: 'Paladin',
      descriptionEn: 'A holy knight',
      descriptionFr: 'Un saint chevalier',
      iconPath: 'paladin.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
      luck: 0,
      armorMastery: 0,
      passiveTrait: 'regenArmor',
    );

    test(
      'initializeCombat sets state, scales hp/attack for standard/elite/boss nodes, and rolls first intent',
      () {
        final container = ProviderContainer();
        final combatController = container.read(combatProvider.notifier);

        // Standard Node
        combatController.initializeCombat(1, MapNodeType.combat, [goblinData]);
        expect(
          combatController.currentState.enemies.length,
          greaterThanOrEqualTo(1),
        );
        expect(
          combatController.currentState.enemies.length,
          lessThanOrEqualTo(2),
        );

        final goblinInstance = combatController.currentState.enemies.first;
        expect(goblinInstance.stats.maxPv, 20); // 20 * 1.0
        expect(goblinInstance.stats.attaque, 5); // 5 * 1.0
        expect(goblinInstance.currentIntent?.type, IntentType.attack);
        expect(goblinInstance.intentStep, 1); // incremented step
        expect(combatController.currentState.selectedEnemyId, isNull);
        expect(combatController.currentState.turnPhase, TurnPhase.player);
        expect(combatController.currentState.isCombatEnded, isFalse);

        // Elite Node (Enemy Lvl 2: HP Multiplier = 1.06 * 1.5 = 1.59)
        combatController.initializeCombat(1, MapNodeType.elite, [goblinData]);
        final eliteGoblin = combatController.currentState.enemies.first;
        expect(eliteGoblin.stats.maxPv, 32); // 20 * 1.59 = 31.8 -> 32
        expect(eliteGoblin.stats.attaque, 8); // 5 * 1.56 = 7.8 -> 8

        // Boss Node (Enemy Lvl 3: HP Multiplier = 1.12 * 3.0 = 3.36)
        combatController.initializeCombat(1, MapNodeType.boss, [goblinData]);
        expect(combatController.currentState.enemies.length, 1);
        final bossGoblin = combatController.currentState.enemies.first;
        expect(bossGoblin.stats.maxPv, 67); // 20 * 3.36 = 67.2 -> 67
        expect(bossGoblin.stats.attaque, 16); // 5 * 3.24 = 16.2 -> 16
      },
    );

    test('selectEnemy updates targeted enemy and handles null selection', () {
      final container = ProviderContainer();
      final combatController = container.read(combatProvider.notifier);

      final enemy1 = EnemyInstance(
        data: goblinData,
        stats: EntityStats(
          maxPv: 20,
          currentPv: 20,
          armure: 0,
          attaque: 5,
        ),
      );
      final enemy2 = EnemyInstance(
        data: orcData,
        stats: EntityStats(
          maxPv: 30,
          currentPv: 30,
          armure: 0,
          attaque: 8,
        ),
      );

      combatController.state = CombatState(
        enemies: [enemy1, enemy2],
        selectedEnemyId: enemy1.id,
        turnPhase: TurnPhase.player,
      );

      expect(combatController.currentState.enemies.length, 2);
      expect(combatController.currentState.selectedEnemyId, enemy1.id);

      combatController.selectEnemy(enemy2.id);
      expect(combatController.currentState.selectedEnemyId, enemy2.id);

      combatController.selectEnemy(null);
      expect(combatController.currentState.selectedEnemyId, isNull);
    });

    test('resolveEnemyIntent applies intent effects to the player and self', () {
      final container = ProviderContainer();
      final combatController = container.read(combatProvider.notifier);
      final runController = container.read(runProvider.notifier);
      runController.startNewRun(paladinHero);

      final enemy = EnemyInstance(
        data: goblinData,
        stats: EntityStats(
          maxPv: 20,
          currentPv: 20,
          armure: 0,
          attaque: 5,
        ),
        currentIntent: EnemyIntent(type: IntentType.attack, value: 5),
        intentStep: 1,
      );

      combatController.state = CombatState(
        enemies: [enemy],
        selectedEnemyId: enemy.id,
        turnPhase: TurnPhase.enemy,
      );

      // Intent 1: Attack 5
      expect(enemy.currentIntent?.type, IntentType.attack);
      expect(enemy.currentIntent?.value, 5);

      final playerHpBefore =
          runController.currentState.heroStats.currentPv; // 100
      combatController.resolveEnemyIntent(enemy.id);

      // Player HP should decrease by 5
      expect(
        runController.currentState.heroStats.currentPv,
        playerHpBefore - 5,
      );

      // Roll intent to defend
      combatController
          .endEnemyTurn(); // goblin step 1 -> step 2 (defend) -> step 0 (wrapped since intents length is 2)
      final updatedEnemy = combatController.currentState.enemies.first;
      expect(updatedEnemy.currentIntent?.type, IntentType.defend);
      expect(updatedEnemy.currentIntent?.value, 6);
      expect(updatedEnemy.stats.armure, 0);

      // Apply defense intent
      combatController.resolveEnemyIntent(updatedEnemy.id);
      final defendedEnemy = combatController.currentState.enemies.first;
      // Enemy armor should increase by 6
      expect(defendedEnemy.stats.armure, 6);
    });

    test(
      'startEnemyTurn ticks statuses (Poison) on all enemies and cleans up dead ones',
      () {
        final container = ProviderContainer();
        final combatController = container.read(combatProvider.notifier);
        final runController = container.read(runProvider.notifier);
        runController.startNewRun(paladinHero);

        final enemy1 = EnemyInstance(
          data: goblinData,
          stats: EntityStats(
            maxPv: 20,
            currentPv: 20,
            armure: 0,
            attaque: 5,
          ),
        );
        final enemy2 = EnemyInstance(
          data: orcData,
          stats: EntityStats(
            maxPv: 30,
            currentPv: 30,
            armure: 0,
            attaque: 8,
          ),
        );

        combatController.state = CombatState(
          enemies: [enemy1, enemy2],
          selectedEnemyId: enemy1.id,
          turnPhase: TurnPhase.player,
        );

        // Add Poison: goblin gets 3 poison, orc gets 50 poison (lethal)
        combatController.updateEnemyStats(
          enemy1.id,
          enemy1.stats.addStatus(
            const StatusEffect(
              id: 'poison',
              name: 'Poison',
              type: StatusType.debuff,
              value: 3,
              duration: 2,
            ),
          ),
        );

        combatController.updateEnemyStats(
          enemy2.id,
          enemy2.stats.addStatus(
            const StatusEffect(
              id: 'poison',
              name: 'Poison',
              type: StatusType.debuff,
              value: 50,
              duration: 2,
            ),
          ),
        );

        // Verify states before turn start
        expect(combatController.currentState.enemies.length, 2);
        expect(combatController.currentState.enemies[0].stats.currentPv, 20);
        expect(combatController.currentState.enemies[1].stats.currentPv, 30);

        // Act
        combatController.startEnemyTurn();

        // Assert: Orc should be dead (cleared), goblin should take 3 poison damage (current HP: 17)
        expect(combatController.currentState.enemies.length, 1);
        expect(combatController.currentState.enemies.first.id, enemy1.id);
        expect(combatController.currentState.enemies.first.stats.currentPv, 17);
        // Poison duration ticked down by 1 (2 -> 1)
        expect(
          combatController
              .currentState
              .enemies
              .first
              .stats
              .statuses
              .first
              .duration,
          1,
        );
      },
    );

    test(
      'applyPlayerCardPlay plays Strike card, consumes mana, resolves damage, and cleans dead enemies',
      () {
        final container = ProviderContainer();
        final combatController = container.read(combatProvider.notifier);
        final runController = container.read(runProvider.notifier);
        final deckNotifier = container.read(deckProvider.notifier);

        runController.startNewRun(paladinHero);

        // Inject +5 strength to player hero to test force bonus scaling (Strike 6 + 5 = 11 dmg)
        runController.addStatus(
          const StatusEffect(
            id: 'strength',
            name: 'Force',
            type: StatusType.buff,
            value: 5,
            duration: 99,
          ),
        );

        final enemy = EnemyInstance(
          data: goblinData,
          stats: EntityStats(
            maxPv: 20,
            currentPv: 20,
            armure: 0,
            attaque: 5,
          ),
        );

        combatController.state = CombatState(
          enemies: [enemy],
          selectedEnemyId: enemy.id,
          turnPhase: TurnPhase.player,
        );

        final strikeCard = CardInstance(
          data: const CardData(
            id: 'strike',
            nameEn: 'Strike',
            nameFr: 'Frappe',
            descriptionEn: 'Deals 6 damage.',
            descriptionFr: 'Inflige 6 dégâts.',
            cost: 1,
            type: CardType.attack,
            category: CardCategory.global,
            rarity: CardRarity.common,
            target: CardTarget.singleEnemy,
            effects: [CardEffect(type: 'damage', value: 6)],
          ),
        );

        deckNotifier.initializeStarterDeck([strikeCard]);
        deckNotifier.startCombat(handSize: 0, maxHandSize: GameConstants.maxHandSize);
        deckNotifier.state = deckNotifier.state.copyWith(hand: [strikeCard]);

        expect(runController.currentState.heroStats.currentMana, 3);
        expect(combatController.currentState.enemies.first.stats.currentPv, 20);

        // Play strike: hero effectiveAttaque is 5, card damage is 6, total damage is 6 + 5 = 11.
        combatController.applyPlayerCardPlay(
          strikeCard,
        );

        expect(
          runController.currentState.heroStats.currentMana,
          2,
        ); // cost 1 mana
        expect(
          combatController.currentState.enemies.first.stats.currentPv,
          9,
        ); // 20 - 11 = 9
        expect(combatController.currentState.isCombatEnded, isFalse);

        // Re-add to hand for the second play (since the first play discarded it)
        deckNotifier.state = deckNotifier.state.copyWith(hand: [strikeCard]);

        // Play strike again: HP 9 - 11 <= 0. Enemy should die, combat should end.
        combatController.applyPlayerCardPlay(
          strikeCard,
        );

        expect(combatController.currentState.enemies.isEmpty, isTrue);
        expect(combatController.currentState.isCombatEnded, isTrue);
        expect(combatController.currentState.isVictory, isTrue);
      },
    );

    test(
      'initializeCombat has null selectedEnemyId and does not auto-select on enemy death',
      () {
        final container = ProviderContainer();
        final combatController = container.read(combatProvider.notifier);
        final runController = container.read(runProvider.notifier);
        runController.startNewRun(paladinHero);

        final enemy1 = EnemyInstance(
          data: goblinData,
          stats: EntityStats(
            maxPv: 20,
            currentPv: 20,
            armure: 0,
            attaque: 5,
          ),
        );
        final enemy2 = EnemyInstance(
          data: orcData,
          stats: EntityStats(
            maxPv: 30,
            currentPv: 30,
            armure: 0,
            attaque: 8,
          ),
        );

        combatController.state = CombatState(
          enemies: [enemy1, enemy2],
          selectedEnemyId: null,
          turnPhase: TurnPhase.player,
        );
        expect(combatController.currentState.selectedEnemyId, isNull);

        // Explicitly select enemy1
        final actualEnemy1Id = enemy1.id;
        combatController.selectEnemy(actualEnemy1Id);
        expect(combatController.currentState.selectedEnemyId, actualEnemy1Id);

        // Kill enemy1
        combatController.updateEnemyStats(
          actualEnemy1Id,
          EntityStats(maxPv: 20, currentPv: 0, armure: 0, attaque: 5),
        );
        combatController.startEnemyTurn(); // This will clean up dead enemies (enemy1)

        // enemy1 is dead, selectedEnemyId should now be null, NOT fallback to enemy2
        expect(combatController.currentState.selectedEnemyId, isNull);
      },
    );

    test(
      'Burn, Freeze, and Shock status effects are resolved correctly in combat',
      () {
        final container = ProviderContainer();
        final combatController = container.read(combatProvider.notifier);
        final runController = container.read(runProvider.notifier);
        final deckNotifier = container.read(deckProvider.notifier);

        runController.startNewRun(paladinHero);

        final enemy = EnemyInstance(
          data: goblinData,
          stats: EntityStats(
            maxPv: 20,
            currentPv: 20,
            armure: 0,
            attaque: 5,
          ),
          currentIntent: EnemyIntent(type: IntentType.attack, value: 10),
        );

        combatController.state = CombatState(
          enemies: [enemy],
          selectedEnemyId: enemy.id,
          turnPhase: TurnPhase.player,
        );

        // 1. SHOCK TEST
        // Apply shock status with value 4 to the enemy
        combatController.updateEnemyStats(
          enemy.id,
          combatController.currentState.enemies.first.stats.addStatus(
            const StatusEffect(
              id: 'shock',
              name: 'Électrocution',
              type: StatusType.debuff,
              value: 4,
              duration: 2,
            ),
          ),
        );

        // Play a card that deals 6 damage (Strike).
        // Since strength is 0, base damage = 6. With shock, it should do 6 + 4 = 10 damage.
        final strikeCard = CardInstance(
          data: const CardData(
            id: 'strike',
            nameEn: 'Strike',
            nameFr: 'Frappe',
            descriptionEn: 'Deals 6 damage.',
            descriptionFr: 'Inflige 6 dégâts.',
            cost: 1,
            type: CardType.attack,
            category: CardCategory.global,
            rarity: CardRarity.common,
            target: CardTarget.singleEnemy,
            effects: [CardEffect(type: 'damage', value: 6)],
          ),
        );

        deckNotifier.initializeStarterDeck([strikeCard]);
        deckNotifier.startCombat(handSize: 0, maxHandSize: GameConstants.maxHandSize);
        deckNotifier.state = deckNotifier.state.copyWith(hand: [strikeCard]);

        combatController.applyPlayerCardPlay(
          strikeCard,
        );

        // Enemy HP should be 20 - 10 = 10
        expect(combatController.currentState.enemies.first.stats.currentPv, 10);

        // 2. FREEZE TEST
        // Add freeze status to the enemy
        combatController.updateEnemyStats(
          enemy.id,
          combatController.currentState.enemies.first.stats.addStatus(
            const StatusEffect(
              id: 'freeze',
              name: 'Gel',
              type: StatusType.debuff,
              value: 1,
              duration: 2,
            ),
          ),
        );

        // Set enemy's intent to Attack 10
        combatController.state = combatController.state.copyWith(
          enemies: [
            combatController.currentState.enemies.first.copyWith(
              currentIntent: EnemyIntent(type: IntentType.attack, value: 10),
            ),
          ],
        );

        final playerHpBeforeAttack =
            runController.currentState.heroStats.currentPv; // should be 100
        combatController.resolveEnemyIntent(enemy.id);

        // Attack damage of 10 should be halved to 5 because of freeze
        expect(
          runController.currentState.heroStats.currentPv,
          playerHpBeforeAttack - 5,
        );

        // Verify that freeze duration decreased by 1 (was 2, now 1)
        expect(
          combatController.currentState.enemies.first.stats.statuses.firstWhere((s) => s.id == 'freeze').duration,
          1,
        );

        // 3. VULNERABLE TEST (Enemy to Player)
        // Reset player HP to 100
        runController.setHeroStats(currentPv: 100);
        // Add vulnerable status to hero
        runController.addStatus(
          const StatusEffect(
            id: 'vulnerable',
            name: 'Vulnérable',
            type: StatusType.debuff,
            value: 1,
            duration: 2,
          ),
        );
        // Enemy attacks with 10. Halved to 5 because of freeze (which is now at duration 1),
        // then multiplied by 1.5 because of vulnerable: 5 * 1.5 = 7.5 -> 8.
        final playerHpBeforeVulnerableAttack =
            runController.currentState.heroStats.currentPv; // 100
        combatController.resolveEnemyIntent(enemy.id);

        expect(
          runController.currentState.heroStats.currentPv,
          playerHpBeforeVulnerableAttack - 8,
        );

        // Verify that freeze status is now removed because its duration dropped to 0
        expect(
          combatController.currentState.enemies.first.stats.statuses.any((s) => s.id == 'freeze'),
          isFalse,
        );

        // 4. VULNERABLE TEST (Player to Enemy)
        // Reset enemy HP to 20 and clear existing statuses (like shock)
        combatController.updateEnemyStats(
          enemy.id,
          combatController.currentState.enemies.first.stats.copyWith(currentPv: 20, statuses: []),
        );
        // Add vulnerable status to enemy
        combatController.updateEnemyStats(
          enemy.id,
          combatController.currentState.enemies.first.stats.addStatus(
            const StatusEffect(
              id: 'vulnerable',
              name: 'Vulnérable',
              type: StatusType.debuff,
              value: 1,
              duration: 2,
            ),
          ),
        );
        // Play a card that deals 6 damage (Strike).
        // Since strength is 0, base damage = 6.
        // Enemy has vulnerable, so damage should be 6 * 1.5 = 9.
        deckNotifier.state = deckNotifier.state.copyWith(hand: [strikeCard]);
        combatController.applyPlayerCardPlay(
          strikeCard,
        );
        // Enemy HP should be 20 - 9 = 11.
        expect(combatController.currentState.enemies.first.stats.currentPv, 11);

        // 5. BURN TEST
        // Add burn status with value 3 to the enemy
        combatController.updateEnemyStats(
          enemy.id,
          combatController.currentState.enemies.first.stats.addStatus(
            const StatusEffect(
              id: 'burn',
              name: 'Brûlure',
              type: StatusType.debuff,
              value: 3,
              duration: 2,
            ),
          ),
        );

        final enemyHpBeforeBurn = combatController
            .currentState
            .enemies
            .first
            .stats
            .currentPv; // should be 11
        combatController.startEnemyTurn();

        // Enemy HP should decrease by 3 due to burn, so 11 - 3 = 8
        expect(
          combatController.currentState.enemies.first.stats.currentPv,
          enemyHpBeforeBurn - 3,
        );
      },
    );

    test('executeSkill resolves damage_aoe, damage_targeted, damage_pierce, and armor_buff correctly', () {
      final container = ProviderContainer();
      final combatController = container.read(combatProvider.notifier);
      final runController = container.read(runProvider.notifier);
      runController.startNewRun(paladinHero);
      runController.state = runController.state.copyWith(
        heroStats: runController.state.heroStats.copyWith(attaque: 5),
      );

      final enemy1 = EnemyInstance(
        data: goblinData,
        stats: EntityStats(
          maxPv: 20,
          currentPv: 20,
          armure: 10,
          attaque: 5,
        ),
      );
      final enemy2 = EnemyInstance(
        data: orcData,
        stats: EntityStats(
          maxPv: 30,
          currentPv: 30,
          armure: 0,
          attaque: 8,
        ),
      );

      combatController.state = CombatState(
        enemies: [enemy1, enemy2],
        selectedEnemyId: enemy1.id,
        turnPhase: TurnPhase.player,
      );

      // 1. damage_aoe test
      // Hero base damage is 5 (effectiveAttaque = 5 since strength is 0)
      // effectValue = 200 (i.e. 200% scaling -> 5 * 2.0 = 10 damage)
      final aoeSkill = const SkillData(
        id: 'aoe_test',
        name: 'AOE Test',
        manaCost: 0,
        effectType: 'damage_aoe',
        effectValue: 200,
      );

      combatController.executeSkill(aoeSkill);
      // Enemy 2 has 30 HP, 0 armor. 30 - 10 = 20.
      expect(combatController.currentState.enemies[1].stats.currentPv, 20);

      // 2. damage_targeted test
      // Target enemy 1 (which has 10 armor and 20 HP originally).
      // aoe skill did 10 damage: takeDamage(10) -> armor becomes 0, PV remains 20.
      // Now, let's do a targeted skill on enemy1: 100% scaling -> 5 damage.
      final targetedSkill = const SkillData(
        id: 'targeted_test',
        name: 'Targeted Test',
        manaCost: 0,
        effectType: 'damage_targeted',
        effectValue: 100,
      );
      combatController.executeSkill(targetedSkill, targetEnemyId: enemy1.id);
      // enemy1 has 0 armor, 20 HP. -5 damage -> 15 HP.
      expect(combatController.currentState.enemies[0].stats.currentPv, 15);

      // 3. damage_pierce test
      // Deals effectiveAttaque (5 damage) and steals effectValue% armor (50% armor)
      // Let's first set enemy1 armor to 10
      combatController.updateEnemyStats(
        enemy1.id,
        combatController.currentState.enemies[0].stats.copyWith(armure: 10),
      );
      final pierceSkill = const SkillData(
        id: 'pierce_test',
        name: 'Pierce Test',
        manaCost: 0,
        effectType: 'damage_pierce',
        effectValue: 50,
      );
      final heroArmorBefore = runController.currentState.heroStats.armure;
      combatController.executeSkill(pierceSkill, targetEnemyId: enemy1.id);
      // Stolen armor: 10 * 50% = 5.
      // Enemy armor: 10 - 5 = 5.
      // Enemy HP: 15 - 5 = 10.
      expect(combatController.currentState.enemies[0].stats.armure, 5);
      expect(combatController.currentState.enemies[0].stats.currentPv, 10);
      expect(runController.currentState.heroStats.armure, heroArmorBefore + 5);

      // 4. armor_buff test
      final armorBuffSkill = const SkillData(
        id: 'armor_test',
        name: 'Armor Test',
        manaCost: 0,
        effectType: 'armor_buff',
        effectValue: 8,
      );
      final heroArmorBeforeBuff = runController.currentState.heroStats.armure;
      combatController.executeSkill(armorBuffSkill);
      expect(runController.currentState.heroStats.armure, heroArmorBeforeBuff + 8);
    });
  });

  group('CombatController — moitié joueur du cycle de tour', () {
    // `paladinHero`, `goblinData` et `orcData` sont déclarés à l'intérieur du
    // groupe `CombatController Tests`. Ce groupe étant un frère, il ne les voit
    // pas : il déclare donc son propre héros.
    final paladinHero = HeroData(
      id: 'paladin',
      nameEn: 'Paladin',
      nameFr: 'Paladin',
      descriptionEn: 'A holy knight',
      descriptionFr: 'Un saint chevalier',
      iconPath: 'paladin.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
      luck: 0,
      armorMastery: 0,
      passiveTrait: 'regenArmor',
    );

    const ironTalisman = RelicData(
      id: 'iron_talisman',
      nameEn: 'Iron Talisman',
      nameFr: 'Talisman de Fer',
      trigger: RelicTrigger.startOfTurn,
      effectType: 'gain_armor',
      value: 2,
      rarity: RelicRarity.common,
      emoji: '🪙',
    );

    CardInstance card(String id) => CardInstance(
          data: CardData(
            id: id,
            nameEn: id,
            nameFr: id,
            cost: 1,
            type: CardType.skill,
            category: CardCategory.global,
            rarity: CardRarity.common,
            target: CardTarget.self,
            effects: const [],
          ),
        );

    test('startPlayerTurn exécute la relique startOfTurn ET la pioche', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final runController = container.read(runProvider.notifier);
      final deckNotifier = container.read(deckProvider.notifier);
      final combatController = container.read(combatProvider.notifier);

      runController.startNewRun(paladinHero);
      container.read(inventoryProvider.notifier).addRelic(ironTalisman);
      deckNotifier.initializeStarterDeck(List.generate(10, (i) => card('c$i')));
      deckNotifier.startCombat(handSize: 0, maxHandSize: GameConstants.maxHandSize);

      combatController.startPlayerTurn();

      // Moitié « run » : mana restauré au max et armure de la relique appliquée.
      expect(runController.currentState.heroStats.currentMana,
          runController.currentState.heroStats.maxMana);
      expect(runController.currentState.heroStats.armure, 2);
      // Moitié « deck » : la main vaut cardsPerTurn.
      expect(deckNotifier.state.hand.length, 5);
    });

    test('startPlayerTurn pioche cardsPerTurn, pas 5 en dur', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final runController = container.read(runProvider.notifier);
      final deckNotifier = container.read(deckProvider.notifier);
      final combatController = container.read(combatProvider.notifier);

      runController.startNewRun(paladinHero);
      runController.applyRunRuleModifier(cardsPerTurnAcc: 1);
      deckNotifier.initializeStarterDeck(List.generate(10, (i) => card('c$i')));
      deckNotifier.startCombat(handSize: 0, maxHandSize: GameConstants.maxHandSize);

      combatController.startPlayerTurn();

      expect(deckNotifier.state.hand.length, 6);
    });

    test('startPlayerCombat ouvre le combat et tire la main de départ', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final runController = container.read(runProvider.notifier);
      final deckNotifier = container.read(deckProvider.notifier);
      final combatController = container.read(combatProvider.notifier);

      runController.startNewRun(paladinHero);
      deckNotifier.initializeStarterDeck(List.generate(10, (i) => card('c$i')));
      // Statut résiduel d'un combat précédent : startCombat doit le nettoyer.
      runController.addStatus(const StatusEffect(
        id: 'poison',
        name: 'Poison',
        type: StatusType.debuff,
        value: 3,
        duration: 3,
      ));

      combatController.startPlayerCombat();

      // Cible le poison plutôt que `isEmpty` : le test resterait vrai si un
      // passif ou une relique ajoutait un statut au début du combat.
      expect(
        runController.currentState.heroStats.statuses
            .any((s) => s.id == 'poison'),
        isFalse,
      );
      expect(runController.currentState.heroStats.currentMana,
          runController.currentState.heroStats.maxMana);
      expect(deckNotifier.state.hand.length, 5);
      expect(deckNotifier.state.drawPile.length, 5);
      expect(deckNotifier.state.reshuffleCount, 0);
    });
  });
}
