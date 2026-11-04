import '../../services/audio/audio_source.dart';
import 'card_data.dart';
import 'card_delta.dart';
import 'effect_kind.dart';
import 'signature_evolution_data.dart';

/// Une signature de classe : une compétence à recharge, qui n'entre jamais
/// dans le deck (spec P-43 E4, §3.1).
///
/// Ce n'est pas une carte : sans rareté, sans épuisement, sans catégorie. Le
/// chargeur injecte [heroClass] depuis le dossier de la classe.
class SignatureData implements AudioSource {
  /// Les types qu'une signature peut avoir : `status` n'est pas jouable.
  static const Set<CardType> playableTypes = {
    CardType.attack,
    CardType.skill,
    CardType.power,
  };

  final String id;
  final String heroClass;
  final String nameEn;
  final String nameFr;
  final String descriptionEn;
  final String descriptionFr;
  final int cost;

  /// Le nombre de tours de recharge après usage, au moins 1 (D54).
  final int cooldown;
  final CardType type;
  final CardTarget target;
  @override
  final String? animation;
  @override
  final String? sfx;
  final List<CardEffect> effects;

  /// Le pool d'évolutions de la signature (spec §3.7).
  final List<SignatureEvolutionData> evolutions;

  const SignatureData({
    required this.id,
    required this.heroClass,
    this.nameEn = '',
    this.nameFr = '',
    this.descriptionEn = '',
    this.descriptionFr = '',
    required this.cost,
    required this.cooldown,
    required this.type,
    this.target = CardTarget.singleEnemy,
    this.animation,
    this.sfx,
    required this.effects,
    this.evolutions = const [],
  });

  static final _placeholder = RegExp(r'\{([a-z_]+)\}');
  static final _snakeCase = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');

  /// La clé `{…}` par laquelle une description désigne [effect] : son type
  /// d'effet propre ([EffectKind.plain]), ou le `statusId` d'un `apply_status`
  /// propre.
  static String? _templateKey(CardEffect effect) => effect.type == 'apply_status'
      ? effect.statusId
      : EffectKind.plain.contains(effect.type)
          ? effect.type
          : null;

  /// Remplit chaque `{clé}` de [template] de la valeur du premier effet de ce
  /// type, ou du premier `apply_status` de ce statut ; une clé sans effet
  /// reste telle quelle (le chargeur l'interdit).
  static String fillTemplate(String template, List<CardEffect> effects) =>
      template.replaceAllMapped(_placeholder, (m) {
        final key = m.group(1)!;
        final effect = effects.where((e) => _templateKey(e) == key).firstOrNull;
        return effect == null ? m.group(0)! : '${effect.value}';
      });

  String getName(String locale) => locale == 'fr' ? nameFr : nameEn;

  /// La description de la signature de base, gabarit rempli (A25).
  String getDescription(String locale) => fillTemplate(
        locale == 'fr' ? descriptionFr : descriptionEn,
        effects,
      );

  /// Ces clés appartiennent à une carte : les accepter silencieusement serait
  /// promettre un comportement que le moteur ne tient pas (spec A11).
  static const _forbiddenKeys = ['rarity', 'isExhaust', 'category'];

