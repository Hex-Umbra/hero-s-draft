import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/enemy_intent.dart';

void main() {
  group('EntityStats & StatusEffect', () {
    test('takeDamage applies to armor first then PV', () {
      var stats = EntityStats(
        maxPv: 100,
        currentPv: 100,
        maxMana: 10,
        currentMana: 10,
        armure: 10,
        attaque: 0,
      );

      stats = stats.takeDamage(15);

      expect(stats.armure, 0);
      expect(stats.currentPv, 95);
    });

    test('addStatus applies buff and tickStatuses reduces duration', () {
      var stats = EntityStats(
        maxPv: 100,
        currentPv: 100,
        maxMana: 10,
        currentMana: 10,
        armure: 0,
        attaque: 0,
      );

      final poison = StatusEffect(
        id: 'poison',
        name: 'Poison',
        type: StatusType.debuff,
        value: 3,
        duration: 2,
      );

      stats = stats.addStatus(poison);

      expect(stats.statuses.length, 1);
      expect(stats.statuses.first.value, 3);
      expect(stats.statuses.first.duration, 2);

      // Add another poison stack, should merge values
      final poison2 = StatusEffect(
        id: 'poison',
        name: 'Poison',
        type: StatusType.debuff,
        value: 2,
        duration: 3,
      );

      stats = stats.addStatus(poison2);

      expect(stats.statuses.length, 1);
      expect(stats.statuses.first.value, 5); // 3 + 2
      expect(stats.statuses.first.duration, 3); // max(2, 3)

      // Tick statuses reduces duration
      stats = stats.tickStatuses();
      expect(stats.statuses.first.duration, 2);

      stats = stats.tickStatuses();
      expect(stats.statuses.first.duration, 1);
    });

    test('effectiveAttaque calculates base + strength', () {
      var stats = EntityStats(
        maxPv: 100,
        currentPv: 100,
        maxMana: 10,
        currentMana: 10,
        armure: 0,
        attaque: 5,
      );

      expect(stats.effectiveAttaque, 5);

      final strength = StatusEffect(
        id: 'strength',
        name: 'Force',
        type: StatusType.buff,
        value: 3,
        duration: 1,
      );

      stats = stats.addStatus(strength);

      expect(stats.effectiveAttaque, 8); // 5 base + 3 strength
    });

    test('EnemyInstance effectiveIntent scales attack with current stats', () {
      var enemy = EnemyInstance(
        stats: EntityStats(
          maxPv: 20,
          currentPv: 20,
          armure: 0,
          attaque: 8,
        ),
        data: const EnemyData(
          id: 'test',
          nameEn: 'Test Enemy',
          nameFr: 'Test Ennemi',
          maxHp: 20,
          baseDamage: 8,
          spritePath: '',
        ),
      );

      // Raw intent is attack with value 8
      enemy = enemy.copyWith(
        currentIntent: EnemyIntent(type: IntentType.attack, value: 8),
      );
      expect(enemy.effectiveIntent?.value, 8);

      // 1. Permanent/spawn-time scaling: Boost base stats.attaque to 10 (e.g. from level)
      var scaledEnemy = enemy.copyWith(
        stats: enemy.stats.copyWith(attaque: 10),
      );
      expect(scaledEnemy.effectiveIntent?.value, 10); // 8 * 1.25 = 10

      // Raw intent with value 12 (special attack) when base stats.attaque is scaled to 10
      scaledEnemy = scaledEnemy.copyWith(
        currentIntent: EnemyIntent(type: IntentType.attack, value: 12),
      );
      expect(scaledEnemy.effectiveIntent?.value, 15); // 12 * 1.25 = 15

      // 2. In-battle strength status: Keep base stats.attaque at 8, add a +2 strength buff
      var buffedEnemy = enemy.copyWith(
        stats: enemy.stats.addStatus(
          const StatusEffect(
            id: 'strength',
            name: 'Force',
            type: StatusType.buff,
            value: 2,
            duration: 99,
          ),
        ),
      );
      expect(buffedEnemy.stats.effectiveAttaque, 10);

      // Raw intent with value 12 (special attack) with +2 strength
      buffedEnemy = buffedEnemy.copyWith(
        currentIntent: EnemyIntent(type: IntentType.attack, value: 12),
      );
      expect(buffedEnemy.effectiveIntent?.value, 14); // 12 + 2 = 14

      // 3. In-battle strength debuff: Keep base stats.attaque at 8, add a -2 strength debuff
      var debuffedEnemy = enemy.copyWith(
        stats: enemy.stats.addStatus(
          const StatusEffect(
            id: 'strength',
            name: 'Force',
            type: StatusType.buff,
            value: -2,
            duration: 99,
          ),
        ),
      );
      expect(debuffedEnemy.stats.effectiveAttaque, 6);

      // Raw intent with value 12 (special attack) with -2 strength
      debuffedEnemy = debuffedEnemy.copyWith(
        currentIntent: EnemyIntent(type: IntentType.attack, value: 12),
      );
      expect(debuffedEnemy.effectiveIntent?.value, 10); // 12 - 2 = 10
    });

    test(
      'EnemyInstance effectiveIntent scales attack proportionally for Elites with buffs',
      () {
        // Simulate an elite enemy spawned with a multiplier of 2.25
        // JSON baseDamage = 8. Spawns with stats.attaque = 18.
        var eliteEnemy = EnemyInstance(
          stats: EntityStats(
            maxPv: 50,
            currentPv: 50,
            armure: 0,
            attaque: 18,
          ),
          data: const EnemyData(
            id: 'orc',
            nameEn: 'Furious Orc',
            nameFr: 'Orc Furieux',
            maxHp: 50,
            baseDamage: 8,
            spritePath: '',
          ),
        );

        // 1st action: Attack 8 in JSON should scale to 18
        eliteEnemy = eliteEnemy.copyWith(
          currentIntent: EnemyIntent(type: IntentType.attack, value: 8),
        );
        expect(eliteEnemy.effectiveIntent?.value, 18);

        // 2nd action: Buff 2 in JSON is executed, applying 2 Strength status
        eliteEnemy = eliteEnemy.copyWith(
          stats: eliteEnemy.stats.addStatus(
            const StatusEffect(
              id: 'strength',
              name: 'Force',
              type: StatusType.buff,
              value: 2,
              duration: 99,
            ),
          ),
        );
        expect(eliteEnemy.stats.effectiveAttaque, 20);

        // 3rd action: Attack 8 in JSON should now scale to 18 + 2 (inBattleBonus) = 20
        eliteEnemy = eliteEnemy.copyWith(
          currentIntent: EnemyIntent(type: IntentType.attack, value: 8),
        );
        expect(eliteEnemy.effectiveIntent?.value, 20);

        // A stronger attack: Attack 10 in JSON should scale to 23 (10 * 2.25) + 2 (inBattleBonus) = 25
        eliteEnemy = eliteEnemy.copyWith(
          currentIntent: EnemyIntent(type: IntentType.attack, value: 10),
        );
        expect(eliteEnemy.effectiveIntent?.value, 25);

        // An even stronger attack: Attack 12 in JSON should scale to 27 (12 * 2.25) + 2 (inBattleBonus) = 29
        eliteEnemy = eliteEnemy.copyWith(
          currentIntent: EnemyIntent(type: IntentType.attack, value: 12),
        );
        expect(eliteEnemy.effectiveIntent?.value, 29);
      },
    );
  });
}
