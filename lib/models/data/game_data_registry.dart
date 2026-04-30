import 'enemy_data.dart';
import 'hero_data.dart';
import 'skill_data.dart';

class GameDataRegistry {
  final List<EnemyData> enemies;
  final List<HeroData> heroes;
  final List<SkillData> skills;

  const GameDataRegistry({
    required this.enemies,
    required this.heroes,
    required this.skills,
  });
}
