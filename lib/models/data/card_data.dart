import 'dart:math' show max;

import 'package:flutter/foundation.dart';
import '../../services/audio/audio_source.dart';
import 'game_data_registry.dart';

enum CardType { attack, skill, power, status }

enum CardRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary;

  /// Rareté que produit une fusion 3→1 de cartes de cette rareté.
  ///
  /// `null` au sommet de l'échelle (`legendary`).
  CardRarity? get next => switch (this) {
        CardRarity.common => CardRarity.uncommon,
        CardRarity.uncommon => CardRarity.rare,
        CardRarity.rare => CardRarity.epic,
        CardRarity.epic => CardRarity.legendary,
        CardRarity.legendary => null,
      };

  /// Le nombre de fusions qu'il a fallu pour atteindre cette rareté : 0 à 4
  /// de `common` à `legendary`. `minFusionRank` le compare
  /// (`ForgeRuneRules.isEligible`), G1 compte ses paliers (`scaleValue`), il
  /// borne les runes d'une pré-forgée (`ShopController`), et la difficulté en
  /// somme le double (`DeckState.fusionRankSum`).
  int get fusionRank => switch (this) {
        CardRarity.common => 0,
        CardRarity.uncommon => 1,
        CardRarity.rare => 2,
        CardRarity.epic => 3,
        CardRarity.legendary => 4,
      };

  /// Le multiplicateur du palier de cette rareté, que G1 applique palier par
  /// palier (`scaleValue`).
  double get multiplier => switch (this) {
        CardRarity.common => 1.0,
        CardRarity.uncommon => 1.2,
        CardRarity.rare => 1.4,
        CardRarity.epic => 1.6,
        CardRarity.legendary => 2.0,
      };

  /// Les paliers de l'échelle de fusion au-delà de `common`, dans l'ordre.
  static const _fusionSteps = [
    CardRarity.uncommon,
    CardRarity.rare,
    CardRarity.epic,
    CardRarity.legendary,
  ];

  /// G1 : [base] à cette rareté. À chaque palier franchi depuis `common` —
  /// [fusionRank] paliers —, la valeur prend le multiplicateur du palier, et
  /// au moins 1 de plus que la précédente : une fusion augmente d'au moins 1
  /// chaque chiffre que la rareté multiplie (brainstorm §4.5, spec P-43 E1,
  /// A5, §4.3). Une base nulle ou négative est rendue telle quelle.
  int scaleValue(int base) {
    if (base <= 0) return base;
    var value = base;
    for (final step in _fusionSteps.take(fusionRank)) {
      value = max((base * step.multiplier).round(), value + 1);
    }
    return value;
  }
}

enum CardTarget { singleEnemy, allEnemies, self, none }

/// Ce qu'une croissance (`ScaleWith`) lit pour grandir (spec P-44 lot 1, §4.2).
enum ScaleSource {
  armor,
  missingHp,
  cardsPlayedThisTurn,
  enemiesAlive,
  targetStatus,
  targetMissingHp,
}

/// La croissance d'un effet : sa valeur gagne `ratio` fois ce que [source]
/// vaut au moment de la résolution (spec P-44 lot 1, §3.1).
class ScaleWith {
  final ScaleSource source;
  final double ratio;

  /// Le statut que [source] lit : exigé par `targetStatus`, refusé ailleurs.
  final String? statusId;

  const ScaleWith({required this.source, required this.ratio, this.statusId});

