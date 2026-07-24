import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/skill_state.dart';

void main() {
  group('SkillState persistence', () {
    test('toJson/fromJson round-trips cooldowns', () {
      const state = SkillState(skill1Cooldown: 2, skill2Cooldown: 0);

      final json = state.toJson();
      final restored = SkillState.fromJson(json);

      expect(restored.skill1Cooldown, 2);
      expect(restored.skill2Cooldown, 0);
    });

    test('fromJson defaults missing fields to 0', () {
      final restored = SkillState.fromJson(const {});
      expect(restored.skill1Cooldown, 0);
      expect(restored.skill2Cooldown, 0);
    });
  });
}
