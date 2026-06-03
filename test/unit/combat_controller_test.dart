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
        final combatController = CombatController();

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

        // Elite Node (Enemy Lvl 2: HP Multiplier = 1.12 * 1.5 = 1.68)
        combatController.initializeCombat(1, MapNodeType.elite, [goblinData]);
        final eliteGoblin = combatController.currentState.enemies.first;
        expect(eliteGoblin.stats.maxPv, 34); // 20 * 1.68 = 33.6 -> 34
        expect(eliteGoblin.stats.attaque, 8); // 5 * 1.62 = 8.1 -> 8

        // Boss Node (Enemy Lvl 3: HP Multiplier = 1.24 * 3.0 = 3.72)
        combatController.initializeCombat(1, MapNodeType.boss, [goblinData]);
        expect(combatController.currentState.enemies.length, 1);
        final bossGoblin = combatController.currentState.enemies.first;
        expect(bossGoblin.stats.maxPv, 74); // 20 * 3.72 = 74.4 -> 74
        expect(bossGoblin.stats.attaque, 17); // 5 * 3.48 = 17.4 -> 17
      },
    );

    test('selectEnemy updates targeted enemy and handles null selection', () {
      final combatController = CombatController();

      final enemy1 = EnemyInstance(
        data: goblinData,
        stats: const EntityStats(
          maxPv: 20,
          currentPv: 20,
          armure: 0,
          attaque: 5,
        ),
      );
      final enemy2 = EnemyInstance(
        data: orcData,
        stats: const EntityStats(
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
      final combatController = CombatController();
      final container = ProviderContainer();
      final runController = container.read(runProvider.notifier);
      runController.startNewRun(paladinHero);

      final enemy = EnemyInstance(
        data: goblinData,
        stats: const EntityStats(
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
      combatController.resolveEnemyIntent(enemy.id, runController);

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
      combatController.resolveEnemyIntent(updatedEnemy.id, runController);
      final defendedEnemy = combatController.currentState.enemies.first;
      // Enemy armor should increase by 6
      expect(defendedEnemy.stats.armure, 6);
    });

    test(
      'startEnemyTurn ticks statuses (Poison) on all enemies and cleans up dead ones',
      () {
        final combatController = CombatController();
        final container = ProviderContainer();
        final runController = container.read(runProvider.notifier);
        runController.startNewRun(paladinHero);

        final enemy1 = EnemyInstance(
          data: goblinData,
          stats: const EntityStats(
            maxPv: 20,
            currentPv: 20,
            armure: 0,
            attaque: 5,
          ),
        );
        final enemy2 = EnemyInstance(
          data: orcData,
          stats: const EntityStats(
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
        combatController.startEnemyTurn(runController);

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
        final combatController = CombatController();
        final container = ProviderContainer();
        final runController = container.read(runProvider.notifier);
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

        final deckNotifier = DeckNotifier();

        final enemy = EnemyInstance(
          data: goblinData,
          stats: const EntityStats(
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
        deckNotifier.initializeCombat();
        deckNotifier.state = deckNotifier.state.copyWith(hand: [strikeCard]);

        expect(runController.currentState.heroStats.currentMana, 3);
        expect(combatController.currentState.enemies.first.stats.currentPv, 20);

        // Play strike: hero effectiveAttaque is 5, card damage is 6, total damage is 6 + 5 = 11.
        combatController.applyPlayerCardPlay(
          strikeCard,
          runController,
          deckNotifier,
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
          runController,
          deckNotifier,
        );

        expect(combatController.currentState.enemies.isEmpty, isTrue);
        expect(combatController.currentState.isCombatEnded, isTrue);
        expect(combatController.currentState.isVictory, isTrue);
      },
    );

    test(
      'initializeCombat has null selectedEnemyId and does not auto-select on enemy death',
      () {
        final combatController = CombatController();
        final container = ProviderContainer();
        final runController = container.read(runProvider.notifier);
        runController.startNewRun(paladinHero);

        final enemy1 = EnemyInstance(
          data: goblinData,
          stats: const EntityStats(
            maxPv: 20,
            currentPv: 20,
            armure: 0,
            attaque: 5,
          ),
        );
        final enemy2 = EnemyInstance(
          data: orcData,
          stats: const EntityStats(
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
          const EntityStats(maxPv: 20, currentPv: 0, armure: 0, attaque: 5),
        );
        combatController.startEnemyTurn(
          runController,
        ); // This will clean up dead enemies (enemy1)

        // enemy1 is dead, selectedEnemyId should now be null, NOT fallback to enemy2
        expect(combatController.currentState.selectedEnemyId, isNull);
      },
    );

    test(
      'Burn, Freeze, and Shock status effects are resolved correctly in combat',
      () {
        final combatController = CombatController();
        final container = ProviderContainer();
        final runController = container.read(runProvider.notifier);
        runController.startNewRun(paladinHero);

        final enemy = EnemyInstance(
          data: goblinData,
          stats: const EntityStats(
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
        final deckNotifier = DeckNotifier();
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
        deckNotifier.initializeCombat();
        deckNotifier.state = deckNotifier.state.copyWith(hand: [strikeCard]);

        combatController.applyPlayerCardPlay(
          strikeCard,
          runController,
          deckNotifier,
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
        combatController.resolveEnemyIntent(enemy.id, runController);

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
        combatController.resolveEnemyIntent(enemy.id, runController);

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
          runController,
          deckNotifier,
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
        combatController.startEnemyTurn(runController);

        // Enemy HP should decrease by 3 due to burn, so 11 - 3 = 8
        expect(
          combatController.currentState.enemies.first.stats.currentPv,
          enemyHpBeforeBurn - 3,
        );
      },
    );
  });
}
