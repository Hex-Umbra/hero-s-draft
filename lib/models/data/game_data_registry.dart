import 'enemy_data.dart';
import 'hero_data.dart';
import 'skill_data.dart';
import 'card_data.dart';
import 'event_data.dart';

class GameDataRegistry {
  final List<EnemyData> enemies;
  final List<HeroData> heroes;
  final List<SkillData> skills;
  final List<CardData> cards;
  final List<EventData> events;

  const GameDataRegistry({
    required this.enemies,
    required this.heroes,
    required this.skills,
    required this.cards,
    required this.events,
  });
}
