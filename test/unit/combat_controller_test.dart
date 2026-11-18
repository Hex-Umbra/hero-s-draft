import 'dart:convert';
import 'dart:io';

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
import 'package:roguelike_card_game/game/game_constants.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/game/systems/charge_rules.dart';
import 'package:roguelike_card_game/models/charge_track.dart';
import 'package:roguelike_card_game/models/data/charge_data.dart';
import 'package:roguelike_card_game/models/might_target.dart';

import 'enemy_phase_helper.dart';
import 'shipped_data.dart';

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
      classCard: 'paladin.png',
      maxHp: 100,
      maxMana: 3,
      luck: 0,
      mastery: 0,
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
        expect(goblinInstance.stats.might, 5); // 5 * 1.0
        expect(goblinInstance.currentIntent?.type, IntentType.attack);
        expect(goblinInstance.intentStep, 1); // incremented step
        expect(combatController.currentState.selectedEnemyId, isNull);
        expect(combatController.currentState.turnPhase, TurnPhase.player);
        expect(combatController.currentState.isCombatEnded, isFalse);

        // Elite Node (Enemy Lvl 2: HP Multiplier = 1.06 * 1.5 = 1.59)
        combatController.initializeCombat(1, MapNodeType.elite, [goblinData]);
        final eliteGoblin = combatController.currentState.enemies.first;
        expect(eliteGoblin.stats.maxPv, 32); // 20 * 1.59 = 31.8 -> 32
        expect(eliteGoblin.stats.might, 8); // 5 * 1.56 = 7.8 -> 8

        // Boss Node (Enemy Lvl 3: HP Multiplier = 1.12 * 3.0 = 3.36)
        combatController.initializeCombat(1, MapNodeType.boss, [goblinData]);
        expect(combatController.currentState.enemies.length, 1);
        final bossGoblin = combatController.currentState.enemies.first;
        expect(bossGoblin.stats.maxPv, 67); // 20 * 3.36 = 67.2 -> 67
        expect(bossGoblin.stats.might, 16); // 5 * 3.24 = 16.2 -> 16
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
          might: 5,
        ),
      );
      final enemy2 = EnemyInstance(
        data: orcData,
        stats: EntityStats(
          maxPv: 30,
          currentPv: 30,
          armure: 0,
          might: 8,
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
          might: 5,
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

    // P-43 E0 (spec, A2) : l'intention Buff pose sa Puissance au nom de
    // l'ennemi, par l'id de sa donnee ; deux Buff font une entree.
    test('l intention Buff pose une Puissance au nom de l ennemi', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final combatController = container.read(combatProvider.notifier);
      container.read(runProvider.notifier).startNewRun(paladinHero);

      final orc = EnemyInstance(
        data: orcData,
        stats: EntityStats(maxPv: 30, currentPv: 30, armure: 0, might: 8),
        currentIntent: EnemyIntent(type: IntentType.buff, value: 2),
      );
      combatController.state = CombatState(
        enemies: [orc],
        selectedEnemyId: orc.id,
        turnPhase: TurnPhase.enemy,
      );

      combatController.resolveEnemyIntent(orc.id);
      combatController.resolveEnemyIntent(orc.id);

      final might = combatController.currentState.enemies.single.stats.statuses
          .where((s) => s.id == 'might')
          .toList();
      expect(might, hasLength(1));
      expect(might.single.sourceId, 'enemy:orc');
      expect(might.single.value, 2 + 2);
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
            might: 5,
          ),
        );
        final enemy2 = EnemyInstance(
          data: orcData,
          stats: EntityStats(
            maxPv: 30,
            currentPv: 30,
            armure: 0,
            might: 8,
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
        runEnemyPhaseStart(combatController);

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
            id: 'might',
            name: 'Puissance',
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
            might: 5,
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
            rarity: CardRarity.common,
            target: CardTarget.singleEnemy,
            effects: [CardEffect(type: 'damage', value: 6)],
          ),
        );

        deckNotifier.initializeStarterDeck([strikeCard]);
        deckNotifier.startCombat(handSize: 0, maxHandSize: GameConstants.startingMaxHandSize);
        deckNotifier.state = deckNotifier.state.copyWith(hand: [strikeCard]);

        expect(runController.currentState.heroStats.currentMana, 3);
        expect(combatController.currentState.enemies.first.stats.currentPv, 20);

        // Play strike: hero effectiveMight is 5, card damage is 6, total damage is 6 + 5 = 11.
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
      'applyPlayerCardPlay declenche les reliques de la carte et du type, '
      'puis retire les ennemis morts',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final combatController = container.read(combatProvider.notifier);
        final runController = container.read(runProvider.notifier);
        final deckNotifier = container.read(deckProvider.notifier);
        runController.startNewRun(paladinHero);

        final inventory = container.read(inventoryProvider.notifier);
        inventory.addRelic(const RelicData(
          id: 'amulette_test',
          trigger: RelicTrigger.onCardPlayed,
          effectType: 'gain_armor',
          value: 1,
          rarity: RelicRarity.common,
          emoji: 'A',
        ));
        inventory.addRelic(const RelicData(
          id: 'shuriken_test',
          trigger: RelicTrigger.onAttackPlayed,
          effectType: 'charge_might_combat',
          value: 1,
          rarity: RelicRarity.common,
          emoji: 'S',
        ));

        final frail = EnemyInstance(
          data: goblinData,
          stats: EntityStats(maxPv: 10, currentPv: 10, armure: 0, might: 0),
        );
        final sturdy = EnemyInstance(
          data: orcData,
          stats: EntityStats(maxPv: 500, currentPv: 500, armure: 0, might: 0),
        );
        combatController.state = CombatState(
          enemies: [frail, sturdy],
          selectedEnemyId: frail.id,
          turnPhase: TurnPhase.player,
        );

        final attack = CardInstance(
          data: CardData.fromJson({
            'id': 'attaque_test',
            'name_en': 'Test',
            'name_fr': 'Test',
            'description_en': 'Test',
            'description_fr': 'Test',
            'cost': 0,
            'type': 'attack',
            'rarity': 'common',
            'target': 'singleEnemy',
            'effects': [
              {'type': 'damage', 'value': 999},
            ],
          }),
        );
        final skill = CardInstance(
          data: CardData.fromJson({
            'id': 'competence_test',
            'name_en': 'Test',
            'name_fr': 'Test',
            'description_en': 'Test',
            'description_fr': 'Test',
            'cost': 0,
            'type': 'skill',
            'rarity': 'common',
            'target': 'self',
            'effects': [
              {'type': 'armor', 'value': 0},
            ],
          }),
        );

        deckNotifier.initializeStarterDeck([attack, skill]);
        deckNotifier.startCombat(
            handSize: 0, maxHandSize: GameConstants.startingMaxHandSize);
        deckNotifier.state =
            deckNotifier.state.copyWith(hand: [attack, skill]);

        combatController.applyPlayerCardPlay(attack);

        int charge() => runController.currentState.heroStats.statuses
            .singleWhere((s) => s.id == 'shuriken_charge')
            .value;
        expect(runController.currentState.heroStats.armure, 1);
        expect(charge(), 1);
        expect(combatController.currentState.enemies.map((e) => e.id),
            [sturdy.id]);
        expect(combatController.currentState.defeatedEnemies.map((e) => e.id),
            [frail.id]);
        expect(
            container.read(deckProvider).discardPile.map((c) => c.data.id),
            contains('attaque_test'));

        combatController.applyPlayerCardPlay(skill);

        expect(runController.currentState.heroStats.armure, 2);
        expect(charge(), 1);
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
            might: 5,
          ),
        );
        final enemy2 = EnemyInstance(
          data: orcData,
          stats: EntityStats(
            maxPv: 30,
            currentPv: 30,
            armure: 0,
            might: 8,
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
          EntityStats(maxPv: 20, currentPv: 0, armure: 0, might: 5),
        );
        runEnemyPhaseStart(combatController); // This will clean up dead enemies (enemy1)

        // enemy1 is dead, selectedEnemyId should now be null, NOT fallback to enemy2
        expect(combatController.currentState.selectedEnemyId, isNull);
      },
    );

    // P-53 (spec §4.7, §4.10) : la fermeture du tour du joueur, la chaîne du
    // Feu vague par vague, puis les autres statuts et le nettoyage des morts.
    group('Les charges au tour ennemi', () {
      final shipped = shippedChargeCatalog();
      final burn = shipped['burn']!;
      final shock = shipped['shock']!;

      late ProviderContainer container;
      late CombatController combat;
      late RunController run;

      setUp(() {
        container = ProviderContainer(overrides: [shippedChargeOverride()]);
        combat = container.read(combatProvider.notifier);
        run = container.read(runProvider.notifier);
        run.startNewRun(paladinHero);
      });

      tearDown(() => container.dispose());

      EnemyInstance foe(
        String id, {
        int burning = 0,
        int poison = 0,
        int pv = 200,
      }) {
        var stats = EntityStats(maxPv: pv, currentPv: pv, armure: 0, might: 0);
        if (burning > 0) {
          stats = ChargeRules.pose(stats, burn, burning, ChargeBearer.enemy);
        }
        if (poison > 0) {
          stats = stats.addStatus(StatusEffect(
            id: 'poison',
            name: 'Poison',
            type: StatusType.debuff,
            value: poison,
            duration: 2,
          ));
        }
        return EnemyInstance(id: id, data: goblinData, stats: stats);
      }

      void fight(List<EnemyInstance> row, {String? selected}) {
        combat.state = CombatState(
          enemies: row,
          selectedEnemyId: selected,
          turnPhase: TurnPhase.player,
        );
      }

      EnemyInstance byId(String id) =>
          combat.currentState.enemies.singleWhere((e) => e.id == id);
      int lost(String id) => 200 - byId(id).stats.currentPv;
      int fireOn(String id) => ChargeRules.points(byId(id).stats, 'burn');
      Iterable<String> rowIds() => combat.currentState.enemies.map((e) => e.id);

      void resolveRemainingWaves() {
        while (combat.resolveNextFireWave()) {}
      }

      void play(CardInstance card) {
        final deck = container.read(deckProvider.notifier);
        deck.initializeStarterDeck([card]);
        deck.startCombat(
            handSize: 0, maxHandSize: GameConstants.startingMaxHandSize);
        deck.state = deck.state.copyWith(hand: [card]);
        combat.applyPlayerCardPlay(card);
      }

      test('le Feu se resout avant le Poison', () {
        fight([foe('B', burning: 3, poison: 3, pv: 20)]);

        combat.startEnemyTurn();
        expect(byId('B').stats.currentPv, 20 - 12);
        final poison =
            byId('B').stats.statuses.singleWhere((s) => s.id == 'poison');
        expect((poison.value, poison.duration), (3, 2));

        resolveRemainingWaves();
        combat.resolveEnemyStatuses();
        expect(byId('B').stats.currentPv, 20 - 12 - 3);
      });

      test('les vagues une a une', () {
        fight([foe('A'), foe('B', burning: 9), foe('C')]);

        expect(combat.startEnemyTurn(), isTrue);
        final first = combat.currentState.fireWaveReport!;
        expect(first.wave, 1);
        final resolution = first.resolved.single;
        expect(
          (resolution.bearerId, resolution.tranches),
          ('B', 3),
        );
        expect(
          resolution.splashes.map((s) => (s.targetId, s.charge)),
          [('A', 3), ('C', 3)],
        );
        expect([lost('A'), lost('B'), lost('C')], [36, 36, 36]);

        expect(combat.resolveNextFireWave(), isTrue);
        expect(combat.currentState.fireWaveReport!.wave, 2);
        expect(combat.resolveNextFireWave(), isTrue);
        expect(combat.currentState.fireWaveReport!.wave, 3);
        expect(combat.resolveNextFireWave(), isFalse);
        expect(combat.currentState.fireWaveReport, isNull);
        expect([lost('A'), lost('B'), lost('C')], [48, 64, 48]);
      });

      test('cleanDeadEnemies apres les statuts, la rangee se resserre', () {
        fight([foe('A', pv: 20), foe('B', burning: 9), foe('C')]);

        combat.startEnemyTurn();
        expect(byId('A').stats.currentPv, 0);
        resolveRemainingWaves();
        expect(rowIds(), ['A', 'B', 'C']);

        combat.resolveEnemyStatuses();
        expect(rowIds(), ['B', 'C']);
        expect(
          combat.currentState.defeatedEnemies.map((e) => e.id),
          ['A'],
        );
      });

      test('un porteur que son Poison acheve a son tour explose quand meme',
          () {
        fight([
          foe('A'),
          foe('B', burning: 3, poison: 15, pv: 20),
          foe('C'),
        ]);

        combat.startEnemyTurn();
        expect([lost('A'), lost('C')], [12, 12]);
        expect([fireOn('A'), fireOn('C')], [1, 1]);
        expect(byId('B').stats.currentPv, greaterThan(0));

        resolveRemainingWaves();
        combat.resolveEnemyStatuses();

        // Le point de Feu de chaque voisin, sous le seuil, fait
        // halfUp(1 × 4, 50) = 2 à la vague 2.
        expect([lost('A'), lost('C')], [12 + 2, 12 + 2]);
        expect([fireOn('A'), fireOn('C')], [0, 0]);
        expect(rowIds(), ['A', 'C']);
        expect(
          combat.currentState.defeatedEnemies.map((e) => e.id),
          ['B'],
        );
      });

      test('un ennemi tue par une carte perd son Feu sans exploser', () {
        fight(
          [foe('A'), foe('B', burning: 3, pv: 6), foe('C')],
          selected: 'B',
        );

        play(CardInstance(
          data: const CardData(
            id: 'strike',
            nameEn: 'Strike',
            nameFr: 'Frappe',
            cost: 0,
            type: CardType.attack,
            rarity: CardRarity.common,
            target: CardTarget.singleEnemy,
            effects: [CardEffect(type: 'damage', value: 6)],
          ),
        ));
        expect(rowIds(), ['A', 'C']);

        expect(combat.startEnemyTurn(), isFalse);
        expect([lost('A'), lost('C')], [0, 0]);
      });

      test('les deux fermetures de phase', () {
        fight([foe('A')]);
        void charge() {
          combat.updateEnemyStats(
            'A',
            ChargeRules.pose(byId('A').stats, shock, 3, ChargeBearer.enemy),
          );
          run.updateHeroStats(
            (s) => ChargeRules.pose(s, shock, 3, ChargeBearer.hero),
          );
        }

        (int, ChargeState) onFoe() => (
              ChargeRules.points(byId('A').stats, 'shock'),
              byId('A').stats.charges['shock']!.state,
            );
        (int, ChargeState) onHero() => (
              ChargeRules.points(run.currentState.heroStats, 'shock'),
              run.currentState.heroStats.charges['shock']!.state,
            );

        charge();
        expect(onFoe(), (3, ChargeState.brokenActive));
        expect(onHero(), (3, ChargeState.brokenActive));

        combat.startEnemyTurn();
        expect(onFoe(), (0, ChargeState.none));
        expect(onHero(), (0, ChargeState.none));

        charge();
        expect(onFoe(), (3, ChargeState.brokenActive));
        expect(onHero(), (3, ChargeState.brokenActive));

        combat.endEnemyTurn();
        expect(onFoe(), (0, ChargeState.none));
        expect(onHero(), (0, ChargeState.none));
      });

      test('le Feu d une explosion ne recoit aucun bonus de Puissance', () {
        run.updateHeroStats(
          (s) => s.copyWith(might: 2, mightTargets: {MightTarget.alteration}),
        );
        fight([foe('A'), foe('B'), foe('C')], selected: 'B');

        play(CardInstance(
          data: const CardData(
            id: 'allumage_test',
            cost: 0,
            type: CardType.skill,
            rarity: CardRarity.common,
            target: CardTarget.singleEnemy,
            effects: [
              CardEffect(type: 'apply_status', value: 3, statusId: 'burn'),
            ],
          ),
        ));
        expect(fireOn('B'), 3 + 2);

        combat.startEnemyTurn();
        expect([fireOn('A'), fireOn('C')], [1, 1]);
      });

      // Un ennemi qui porte déjà `points` de Gel, et une intention en cours.
      EnemyInstance frozenFoe(
        String id, {
        int points = 3,
        bool withIntent = true,
        int burning = 0,
        int poison = 0,
      }) {
        final base = foe(id, burning: burning, poison: poison);
        return base.copyWith(
          stats: ChargeRules.pose(
            base.stats,
            shipped['freeze']!,
            points,
            ChargeBearer.enemy,
          ),
          currentIntent: EnemyIntent(type: IntentType.attack, value: 10),
          clearIntent: !withIntent,
          intentStep: 1,
        );
      }

      test('l ennemi gele ne resout rien et consomme son gel', () {
        fight([
          frozenFoe('A'),
          frozenFoe('B', points: 2),
        ]);
        final pv = run.currentState.heroStats.currentPv;
        expect(byId('A').skipsAction, isTrue);

        runEnemyPhaseStart(combat);
        // Un Gel sous le seuil décline d'un point, à la phase de son porteur.
        expect(ChargeRules.points(byId('B').stats, 'freeze'), 1);

        combat.resolveEnemyIntent('A');
        expect(run.currentState.heroStats.currentPv, pv);
        expect(byId('A').skipsAction, isFalse);

        combat.endEnemyTurn();
        expect(byId('A').currentIntent, goblinData.intents![1]);
      });

      test('ses statuts se resolvent quand meme', () {
        fight([frozenFoe('A', burning: 3, poison: 3)]);
        final pv = run.currentState.heroStats.currentPv;

        runEnemyPhaseStart(combat);
        expect(lost('A'), 15);

        combat.resolveEnemyIntent('A');
        expect(run.currentState.heroStats.currentPv, pv);
        expect(lost('A'), 15);
      });

      test('un ennemi gele sans intention consomme son gel', () {
        fight([frozenFoe('A', withIntent: false)]);
        expect(byId('A').currentIntent, isNull);
        expect(byId('A').skipsAction, isTrue);

        combat.resolveEnemyIntent('A');

        expect(byId('A').skipsAction, isFalse);
      });

      test('un combat de boss : chaque ennemi a 6 ; une elite a 3', () {
        List<int> thresholds(MapNodeType type, int act) {
          combat.initializeCombat(1, type, [goblinData], act: act);
          return [
            for (final enemy in combat.currentState.enemies)
              ChargeRules.linesFor(
                ChargeRules.pose(
                  enemy.stats,
                  shipped['freeze']!,
                  2,
                  ChargeRules.bearerOf(enemy),
                ),
              ).single.threshold,
          ];
        }

        final boss = thresholds(MapNodeType.boss, 6);
        expect(boss, isNotEmpty);
        expect(boss.every((t) => t == 6), isTrue);

        final elite = thresholds(MapNodeType.elite, 1);
        expect(elite, isNotEmpty);
        expect(elite.every((t) => t == 3), isTrue);
      });

      test('Nova de givre pose le Gel sur chaque ennemi, au seuil de son porteur',
          () {
        final json = jsonDecode(
          File('assets/data/cards/mana_flux/frost_nova.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        final nova = CardData.fromJson(json);
        final points = nova.effects.single.value;
        fight([foe('A'), foe('B').copyWith(isBoss: true)]);

        play(CardInstance(data: nova));

        (String, int, int) freezeOn(String id) {
          final line = ChargeRules.linesFor(byId(id).stats).single;
          return (line.chargeId, line.points, line.threshold);
        }

        expect(freezeOn('A'), ('freeze', points, 3));
        expect(freezeOn('B'), ('freeze', points, 6));
      });
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
      classCard: 'paladin.png',
      maxHp: 100,
      maxMana: 3,
      luck: 0,
      mastery: 0,
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
      deckNotifier.startCombat(handSize: 0, maxHandSize: GameConstants.startingMaxHandSize);

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
      deckNotifier.startCombat(handSize: 0, maxHandSize: GameConstants.startingMaxHandSize);

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
