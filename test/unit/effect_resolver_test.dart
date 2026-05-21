import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/data/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';
import 'package:roguelike_card_game/game/components/entities/enemy_card.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/enemy_intent.dart';

void main() {
  group('EntityStats & StatusEffect', () {
    test('takeDamage applies to armor first then PV', () {
      var stats = const EntityStats(
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
      var stats = const EntityStats(
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
      var stats = const EntityStats(
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

    test('EnemyCard effectiveIntent scales attack with current stats', () {
      final enemy = EnemyCard(
        stats: const EntityStats(
          maxPv: 20,
          currentPv: 20,
          armure: 0,
          attaque: 8,
        ),
        data: const EnemyData(
          id: 'test',
          name: 'Test Enemy',
          maxHp: 20,
          baseDamage: 8,
          spritePath: '',
        ),
        onTapEnemy: (_) {},
      );

      // Raw intent is attack with value 8
      enemy.currentIntent = EnemyIntent(type: IntentType.attack, value: 8);
      expect(enemy.effectiveIntent?.value, 8);

      // Boost stats.attaque to 10 (+2 buff)
      enemy.stats = enemy.stats.copyWith(attaque: 10);
      expect(enemy.effectiveIntent?.value, 10); // Should be 10!

      // Raw intent with value 12 (special attack) when stats.attaque is 10
      enemy.currentIntent = EnemyIntent(type: IntentType.attack, value: 12);
      expect(enemy.effectiveIntent?.value, 14); // 12 + (10 - 8) = 14!

      // Debuff stats.attaque to 6
      enemy.stats = enemy.stats.copyWith(attaque: 6);
      expect(enemy.effectiveIntent?.value, 10); // 12 + (6 - 8) = 10 (which is >= stats.attaque 6)

      // Test with status effect 'strength' buff of +3
      final strengthBuff = StatusEffect(
        id: 'strength',
        name: 'Force',
        type: StatusType.buff,
        value: 3,
        duration: 2,
      );
      enemy.stats = enemy.stats.addStatus(strengthBuff);
      
      // Now base stats.attaque is 6, but effectiveAttaque is 9.
      // The attack intent value is 12 (special attack).
      // Base damage in data is 8.
      // bonus = stats.effectiveAttaque - baseDamage = 9 - 8 = 1.
      // value = max(stats.effectiveAttaque, intent.value + bonus) = max(9, 12 + 1) = 13.
      expect(enemy.effectiveIntent?.value, 13);
    });
  });
}
