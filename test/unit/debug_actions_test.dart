import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/debug_run_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/services/debug_actions.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/enemy_intent.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';

const paladin = HeroData(
  id: 'paladin',
  nameEn: 'Paladin',
  nameFr: 'Paladin',
  descriptionEn: 'A holy knight',
  descriptionFr: 'Un saint chevalier',
  classCard: 'paladin.png',
  maxHp: 100,
  maxMana: 3,
  baseDamage: 5,
  luck: 0,
  armorMastery: 0,
  passiveTrait: 'regen_armor',
);

/// Une run *debug*, seule dans laquelle `DebugActions` accepte d'agir.
ProviderContainer _startedRun() {
  final container = ProviderContainer();
  container.read(debugRunProvider.notifier).requestDebugRun();
  container.read(runProvider.notifier).startNewRun(paladin);
  return container;
}

void main() {
  group('DebugActions — run et heros', () {
    test('updateHeroStats ecrit les PV du heros', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      expect(container.read(debugRunProvider).isDebugRun, isTrue);

      DebugActions.updateHeroStats(
        container.read,
        (s) => s.copyWith(currentPv: 42),
      );

      expect(container.read(runProvider).heroStats.currentPv, 42);
    });

    test('setGold fixe l or a la valeur exacte, a la hausse comme a la baisse', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      expect(container.read(inventoryProvider).gold, 50);

      DebugActions.setGold(container.read, 999);
      expect(container.read(inventoryProvider).gold, 999);

      DebugActions.setGold(container.read, 7);
      expect(container.read(inventoryProvider).gold, 7);
    });

    test('updateRun force l acte sans toucher a la carte ni a la position', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      final mapBefore = container.read(runProvider).mapNodes;
      final nodeBefore = container.read(runProvider).currentNodeId;

      DebugActions.updateRun(container.read, (s) => s.copyWith(act: 3));

      expect(container.read(runProvider).act, 3);
      expect(container.read(runProvider).mapNodes, same(mapBefore));
      expect(container.read(runProvider).currentNodeId, nodeBefore);
    });

    test('advanceToNextAct incremente l acte ET regenere la carte', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      final mapBefore = container.read(runProvider).mapNodes;

      DebugActions.advanceToNextAct(container.read);

      expect(container.read(runProvider).act, 2);
      expect(container.read(runProvider).mapNodes, isNot(same(mapBefore)));
      expect(container.read(runProvider).currentNodeId, isNull);
    });
  });

  group('DebugActions — deck et reliques', () {
    const strike = CardData(
      id: 'strike_basic',
      nameEn: 'Strike',
      nameFr: 'Frappe',
      descriptionEn: 'Deals 6 damage.',
      descriptionFr: 'Inflige 6 degats.',
      cost: 1,
      type: CardType.attack,
      category: CardCategory.global,
      rarity: CardRarity.common,
      target: CardTarget.singleEnemy,
      effects: [CardEffect(type: 'damage', value: 6)],
    );

    test('addCard ajoute une instance au deck maitre', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      expect(container.read(deckProvider).masterDeck, isEmpty);

      DebugActions.addCard(container.read, strike);

      expect(container.read(deckProvider).masterDeck.length, 1);
      expect(
        container.read(deckProvider).masterDeck.first.data.id,
        'strike_basic',
      );
    });

    test('removeCard retire exactement l instance visee', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      DebugActions.addCard(container.read, strike);
      DebugActions.addCard(container.read, strike);
      final victim = container.read(deckProvider).masterDeck.first.uniqueId;

      DebugActions.removeCard(container.read, victim);

      final remaining = container.read(deckProvider).masterDeck;
      expect(remaining.length, 1);
      expect(remaining.first.uniqueId, isNot(victim));
    });
  });

  group('DebugActions — combat', () {
    final goblinData = EnemyData(
      id: 'goblin',
      nameEn: 'Goblin',
      nameFr: 'Gobelin',
      maxHp: 20,
      baseDamage: 5,
      spritePath: 'goblin.png',
      tier: 1,
      intents: [EnemyIntent(type: IntentType.attack, value: 5)],
    );

    EnemyInstance freshGoblin() => EnemyInstance(
      data: goblinData,
      stats: EntityStats(maxPv: 20, currentPv: 20, armure: 0, attackPower: 5),
    );

    test('setEnemyHp a 0 tue la cible et laisse les autres intacts', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      final combat = container.read(combatProvider.notifier);
      final a = freshGoblin();
      final b = freshGoblin();
      final c = freshGoblin();
      combat.updateState(CombatState(enemies: [a, b, c]));

      DebugActions.setEnemyHp(container.read, b.id, 0);

      final remaining = container.read(combatProvider).enemies;
      expect(remaining.length, 2);
      expect(remaining.map((e) => e.id), containsAll([a.id, c.id]));
      expect(remaining.every((e) => e.stats.currentPv == 20), isTrue);
      expect(container.read(combatProvider).isCombatEnded, isFalse);
    });

    test('setEnemyHp a une valeur non nulle laisse la cible en vie', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      final combat = container.read(combatProvider.notifier);
      final a = freshGoblin();
      combat.updateState(CombatState(enemies: [a]));

      DebugActions.setEnemyHp(container.read, a.id, 3);

      final enemies = container.read(combatProvider).enemies;
      expect(enemies.length, 1);
      expect(enemies.first.stats.currentPv, 3);
      expect(container.read(combatProvider).isCombatEnded, isFalse);
    });

    test('killAllEnemies fait apparaitre la vague suivante sans finir le combat', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      final combat = container.read(combatProvider.notifier);
      combat.updateState(
        CombatState(
          enemies: [freshGoblin()],
          pendingEnemies: [freshGoblin()],
        ),
      );

      DebugActions.killAllEnemies(container.read);

      expect(container.read(combatProvider).enemies.length, 1);
      expect(container.read(combatProvider).pendingEnemies, isEmpty);
      expect(container.read(combatProvider).isCombatEnded, isFalse);
    });

    test('winCombat court-circuite tout, files comprises', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      final combat = container.read(combatProvider.notifier);
      combat.updateState(
        CombatState(
          enemies: [freshGoblin()],
          pendingEnemies: [freshGoblin()],
        ),
      );

      DebugActions.winCombat(container.read);

      expect(container.read(combatProvider).enemies, isEmpty);
      expect(container.read(combatProvider).pendingEnemies, isEmpty);
      expect(container.read(combatProvider).isCombatEnded, isTrue);
      expect(container.read(combatProvider).isVictory, isTrue);
    });

    test('loseCombat met le heros a 0 PV', () {
      final container = _startedRun();
      addTearDown(container.dispose);

      DebugActions.loseCombat(container.read);

      expect(container.read(runProvider).heroStats.currentPv, 0);
      expect(container.read(runProvider).isDead, isTrue);
    });

    test('skipEnemyPhase force la phase joueur', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      final combat = container.read(combatProvider.notifier);
      combat.updateState(
        CombatState(enemies: [freshGoblin()], turnPhase: TurnPhase.enemy),
      );

      DebugActions.skipEnemyPhase(container.read);

      expect(container.read(combatProvider).turnPhase, TurnPhase.player);
    });
  });
}
