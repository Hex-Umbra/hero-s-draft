import 'package:meta/meta.dart';

/// La demie vers le haut, en arithmétique entière : [value] × [percent] / 100
/// (spec P-53, A15 — la forme d'ADR-105 D6). Une seule définition, pour tous
/// les lecteurs de la règle.
int halfUp(int value, int percent) => (value * percent + 50) ~/ 100;

/// La sorte d'une rupture : ce qui arrive au porteur quand sa charge rompt.
/// Le nom de la valeur est la valeur JSON.
enum RuptureKind {
  /// Le porteur perd toute sa prochaine action.
  skipAction,

  /// Pendant le prochain tour du porteur, ses coups infligent moins.
  weakenDealt,

  /// Toute la charge se résout et explose sur les voisins.
  explode,

  /// Chaque coup reçu fait plus, davantage une fois la charge rompue.
  amplifyHits,
}

/// Le moment de la rupture : à l'atteinte du seuil, ou au tour du porteur.
enum ChargeBreaksOn { threshold, bearerTurn }

/// Qui porte une charge : un ennemi (élites comprises), un boss ou le héros.
/// Le seuil de départ et la rupture en dépendent.
enum ChargeBearer { enemy, boss, hero }

/// Une rupture : sa sorte et ses paramètres entiers. Immuable, comparable par
/// valeur.
@immutable
class ChargeRupture {
  final RuptureKind kind;
  final Map<String, int> params;

  ChargeRupture({required this.kind, required Map<String, int> params})
      : params = Map.unmodifiable(params);

  /// Les paramètres que chaque sorte déclare, ni plus ni moins.
  static const Map<RuptureKind, Set<String>> paramsOf = {
    RuptureKind.skipAction: <String>{},
    RuptureKind.weakenDealt: {'percent'},
    RuptureKind.explode: {
      'damagePerPoint',
      'explosionDamage',
      'chargePerNeighbour',
    },
    RuptureKind.amplifyHits: {'bonusPerPoint'},
  };

  int get percent => params['percent']!;
  int get damagePerPoint => params['damagePerPoint']!;
  int get explosionDamage => params['explosionDamage']!;
  int get chargePerNeighbour => params['chargePerNeighbour']!;
  int get bonusPerPoint => params['bonusPerPoint']!;

  /// Vrai quand la rupture installe un état qui dure ; faux pour `explode`,
  /// qui se résout d'un coup.
  bool get lasts => kind != RuptureKind.explode;

  /// Le moment que la sorte exige de `breaksOn`.
  ChargeBreaksOn get moment => kind == RuptureKind.explode
      ? ChargeBreaksOn.bearerTurn
      : ChargeBreaksOn.threshold;

  /// La valeur par point que `belowThresholdPercent` module ; `null` pour une
  /// sorte qui n'en a pas.
  int? get _perPoint => switch (kind) {
        RuptureKind.explode => damagePerPoint,
        RuptureKind.amplifyHits => bonusPerPoint,
        _ => null,
      };

  Map<String, dynamic> toJson() => {'kind': kind.name, ...params};

  @override
  bool operator ==(Object other) =>
      other is ChargeRupture &&
      other.kind == kind &&
      other.params.length == params.length &&
      params.entries.every((e) => other.params[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
        kind,
        Object.hashAllUnordered(
          params.entries.map((e) => Object.hash(e.key, e.value)),
        ),
      );
}

/// Une charge élémentaire, telle que son fichier `assets/data/charges/<id>.json`
/// la déclare (spec P-53, §3.1) : des points qui s'accumulent jusqu'à un
/// seuil où ils rompent. `fromJson` valide tout (A3), au chargement.
@immutable
class ChargeData {
  final String id;
  final String nameFr;
  final String nameEn;

  /// Le nom de l'état rompu ; exigé pour une rupture qui dure, refusé sinon.
  final String? brokenNameFr;
  final String? brokenNameEn;

  /// La règle pour un ennemi porteur, à jetons (§6.1).
  final String descriptionFr;
  final String descriptionEn;

  /// La règle sur le héros ; exigée si et seulement si [heroRupture] existe.
  final String? heroDescriptionFr;
  final String? heroDescriptionEn;

  final int threshold;
  final int? bossThreshold;
  final int? heroThreshold;
  final int thresholdGrowth;
  final bool overcharge;
  final int decay;
  final ChargeBreaksOn breaksOn;
  final int? belowThresholdPercent;
  final ChargeRupture rupture;
  final ChargeRupture? heroRupture;

  const ChargeData._({
    required this.id,
    required this.nameFr,
    required this.nameEn,
    required this.brokenNameFr,
    required this.brokenNameEn,
    required this.descriptionFr,
    required this.descriptionEn,
    required this.heroDescriptionFr,
    required this.heroDescriptionEn,
    required this.threshold,
    required this.bossThreshold,
    required this.heroThreshold,
    required this.thresholdGrowth,
    required this.overcharge,
    required this.decay,
    required this.breaksOn,
    required this.belowThresholdPercent,
    required this.rupture,
    required this.heroRupture,
  });