  factory SignatureData.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Signature: "id" absent ou vide');
    }
    FormatException fault(String key, String why) =>
        FormatException('Signature "$id": "$key" $why');

    for (final key in _forbiddenKeys) {
      if (json.containsKey(key)) {
        throw fault(key, 'est interdit sur une signature');
      }
    }

    String text(String key) {
      final value = json[key];
      if (value is! String || value.isEmpty) {
        throw fault(key, 'doit etre une chaine non vide');
      }
      return value;
    }

    int integer(String key, int min) {
      final value = json[key];
      if (value is! int || value < min) {
        throw fault(key, 'doit etre un entier >= $min');
      }
      return value;
    }

    final heroClass = text('heroClass');
    final nameEn = text('name_en');
    final nameFr = text('name_fr');
    final descriptionEn = text('description_en');
    final descriptionFr = text('description_fr');
    final cost = integer('cost', 0);
    final cooldown = integer('cooldown', 1);

    final type = SignatureData.playableTypes
        .where((t) => t.name == json['type'])
        .firstOrNull;
    if (type == null) {
      throw fault('type', 'doit etre attack, skill ou power');
    }

    final rawEffects = json['effects'];
    if (rawEffects is! List || rawEffects.isEmpty) {
      throw fault('effects', 'doit etre une liste non vide');
    }

    final target = CardTarget.values.firstWhere(
      (e) => e.name == json['target'],
      orElse: () => CardTarget.singleEnemy,
    );
    final effects = [
      for (final e in rawEffects) CardEffect.fromJson(e as Map<String, dynamic>),
    ];
    CardEffect.checkScaleTarget(effects, target, owner: id);
    final evolutions = _readEvolutions(
      json['evolutions'],
      fault: fault,
      target: target,
      effects: effects,
      descriptions: {
        'description_fr': descriptionFr,
        'description_en': descriptionEn,
      },
    );

    return SignatureData(
      id: id,
      heroClass: heroClass,
      nameEn: nameEn,
      nameFr: nameFr,
      descriptionEn: descriptionEn,
      descriptionFr: descriptionFr,
      cost: cost,
      cooldown: cooldown,
      type: type,
      target: target,
      animation: json['animation'] as String?,
      sfx: json['sfx'] as String?,
      effects: effects,
      evolutions: evolutions,
    );
  }

  /// Lit le pool et applique les règles qui le concernent en entier (spec
  /// §3.7).
  static List<SignatureEvolutionData> _readEvolutions(
    Object? raw, {
    required FormatException Function(String key, String why) fault,
    required CardTarget target,
    required List<CardEffect> effects,
    required Map<String, String> descriptions,
  }) {
    if (raw is! List || raw.isEmpty) {
      throw fault('evolutions', 'doit etre une liste non vide');
    }
    final pool = [
      for (final e in raw)
        SignatureEvolutionData.fromJson(e as Map<String, dynamic>),
    ];

    final seen = <String>{};
    for (final e in pool) {
      if (!_snakeCase.hasMatch(e.id)) {
        throw fault('evolutions', 'id "${e.id}" hors snake_case');
      }
      if (!seen.add(e.id)) {
        throw fault('evolutions', 'id "${e.id}" en double');
      }
    }
    if (!pool.any((e) => e.tier == EvolutionTier.minor)) {
      throw fault('evolutions', 'doit contenir au moins une mineure');
    }

    final majors = {
      for (final e in pool)
        if (e.tier == EvolutionTier.major) e.id,
    };
    for (final e in pool) {
      if (e.target != null && target != CardTarget.singleEnemy) {
        throw fault(
          'evolutions',
          '"${e.id}" : target n\'est admis que sur une signature singleEnemy',
        );
      }
      for (final excluded in e.excludes) {
        if (!majors.contains(excluded)) {
          throw fault(
            'evolutions',
            '"${e.id}" : excludes "$excluded" ne nomme pas une majeure du '
                'pool',
          );
        }
      }
    }

    final ownKeys = effects.map(_templateKey).nonNulls.toSet();
    for (final MapEntry(key: field, value: description) in descriptions.entries) {
      for (final m in _placeholder.allMatches(description)) {
        final key = m.group(1)!;
        if (!ownKeys.contains(key)) {
          throw fault(field, 'nomme {$key}, qui n\'est pas un effet propre');
        }
      }
      for (final e in pool) {
        for (final delta in e.deltas.whereType<FlatBonusDelta>()) {
          for (final effect in effects.where(delta.targets)) {
            final key = _templateKey(effect);
            if (key != null && !description.contains('{$key}')) {
              throw fault(
                field,
                'doit contenir {$key} : "${e.id}" augmente cet effet',
              );
            }
          }
        }
      }
    }
    return pool;
  }
}
