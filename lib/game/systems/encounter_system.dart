import 'dart:math';
import '../../models/data/enemy_data.dart';
import '../../models/map_node.dart';

class EncounterSystem {
  static final Random _rng = Random();

  static List<EnemyData> generateEnemiesForLevel(
    int level,
    List<EnemyData> availableEnemies, {
    MapNodeType? nodeType,
  }) {
    if (availableEnemies.isEmpty) return [];

    bool isBoss = nodeType == MapNodeType.boss || (level > 0 && level % 10 == 0);
    bool isElite = nodeType == MapNodeType.elite;

    // Nombre d'ennemis aléatoire (1 à 3 max) basé sur la difficulté
    int numEnemies = _rng.nextInt(level > 5 ? 3 : 2) + 1;

    if (isBoss) {
      numEnemies = 1;
    } else if (isElite) {
      numEnemies = _rng.nextInt(2) + 2; // 2 ou 3 ennemis pour un Élite
    }

    List<EnemyData> enemies = [];

    for (int i = 0; i < numEnemies; i++) {
      // Pour l'instant on pioche aléatoirement dans la liste
      final randomEnemy =
          availableEnemies[_rng.nextInt(availableEnemies.length)];
      enemies.add(randomEnemy);
    }

    return enemies;
  }
}
