import 'enemy_instance.dart';

enum TurnPhase { player, enemy }

class CombatState {
  final List<EnemyInstance> enemies;
  final List<EnemyInstance> pendingEnemies;
  final List<EnemyInstance> defeatedEnemies;
  final TurnPhase turnPhase;
  final int turnCount;
  final String? selectedEnemyId;
  final bool isCombatEnded;
  final bool isVictory;

  const CombatState({
    this.enemies = const [],
    this.pendingEnemies = const [],
    this.defeatedEnemies = const [],
    this.turnPhase = TurnPhase.player,
    this.turnCount = 1,
    this.selectedEnemyId,
    this.isCombatEnded = false,
    this.isVictory = false,
  });

  CombatState copyWith({
    List<EnemyInstance>? enemies,
    List<EnemyInstance>? pendingEnemies,
    List<EnemyInstance>? defeatedEnemies,
    TurnPhase? turnPhase,
    int? turnCount,
    String? selectedEnemyId,
    bool? isCombatEnded,
    bool? isVictory,
    bool clearSelectedEnemy = false,
  }) {
    return CombatState(
      enemies: enemies ?? this.enemies,
      pendingEnemies: pendingEnemies ?? this.pendingEnemies,
      defeatedEnemies: defeatedEnemies ?? this.defeatedEnemies,
      turnPhase: turnPhase ?? this.turnPhase,
      turnCount: turnCount ?? this.turnCount,
      selectedEnemyId: clearSelectedEnemy
          ? null
          : (selectedEnemyId ?? this.selectedEnemyId),
      isCombatEnded: isCombatEnded ?? this.isCombatEnded,
      isVictory: isVictory ?? this.isVictory,
    );
  }

  factory CombatState.fromJson(Map<String, dynamic> json) {
    var enemiesJson = json['enemies'] as List?;
    List<EnemyInstance> parsedEnemies = [];
    if (enemiesJson != null) {
      parsedEnemies = enemiesJson
          .map((e) => EnemyInstance.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    var pendingEnemiesJson = json['pendingEnemies'] as List?;
    List<EnemyInstance> parsedPendingEnemies = [];
    if (pendingEnemiesJson != null) {
      parsedPendingEnemies = pendingEnemiesJson
          .map((e) => EnemyInstance.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    var defeatedEnemiesJson = json['defeatedEnemies'] as List?;
    List<EnemyInstance> parsedDefeatedEnemies = [];
    if (defeatedEnemiesJson != null) {
      parsedDefeatedEnemies = defeatedEnemiesJson
          .map((e) => EnemyInstance.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return CombatState(
      enemies: parsedEnemies,
      pendingEnemies: parsedPendingEnemies,
      defeatedEnemies: parsedDefeatedEnemies,
      turnPhase: TurnPhase.values.firstWhere(
        (e) => e.toString().split('.').last == json['turnPhase'],
        orElse: () => TurnPhase.player,
      ),
      turnCount: json['turnCount'] as int? ?? 1,
      selectedEnemyId: json['selectedEnemyId'] as String?,
      isCombatEnded: json['isCombatEnded'] as bool? ?? false,
      isVictory: json['isVictory'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'enemies': enemies.map((e) => e.toJson()).toList(),
    'pendingEnemies': pendingEnemies.map((e) => e.toJson()).toList(),
    'defeatedEnemies': defeatedEnemies.map((e) => e.toJson()).toList(),
    'turnPhase': turnPhase.toString().split('.').last,
    'turnCount': turnCount,
    'selectedEnemyId': selectedEnemyId,
    'isCombatEnded': isCombatEnded,
    'isVictory': isVictory,
  };
}