  factory ScaleWith.fromJson(Map<String, dynamic> json) {
    final name = json['source'];
    final source = ScaleSource.values.where((s) => s.name == name).firstOrNull;
    if (source == null) {
      throw FormatException(
        'CardEffect: "scaleWith.source" inconnue : $name',
      );
    }
    final ratio = json['ratio'];
    if (ratio is! num || ratio <= 0) {
      throw FormatException(
        'CardEffect: "scaleWith.ratio" doit etre un nombre > 0 : $ratio',
      );
    }
    // A11 : sous 1, le texte écrit `1 / ratio` en tranches entières.
    final inverse = 1 / ratio;
    if (ratio < 1 && (inverse - inverse.round()).abs() > 1e-9) {
      throw FormatException(
        'CardEffect: "scaleWith.ratio" sous 1 doit etre l\'inverse d\'un '
        'entier : $ratio',
      );
    }
    final statusId = json['statusId'];
    if (source == ScaleSource.targetStatus) {
      if (statusId is! String || statusId.isEmpty) {
        throw const FormatException(
          'CardEffect: "scaleWith.statusId" est exigee par targetStatus',
        );
      }
    } else if (statusId != null) {
      throw FormatException(
        'CardEffect: "scaleWith.statusId" est refusee avec ${source.name}',
      );
    }
    return ScaleWith(
      source: source,
      ratio: ratio.toDouble(),
      statusId: statusId as String?,
    );
  }

  /// Ce que [quantity] ajoute à la valeur : `quantity x ratio`, arrondi vers
  /// le bas, avec la tolérance de `StatRule.convertedAmount` (A11).
  int termFor(int quantity) => (quantity * ratio + 1e-9).floor();

  Map<String, dynamic> toJson() => {
        'source': source.name,
        'ratio': ratio,
        if (statusId != null) 'statusId': statusId,
      };
}

class CardEffect {
  final String type;
  final int value;
  final String? statusId;
  final int? duration;

  /// Le nombre de coups d'un effet `damage` (spec P-44 lot 1, §3.1).
  final int hits;

  /// La part de Puissance que chaque coup d'un `damage` reçoit, dans ]0, 1].
  final double mightRatio;

  /// La croissance de l'effet, `null` s'il ne grandit pas.
  final ScaleWith? scaleWith;

  const CardEffect({
    required this.type,
    required this.value,
    this.statusId,
    this.duration,
    this.hits = 1,
    this.mightRatio = 1,
    this.scaleWith,
  });

  factory CardEffect.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    FormatException fault(String key, String why) =>
        FormatException('CardEffect "$type": "$key" $why');

    for (final key in const ['hits', 'mightRatio']) {
      if (json.containsKey(key) && type != 'damage') {
        throw fault(key, 'n\'est permis que sur un effet damage');
      }
    }
    final rawHits = json['hits'];
    if (json.containsKey('hits') && (rawHits is! int || rawHits < 1)) {
      throw fault('hits', 'doit etre un entier >= 1 : $rawHits');
    }
    final rawRatio = json['mightRatio'];
    if (json.containsKey('mightRatio') &&
        (rawRatio is! num || rawRatio <= 0 || rawRatio > 1)) {
      throw fault('mightRatio', 'doit etre dans ]0, 1] : $rawRatio');
    }
    final hits = rawHits as int? ?? 1;

    final rawScale = json['scaleWith'];
    if (rawScale != null) {
      if (type == 'draw' || type == 'gain_mana') {
        throw fault('scaleWith', 'est refuse : la rarete gele cet effet');
      }
      if (hits >= 2) {
        throw fault('scaleWith', 'est refuse sur un effet a plusieurs coups');
      }
    }

