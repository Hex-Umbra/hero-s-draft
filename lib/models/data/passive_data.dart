import 'relic_data.dart';
import 'package:flutter/foundation.dart';
import 'game_data_registry.dart';

/// Ce qu'un point de Maîtrise apporte à un passif (spec P-49, §3.3).
///
/// La Maîtrise est une stat unique ; c'est le passif qui déclare le paramètre
/// qu'elle augmente, et de combien par point.
@immutable
class PassiveMastery {
  /// Les paramètres qu'un point de Maîtrise peut augmenter. Le lot B de P-41
  /// en ajoute un par paramètre qu'il crée sur [PassiveData] ; l'éditeur de
  /// contenu lit cette liste.
  static const List<String> fields = ['value'];

  /// Le paramètre augmenté, parmi [fields].
  final String field;

  /// Ce qu'un point ajoute au paramètre. Jamais nul ; négatif pour un
  /// paramètre qui baisse avec la Maîtrise, comme un seuil.
  final int perPoint;

  /// L'effet, avec `{amount}` à la place de la valeur.
  final String descriptionEn;
  final String descriptionFr;

  const PassiveMastery({
    required this.field,
    required this.perPoint,
    this.descriptionEn = '',
    this.descriptionFr = '',
  });

  /// L'effet de [points] de Maîtrise : `{amount}` y devient
  /// `|perPoint × points|`, le texte portant le sens (spec P-49, §6.5).
  String describe(String locale, int points) =>
      (locale == 'fr' ? descriptionFr : descriptionEn)
          .replaceAll('{amount}', (perPoint * points).abs().toString());

  factory PassiveMastery.fromJson(Map<String, dynamic> json) {
    final field = json['field'] as String;
    if (!fields.contains(field)) {
      throw FormatException(
        'mastery.field "$field" inconnu — attendu : ${fields.join(', ')}',
      );
    }
    final perPoint = json['perPoint'] as int;
    if (perPoint == 0) {
      throw const FormatException('mastery.perPoint ne peut pas valoir 0');
    }
    final descriptionEn = json['description_en'] as String? ?? '';
    final descriptionFr = json['description_fr'] as String? ?? '';
    for (final (key, text) in [
      ('description_en', descriptionEn),
      ('description_fr', descriptionFr),
    ]) {
      if (!text.contains('{amount}')) {
        throw FormatException('mastery.$key doit contenir {amount}');
      }
    }
    return PassiveMastery(
      field: field,
      perPoint: perPoint,
      descriptionEn: descriptionEn,
      descriptionFr: descriptionFr,
    );
  }
}

class PassiveData {
  final String id;
  final String nameEn;
  final String nameFr;
  final String descriptionEn;
  final String descriptionFr;
  final RelicTrigger trigger;
  final String effectType; // ex: 'gain_armor', 'berserker_armor', 'spell_armor'
  final int value;

  /// Les classes qui peuvent prendre ce passif ; `null` : toutes
  /// (spec P-49, §3.2). Seul le point d'accès unique la lit (spec P-49, §4).
  final List<String>? classes;

  /// Ce qu'un point de Maîtrise apporte à ce passif ; `null` : rien.
  final PassiveMastery? mastery;

  const PassiveData({
    required this.id,
    this.nameEn = '',
    this.nameFr = '',
    this.descriptionEn = '',
    this.descriptionFr = '',
    required this.trigger,
    required this.effectType,
    required this.value,
    this.classes,
    this.mastery,
  });

  String getName(String locale) => locale == 'fr' ? nameFr : nameEn;
  String getDescription(String locale) =>
      locale == 'fr' ? descriptionFr : descriptionEn;

  /// Ce passif avec [points] de Maîtrise appliqués au paramètre que désigne
  /// [mastery] (spec P-49, §6.2). Rendu tel quel sans [mastery] ou à 0 point.
  /// Borner le résultat est l'affaire de la stratégie qui le lit.
  PassiveData withMastery(int points) {
    final m = mastery;
    if (m == null || points == 0) return this;
    return switch (m.field) {
      'value' => _withValue(value + m.perPoint * points),
      // `fromJson` refuse tout autre champ ; un passif construit en code avec
      // un champ inconnu ignore sa Maîtrise plutôt que de lever en combat.
      _ => this,
    };
  }

  PassiveData _withValue(int newValue) => PassiveData(
        id: id,
        nameEn: nameEn,
        nameFr: nameFr,
        descriptionEn: descriptionEn,
        descriptionFr: descriptionFr,
        trigger: trigger,
        effectType: effectType,
        value: newValue,
        classes: classes,
        mastery: mastery,
      );

  factory PassiveData.fromJson(Map<String, dynamic> json) {
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

    final classesJson = json['classes'] as List<dynamic>?;
    if (classesJson != null && classesJson.isEmpty) {
      throw const FormatException(
        'classes ne peut pas être vide : omettre la clé ouvre le passif à '
        'toutes les classes',
      );
    }
    final masteryJson = json['mastery'] as Map<String, dynamic>?;

    return PassiveData(
      id: json['id'] as String,
      nameEn: nEn,
      nameFr: nFr,
      descriptionEn: dEn,
      descriptionFr: dFr,
      trigger: RelicTrigger.values.firstWhere((e) => e.name == json['trigger']),
      effectType: json['effectType'] as String,
      value: json['value'] as int,
      classes: classesJson?.map((e) => e as String).toList(),
      mastery:
          masteryJson == null ? null : PassiveMastery.fromJson(masteryJson),
    );
  }

  static PassiveData? getById(String id) {
    final registry = GameDataRegistry.instance;
    if (registry == null) return null;
    try {
      return registry.passives.firstWhere((p) => p.id == id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PassiveData.getById: no passive found for id "$id" ($e)');
      }
      return null;
    }
  }
}
