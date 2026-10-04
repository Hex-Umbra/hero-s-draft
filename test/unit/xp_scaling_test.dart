import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/models/map_node.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/xp_curve_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// La courbe de D67, écrite ici et non lue dans le fichier : ces cas gardent
/// la règle du palier ; `real_bundle_load_test.dart` garde la donnée livrée.
const _d67 = XpCurveData([
  115, 200, 310, 480, 590, 775, 955, 1100, //
  1040, 1185, 1370, 1370, 1300, 1375, 1015,
]);

void main() {
  // Le palier est dérivé de l'acte, jamais stocké (spec P-43 E3, §4.4, A8).
  group('XP and Level Up Unit Tests', () {
    late ProviderContainer container;
    late RunController runController;

    final testHero = HeroData(
      id: 'paladin',
      nameEn: 'Paladin',
      nameFr: 'Paladin',
      descriptionEn: 'Holy knight',
      descriptionFr: 'Chevalier sacre',
      classCard: 'paladin.png',
      maxHp: 80,
      maxMana: 3,
      luck: 1,
      mastery: 0,
    );

    setUp(() {
      // Un conteneur nu : la courbe est surchargée, le chargeur jamais lu
      // (spec P-43 E3, §8, « Le piège du montage »).
      container = ProviderContainer(
        overrides: [xpCurveProvider.overrideWithValue(_d67)],
      );
      runController = container.read(runProvider.notifier);
      runController.startNewRun(testHero);
    });

    tearDown(() {
      container.dispose();
    });

    /// Place la run à l'acte [act], sans régénérer la carte.
    void moveToAct(int act) => runController.updateState(
          runController.currentState.copyWith(act: act),
        );

    test('au depart : niveau 1, 0 XP, et le palier de l acte 1 vaut 115', () {
      final stats = runController.currentState.heroStats;
      expect(stats.level, 1);
      expect(stats.xp, 0);
      expect(
        container
            .read(xpCurveProvider)
            .thresholdFor(runController.currentState.act),
        115,
      );
    });

    test('gainXp ajoute l XP sous le palier, sans niveau', () {
      expect(runController.gainXp(114), isFalse);

      final stats = runController.currentState.heroStats;
      expect(stats.level, 1);
      expect(stats.xp, 114);
      expect(runController.currentState.pendingDrafts, 0);
    });

    test('gainXp passe un niveau au palier de l acte et reporte l excedent',
        () {
      expect(runController.gainXp(120), isTrue);

      final stats = runController.currentState.heroStats;
      expect(stats.level, 2);
      expect(stats.xp, 5); // 120 - 115
      expect(runController.currentState.pendingDrafts, 1);
    });

    test('plusieurs niveaux d un coup, au palier de l acte a chaque niveau',
        () {
      // 260 = 115 + 115 + 30 : le palier ne grandit plus avec le niveau.
      expect(runController.gainXp(260), isTrue);

      final stats = runController.currentState.heroStats;
      expect(stats.level, 3);
      expect(stats.xp, 30);
      expect(runController.currentState.pendingDrafts, 2);
    });

    test('le palier suit l acte courant', () {
      moveToAct(2);

      expect(runController.gainXp(199), isFalse); // 200 a l acte 2
      expect(runController.gainXp(1), isTrue);

      final stats = runController.currentState.heroStats;
      expect(stats.level, 2);
      expect(stats.xp, 0);
    });

    test('un palier qui baisse sous l XP accumulee donne le niveau au gain '
        'suivant', () {
      moveToAct(8);
      expect(runController.gainXp(1050), isFalse); // 1100 a l acte 8

      moveToAct(9);
      // Changer d'acte ne fait rien gagner : le palier n'est lu qu'au gain.
      expect(runController.currentState.heroStats.level, 1);
      expect(runController.currentState.heroStats.xp, 1050);

      expect(runController.gainXp(1), isTrue); // 1051 >= 1040
      final stats = runController.currentState.heroStats;
      expect(stats.level, 2);
      expect(stats.xp, 11);
      expect(runController.currentState.pendingDrafts, 1);
    });

    test('au-dela de la table, la derniere valeur', () {
      moveToAct(20);

      expect(runController.gainXp(1014), isFalse); // 1015 au-dela de l acte 15
      expect(runController.gainXp(1), isTrue);

      final stats = runController.currentState.heroStats;
      expect(stats.level, 2);
      expect(stats.xp, 0);
    });
  });

  group('Enemy Level & Stats Scaling Unit Tests', () {
    final slimeData = const EnemyData(
      id: 'slime',
      maxHp: 20,
      baseDamage: 5,
      spritePath: 'slime.png',
      tier: 1,
      xp: 30,
    );

    test(
      'Enemy level calculates correctly based on player level, act and node type',
      () {
        final container = ProviderContainer();
        final combatController = container.read(combatProvider.notifier);

        // Case 1: Player Lvl 1, Act 1, Normal Combat -> Enemy Lvl 1
        combatController.initializeCombat(
          1,
          MapNodeType.combat,
          [slimeData],
          playerLevel: 1,
          act: 1,
        );
        expect(combatController.currentState.enemies.first.stats.level, 1);
        expect(
          combatController.currentState.enemies.first.stats.maxPv,
          20,
        ); // 20 * 1.0

        // Case 2: Player Lvl 2, Act 1, Elite Combat -> Enemy Lvl 3 (playerLvl 2 + actMod 0 + eliteMod 1)
        combatController.initializeCombat(
          1,
          MapNodeType.elite,
          [slimeData],
          playerLevel: 2,
          act: 1,
        );
        expect(combatController.currentState.enemies.first.stats.level, 3);
        // HP multiplier = (1.0 + 0.06 * (3-1)) * 1.5 = 1.12 * 1.5 = 1.68
        // maxPv = (20 * 1.68).round() = 34
        expect(combatController.currentState.enemies.first.stats.maxPv, 34);

        // Case 3: Player Lvl 3, Act 2, Boss Combat -> Enemy Lvl 5 (playerLvl 3 + bossMod 2; act no longer contributes to enemy level)
        combatController.initializeCombat(
          1,
          MapNodeType.boss,
          [slimeData],
          playerLevel: 3,
          act: 2,
        );
        expect(combatController.currentState.enemies.first.stats.level, 5);
      },
    );
  });

  group('Defeated Enemies and XP Collection Unit Tests', () {
    final slimeData = const EnemyData(
      id: 'slime',
      maxHp: 20,
      baseDamage: 5,
      spritePath: 'slime.png',
      tier: 1,
      xp: 30,
    );

    test(
      'Defeated enemies are recorded in defeatedEnemies list when cleaned',
      () {
        final container = ProviderContainer();
        final combatController = container.read(combatProvider.notifier);

        combatController.initializeCombat(
          1,
          MapNodeType.combat,
          [slimeData],
          playerLevel: 1,
          act: 1,
        );

        final initialEnemyCount = combatController.currentState.enemies.length;
        expect(initialEnemyCount, greaterThan(0));
        expect(combatController.currentState.defeatedEnemies.length, 0);

        // Set all enemies to 0 PV
        for (var enemy in combatController.currentState.enemies) {
          combatController.updateEnemyStats(
            enemy.id,
            enemy.stats.copyWith(currentPv: 0),
          );
        }

        // Trigger dead enemy cleaning by starting enemy turn
        combatController.startEnemyTurn();

        // Verify that all enemies have been moved to defeatedEnemies
        expect(combatController.currentState.enemies.length, 0);
        expect(
          combatController.currentState.defeatedEnemies.length,
          initialEnemyCount,
        );
        expect(
          combatController.currentState.defeatedEnemies.first.data.id,
          'slime',
        );
        expect(combatController.currentState.isVictory, isTrue);
        expect(combatController.currentState.isCombatEnded, isTrue);
      },
    );
  });
}
