import 'dart:math' show max;

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

  /// La valeur sous laquelle la Maîtrise ne fait pas descendre le paramètre
  /// — le seuil de *Flux de Mana*, jamais sous 2 (D43, D60 ; spec P-43 E3,
  /// A23). `null` : aucun plancher. N'a de sens que sur un [perPoint]
  /// négatif ; `PassiveData.withMastery` l'applique.
  final int? floor;

  /// L'effet, avec `{amount}` à la place de la valeur — que
  /// `PassiveData.describeMastery` remplit.
  final String descriptionEn;
  final String descriptionFr;

  const PassiveMastery({
    required this.field,
    required this.perPoint,
    this.floor,
    this.descriptionEn = '',
    this.descriptionFr = '',
  });

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
    final floor = json['floor'];
    if (floor != null && (floor is! int || perPoint >= 0)) {
      throw FormatException(
        'mastery.floor vaut un entier, sur un perPoint négatif — reçu : floor '
        '$floor, perPoint $perPoint',
      );
    }
    return PassiveMastery(
      field: field,
      perPoint: perPoint,
      floor: floor as int?,
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

  /// Un seuil, que lit la stratégie du passif (spec P-43 E3, A24) : les
  /// Compétences à réunir avant que *Flux de Mana* agisse — 0 : à chaque
  /// déclenchement — ; l'armure survivante d'une tranche de *Bénédiction* —
  /// sous 1, aucune tranche.
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
  /// [mastery] (spec P-49, §6.2), jamais sous son plancher s'il en déclare un
  /// (spec P-43 E3, A23). Rendu tel quel sans [mastery] ou à 0 point.
  PassiveData withMastery(int points) {
    final m = mastery;
    if (m == null || points == 0) return this;
    int mastered(int base) {
      final raised = base + m.perPoint * points;
      final floor = m.floor;
      return floor == null ? raised : max(floor, raised);
    }

    return switch (m.field) {
      'value' => _copyWith(value: mastered(value)),
      'duration' => _copyWith(duration: mastered(duration)),
      'threshold' => _copyWith(threshold: mastered(threshold)),
      // `fromJson` refuse tout autre champ ; un passif construit en code avec
      // un champ inconnu ignore sa Maîtrise plutôt que de lever en combat.
      _ => this,
    };
  }

  /// L'effet de la Maîtrise qui passe de [from] à [to] points, dans le texte
  /// du bloc `mastery` (spec P-43 E3, §4.11, A23) : `{amount}` y devient
  /// l'écart du paramètre visé entre ces deux nombres de points, plancher
  /// compris — ce que le joueur gagne vraiment, le texte portant le sens.
  /// `null` sans bloc `mastery`, ou quand l'écart est nul : rien ne change.
  String? describeMastery(String locale, {required int from, required int to}) {
    final m = mastery;
    if (m == null) return null;
    final amount = (_parameterOf(withMastery(to), m.field) -
            _parameterOf(withMastery(from), m.field))
        .abs();
    if (amount == 0) return null;
    return (locale == 'fr' ? m.descriptionFr : m.descriptionEn)
        .replaceAll('{amount}', '$amount');
  }

  /// Le paramètre [field] de [passive], parmi ceux qu'une Maîtrise peut viser.
  static int _parameterOf(PassiveData passive, String field) =>
      switch (field) {
        'value' => passive.value,
        'duration' => passive.duration,
        'threshold' => passive.threshold,
        _ => 0,
      };

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

    final passive = PassiveData(
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
    // Un plancher au-dessus de la valeur de base mordrait sans Maîtrise
    // (spec P-43 E3, A23).
    final mastery = passive.mastery;
    final floor = mastery?.floor;
    if (mastery != null &&
        floor != null &&
        floor > _parameterOf(passive, mastery.field)) {
      throw FormatException(
        'mastery.floor ($floor) dépasse la valeur de base de '
        '${mastery.field} (${_parameterOf(passive, mastery.field)})',
      );
    }
    return passive;
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
