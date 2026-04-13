import 'entity_stats.dart';

enum PlayerClassType { paladin, berserker, mage }

class PlayerClass {
  final PlayerClassType type;
  final String name;
  final String heroDescription;
  final EntityStats startingStats;

  const PlayerClass({
    required this.type,
    required this.name,
    required this.heroDescription,
    required this.startingStats,
  });

  static const paladin = PlayerClass(
    type: PlayerClassType.paladin,
    name: 'Le Paladin',
    heroDescription: 'Orienté Survie\nSpécial: Châtiment - Inflige 150% Armure',
    startingStats: EntityStats(
      maxPv: 100,
      currentPv: 100,
      maxMana: 10,
      currentMana: 10,
      armure: 20,
      attaque: 5,
      defense: 0.1, // 10% réduction
    ),
  );

  static const berserker = PlayerClass(
    type: PlayerClassType.berserker,
    name: 'Le Berserker',
    heroDescription: 'Orienté Dégâts\nSpécial: Siphon - Dégâts critiques et vol vie',
    startingStats: EntityStats(
      maxPv: 80,
      currentPv: 80,
      maxMana: 5,
      currentMana: 5,
      armure: 0,
      attaque: 15,
      defense: 0.0,
    ),
  );

  static const mage = PlayerClass(
    type: PlayerClassType.mage,
    name: 'Le Mage',
    heroDescription: 'Orienté Altération\nSpécial: Éclair - Ignore Armure/Défense',
    startingStats: EntityStats(
      maxPv: 60,
      currentPv: 60,
      maxMana: 15,
      currentMana: 15,
      armure: 5,
      attaque: 10,
      defense: 0.05,
    ),
  );

  static List<PlayerClass> get availableClasses => [paladin, berserker, mage];
}
