import 'package:flutter/foundation.dart';
import 'card_data.dart';
import 'card_delta.dart';
import 'game_data_registry.dart';
import '../effective_card.dart';
import '../missing_save_item.dart';

class ForgeUpgradeData {
  final String id;
  final String nameEn;
  final String nameFr;
  final String descriptionEn;
  final String descriptionFr;
  final String icon;
  final String color;
  final List<String> pools;
  final List<String>? eligibleCardTypes;
  final bool requiresExhaust;

  /// Une rune cumulable additionne ses tiers : deux `sharp:1` valent un
  /// `sharp:2`. Une rune non cumulable est binaire — `enduring` retire
  /// l'épuisement ou non — et n'a qu'un tier, 1 (voir `ForgeRuneRules`).
  final bool stackable;

  /// Le niveau le plus haut que la rune atteint sur une carte, exemplaires
  /// additionnés ; `null` : sans plafond (D27, spec P-43 E1, A8). La clé est
  /// obligatoire dans le fichier, `null` compris ; le constructeur laisse aux
  /// tests une rune sans plafond.
  final int? maxLevel;

  /// Ce que fait la rune : des sortes de delta, déclarées par niveau (spec
  /// P-43 E1, A1, §4.1). Obligatoire et non vide dans le fichier ; le
  /// constructeur en laisse aux tests une liste vide, qui ne fait rien.
  final List<CardDelta> deltas;
  final int weight;
  final String emoji;

  const ForgeUpgradeData({
    required this.id,
    required this.nameEn,
    required this.nameFr,
    required this.descriptionEn,
    required this.descriptionFr,
    required this.icon,
    required this.color,
    required this.pools,
    this.eligibleCardTypes,
    this.requiresExhaust = false,
    this.stackable = true,
    this.maxLevel,
    this.deltas = const [],
    this.weight = 10,
    this.emoji = '🔮',
  });

