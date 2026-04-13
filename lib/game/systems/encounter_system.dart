import 'dart:math';
import '../../data/models/entity_stats.dart';

class EncounterSystem {
  static final Random _rng = Random();

  /// Génère une liste de statistiques ennemies pour un niveau donné
  static List<EntityStats> generateEnemiesForLevel(int level) {
    bool isBoss = level > 0 && level % 10 == 0;
    
    if (isBoss) {
      return [_generateEnemy(level, s0: 100, isBoss: true)];
    }

    // Nombre d'ennemis aléatoire (1 à 3 max) basé sur la difficulté
    int numEnemies = _rng.nextInt(level > 5 ? 3 : 2) + 1;
    
    // On divise les stats de base par le nombre d'ennemis pour équilibrer
    double scalingFactor = 1.0 / numEnemies;
    List<EntityStats> enemies = [];
    
    for (int i = 0; i < numEnemies; i++) {
        enemies.add(_generateEnemy(level, s0: (50 * scalingFactor).round(), isBoss: false));
    }
    
    return enemies;
  }

  /// Applique la formule mathématique du PRD
  static EntityStats _generateEnemy(int n, {required int s0, required bool isBoss}) {
    int p = (n / 10).floor(); // Paliers de Boss
    int e = (p / 3).floor();  // Ère de difficulté

    // Formule : S(N) = S0 * (1 + 0.05*N) * 1.15^P * 1.40^E
    double multiplier = (1 + 0.05 * n) * pow(1.15, p) * pow(1.40, e);

    int hp = (s0 * multiplier).round();
    int atk = ((isBoss ? 8 : 4) * multiplier).round();
    int armure = ((isBoss ? 10 : 2) * multiplier).round();

    // Défense asymptotique : Dmax * (1 - e^(-k*N))
    double dMax = 0.75;
    double k = 0.02;
    double defense = dMax * (1 - exp(-k * n));

    return EntityStats(
      maxPv: hp,
      currentPv: hp,
      armure: armure,
      attaque: atk,
      defense: defense,
    );
  }
}
