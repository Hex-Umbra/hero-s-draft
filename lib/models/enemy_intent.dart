enum IntentType { attack, defend, buff }

class EnemyIntent {
  final IntentType type;
  final int value;

  EnemyIntent({required this.type, required this.value});

  factory EnemyIntent.fromJson(Map<String, dynamic> json) {
    return EnemyIntent(
      type: IntentType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => IntentType.attack,
      ),
      value: json['value'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.toString().split('.').last,
    'value': value,
  };
}
