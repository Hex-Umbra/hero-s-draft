import 'enemy_data.dart';
import 'hero_data.dart';
import 'skill_data.dart';
import 'card_data.dart';
import 'event_data.dart';
import 'passive_data.dart';
import 'relic_data.dart';
import 'forge_upgrade_data.dart';
import 'audio_data.dart';

class GameDataRegistry {
  final List<EnemyData> enemies;
  final List<HeroData> heroes;
  final List<SkillData> skills;
  final List<CardData> cards;
  final List<EventData> events;
  final List<PassiveData> passives;
  final List<RelicData> relics;
  final List<ForgeUpgradeData> forgeUpgrades;
  final AudioData audio;

  static GameDataRegistry? _instance;
  static GameDataRegistry? get instance => _instance;

  GameDataRegistry({
    required this.enemies,
    required this.heroes,
    required this.skills,
    required this.cards,
    required this.events,
    required this.passives,
    required this.relics,
    required this.forgeUpgrades,
    this.audio = const AudioData.disabled(),
  }) {
    _instance = this;
  }
}