    return CardEffect(
      type: type,
      value: json['value'] as int,
      statusId: json['statusId'] as String?,
      duration: json['duration'] as int?,
      hits: hits,
      mightRatio: (rawRatio as num?)?.toDouble() ?? 1,
      scaleWith: rawScale == null
          ? null
          : ScaleWith.fromJson(rawScale as Map<String, dynamic>),
    );
  }

  /// Cet effet à la valeur [value], tous ses autres champs gardés.
  CardEffect copyWithValue(int value) => CardEffect(
        type: type,
        value: value,
        statusId: statusId,
        duration: duration,
        hits: hits,
        mightRatio: mightRatio,
        scaleWith: scaleWith,
      );

  /// Une croissance qui lit la cible n'a de sens que sur une cible unique
  /// (spec P-44 lot 1, §3.1 : la cible étant la sienne). [owner] nomme la
  /// carte ou la signature fautive.
  static void checkScaleTarget(
    Iterable<CardEffect> effects,
    CardTarget target, {
    required String owner,
  }) {
    if (target == CardTarget.singleEnemy) return;
    for (final effect in effects) {
      final source = effect.scaleWith?.source;
      if (source == ScaleSource.targetStatus ||
          source == ScaleSource.targetMissingHp) {
        throw FormatException(
          '"$owner": "scaleWith.source" ${source!.name} exige une cible '
          'unique (cible : ${target.name})',
        );
      }
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'value': value,
        if (statusId != null) 'statusId': statusId,
        if (duration != null) 'duration': duration,
        if (hits != 1) 'hits': hits,
        if (mightRatio != 1) 'mightRatio': mightRatio,
        if (scaleWith != null) 'scaleWith': scaleWith!.toJson(),
      };
}

class CardData implements AudioSource {
  final String id;
  final String nameEn;
  final String nameFr;
  final String descriptionEn;
  final String descriptionFr;
  final int cost;

  /// Le coût en PV et en Armure (D40) : jamais lu par la rareté, jamais
  /// touché par une rune — `cheap` ne réduit que [cost], le mana.
  final int hpCost;
  final int armorCost;
  final CardType type;
  final CardRarity rarity;
  final CardTarget target;
  final String? spritePath;
  @override
  final String? animation; // Type d'animation (ex: 'melee', 'magic', 'buff')
  @override
  final String? sfx; // Identifiant de son propre a la carte (voir audio.json)
  final bool isExhaust;
  final List<CardEffect> effects;

  const CardData({
    required this.id,
    this.nameEn = '',
    this.nameFr = '',
    this.descriptionEn = '',
    this.descriptionFr = '',
    required this.cost,
    this.hpCost = 0,
    this.armorCost = 0,
    required this.type,
    required this.rarity,
    required this.target,
    this.spritePath,
    this.animation,
    this.sfx,
    this.isExhaust = false,
    required this.effects,
  });

  String getName(String locale) => locale == 'fr' ? nameFr : nameEn;
  String getDescription(String locale) =>
      locale == 'fr' ? descriptionFr : descriptionEn;

  /// Le prédicat d'offre unique (ADR-101 D1) : boutique, trouvaille, draft de
  /// départ, `starterPool` du tutoriel ; la vague 5 lui donnera le passif actif.
  bool get isOfferable => type != CardType.status;

  factory CardData.fromJson(Map<String, dynamic> json) {
    // L'appartenance vient du répertoire (A10) : une carte ne la déclare pas.
    for (final key in const ['heroClass', 'category']) {
      if (json.containsKey(key)) {
        throw FormatException(
          'CardData: la clé "$key" est refusée, une carte tient son '
          'appartenance de son répertoire (carte "${json['id']}")',
        );
      }
    }
    final (mana, hpCost, armorCost) = _readCosts(json);
    final nEn = json['name_en'] as String? ?? json['name'] as String? ?? '';
    final nFr = json['name_fr'] as String? ?? json['name'] as String? ?? '';
    final dEn =
        json['description_en'] as String? ??
        json['description'] as String? ??
        '';
    final dFr =
        json['description_fr'] as String? ??
        json['description'] as String? ??
        '';

    final target = CardTarget.values.firstWhere(
      (e) => e.name == json['target'],
      orElse: () => CardTarget.singleEnemy,
    );
    final effects =
        (json['effects'] as List<dynamic>?)
            ?.map((e) => CardEffect.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <CardEffect>[];
    CardEffect.checkScaleTarget(effects, target, owner: json['id'] as String);

    return CardData(
      id: json['id'] as String,
      nameEn: nEn,
      nameFr: nFr,
      descriptionEn: dEn,
      descriptionFr: dFr,
      cost: mana,
      hpCost: hpCost,
      armorCost: armorCost,
      type: CardType.values.firstWhere((e) => e.name == json['type']),
      rarity: CardRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => CardRarity.common,
      ),
      target: target,
      spritePath: json['spritePath'] as String?,
      animation: json['animation'] as String?,
      sfx: json['sfx'] as String?,
      isExhaust: json['isExhaust'] as bool? ?? false,
      effects: effects,
    );
  }