  static const Set<String> _allowedKeys = {
    'id',
    'name_fr',
    'name_en',
    'brokenName_fr',
    'brokenName_en',
    'description_fr',
    'description_en',
    'heroDescription_fr',
    'heroDescription_en',
    'threshold',
    'bossThreshold',
    'heroThreshold',
    'thresholdGrowth',
    'overcharge',
    'decay',
    'breaksOn',
    'belowThresholdPercent',
    'rupture',
    'heroRupture',
  };

  /// Le seuil de départ du [bearer] ; absent du fichier : [threshold].
  int startThreshold(ChargeBearer bearer) => switch (bearer) {
        ChargeBearer.enemy => threshold,
        ChargeBearer.boss => bossThreshold ?? threshold,
        ChargeBearer.hero => heroThreshold ?? threshold,
      };

  /// La rupture qui vaut pour le [bearer] : celle du héros, si le fichier la
  /// déclare, sinon la commune.
  ChargeRupture ruptureFor(ChargeBearer bearer) =>
      bearer == ChargeBearer.hero ? heroRupture ?? rupture : rupture;

  /// La valeur par point sous le seuil (`belowThresholdPercent` de la valeur
  /// par point de la rupture, la demie vers le haut) ; `null` sans
  /// `belowThresholdPercent`.
  int? get belowValue {
    final percent = belowThresholdPercent;
    if (percent == null) return null;
    final perPoint = rupture._perPoint ?? heroRupture?._perPoint;
    return perPoint == null ? null : halfUp(perPoint, percent);
  }

  String name(String locale) => locale == 'fr' ? nameFr : nameEn;

  String? brokenName(String locale) =>
      locale == 'fr' ? brokenNameFr : brokenNameEn;

  /// La règle d'un ennemi porteur, jetons remplis.
  String describe(String locale) => _fill(
        locale == 'fr' ? descriptionFr : descriptionEn,
        _tokens(locale, rupture),
      );

  Map<String, String> _tokens(String locale, ChargeRupture forRupture) => {
        'name': name(locale),
        'threshold': '$threshold',
        'bossThreshold': '${startThreshold(ChargeBearer.boss)}',
        'heroThreshold': '${startThreshold(ChargeBearer.hero)}',
        'growth': '$thresholdGrowth',
        'decay': '$decay',
        for (final entry in forRupture.params.entries)
          entry.key: '${entry.value}',
        if (belowValue != null) 'belowValue': '$belowValue',
      };

  static final RegExp _token = RegExp(r'\{(\w+)\}');

  static String _fill(String template, Map<String, String> tokens) =>
      template.replaceAllMapped(_token, (m) => tokens[m[1]!] ?? m[0]!);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name_fr': nameFr,
        'name_en': nameEn,
        if (brokenNameFr != null) 'brokenName_fr': brokenNameFr,
        if (brokenNameEn != null) 'brokenName_en': brokenNameEn,
        'description_fr': descriptionFr,
        'description_en': descriptionEn,
        if (heroDescriptionFr != null) 'heroDescription_fr': heroDescriptionFr,
        if (heroDescriptionEn != null) 'heroDescription_en': heroDescriptionEn,
        'threshold': threshold,
        if (bossThreshold != null) 'bossThreshold': bossThreshold,
        if (heroThreshold != null) 'heroThreshold': heroThreshold,
        'thresholdGrowth': thresholdGrowth,
        'overcharge': overcharge,
        'decay': decay,
        'breaksOn': breaksOn.name,
        if (belowThresholdPercent != null)
          'belowThresholdPercent': belowThresholdPercent,
        'rupture': rupture.toJson(),
        if (heroRupture != null) 'heroRupture': heroRupture!.toJson(),
      };

  // ----- Lecture et validation (spec A3) -----

  static FormatException _refuse(String id, String key, String rule) =>
      FormatException('$id : "$key" $rule');

