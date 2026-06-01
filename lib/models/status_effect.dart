enum StatusType { buff, debuff }

class StatusEffect {
  final String id;
  final String name;
  final StatusType type;
  final int value;
  final int duration;
  final bool isStackable;

  const StatusEffect({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.duration,
    this.isStackable = true,
  });

  StatusEffect copyWith({
    String? id,
    String? name,
    StatusType? type,
    int? value,
    int? duration,
    bool? isStackable,
  }) {
    return StatusEffect(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      duration: duration ?? this.duration,
      isStackable: isStackable ?? this.isStackable,
    );
  }

  factory StatusEffect.fromJson(Map<String, dynamic> json) {
    return StatusEffect(
      id: json['id'] as String,
      name: json['name'] as String,
      type: StatusType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => StatusType.buff,
      ),
      value: json['value'] as int,
      duration: json['duration'] as int,
      isStackable: json['isStackable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.toString().split('.').last,
    'value': value,
    'duration': duration,
    'isStackable': isStackable,
  };

  /// Retourne un nouvel effet combiné si stackable, sinon rafraîchit la durée
  StatusEffect combine(StatusEffect other) {
    if (id != other.id) return this;
    if (isStackable) {
      return copyWith(
        value: value + other.value,
        duration: duration > other.duration
            ? duration
            : other.duration, // Ne pas additionner les durées
      );
    } else {
      // Rafraîchit la durée si elle est plus grande
      return copyWith(
        duration: other.duration > duration ? other.duration : duration,
        value: other.value > value ? other.value : value,
      );
    }
  }
}
