import 'dart:math' show max;

import 'package:meta/meta.dart';
import 'enemy_instance.dart';

enum TurnPhase { player, enemy }

@immutable
class CombatState {
  final List<EnemyInstance> enemies;
  final List<EnemyInstance> pendingEnemies;
  final List<EnemyInstance> defeatedEnemies;
  final TurnPhase turnPhase;
  final int turnCount;
  final String? selectedEnemyId;
  final bool isCombatEnded;
  final bool isVictory;

  /// Par id de signature, le tour à partir duquel elle se rejoue (spec P-43
  /// E4, §4.2 ; A7). Absente : disponible. Écrite une fois, au jeu ; lue par
  /// soustraction ; jamais décomptée. Un `CombatState` neuf la porte vide —
  /// toutes les signatures sont prêtes au premier tour de chaque combat
  /// (D41). **Jamais sérialisée** : ni `toJson` ni `fromJson` ne la lisent.
  final Map<String, int> signaturesReadyOn;

  CombatState({
    List<EnemyInstance> enemies = const [],
    List<EnemyInstance> pendingEnemies = const [],
    List<EnemyInstance> defeatedEnemies = const [],
    this.turnPhase = TurnPhase.player,
    this.turnCount = 1,
    this.selectedEnemyId,
    this.isCombatEnded = false,
    this.isVictory = false,
    Map<String, int> signaturesReadyOn = const {},
  })  : enemies = List.unmodifiable(enemies),
        pendingEnemies = List.unmodifiable(pendingEnemies),
        defeatedEnemies = List.unmodifiable(defeatedEnemies),
        signaturesReadyOn = Map.unmodifiable(signaturesReadyOn);

  CombatState copyWith({
    List<EnemyInstance>? enemies,
    List<EnemyInstance>? pendingEnemies,
    List<EnemyInstance>? defeatedEnemies,
    TurnPhase? turnPhase,
    int? turnCount,
    String? selectedEnemyId,
    bool? isCombatEnded,
    bool? isVictory,
    Map<String, int>? signaturesReadyOn,
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
      signaturesReadyOn: signaturesReadyOn ?? this.signaturesReadyOn,
    );
  }

  /// Dans combien de tours joueur la signature [id] revient : 0 si elle est
  /// prête. Ne bouge pas pendant le tour ennemi.
  int signatureTurnsLeft(String id) {
    final readyOn = signaturesReadyOn[id];
    return readyOn == null ? 0 : max(0, readyOn - turnCount);
  }

  bool isSignatureReady(String id) => signatureTurnsLeft(id) == 0;

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
