enum StatusType { buff, debuff }

/// L'identité de ce qui pose un statut, `<nature>:<id>` (spec P-43 E0, §4.2).
///
/// Le seul endroit qui écrive ces formes. La source est l'identifiant du
/// **contenu** qui pose, jamais celui d'un exemplaire : deux exemplaires d'une
/// même carte sont une même source, et la même source rejouée s'additionne
/// comme avant (D36). Le préfixe de nature empêche une carte et un passif de
/// même identifiant de se confondre.
abstract final class StatusSource {
  /// Une carte, par l'id de sa donnée : `card:demon_form`.
  static String card(String cardId) => 'card:$cardId';

  /// Une règle de classe, par la ressource qu'elle convertit, dans le
  /// vocabulaire du fichier (`StatRule.statName`) : `rule:armor`.
  static String rule(String resource) => 'rule:$resource';
}

class StatusEffect {
  final String id;
  final String name;
  final StatusType type;
  final int value;
  final int duration;
  final bool isStackable;

  /// Ce qui a posé le statut ([StatusSource]), ou `null` : « sans source ».
  /// Seule la Puissance en reçoit une (spec P-43 E0, A1) ; tout autre statut
  /// est posé sans source et fusionne comme avant.
  final String? sourceId;

  const StatusEffect({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.duration,
    this.isStackable = true,
    this.sourceId,
  });

  StatusEffect copyWith({
    String? id,
    String? name,
    StatusType? type,
    int? value,
    int? duration,
    bool? isStackable,
    String? sourceId,
  }) {
    return StatusEffect(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      duration: duration ?? this.duration,
      isStackable: isStackable ?? this.isStackable,
      sourceId: sourceId ?? this.sourceId,
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
      // Absente d'une sauvegarde écrite avant P-43 E0 : sans source.
      sourceId: json['sourceId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.toString().split('.').last,
    'value': value,
    'duration': duration,
    'isStackable': isStackable,
    if (sourceId != null) 'sourceId': sourceId,
  };

  /// Vrai si [other] rejoint cet effet plutôt que d'ouvrir une autre entrée :
  /// même statut **et** même source, `null` compris (spec P-43 E0, §4.1). La
  /// seule règle de fusion, que lisent [combine] et `EntityStats.addStatus`.
  bool mergesWith(StatusEffect other) =>
      id == other.id && sourceId == other.sourceId;

  /// Retourne un nouvel effet combiné si stackable, sinon rafraîchit la durée.
  /// Rendu tel quel si [other] ne le rejoint pas ([mergesWith]).
  StatusEffect combine(StatusEffect other) {
    if (!mergesWith(other)) return this;
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