  static String _text(Map<String, dynamic> json, String key, String id) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw _refuse(id, key, 'est obligatoire (texte non vide)');
    }
    return value;
  }

  /// Un couple de textes facultatif : les deux langues, ou aucune.
  static (String?, String?) _optionalPair(
    Map<String, dynamic> json,
    String base,
    String id,
  ) {
    final fr = json['${base}_fr'];
    final en = json['${base}_en'];
    for (final (key, value) in [('${base}_fr', fr), ('${base}_en', en)]) {
      if (value != null && (value is! String || value.isEmpty)) {
        throw _refuse(id, key, 'doit être un texte non vide');
      }
    }
    if ((fr == null) != (en == null)) {
      throw _refuse(id, base, 'doit porter ses deux langues — ${base}_fr et ${base}_en');
    }
    return (fr as String?, en as String?);
  }

  static int _int(
    Map<String, dynamic> json,
    String key,
    String id, {
    required int min,
    int? max,
  }) {
    final value = json[key];
    if (value is! int) {
      throw _refuse(id, key, 'doit être un entier — reçu : $value');
    }
    if (value < min || (max != null && value > max)) {
      final range = max == null ? '≥ $min' : 'entre $min et $max';
      throw _refuse(id, key, 'doit être $range — reçu : $value');
    }
    return value;
  }

  static int? _optionalInt(
    Map<String, dynamic> json,
    String key,
    String id, {
    required int min,
    int? max,
  }) =>
      json[key] == null ? null : _int(json, key, id, min: min, max: max);

  static ChargeRupture? _readRupture(
    Map<String, dynamic> json,
    String key,
    String id, {
    required bool required,
  }) {
    final raw = json[key];
    if (raw == null) {
      if (required) throw _refuse(id, key, 'est obligatoire');
      return null;
    }
    if (raw is! Map) {
      throw _refuse(id, key, 'doit être un objet à "kind" — reçu : $raw');
    }
    final kindName = raw['kind'];
    final kind = RuptureKind.values.where((k) => k.name == kindName).firstOrNull;
    if (kind == null) {
      throw _refuse(
        id,
        '$key.kind',
        'inconnu : "$kindName" — attendu : '
            '${RuptureKind.values.map((k) => k.name).join(', ')}',
      );
    }
    final expected = ChargeRupture.paramsOf[kind]!;
    for (final param in raw.keys) {
      if (param != 'kind' && !expected.contains(param)) {
        throw _refuse(
          id,
          '$key.$param',
          'n\'est pas un paramètre de ${kind.name}'
              '${expected.isEmpty ? ' (aucun paramètre)' : ' (${expected.join(', ')})'}',
        );
      }
    }
    final params = <String, int>{};
    for (final param in expected) {
      if (!raw.containsKey(param)) {
        throw _refuse(id, '$key.$param', 'est obligatoire pour ${kind.name}');
      }
      // `percent` 1 à 100 ; `bonusPerPoint` ≥ 1 ; les trois de `explode` ≥ 0.
      final (min, max) = switch (param) {
        'percent' => (1, 100),
        'bonusPerPoint' => (1, null),
        _ => (0, null),
      };
      params[param] = _int(
        raw.cast<String, dynamic>(),
        param,
        '$id : $key',
        min: min,
        max: max,
      );
    }
    return ChargeRupture(kind: kind, params: params);
  }

  factory ChargeData.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    if (rawId is! String || rawId.isEmpty) {
      throw const FormatException('charge : "id" est obligatoire');
    }
    final id = rawId;

    for (final key in json.keys) {
      if (!_allowedKeys.contains(key)) {
        throw _refuse(id, key, 'n\'est pas une clé d\'une charge');
      }
    }

    final nameFr = _text(json, 'name_fr', id);
    final nameEn = _text(json, 'name_en', id);
    final descriptionFr = _text(json, 'description_fr', id);
    final descriptionEn = _text(json, 'description_en', id);

    final threshold = _int(json, 'threshold', id, min: 1);
    final bossThreshold = _optionalInt(json, 'bossThreshold', id, min: 1);
    final heroThreshold = _optionalInt(json, 'heroThreshold', id, min: 1);
    final growth = _int(json, 'thresholdGrowth', id, min: 0);
    final decay = _int(json, 'decay', id, min: 0);
    final overcharge = json['overcharge'];
    if (overcharge is! bool) {
      throw _refuse(id, 'overcharge', 'doit être un booléen — reçu : $overcharge');
    }
    final breaksOnName = json['breaksOn'];
    final breaksOn =
        ChargeBreaksOn.values.where((b) => b.name == breaksOnName).firstOrNull;
    if (breaksOn == null) {
      throw _refuse(
        id,
        'breaksOn',
        'inconnu : "$breaksOnName" — attendu : '
            '${ChargeBreaksOn.values.map((b) => b.name).join(', ')}',
      );
    }

    final rupture = _readRupture(json, 'rupture', id, required: true)!;
    final heroRupture = _readRupture(json, 'heroRupture', id, required: false);
    final ruptures = {
      'rupture': rupture,
      'heroRupture': ?heroRupture,
    };

    final (brokenFr, brokenEn) = _optionalPair(json, 'brokenName', id);
    final lasts = ruptures.values.any((r) => r.lasts);
    if (lasts && brokenFr == null) {
      throw _refuse(id, 'brokenName', 'est exigé pour une rupture qui dure');
    }
    if (!lasts && brokenFr != null) {
      throw _refuse(id, 'brokenName', 'est refusé : explode ne laisse aucun état');
    }

    final (heroFr, heroEn) = _optionalPair(json, 'heroDescription', id);
    if (heroRupture != null && heroFr == null) {
      throw _refuse(id, 'heroDescription', 'est exigée avec heroRupture');
    }
    if (heroRupture == null && heroFr != null) {
      throw _refuse(id, 'heroDescription', 'est refusée sans heroRupture');
    }

    for (final MapEntry(key: key, value: r) in ruptures.entries) {
      if (r.moment != breaksOn) {
        throw _refuse(
          id,
          'breaksOn',
          'doit valoir ${r.moment.name} pour $key ${r.kind.name} — '
              'reçu : ${breaksOn.name}',
        );
      }
    }

    final below = _optionalInt(json, 'belowThresholdPercent', id, min: 0, max: 100);
    final needsBelow = ruptures.values.any((r) => r._perPoint != null);
    if (needsBelow && below == null) {
      throw _refuse(id, 'belowThresholdPercent', 'est exigé pour explode et amplifyHits');
    }
    if (!needsBelow && below != null) {
      throw _refuse(id, 'belowThresholdPercent', 'est refusé : aucune rupture n\'en a l\'usage');
    }

    // Chaque explosion consomme une tranche et pose au plus deux fois
    // `chargePerNeighbour` : la chaîne ne s'arrête qu'à ce prix (spec §4.7).
    for (final r in ruptures.values.where((r) => r.kind == RuptureKind.explode)) {
      final floor = 2 * r.chargePerNeighbour;
      for (final (key, start) in [
        ('threshold', threshold),
        ('bossThreshold', bossThreshold ?? threshold),
        ('heroThreshold', heroThreshold ?? threshold),
      ]) {
        if (start <= floor) {
          throw _refuse(
            id,
            key,
            'doit dépasser 2 × chargePerNeighbour ($floor) pour explode — reçu : $start',
          );
        }
      }
    }

    if ((heroRupture ?? rupture).kind == RuptureKind.skipAction) {
      throw _refuse(
        id,
        heroRupture == null ? 'rupture' : 'heroRupture',
        'skipAction ne vaut pas pour le héros : déclarer une heroRupture',
      );
    }

    final charge = ChargeData._(
      id: id,
      nameFr: nameFr,
      nameEn: nameEn,
      brokenNameFr: brokenFr,
      brokenNameEn: brokenEn,
      descriptionFr: descriptionFr,
      descriptionEn: descriptionEn,
      heroDescriptionFr: heroFr,
      heroDescriptionEn: heroEn,
      threshold: threshold,
      bossThreshold: bossThreshold,
      heroThreshold: heroThreshold,
      thresholdGrowth: growth,
      overcharge: overcharge,
      decay: decay,
      breaksOn: breaksOn,
      belowThresholdPercent: below,
      rupture: rupture,
      heroRupture: heroRupture,
    );
    charge._checkTokens();
    return charge;
  }

  /// Refuse un jeton qui n'est pas de la liste de §6.1 : ceux d'une charge,
  /// ceux de la rupture du texte, et `belowValue` quand il existe.
  void _checkTokens() {
    final texts = {
      'description_fr': (descriptionFr, 'fr', rupture),
      'description_en': (descriptionEn, 'en', rupture),
      if (heroRupture != null) ...{
        'heroDescription_fr': (heroDescriptionFr!, 'fr', heroRupture!),
        'heroDescription_en': (heroDescriptionEn!, 'en', heroRupture!),
      },
    };
    for (final MapEntry(key: key, value: (text, locale, forRupture))
        in texts.entries) {
      final known = _tokens(locale, forRupture).keys.toSet();
      for (final match in _token.allMatches(text)) {
        if (!known.contains(match[1])) {
          throw _refuse(
            id,
            key,
            'porte un jeton inconnu : {${match[1]}} — admis : '
                '${(known.toList()..sort()).map((t) => '{$t}').join(', ')}',
          );
        }
      }
    }
  }
}

/// Le catalogue des charges du registre, par id. Vide par défaut, comme
/// `EffectIconTable` : un registre construit à la main ne porte aucune
/// charge, et rien ne se pose alors (spec P-53, A4).
class ChargeCatalog {
  final Map<String, ChargeData> _byId;

  const ChargeCatalog.empty() : _byId = const {};

  ChargeCatalog._(this._byId);

  factory ChargeCatalog.of(List<ChargeData> charges) =>
      ChargeCatalog._({for (final c in charges) c.id: c});

  ChargeData? operator [](String id) => _byId[id];

  bool isCharge(String id) => _byId.containsKey(id);

  Set<String> get ids => _byId.keys.toSet();

  Iterable<ChargeData> get all => _byId.values;

  bool get isEmpty => _byId.isEmpty;
}
