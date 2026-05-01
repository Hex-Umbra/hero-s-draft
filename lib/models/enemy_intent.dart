enum IntentType { attack, defend, buff }

class EnemyIntent {
  final IntentType type;
  final int value;

  EnemyIntent({required this.type, required this.value});
}
