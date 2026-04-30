import 'dart:math';
import '../../data/models/entity_stats.dart';
import '../../models/data/enemy_data.dart';

class EncounterSystem {
  static final Random _rng = Random();

  static List<EnemyData> generateEnemiesForLevel(int level, List<EnemyData> availableEnemies) {
    if (availableEnemies.isEmpty) return [];

    bool isBoss = level > 0 && level % 10 == 0;
    
    // Nombre d'ennemis aléatoire (1 à 3 max) basé sur la difficulté
    int numEnemies = _rng.nextInt(level > 5 ? 3 : 2) + 1;
    if (isBoss) numEnemies = 1;
    
    List<EnemyData> enemies = [];
    
    for (int i = 0; i < numEnemies; i++) {
      // Pour l'instant on pioche aléatoirement dans la liste
      final randomEnemy = availableEnemies[_rng.nextInt(availableEnemies.length)];
      enemies.add(randomEnemy);
    }
    
    return enemies;
  }
}
