import 'dart:math' show min;

import 'card_data.dart';
import 'card_delta.dart';

/// Le rang d'une évolution : trois mineures par signature, qui se montent, et
/// quatre majeures, qui se prennent une fois (spec §3.7, Q6).
enum EvolutionTier { minor, major }

/// Une évolution de signature, déclarée en donnée dans le pool de sa signature
/// (spec §3.7) : ce qu'elle change, en deltas, en cible ou en recharge.
class SignatureEvolutionData {
  /// Les sortes de delta qu'un pool emploie ; toute autre est refusée.
  static const deltaTypeNames = [
    'flatBonus',
    'addEffect',
    'reduceCost',
    'critBonus',
  ];

  /// Les cibles qu'une évolution majeure peut imposer.
  static const targetNames = ['allEnemies'];

  final String id;
  final EvolutionTier tier;
  final String nameEn;
  final String nameFr;
  final String descriptionEn;
  final String descriptionFr;
  final List<CardDelta> deltas;

  /// La cible imposée, `null` si l'évolution n'en change pas.
  final CardTarget? target;

  /// Le changement de recharge, `0` si l'évolution n'en change pas.
  final int cooldown;

  /// Les ids de majeures du même pool qui lui sont incompatibles.
  final List<String> excludes;
  final String icon;
  final String color;

  const SignatureEvolutionData({
    required this.id,
    required this.tier,
    this.nameEn = '',
    this.nameFr = '',
    this.descriptionEn = '',
    this.descriptionFr = '',
    this.deltas = const [],
    this.target,
    this.cooldown = 0,
    this.excludes = const [],
    this.icon = '',
    this.color = '',
  });

  /// Vrai si l'évolution change ce que la signature fait plutôt que de lui
  /// ajouter un nombre (A25).
  bool get isVerbal =>
      target != null ||
      deltas.any((d) => d is AddEffectDelta || d is CritBonusDelta);

  /// Q7 : l'exclusion se lit dans les deux sens.
  bool excludesOrIsExcludedBy(SignatureEvolutionData other) =>
      excludes.contains(other.id) || other.excludes.contains(id);

  String getName(String locale) => locale == 'fr' ? nameFr : nameEn;

  /// La description, `{val}` remplacé par ce que le premier delta porteur d'un
  /// nombre ajoute au niveau [level] ; [cost] est le coût de la signature, que
  /// borne une baisse de coût.
  String getDescription(int level, String locale, {required int cost}) {
    final template = locale == 'fr' ? descriptionFr : descriptionEn;
    return template.replaceAll('{val}', '${_valueAdded(level, cost)}');
  }

  int _valueAdded(int level, int cost) {
    if (deltas.isEmpty) return 0;
    return switch (deltas.first) {
      FlatBonusDelta(:final valuePerLevel) ||
      AddEffectDelta(:final valuePerLevel) ||
      CritBonusDelta(:final valuePerLevel) =>
        valuePerLevel * level,
      ReduceCostDelta(:final valuePerLevel) => min(cost, valuePerLevel * level),
      _ => 0,
    };
  }

  factory SignatureEvolutionData.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Evolution: "id" absent ou vide');
    }
    FormatException fault(String key, String why) =>
        FormatException('Evolution "$id": "$key" $why');

    String text(String key) {
      final value = json[key];
      if (value is! String || value.isEmpty) {
        throw fault(key, 'doit etre une chaine non vide');
      }
      return value;
    }

    final tier =
        EvolutionTier.values.where((t) => t.name == json['tier']).firstOrNull;
    if (tier == null) throw fault('tier', 'doit etre minor ou major');
    final isMajor = tier == EvolutionTier.major;

    final nameFr = text('name_fr');
    final nameEn = text('name_en');
    final descriptionFr = text('description_fr');
    final descriptionEn = text('description_en');

    final rawDeltas = json['deltas'] ?? const [];
    if (rawDeltas is! List) throw fault('deltas', 'doit etre une liste');
    final deltas = <CardDelta>[];
    for (final raw in rawDeltas) {
      final type = raw is Map<String, dynamic> ? raw['type'] : null;
      if (!deltaTypeNames.contains(type)) {
        throw fault(
          'deltas',
          'ne peut pas porter la sorte "$type" — attendu : '
              '${deltaTypeNames.join(', ')}',
        );
      }
      try {
        deltas.add(CardDelta.fromJson(raw as Map<String, dynamic>));
      } on FormatException catch (e) {
        throw fault('deltas', 'invalide : ${e.message}');
      }
    }

    for (final key in const ['target', 'cooldown', 'excludes']) {
      if (!isMajor && json.containsKey(key)) {
        throw fault(key, 'est reserve aux majeures');
      }
    }

    CardTarget? target;
    if (json.containsKey('target')) {
      final rawTarget = json['target'];
      if (!targetNames.contains(rawTarget)) {
        throw fault('target', 'doit etre ${targetNames.join(', ')}');
      }
      target = CardTarget.values.byName(rawTarget as String);
    }

    var cooldown = 0;
    if (json.containsKey('cooldown')) {
      final rawCooldown = json['cooldown'];
      if (rawCooldown is! int || rawCooldown == 0) {
        throw fault('cooldown', 'doit etre un entier non nul');
      }
      cooldown = rawCooldown;
    }

    var excludes = const <String>[];
    if (json.containsKey('excludes')) {
      final rawExcludes = json['excludes'];
      if (rawExcludes is! List ||
          rawExcludes.isEmpty ||
          rawExcludes.any((e) => e is! String || e.isEmpty)) {
        throw fault('excludes', 'doit etre une liste non vide de textes');
      }
      excludes = rawExcludes.cast<String>();
      if (excludes.contains(id)) {
        throw fault('excludes', 'ne peut pas nommer l\'evolution elle-meme');
      }
    }

    if (deltas.isEmpty && target == null && cooldown == 0) {
      throw fault('deltas', 'ou target ou cooldown : au moins un changement');
    }

    final icon = text('icon');
    final color = text('color');

    final evolution = SignatureEvolutionData(
      id: id,
      tier: tier,
      nameEn: nameEn,
      nameFr: nameFr,
      descriptionEn: descriptionEn,
      descriptionFr: descriptionFr,
      deltas: deltas,
      target: target,
      cooldown: cooldown,
      excludes: excludes,
      icon: icon,
      color: color,
    );
    final numeric = cooldown != 0 ||
        deltas.any((d) => d is FlatBonusDelta || d is ReduceCostDelta);
    if (evolution.isVerbal && numeric) {
      throw fault(
        'deltas',
        'est a la fois chiffree et verbale : addEffect, critBonus et target '
            'ne se melangent pas a flatBonus, reduceCost ni cooldown',
      );
    }
    return evolution;
  }
}
