import 'dart:math' show max;

import 'card_data.dart';

/// Une opération sur une carte, déclarée par niveau : ce qu'une rune fait, en
/// donnée (spec P-43 E1, A1, §4.1).
///
/// Le vocabulaire est **fermé** : une sorte neuve s'écrit ici une fois, par
/// mécanisme, avec le lecteur de son lot — jamais un `case` par rune.
/// L'applicateur (`EffectiveCard.apply`) reçoit des paires *(delta, niveau)* ;
/// une rune en fournit par `EffectiveCard.runeDeltas`, et la vague 5 y
/// traduira de même les évolutions de signature.
sealed class CardDelta {
  const CardDelta();

  /// Les `type` qu'un fichier peut déclarer.
  static const typeNames = [
    'percentBonus',
    'addEffect',
    'removeExhaust',
    'reduceCost',
    'critBonus',
    'addExhaust',
  ];

  /// Lit une entrée de `deltas`. Lève `FormatException` sur un type inconnu ou
  /// un paramètre manquant : `GameDataLoader` accumule le refus.
  factory CardDelta.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    return switch (type) {
      'percentBonus' => PercentBonusDelta(
          effect: _text(json, 'effect'),
          valuePercentPerLevel: _positive(json, 'valuePercentPerLevel'),
        ),
      'addEffect' => AddEffectDelta._fromJson(json),
      'removeExhaust' => const RemoveExhaustDelta(),
      'reduceCost' =>
        ReduceCostDelta(valuePerLevel: _positive(json, 'valuePerLevel')),
      'critBonus' =>
        CritBonusDelta(valuePerLevel: _positive(json, 'valuePerLevel')),
      'addExhaust' => const AddExhaustDelta(),
      _ => throw FormatException(
          'deltas.type : valeur "$type" inconnue — attendu : '
          '${typeNames.join(', ')}',
        ),
    };
  }

  Map<String, dynamic> toJson();

  static String _text(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('deltas.$key : texte obligatoire — reçu : $value');
    }
    return value;
  }

  static int _positive(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! int || value <= 0) {
      throw FormatException(
        'deltas.$key : entier strictement positif obligatoire — reçu : $value',
      );
    }
    return value;
  }
}

/// Chaque effet **propre** de la carte de type [effect] gagne un pourcentage
/// de sa valeur à la rareté de la carte (D33) : `sharp`, `hardened`.
final class PercentBonusDelta extends CardDelta {
  const PercentBonusDelta({
    required this.effect,
    required this.valuePercentPerLevel,
  });

  final String effect;
  final int valuePercentPerLevel;

  /// Le bonus au niveau [level] — total des exemplaires — sur la valeur
  /// [base] : `p × L × B` %, arrondi au plus proche, la demie vers le haut, en
  /// arithmétique entière, et au moins [level] (D33, spec P-43 E1, A7). La
  /// seule écriture de la formule.
  int bonusFor(int base, int level) =>
      max((valuePercentPerLevel * level * base + 50) ~/ 100, level);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'percentBonus',
        'effect': effect,
        'valuePercentPerLevel': valuePercentPerLevel,
      };
}

/// Ajoute à la carte un effet de valeur `valuePerLevel × L` — et, pour un
/// `apply_status`, de durée `durationPerLevel × L` —, résolu avant ceux de la
/// carte, jamais multiplié par la rareté ni visé par un pourcentage : `quick`,
/// `eco`, les trois runes élémentaires.
final class AddEffectDelta extends CardDelta {
  const AddEffectDelta({
    required this.effect,
    required this.valuePerLevel,
    this.statusId,
    this.durationPerLevel,
  });

  /// `statusId` et `durationPerLevel` sont exigés pour un `apply_status`, et
  /// refusés pour tout autre type d'effet.
  factory AddEffectDelta._fromJson(Map<String, dynamic> json) {
    final effect = CardDelta._text(json, 'effect');
    final valuePerLevel = CardDelta._positive(json, 'valuePerLevel');
    if (effect != 'apply_status') {
      if (json.containsKey('statusId') || json.containsKey('durationPerLevel')) {
        throw FormatException(
          'deltas : statusId et durationPerLevel ne valent que pour '
          'apply_status — reçus pour "$effect"',
        );
      }
      return AddEffectDelta(effect: effect, valuePerLevel: valuePerLevel);
    }
    return AddEffectDelta(
      effect: effect,
      valuePerLevel: valuePerLevel,
      statusId: CardDelta._text(json, 'statusId'),
      durationPerLevel: CardDelta._positive(json, 'durationPerLevel'),
    );
  }

  final String effect;
  final int valuePerLevel;
  final String? statusId;
  final int? durationPerLevel;

  /// L'effet ajouté au niveau [level].
  CardEffect effectAt(int level) {
    final duration = durationPerLevel;
    return CardEffect(
      type: effect,
      value: valuePerLevel * level,
      statusId: statusId,
      duration: duration == null ? null : duration * level,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'addEffect',
        'effect': effect,
        'valuePerLevel': valuePerLevel,
        if (statusId != null) 'statusId': statusId,
        if (durationPerLevel != null) 'durationPerLevel': durationPerLevel,
      };
}

/// La carte ne s'épuise plus, quel que soit le niveau (ADR-094 D4) :
/// `enduring`.
final class RemoveExhaustDelta extends CardDelta {
  const RemoveExhaustDelta();

  @override
  Map<String, dynamic> toJson() => {'type': 'removeExhaust'};
}

/// La carte coûte `valuePerLevel × L` Mana de moins, jamais moins de 0 ; la
/// rareté ne change jamais le coût (spec P-43 E2, §4.1) : `cheap`.
final class ReduceCostDelta extends CardDelta {
  const ReduceCostDelta({required this.valuePerLevel});

  final int valuePerLevel;

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'reduceCost', 'valuePerLevel': valuePerLevel};
}

/// +`valuePerLevel × L` points de pourcentage de critique sur les dégâts de
/// la carte (spec P-43 E2, §4.1) : `precise`.
final class CritBonusDelta extends CardDelta {
  const CritBonusDelta({required this.valuePerLevel});

  final int valuePerLevel;

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'critBonus', 'valuePerLevel': valuePerLevel};
}

/// La carte s'épuise, quel que soit le niveau, et l'emporte sur
/// [RemoveExhaustDelta] (D33 ; spec P-43 E2, A10) : `spectral`.
final class AddExhaustDelta extends CardDelta {
  const AddExhaustDelta();

  @override
  Map<String, dynamic> toJson() => {'type': 'addExhaust'};
}
