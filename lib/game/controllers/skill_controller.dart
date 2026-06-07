import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/skill_state.dart';
import 'run_controller.dart';

class SkillController extends Notifier<SkillState> {
  @override
  SkillState build() {
    return const SkillState();
  }

  void tickCooldowns() {
    state = SkillState(
      skill1Cooldown: state.skill1Cooldown > 0 ? state.skill1Cooldown - 1 : 0,
      skill2Cooldown: state.skill2Cooldown > 0 ? state.skill2Cooldown - 1 : 0,
    );
  }

  bool triggerSkill1(int cd, {int mana = 0, int hpPercent = 0}) {
    if (state.skill1Cooldown > 0) return false;
    final success = ref
        .read(runProvider.notifier)
        .consumeResource(mana: mana, hpPercent: hpPercent);
    if (!success) return false;
    state = state.copyWith(skill1Cooldown: cd);
    return true;
  }

  bool triggerSkill2(int cd, {int mana = 0, int hpPercent = 0}) {
    if (state.skill2Cooldown > 0) return false;
    final success = ref
        .read(runProvider.notifier)
        .consumeResource(mana: mana, hpPercent: hpPercent);
    if (!success) return false;
    state = state.copyWith(skill2Cooldown: cd);
    return true;
  }

  void resetCooldowns() {
    state = const SkillState();
  }
}

final skillProvider = NotifierProvider<SkillController, SkillState>(SkillController.new);