  static const _costKeys = {'mana', 'hp', 'armor'};

  /// A9 : `cost` (le mana seul) ou `costs`, jamais les deux. `costs` exige
  /// `mana` (entier >= 0) et au moins un de `hp`, `armor` (entier >= 1) ;
  /// toute autre clé est refusée, nommée — `discard` est P-44 lot 4.
  static (int, int, int) _readCosts(Map<String, dynamic> json) {
    FormatException fault(String why) =>
        FormatException('CardData "${json['id']}": $why');

    if (!json.containsKey('costs')) return (json['cost'] as int, 0, 0);
    if (json.containsKey('cost')) {
      throw fault('"cost" et "costs" ensemble sont refusés : l\'un ou l\'autre');
    }
    final costs = json['costs'];
    if (costs is! Map<String, dynamic>) {
      throw fault('"costs" doit être un objet — reçu : $costs');
    }
    for (final key in costs.keys) {
      if (!_costKeys.contains(key)) throw fault('"costs.$key" est refusée');
    }
    final mana = costs['mana'];
    if (mana is! int || mana < 0) {
      throw fault('"costs.mana" doit être un entier >= 0 — reçu : $mana');
    }
    int extra(String key) {
      final value = costs[key];
      if (value == null) return 0;
      if (value is! int || value < 1) {
        throw fault('"costs.$key" doit être un entier >= 1 — reçu : $value');
      }
      return value;
    }

    final hp = extra('hp');
    final armor = extra('armor');
    if (hp == 0 && armor == 0) {
      throw fault('"costs" sans "hp" ni "armor" : écrire "cost"');
    }
    return (mana, hp, armor);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name_en': nameEn,
        'name_fr': nameFr,
        'description_en': descriptionEn,
        'description_fr': descriptionFr,
        if (hpCost > 0 || armorCost > 0)
          'costs': {
            'mana': cost,
            if (hpCost > 0) 'hp': hpCost,
            if (armorCost > 0) 'armor': armorCost,
          }
        else
          'cost': cost,
        'type': type.name,
        'rarity': rarity.name,
        'target': target.name,
        if (spritePath != null) 'spritePath': spritePath,
        if (animation != null) 'animation': animation,
        'isExhaust': isExhaust,
        'effects': effects.map((e) => e.toJson()).toList(),
      };

  static CardData? getById(String id) {
    final registry = GameDataRegistry.instance;
    if (registry == null) return null;
    try {
      return registry.cards.firstWhere((c) => c.id == id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CardData.getById: no card found for id "$id" ($e)');
      }
      return null;
    }
  }

  /// Ordre d'affichage canonique : rareté, puis coût, puis id.
  ///
  /// Partagé par `CardDictionaryScreen`, `StarterDeckDraftScreen` et le
  /// tutoriel (`TutorialFixtures.starterPool`) pour que les trois pools
  /// s'affichent dans un ordre choisi, et non dans celui — alphabétique par
  /// `id` — que le chargeur donne au registre.
  static int compareByDisplayOrder(CardData a, CardData b) {
    final byRarity = a.rarity.index.compareTo(b.rarity.index);
    if (byRarity != 0) return byRarity;
    final byCost = a.cost.compareTo(b.cost);
    if (byCost != 0) return byCost;
    return a.id.compareTo(b.id);
  }
}
