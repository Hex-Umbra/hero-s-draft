import 'enemy_data.dart';
import 'hero_data.dart';
import 'card_data.dart';
import 'event_data.dart';
import 'passive_data.dart';
import 'relic_data.dart';
import 'forge_upgrade_data.dart';
import 'audio_data.dart';

class GameDataRegistry {
  final List<EnemyData> enemies;
  final List<HeroData> heroes;
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
    required this.cards,
    required this.events,
    required this.passives,
    required this.relics,
    required this.forgeUpgrades,
    this.audio = const AudioData.disabled(),
  }) {
    _instance = this;
  }

  /// Les chemins d'images référencés par les entités chargées.
  ///
  /// Unique source de la liste de préchargement de Flame : avant, la couche
  /// de rendu relisait elle-même les données d'ennemis et de héros pour la
  /// reconstituer.
  /// C'est un getter calculé et non un champ de constructeur, pour ne pas
  /// casser les dizaines de `GameDataRegistry(...)` construits par les tests.
  List<String> get imagesToPreload => <String>{
        ...heroes.map((h) => h.iconPath),
        ...enemies.map((e) => e.spritePath),
      }.where((path) => path.isNotEmpty).toList();
}
