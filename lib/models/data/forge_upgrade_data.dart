import 'package:flutter/foundation.dart';
import 'card_delta.dart';
import 'game_data_registry.dart';
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
  final int valueMultiplier;

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
    this.valueMultiplier = 1,
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
      valueMultiplier: json['valueMultiplier'] as int? ?? 1,
      deltas: _readDeltas(id, json['deltas']),
      weight: json['weight'] as int? ?? 10,
      emoji: json['emoji'] as String? ?? '🔮',
    );
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
      'valueMultiplier': valueMultiplier,
      'deltas': [for (final delta in deltas) delta.toJson()],
      'weight': weight,
      'emoji': emoji,
    };
  }

  String getName(String locale) {
    return locale == 'fr' ? nameFr : nameEn;
  }

  String getDescription(int tier, String locale) {
    final template = locale == 'fr' ? descriptionFr : descriptionEn;
    final val = tier * valueMultiplier;
    return template
        .replaceAll('{tier}', tier.toString())
        .replaceAll('{val}', val.toString());
  }

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
