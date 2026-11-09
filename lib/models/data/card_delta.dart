import 'dart:math' show max;

import 'card_data.dart';

/// Une opération sur une carte, déclarée par niveau : ce qu'une rune fait, en
/// donnée (spec P-43 E1, A1, §4.1).
///
/// Le vocabulaire est **fermé** : une sorte neuve s'écrit ici une fois, par
/// mécanisme, avec le lecteur de son lot — jamais un `case` par rune.
/// L'applicateur (`EffectiveCard.apply`) reçoit des paires *(delta, niveau)* ;
/// une rune en fournit par `EffectiveCard.runeDeltas`, et les évolutions de
/// signature y sont traduites de même.
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
    'armorPierce',
    'lifestealPercent',
    'splashPercent',
    'echoChance',
    'refundHpCost',
    'flatBonus',
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
      'armorPierce' => ArmorPierceDelta(
          valuePercentPerLevel: _positive(json, 'valuePercentPerLevel'),
        ),
      'lifestealPercent' => LifestealPercentDelta(
          valuePercentPerLevel: _positive(json, 'valuePercentPerLevel'),
        ),
      'splashPercent' => SplashPercentDelta(
          valuePercentPerLevel: _positive(json, 'valuePercentPerLevel'),
        ),
      'echoChance' => EchoChanceDelta(
          valuePercentPerLevel: _positive(json, 'valuePercentPerLevel'),
        ),
      'refundHpCost' => RefundHpCostDelta(
          valuePercentPerLevel: _positive(json, 'valuePercentPerLevel'),
        ),
      'flatBonus' => FlatBonusDelta._fromJson(json),
      _ => throw FormatException(
          'deltas.type : valeur "$type" inconnue — attendu : '
          '${typeNames.join(', ')}',
        ),
    };
  }

  Map<String, dynamic> toJson();

  /// Vrai si la rune portée au niveau [level] ne peut plus rien donner par un
  /// niveau de plus : une sorte en pourcentage qui vaut 100 au plus le
  /// surcharge (A22). *Transcendance* ne propose pas une rune dont chaque delta
  /// est saturé.
  bool saturatesAt(int level) => false;

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

/// Chaque effet **propre** de la carte que [targets] vise gagne
/// `valuePerLevel × L`, ajouté après la rareté, jamais multiplié par elle, sur
/// chaque coup d'un multi-coups (spec A24).
final class FlatBonusDelta extends CardDelta {
  const FlatBonusDelta({
    required this.effect,
    required this.valuePerLevel,
    this.statusId,
  });

  /// `statusId` ne vaut que pour un `apply_status`.
  factory FlatBonusDelta._fromJson(Map<String, dynamic> json) {
    final effect = CardDelta._text(json, 'effect');
    final valuePerLevel = CardDelta._positive(json, 'valuePerLevel');
    if (effect != 'apply_status') {
      if (json.containsKey('statusId')) {
        throw FormatException(
          'deltas : statusId ne vaut que pour apply_status — reçu pour '
          '"$effect"',
        );
      }
      return FlatBonusDelta(effect: effect, valuePerLevel: valuePerLevel);
    }
    return FlatBonusDelta(
      effect: effect,
      valuePerLevel: valuePerLevel,
      statusId: json.containsKey('statusId')
          ? CardDelta._text(json, 'statusId')
          : null,
    );
  }

  final String effect;
  final int valuePerLevel;
  final String? statusId;

  /// Vrai si [e] est un effet que ce delta augmente.
  bool targets(CardEffect e) =>
      e.type == effect && (statusId == null || e.statusId == statusId);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'flatBonus',
        'effect': effect,
        'valuePerLevel': valuePerLevel,
        if (statusId != null) 'statusId': statusId,
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

/// Les coups de la carte ignorent `valuePercentPerLevel × L` % de l'Armure de
/// la cible, au plus 100 % (spec §3.6, §4.6, A16) : `piercing`.
final class ArmorPierceDelta extends CardDelta {
  const ArmorPierceDelta({required this.valuePercentPerLevel});

  final int valuePercentPerLevel;

  @override
  bool saturatesAt(int level) => valuePercentPerLevel * level >= 100;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'armorPierce',
        'valuePercentPerLevel': valuePercentPerLevel,
      };
}

/// La carte soigne le héros de `valuePercentPerLevel × L` % des dégâts qu'elle
/// inflige, au plus 100 % (spec §3.6, §4.6, A18) : `lifesteal`.
final class LifestealPercentDelta extends CardDelta {
  const LifestealPercentDelta({required this.valuePercentPerLevel});

  final int valuePercentPerLevel;

  @override
  bool saturatesAt(int level) => valuePercentPerLevel * level >= 100;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'lifestealPercent',
        'valuePercentPerLevel': valuePercentPerLevel,
      };
}

/// Chaque coup de la carte éclabousse les autres ennemis vivants de
/// `valuePercentPerLevel × L` % de sa valeur initiale (spec §3.6, §4.6, A17) :
/// `splash`. Sans saturation : le pourcentage n'a pas de borne.
final class SplashPercentDelta extends CardDelta {
  const SplashPercentDelta({required this.valuePercentPerLevel});

  final int valuePercentPerLevel;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'splashPercent',
        'valuePercentPerLevel': valuePercentPerLevel,
      };
}

/// Après sa première résolution, la carte se résout une seconde fois avec
/// `valuePercentPerLevel × L` % de chances, au plus 100 % (spec §3.6, §4.7,
/// A19) : `echo`.
final class EchoChanceDelta extends CardDelta {
  const EchoChanceDelta({required this.valuePercentPerLevel});

  final int valuePercentPerLevel;

  @override
  bool saturatesAt(int level) => valuePercentPerLevel * level >= 100;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'echoChance',
        'valuePercentPerLevel': valuePercentPerLevel,
      };
}

/// Après la résolution de la carte, le héros récupère `valuePercentPerLevel ×
/// L` % de son coût en PV, la demie vers le haut, borné aux PV max (spec §4.1,
/// A20) : `transfusion`. Non saturant : la rune est binaire.
final class RefundHpCostDelta extends CardDelta {
  const RefundHpCostDelta({required this.valuePercentPerLevel});

  final int valuePercentPerLevel;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'refundHpCost',
        'valuePercentPerLevel': valuePercentPerLevel,
      };
}