  factory ForgeUpgradeData.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return ForgeUpgradeData(
      id: id,
      nameEn: json['name_en'] as String? ?? '',
      nameFr: json['name_fr'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? '',
      descriptionFr: json['description_fr'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      color: json['color'] as String? ?? '',
      pools: List<String>.from(json['pools'] as List? ?? []),
      eligibleCardTypes: json['eligibleCardTypes'] != null
          ? List<String>.from(json['eligibleCardTypes'] as List)
          : null,
      requiresExhaust: json['requiresExhaust'] as bool? ?? false,
      stackable: json['stackable'] as bool? ?? true,
      maxLevel: _readMaxLevel(id, json),
      deltas: _readDeltas(id, json['deltas']),
      weight: json['weight'] as int? ?? 10,
      emoji: json['emoji'] as String? ?? '🔮',
    );
  }

  /// La clé est obligatoire (D27) : `null` pour « sans plafond », sinon un
  /// entier d'au moins 1 — une sentinelle dirait « aucun » par un nombre
  /// (spec P-43 E1, A8).
  static int? _readMaxLevel(String id, Map<String, dynamic> json) {
    if (!json.containsKey('maxLevel')) {
      throw FormatException(
        '$id : maxLevel est obligatoire — null pour « sans plafond »',
      );
    }
    final value = json['maxLevel'];
    if (value == null) return null;
    if (value is! int || value < 1) {
      throw FormatException(
        '$id : maxLevel vaut null ou un entier d\'au moins 1 — reçu : $value',
      );
    }
    return value;
  }

  static List<CardDelta> _readDeltas(String id, Object? raw) {
    if (raw is! List || raw.isEmpty) {
      throw FormatException(
        '$id : deltas doit être une liste non vide — reçu : $raw',
      );
    }
    return [
      for (final entry in raw)
        if (entry is Map<String, dynamic>)
          CardDelta.fromJson(entry)
        else
          throw FormatException('$id : deltas porte "$entry", pas un objet'),
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_fr': nameFr,
      'description_en': descriptionEn,
      'description_fr': descriptionFr,
      'icon': icon,
      'color': color,
      'pools': pools,
      if (eligibleCardTypes != null) 'eligibleCardTypes': eligibleCardTypes,
      'requiresExhaust': requiresExhaust,
      'stackable': stackable,
      'maxLevel': maxLevel,
      'deltas': [for (final delta in deltas) delta.toJson()],
      'weight': weight,
      'emoji': emoji,
    };
  }

  String getName(String locale) {
    return locale == 'fr' ? nameFr : nameEn;
  }

  /// La description de la rune au niveau [level], sur [card] à [rarity] (spec
  /// P-43 E1, §5.1) : `{tier}` est le niveau ; `{percent}`, le pourcentage de
  /// ce niveau ; `{val}`, ce que la rune ajoute à **cette** carte au-delà des
  /// [carried] niveaux qu'elle en porte déjà — le gain que joue le moteur,
  /// calculé par l'applicateur sur le premier effet propre du type visé, 0 si
  /// la carte n'en a pas.
  String getDescription(
    int level,
    String locale,
    CardData card,
    CardRarity rarity, {
    int carried = 0,
  }) {
    final template = locale == 'fr' ? descriptionFr : descriptionEn;
    final bonus = deltas.whereType<PercentBonusDelta>().firstOrNull;
    return template
        .replaceAll('{tier}', '$level')
        .replaceAll('{percent}', '${(bonus?.valuePercentPerLevel ?? 0) * level}')
        .replaceAll('{val}', '${_addedTo(card, rarity, level, carried, bonus)}');
  }

  static int _addedTo(
    CardData card,
    CardRarity rarity,
    int level,
    int carried,
    PercentBonusDelta? bonus,
  ) {
    if (bonus == null) return 0;
    final index = card.effects.indexWhere((e) => e.type == bonus.effect);
    if (index == -1) return 0;
    int valueAt(int total) =>
        EffectiveCard.apply(card, rarity, [(bonus, total)]).effects[index].value;
    return valueAt(carried + level) - valueAt(carried);
  }

  /// La ligne de la rune dans l'infobulle d'une carte, au niveau [level] que
  /// joue le moteur — le total de ses exemplaires (spec P-43 E1, §5.2) :
  /// `<nom>[ <niveau>] : <description>`. Le niveau ne s'écrit que si la rune
  /// en a plus d'un (`maxLevel` autre que 1).
  String tooltipLine(int level, String locale, CardData card, CardRarity rarity) {
    final name = maxLevel == 1 ? getName(locale) : '${getName(locale)} $level';
    return '$name : ${getDescription(level, locale, card, rarity)}';
  }

  /// Les lignes des runes [runes] dans l'infobulle de [card] à [rarity] : une
  /// par id, au niveau total de ses exemplaires ([levelsOf]) ; une rune absente
  /// du registre n'en a pas.
  static List<String> tooltipLines(
    List<String> runes,
    String locale,
    CardData card,
    CardRarity rarity,
  ) =>
      [
        for (final MapEntry(key: id, value: level) in levelsOf(runes).entries)
          if (getById(id) case final rune?)
            rune.tooltipLine(level, locale, card, rarity),
      ];

  /// Lit **une** référence `id:niveau` : `(id, niveau)`, ou `null` si elle est
  /// mal formée ou de niveau nul. L'unique analyseur des références de rune
  /// (ADR-094 D5) : toute règle qui lit un niveau passe par lui ou par
  /// [levelsOf].
  static (String, int)? parseRef(String ref) {
    final parts = ref.split(':');
    if (parts.length != 2) return null;
    final level = int.tryParse(parts[1]);
    return level != null && level > 0 ? (parts[0], level) : null;
  }

  /// Les niveaux de [refs], additionnés par id dans l'ordre de leur première
  /// apparition — le niveau que joue le moteur (D75) ; une référence que
  /// [parseRef] refuse est ignorée.
  static Map<String, int> levelsOf(Iterable<String> refs) {
    final levels = <String, int>{};
    for (final ref in refs) {
      final parsed = parseRef(ref);
      if (parsed == null) continue;
      final (id, level) = parsed;
      levels[id] = (levels[id] ?? 0) + level;
    }
    return levels;
  }

  static ForgeUpgradeData? getById(String id) {
    final registry = GameDataRegistry.instance;
    if (registry == null) return null;
    try {
      return registry.forgeUpgrades.firstWhere((u) => u.id == id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ForgeUpgradeData.getById: no upgrade found for id "$id" ($e)');
      }
      return null;
    }
  }

  static (List<String>, List<MissingSaveItem>) filterValidRefs(
    List<dynamic>? raw,
  ) {
    final kept = <String>[];
    final missing = <MissingSaveItem>[];
    for (final entry in (raw ?? const [])) {
      final ref = entry as String;
      final id = ref.split(':').first;
      if (getById(id) != null) {
        kept.add(ref);
      } else {
        missing.add(
          MissingSaveItem(
            id: id,
            nameFr: id,
            nameEn: id,
            category: 'forgeUpgrade',
          ),
        );
      }
    }
    return (kept, missing);
  }
}
