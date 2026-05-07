enum IntentType { attack, defend, buff, debuffDeck }

class EnemyIntent {
  final IntentType type;
  final int value;

  EnemyIntent({required this.type, required this.value});
}
