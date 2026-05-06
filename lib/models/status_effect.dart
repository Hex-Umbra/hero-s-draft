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

  /// Retourne un nouvel effet combiné si stackable, sinon rafraîchit la durée
  StatusEffect combine(StatusEffect other) {
    if (id != other.id) return this;
    if (isStackable) {
      return copyWith(
        value: value + other.value,
        duration: duration + other.duration,
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
