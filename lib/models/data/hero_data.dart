import 'package:flutter/foundation.dart';

import '../might_target.dart';
import 'game_data_registry.dart';
import 'stat_rule.dart';

class HeroData {
  final String id;
  final String nameEn;
  final String nameFr;
  final String descriptionEn;
  final String descriptionFr;

  /// L'image de la carte de classe — 1696 x 2528 pour les trois classes
  /// livrees. C'est elle que `HeroCard` affiche en combat.
  final String classCard;

  /// Une vraie icone, petite, optionnelle. Absente des trois classes livrees :
  /// le dialogue de stats replie alors sur [classCard].
  final String? iconPath;

  /// La couleur d'accent de la classe, en ARGB opaque. `null` quand elle n'est
  /// pas declaree — le lecteur choisit son repli.
  final int? themeColor;

  final int maxHp;
  final int maxMana;
  final int luck;
  final int mastery;

  /// Le critique de départ de la classe, en pourcentage (spec P-41, §7.3).
  /// `EntityStats` le porte déjà : la classe pouvait seulement ne pas le dire.
  final int critChance;

  /// Les règles de stat de la classe : ce qu'elle convertit **au gain**, ce que
  /// l'orientation de la Puissance ne peut pas faire (spec P-41, §7.1). Vide
  /// pour le Paladin et le Mage.
  final List<StatRule> statRules;

  /// Ce que la Puissance de la classe renforce (spec P-41, §7.1). Obligatoire
  /// dans `class.json` : la valeur par défaut ne sert qu'aux constructions
  /// écrites en code.
  final Set<MightTarget> mightTargets;
  final List<String> skills;

  /// Rang d'affichage à la sélection de classe. Donnée de présentation :
  /// l'ordre ne doit pas dépendre de l'ordre du catalogue.
  final int displayOrder;

  const HeroData({
    required this.id,
    this.nameEn = '',
    this.nameFr = '',
    this.descriptionEn = '',
    this.descriptionFr = '',
    required this.classCard,
    this.iconPath,
    this.themeColor,
    required this.maxHp,
    required this.maxMana,
    this.luck = 0,
    this.mastery = 0,
    this.critChance = 0,
    this.statRules = const [],
    this.mightTargets = const {MightTarget.attack},
    this.skills = const [],
    this.displayOrder = 0,
  });

  String getName(String locale) => locale == 'fr' ? nameFr : nameEn;
  String getDescription(String locale) =>
      locale == 'fr' ? descriptionFr : descriptionEn;

  factory HeroData.fromJson(Map<String, dynamic> json) {
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

    return HeroData(
      id: json['id'] as String,
      nameEn: nEn,
      nameFr: nFr,
      descriptionEn: dEn,
      descriptionFr: dFr,
      classCard: json['classCard'] as String,
      iconPath: json['iconPath'] as String?,
      themeColor: _parseHexColor(json['themeColor']),
      maxHp: json['maxHp'] as int,
      maxMana: json['maxMana'] as int,
      luck: json['luck'] as int? ?? 0,
      mastery: json['mastery'] as int? ?? 0,
      critChance: json['critChance'] as int? ?? 0,
      statRules: StatRule.parseAll(json['statRules']),
      mightTargets: MightTarget.parseAll(json['mightTargets']),
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }

  /// `#RRGGBB` -> `0xFFRRGGBB`. `null` pour tout le reste.
  static int? _parseHexColor(Object? value) {
    if (value is! String) return null;
    final match = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(value);
    if (match == null) return null;
    return 0xFF000000 | int.parse(match.group(1)!, radix: 16);
  }

  /// La classe d'identifiant [id] dans le registre chargé, `null` si le
  /// registre n'est pas là ou ne la connaît pas — sur le modèle de
  /// `PassiveData.getById`. C'est par ici qu'une run rechargée retrouve les
  /// règles de sa classe, plutôt que de les relire d'une sauvegarde.
  static HeroData? getById(String id) {
    final registry = GameDataRegistry.instance;
    if (registry == null) return null;
    try {
      return registry.heroes.firstWhere((h) => h.id == id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HeroData.getById: no class found for id "$id" ($e)');
      }
      return null;
    }
  }
}
