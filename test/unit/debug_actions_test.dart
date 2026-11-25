import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/checkpoint_controller.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_skills_link.dart';
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
import 'package:roguelike_card_game/models/data/xp_curve_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/game/systems/charge_rules.dart';
import 'package:roguelike_card_game/models/charge_track.dart';
import 'package:roguelike_card_game/models/data/charge_data.dart';
import 'package:roguelike_card_game/models/status_effect.dart';

import 'shipped_data.dart';

const paladin = HeroData(
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

/// La courbe de D67 : `gainLevel` lit le palier de l'acte courant (spec P-43
/// E3, §4.4).
const _d67 = XpCurveData([
  115, 200, 310, 480, 590, 775, 955, 1100, //
  1040, 1185, 1370, 1370, 1300, 1375, 1015,
]);

/// Une run *debug*, seule dans laquelle `DebugActions` accepte d'agir.
ProviderContainer _startedRun() {
  final container = ProviderContainer(
    overrides: [xpCurveProvider.overrideWithValue(_d67), shippedChargeOverride()],
  );
  container.read(debugRunProvider.notifier).requestDebugRun();
  container.read(runProvider.notifier).startNewRun(paladin);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    test('gainLevel fait gagner exactement un niveau, au palier de l acte '
        'courant', () {
      final container = _startedRun();
      addTearDown(container.dispose);

      DebugActions.gainLevel(container.read);
      expect(container.read(runProvider).heroStats.level, 2);
      expect(container.read(runProvider).heroStats.xp, 0);
      expect(container.read(runProvider).pendingDrafts, 1);

      // A l'acte 9, le palier vaut 1040 : un niveau, ni moins, ni plus.
      DebugActions.updateRun(container.read, (s) => s.copyWith(act: 9));
      DebugActions.gainLevel(container.read);
      expect(container.read(runProvider).heroStats.level, 3);
      expect(container.read(runProvider).heroStats.xp, 0);
      expect(container.read(runProvider).pendingDrafts, 2);
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
      stats: EntityStats(maxPv: 20, currentPv: 20, armure: 0, might: 5),
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

    test('poseCharge suit la regle : le Gel plafonne, la rupture au seuil', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      final a = freshGoblin();
      container
          .read(combatProvider.notifier)
          .updateState(CombatState(enemies: [a]));

      for (var i = 0; i < 3; i++) {
        DebugActions.poseCharge(container.read, 'freeze', enemyId: a.id);
      }
      EnemyInstance foe() => container.read(combatProvider).enemies.single;
      expect(foe().skipsAction, isTrue);
      final frozen = foe().stats;

      DebugActions.poseCharge(container.read, 'freeze', enemyId: a.id);
      expect(foe().stats, same(frozen));

      for (var i = 0; i < 3; i++) {
        DebugActions.poseCharge(container.read, 'shock');
      }
      final hero = container.read(runProvider).heroStats;
      expect(hero.charges['shock']!.state, ChargeState.brokenActive);
    });

    test('hors d une run debug, poseCharge et clearCharges n ecrivent rien', () {
      final container = ProviderContainer(overrides: [shippedChargeOverride()]);
      addTearDown(container.dispose);
      container.read(debugRunProvider.notifier).requestNormalRun();
      container.read(runProvider.notifier).startNewRun(paladin);
      final a = freshGoblin();
      final combat = container.read(combatProvider.notifier);
      combat.updateState(CombatState(enemies: [a]));
      final heroBefore = container.read(runProvider).heroStats;

      DebugActions.poseCharge(container.read, 'shock');
      DebugActions.poseCharge(container.read, 'freeze', enemyId: a.id);
      expect(container.read(runProvider).heroStats, same(heroBefore));
      expect(container.read(combatProvider).enemies.single.stats, same(a.stats));

      container.read(runProvider.notifier).updateHeroStats(
        (s) => ChargeRules.pose(
          s,
          shippedChargeCatalog()['shock']!,
          1,
          ChargeBearer.hero,
        ),
      );
      final posed = container.read(runProvider).heroStats;
      DebugActions.clearCharges(container.read);
      expect(container.read(runProvider).heroStats, same(posed));
    });

    test('spawnEnemy ajoute l ennemi a l echelle de l acte, intention tiree', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      DebugActions.updateRun(container.read, (s) => s.copyWith(act: 3));
      final a = freshGoblin();
      container
          .read(combatProvider.notifier)
          .updateState(CombatState(enemies: [a]));

      DebugActions.spawnEnemy(container.read, goblinData);

      final enemies = container.read(combatProvider).enemies;
      expect(enemies.length, 2);
      expect(enemies.first.id, a.id);
      final spawned = enemies.last;
      expect(spawned.id, isNot(a.id));
      // Acte 3, niveau 1 : PV x1,35 et Puissance x1,25 (EncounterSystem).
      expect(spawned.stats.maxPv, 27);
      expect(spawned.stats.currentPv, 27);
      expect(spawned.stats.might, 6);
      expect(spawned.currentIntent?.type, IntentType.attack);
    });

    test('spawnEnemy s arrete a six ennemis et hors d un combat en cours', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      final combat = container.read(combatProvider.notifier);
      combat.updateState(CombatState(enemies: [freshGoblin()]));

      for (var i = 0; i < 8; i++) {
        DebugActions.spawnEnemy(container.read, goblinData);
      }
      expect(
        container.read(combatProvider).enemies.length,
        DebugActions.maxEnemiesOnBoard,
      );

      combat.updateState(
        CombatState(enemies: [freshGoblin()], isCombatEnded: true),
      );
      DebugActions.spawnEnemy(container.read, goblinData);
      expect(container.read(combatProvider).enemies.length, 1);
    });

    test('hors d une run debug, spawnEnemy n ajoute rien', () {
      final container = ProviderContainer(overrides: [shippedChargeOverride()]);
      addTearDown(container.dispose);
      container.read(debugRunProvider.notifier).requestNormalRun();
      container.read(runProvider.notifier).startNewRun(paladin);
      container
          .read(combatProvider.notifier)
          .updateState(CombatState(enemies: [freshGoblin()]));

      DebugActions.spawnEnemy(container.read, goblinData);

      expect(container.read(combatProvider).enemies.length, 1);
    });

    test('chaque bonus du menu est un buff que createStatus sait creer', () {
      for (final id in DebugActions.buffIds) {
        final buff = DebugActions.buffOf(id);
        expect(buff, isNotNull, reason: id);
        expect(buff!.type, StatusType.buff, reason: id);
        expect(buff.id, id);
      }
      expect(DebugActions.buffOf('poison'), isNull);
    });

    test('poseBuff ajoute un point au heros ou a l ennemi vise, qui s additionne', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      final a = freshGoblin();
      final b = freshGoblin();
      container
          .read(combatProvider.notifier)
          .updateState(CombatState(enemies: [a, b]));

      DebugActions.poseBuff(container.read, 'might', enemyId: b.id);
      DebugActions.poseBuff(container.read, 'might', enemyId: b.id);
      DebugActions.poseBuff(container.read, 'armor_regen');
      DebugActions.poseBuff(container.read, 'poison', enemyId: a.id);

      final enemies = container.read(combatProvider).enemies;
      expect(enemies.first.stats.statuses, isEmpty);
      final might = enemies.last.stats.statuses.single;
      expect((might.id, might.type, might.value), ('might', StatusType.buff, 2));
      final hero = container.read(runProvider).heroStats.statuses;
      expect(hero.map((s) => s.id), contains('armor_regen'));
    });

    test('clearBuffs retire les bonus et laisse les alterations', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      final poisoned = freshGoblin().copyWith(
        stats: EntityStats(
          maxPv: 20,
          currentPv: 20,
          armure: 0,
          might: 5,
          statuses: const [
            StatusEffect(
              id: 'poison',
              name: 'Poison',
              type: StatusType.debuff,
              value: 3,
              duration: 3,
            ),
          ],
        ),
      );
      container
          .read(combatProvider.notifier)
          .updateState(CombatState(enemies: [poisoned]));
      DebugActions.poseBuff(container.read, 'hp_regen', enemyId: poisoned.id);
      DebugActions.poseBuff(container.read, 'might');

      DebugActions.clearBuffs(container.read);

      final statuses =
          container.read(combatProvider).enemies.single.stats.statuses;
      expect(statuses.map((s) => s.id), ['poison']);
      expect(
        container.read(runProvider).heroStats.statuses
            .where((s) => s.type == StatusType.buff),
        isEmpty,
      );
    });

    test('hors d une run debug, poseBuff n ecrit rien', () {
      final container = ProviderContainer(overrides: [shippedChargeOverride()]);
      addTearDown(container.dispose);
      container.read(debugRunProvider.notifier).requestNormalRun();
      container.read(runProvider.notifier).startNewRun(paladin);
      final a = freshGoblin();
      container
          .read(combatProvider.notifier)
          .updateState(CombatState(enemies: [a]));
      final heroBefore = container.read(runProvider).heroStats;

      DebugActions.poseBuff(container.read, 'might');
      DebugActions.poseBuff(container.read, 'might', enemyId: a.id);

      expect(container.read(runProvider).heroStats, same(heroBefore));
      expect(container.read(combatProvider).enemies.single.stats, same(a.stats));
    });

    test('clearCharges vide les points et les pistes du heros et des ennemis', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      final a = freshGoblin();
      container
          .read(combatProvider.notifier)
          .updateState(CombatState(enemies: [a]));
      final poison = StatusEffect(
        id: 'poison',
        name: 'Poison',
        type: StatusType.debuff,
        value: 2,
        duration: 3,
      );
      container.read(combatProvider.notifier).updateEnemyStats(
        a.id,
        a.stats.copyWith(statuses: [poison]),
      );
      for (var i = 0; i < 3; i++) {
        DebugActions.poseCharge(container.read, 'freeze', enemyId: a.id);
      }
      DebugActions.poseCharge(container.read, 'burn');
      DebugActions.poseCharge(container.read, 'shock');

      DebugActions.clearCharges(container.read);

      final hero = container.read(runProvider).heroStats;
      final foe = container.read(combatProvider).enemies.single.stats;
      expect(hero.charges, isEmpty);
      expect(hero.statuses, isEmpty);
      expect(foe.charges, isEmpty);
      expect(foe.statuses.map((s) => s.id), ['poison']);
    });

    test('skipEnemyPhase ne joue aucune fermeture de phase', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      final a = freshGoblin();
      container
          .read(combatProvider.notifier)
          .updateState(CombatState(enemies: [a], turnPhase: TurnPhase.enemy));
      for (var i = 0; i < 3; i++) {
        DebugActions.poseCharge(container.read, 'shock', enemyId: a.id);
      }

      DebugActions.skipEnemyPhase(container.read);

      final foe = container.read(combatProvider).enemies.single.stats;
      expect(foe.charges['shock']!.state, ChargeState.brokenActive);
      expect(container.read(combatProvider).turnPhase, TurnPhase.player);
    });
  });

  group('DebugActions — evolutions de signature (P-7 (a))', () {
    late GameDataRegistry registry;
    setUpAll(() async {
      registry = await loadGameDataRegistry(rootBundle);
    });

    /// Une run de la classe livrée [classId], debug ou non.
    ProviderContainer start(String classId, {bool debug = true}) {
      final container = ProviderContainer();
      final debugRun = container.read(debugRunProvider.notifier);
      debug ? debugRun.requestDebugRun() : debugRun.requestNormalRun();
      final hero = registry.heroes.singleWhere((h) => h.id == classId);
      container
          .read(runProvider.notifier)
          .startNewRun(hero, null, hero.getSignatures(registry));
      addTearDown(container.dispose);
      return container;
    }

    List<String> taken(ProviderContainer container, String signatureId) =>
        container
            .read(runProvider)
            .signatures
            .singleWhere((s) => s.data.id == signatureId)
            .evolutions;

    bool take(ProviderContainer c, String signatureId, String evolutionId) =>
        DebugActions.takeSignatureEvolution(c.read, signatureId, evolutionId);

    test(
      'takeSignatureEvolution suit le palier : une majeure refusee d abord, '
      'admise apres une mineure',
      () {
        final c = start('paladin');

        expect(take(c, 'smite', 'haste'), isFalse);
        expect(taken(c, 'smite'), isEmpty);
        expect(take(c, 'smite', 'zeal'), isTrue);
        expect(taken(c, 'smite'), ['zeal:1']);
        expect(take(c, 'smite', 'haste'), isTrue);
        expect(taken(c, 'smite'), ['zeal:1', 'haste:1']);
      },
    );

    test(
      'une mineure reprise monte a sa place ; une majeure prise ou exclue est '
      'refusee',
      () {
        final c = start('berserker');

        expect(take(c, 'reckless_strike', 'brutality'), isTrue);
        expect(take(c, 'reckless_strike', 'haste'), isTrue);
        expect(take(c, 'reckless_strike', 'brutality'), isTrue);
        expect(taken(c, 'reckless_strike'), ['brutality:2', 'haste:1']);

        expect(take(c, 'reckless_strike', 'devastation'), isFalse);
        expect(take(c, 'reckless_strike', 'haste'), isFalse);
        expect(taken(c, 'reckless_strike'), ['brutality:2', 'haste:1']);
        expect(take(c, 'reckless_strike', 'cleave'), isTrue);
        expect(
          taken(c, 'reckless_strike'),
          ['brutality:2', 'haste:1', 'cleave:1'],
        );
      },
    );

    test(
      'l attente n est pas exigee : acceptee au niveau 1, le niveau du heros '
      'ne bouge pas, rien n est sauve',
      () {
        final c = start('paladin');
        final smite = c
            .read(runProvider)
            .signatures
            .singleWhere((s) => s.data.id == 'smite');
        expect(smite.pendingFor(c.read(runProvider).heroStats.level), 0);

        expect(take(c, 'smite', 'zeal'), isTrue);

        expect(c.read(runProvider).heroStats.level, 1);
        expect(c.read(checkpointProvider), 0);
      },
    );

    test(
      'hors du pool, hors de la run ou hors d une run debug, rien n est ecrit',
      () {
        final c = start('paladin');
        final before = [for (final s in c.read(runProvider).signatures) s.evolutions];

        expect(take(c, 'smite', 'ghost'), isFalse);
        expect(take(c, 'reckless_strike', 'zeal'), isFalse);
        final normal = start('paladin', debug: false);
        final normalBefore = [
          for (final s in normal.read(runProvider).signatures) s.evolutions,
        ];
        expect(take(normal, 'smite', 'zeal'), isFalse);

        expect([for (final s in c.read(runProvider).signatures) s.evolutions],
            before);
        expect([
          for (final s in normal.read(runProvider).signatures) s.evolutions,
        ], normalBefore);
      },
    );

    test(
      'clearSignatureEvolutions rend la signature sans evolution, et elle '
      'seule',
      () {
        final c = start('paladin');
        take(c, 'smite', 'zeal');
        take(c, 'smite', 'haste');
        take(c, 'holy_shield', 'ward');
        expect(taken(c, 'smite'), ['zeal:1', 'haste:1']);
        expect(taken(c, 'holy_shield'), ['ward:1']);

        DebugActions.clearSignatureEvolutions(c.read, 'smite');

        expect(taken(c, 'smite'), isEmpty);
        expect(taken(c, 'holy_shield'), ['ward:1']);
      },
    );
  });
}
