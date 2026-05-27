import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/skill_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

void main() {
  group('SkillController Unit Tests', () {
    late ProviderContainer container;
    late SkillController skillController;
    late RunController runController;

    const dummyHero = HeroData(
      id: 'paladin',
      nameEn: 'Paladin',
      nameFr: 'Paladin',
      iconPath: 'paladin.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
      luck: 0,
      armorMastery: 0,
      passiveTrait: 'regenArmor',
    );

    setUp(() {
      container = ProviderContainer();
      skillController = container.read(skillProvider.notifier);
      runController = container.read(runProvider.notifier);
      runController.startNewRun(dummyHero);
    });

    test('Initial cooldowns are 0', () {
      expect(skillController.state.skill1Cooldown, 0);
      expect(skillController.state.skill2Cooldown, 0);
    });

    test('triggerSkill1 succeeds, consumes mana, and sets cooldown; fails if mana is insufficient', () {
      // Paladin starts with 3 mana.
      // Trigger skill 1 with cost 2 mana, cooldown 3.
      final success = skillController.triggerSkill1(3, mana: 2);
      expect(success, true);
      expect(skillController.state.skill1Cooldown, 3);
      expect(runController.state.heroStats.currentMana, 1);

      // Reset cooldown to try again but with insufficient mana (only 1 left)
      skillController.resetCooldowns();
      final failure = skillController.triggerSkill1(3, mana: 2);
      expect(failure, false);
      expect(skillController.state.skill1Cooldown, 0); // unchanged
      expect(runController.state.heroStats.currentMana, 1); // unchanged
    });

    test('triggerSkill2 succeeds, consumes mana, and sets cooldown; fails if skill on cooldown', () {
      final success = skillController.triggerSkill2(2, mana: 1);
      expect(success, true);
      expect(skillController.state.skill2Cooldown, 2);
      expect(runController.state.heroStats.currentMana, 2);

      // Attempt to trigger while on cooldown
      final failure = skillController.triggerSkill2(2, mana: 1);
      expect(failure, false);
      expect(skillController.state.skill2Cooldown, 2); // unchanged
      expect(runController.state.heroStats.currentMana, 2); // unchanged
    });

    test('tickCooldowns decrements cooldowns correctly', () {
      skillController.triggerSkill1(3, mana: 1);
      skillController.triggerSkill2(1, mana: 1);

      expect(skillController.state.skill1Cooldown, 3);
      expect(skillController.state.skill2Cooldown, 1);

      skillController.tickCooldowns();
      expect(skillController.state.skill1Cooldown, 2);
      expect(skillController.state.skill2Cooldown, 0);

      skillController.tickCooldowns();
      expect(skillController.state.skill1Cooldown, 1);
      expect(skillController.state.skill2Cooldown, 0);
    });

    test('resetCooldowns sets cooldowns to 0', () {
      skillController.triggerSkill1(3, mana: 1);
      skillController.triggerSkill2(2, mana: 1);
      expect(skillController.state.skill1Cooldown, 3);

      skillController.resetCooldowns();
      expect(skillController.state.skill1Cooldown, 0);
      expect(skillController.state.skill2Cooldown, 0);
    });
  });
}
