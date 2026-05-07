import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/data/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';

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
      expect(stats.statuses.first.duration, 5); // 2 + 3

      // Tick statuses reduces duration
      stats = stats.tickStatuses();
      expect(stats.statuses.first.duration, 4);

      stats = stats.tickStatuses();
      expect(stats.statuses.first.duration, 3);
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
  });
}
