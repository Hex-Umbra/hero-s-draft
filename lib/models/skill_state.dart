class SkillState {
  final int skill1Cooldown;
  final int skill2Cooldown;

  const SkillState({this.skill1Cooldown = 0, this.skill2Cooldown = 0});

  SkillState copyWith({int? skill1Cooldown, int? skill2Cooldown}) {
    return SkillState(
      skill1Cooldown: skill1Cooldown ?? this.skill1Cooldown,
      skill2Cooldown: skill2Cooldown ?? this.skill2Cooldown,
    );
  }
}
