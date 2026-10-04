import 'relic_data.dart';

class EventData {
  final String id;
  final String titleEn;
  final String titleFr;
  final String descriptionEn;
  final String descriptionFr;
  final List<EventChoice> choices;

  EventData({
    required this.id,
    this.titleEn = '',
    this.titleFr = '',
    this.descriptionEn = '',
    this.descriptionFr = '',
    required this.choices,
  });

  String getTitle(String locale) => locale == 'fr' ? titleFr : titleEn;
  String getDescription(String locale) =>
      locale == 'fr' ? descriptionFr : descriptionEn;

  factory EventData.fromJson(Map<String, dynamic> json) {
    final tEn = json['title_en'] as String? ?? json['title'] as String? ?? '';
    final tFr = json['title_fr'] as String? ?? json['title'] as String? ?? '';
    final dEn =
        json['description_en'] as String? ??
        json['description'] as String? ??
        '';
    final dFr =
        json['description_fr'] as String? ??
        json['description'] as String? ??
        '';

    return EventData(
      id: json['id'] as String,
      titleEn: tEn,
      titleFr: tFr,
      descriptionEn: dEn,
      descriptionFr: dFr,
      choices: (json['choices'] as List)
          .map((c) => EventChoice.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EventChoice {
  final String textEn;
  final String textFr;
  final String resultTextEn;
  final String resultTextFr;
  final List<EventAction> actions;

  /// Le choix ne se prend que sous ce pourcentage des PV max — les remèdes du
  /// *Colporteur* (spec P-43 E3, §4.9, A19). `null` : aucune condition de PV.
  final int? requiresHpBelowPercent;

  EventChoice({
    this.textEn = '',
    this.textFr = '',
    this.resultTextEn = '',
    this.resultTextFr = '',
    required this.actions,
    this.requiresHpBelowPercent,
  });

  String getText(String locale) => locale == 'fr' ? textFr : textEn;
  String getResultText(String locale) =>
      locale == 'fr' ? resultTextFr : resultTextEn;

  /// Le choix peut-il être pris ? Les PV, l'or et les PV max, lus par
  /// l'appelant ; [hasTradedRelic], qu'une relique est visée par l'échange
  /// (A20), et [hasSharpenableRune], qu'une rune du deck peut encore monter
  /// — deux faits que le modèle reçoit calculés : ce fichier n'importe rien
  /// de `lib/game/` (spec P-43 E3, §4.9 ; C4.4, C4.5). Son appelant de jeu
  /// est `EventController.isChoiceSelectable`.
  bool isSelectable(
    int currentHp,
    int currentGold,
    int currentMaxHp, {
    required bool hasTradedRelic,
    required bool hasSharpenableRune,
  }) {
    final hpCap = requiresHpBelowPercent;
    if (hpCap != null && currentHp * 100 >= currentMaxHp * hpCap) {
      return false;
    }
    for (final action in actions) {
      if (action.type == 'take_damage') {
        final damage = action.value is int
            ? action.value as int
            : int.tryParse(action.value.toString()) ?? 0;
        if (currentHp <= damage) {
          return false;
        }
      } else if (action.type == 'spend_gold') {
        final cost = action.value is int
            ? action.value as int
            : int.tryParse(action.value.toString()) ?? 0;
        if (currentGold < cost) {
          return false;
        }
      } else if (action.type == 'gain_max_hp') {
        final val = action.value is int
            ? action.value as int
            : int.tryParse(action.value.toString()) ?? 0;
        if (val < 0 && currentMaxHp <= -val) {
          return false;
        }
      } else if (action.type == 'trade_relic') {
        if (!hasTradedRelic) return false;
      } else if (action.type == 'lose_hp_percent') {
        // La règle de `take_damage` : le choix ne tue pas.
        if (currentHp <= action.hpPercentOf(currentMaxHp)) return false;
      } else if (action.type == 'sharpen_rune') {
        if (!hasSharpenableRune) return false;
      }
    }
    return true;
  }

  factory EventChoice.fromJson(Map<String, dynamic> json) {
    final tEn = json['text_en'] as String? ?? json['text'] as String? ?? '';
    final tFr = json['text_fr'] as String? ?? json['text'] as String? ?? '';
    final rEn =
        json['result_text_en'] as String? ??
        json['resultText'] as String? ??
        '';
    final rFr =
        json['result_text_fr'] as String? ??
        json['resultText'] as String? ??
        '';

    return EventChoice(
      textEn: tEn,
      textFr: tFr,
      resultTextEn: rEn,
      resultTextFr: rFr,
      actions: (json['actions'] as List)
          .map((a) => EventAction.fromJson(a as Map<String, dynamic>))
          .toList(),
      requiresHpBelowPercent: _readHpPercent(json['requiresHpBelowPercent']),
    );
  }

  /// `requiresHpBelowPercent` : absent, ou un entier de 1 à 100.
  static int? _readHpPercent(Object? raw) {
    if (raw == null) return null;
    if (raw is! int || raw < 1 || raw > 100) {
      throw FormatException(
        'requiresHpBelowPercent vaut un entier de 1 à 100 — reçu : $raw',
      );
    }
    return raw;
  }
}

class EventAction {
  /// Le type d'action, que résout la table d'`EventController.selectChoice`.
  final String type;
  final dynamic value;

  EventAction({required this.type, required this.value});

  /// Le montant d'une action en pourcentage des PV max — `heal_percent`,
  /// `lose_hp_percent` —,
  /// arrondi comme le script de simulation (`.round()` ; spec P-43 E3, §4.9).
  int hpPercentOf(int maxHp) => (maxHp * (value as int) / 100).round();

  /// L'or que rapporte `trade_relic` pour une relique de [rarity] : `value`
  /// par rang, commune = 1 (D63 ; spec P-43 E3, A2).
  int tradeGoldFor(RelicRarity rarity) => (value as int) * (rarity.index + 1);

  /// Les bornes de `value` des actions d'E3 (spec P-43 E3, §3.8, §4.9) : un
  /// entier, refusé hors bornes au chargement ; `max` nul, sans borne haute.
  static const Map<String, ({int min, int? max})> _bounds = {
    'trade_relic': (min: 0, max: null),
    'heal_percent': (min: 1, max: 100),
    'lose_hp_percent': (min: 1, max: 100),
    'sharpen_rune': (min: 1, max: null),
  };

  factory EventAction.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final value = json['value'];
    final bounds = _bounds[type];
    if (bounds != null) {
      final max = bounds.max;
      if (value is! int ||
          value < bounds.min ||
          (max != null && value > max)) {
        throw FormatException(
          '$type : value vaut un entier '
          '${max == null ? "d'au moins ${bounds.min}" : 'de ${bounds.min} à $max'}'
          ' — reçu : $value',
        );
      }
    }
    return EventAction(type: type, value: value);
  }
}
