import 'relic_data.dart';
import 'package:flutter/foundation.dart';
import 'game_data_registry.dart';

/// Ce qu'un point de Maîtrise apporte à un passif (spec P-49, §3.3).
///
/// La Maîtrise est une stat unique ; c'est le passif qui déclare le paramètre
/// qu'elle augmente, et de combien par point.
@immutable
class PassiveMastery {
  /// Les paramètres qu'un point de Maîtrise peut augmenter ; l'éditeur de
  /// contenu lit cette liste.
  ///
  /// `draw` n'en est pas : aucun des neuf passifs ne fait piocher une carte de
  /// plus par point de Maîtrise, et un champ que rien ne vise serait du code
  /// mort dans `withMastery`.
  static const List<String> fields = ['value', 'duration', 'threshold'];

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
  final String effectType; // ex: 'gain_armor', 'rage', 'channeling'

  /// Le chiffre principal du passif : ce que sa stratégie en fait lui
  /// appartient — des points d'armure, de Puissance, de mana, de PV.
  final int value;

  /// La durée, en tours, du statut que le passif pose. Sans objet pour un
  /// passif qui n'en pose pas.
  final int duration;

  /// Le nombre d'occurrences à réunir avant que le passif agisse — le seuil de
  /// *Flux de Mana*. 0 : aucun seuil, le passif agit à chaque déclenchement.
  final int threshold;

  /// Les cartes que le passif fait piocher — *Frénésie*.
  final int draw;

  /// Rang d'affichage parmi les passifs d'une classe. Donnée de présentation,
  /// comme `HeroData.displayOrder` : l'ordre ne doit pas dépendre de l'ordre du
  /// catalogue ni de l'alphabet. Le lot C en fera trois choix rangés ; d'ici
  /// là, le premier est le passif que la classe obtient.
  final int displayOrder;

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
    this.duration = 1,
    this.threshold = 0,
    this.draw = 0,
    this.displayOrder = 0,
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
    final delta = m.perPoint * points;
    return switch (m.field) {
      'value' => _copyWith(value: value + delta),
      'duration' => _copyWith(duration: duration + delta),
      'threshold' => _copyWith(threshold: threshold + delta),
      // `fromJson` refuse tout autre champ ; un passif construit en code avec
      // un champ inconnu ignore sa Maîtrise plutôt que de lever en combat.
      _ => this,
    };
  }

  PassiveData _copyWith({int? value, int? duration, int? threshold}) =>
      PassiveData(
        id: id,
        nameEn: nameEn,
        nameFr: nameFr,
        descriptionEn: descriptionEn,
        descriptionFr: descriptionFr,
        trigger: trigger,
        effectType: effectType,
        value: value ?? this.value,
        duration: duration ?? this.duration,
        threshold: threshold ?? this.threshold,
        draw: draw,
        displayOrder: displayOrder,
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
      duration: json['duration'] as int? ?? 1,
      threshold: json['threshold'] as int? ?? 0,
      draw: json['draw'] as int? ?? 0,
      displayOrder: json['displayOrder'] as int? ?? 0,
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
