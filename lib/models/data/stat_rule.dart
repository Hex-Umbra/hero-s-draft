import 'package:meta/meta.dart';

/// La ressource qu'une règle de classe convertit. La Puissance n'en est pas :
/// la classe l'oriente à la lecture, elle ne la convertit pas au gain
/// (spec P-41, §7.1).
enum RuleStat { armor, mana }

/// Ce que la règle fait de la ressource. `block`, avec `cap` et `decay`, reste
/// une extension possible sans changement de forme : son seul usage prévu — les
/// Compétences du Berserker — est devenu une orientation, et livré sans lecteur
/// ce serait du code mort (spec §7.1).
enum RuleMode { convert }

/// Vers quoi la ressource est convertie.
enum RuleTarget {
  /// Le statut `might`, la Puissance temporaire. Une ressource éphémère ne
  /// devient jamais une ressource permanente (règle R5, spec §7.2).
  statusMight,
}

/// Une règle de stat déclarée par une classe dans son `class.json`
/// (spec P-41, §7.1).
///
/// Une **liste** et non une table : le langage de chemins de l'éditeur de
/// contenu sait désigner un élément de liste (`statRules[].mode`), pas une clé
/// arbitraire d'une table.
@immutable
class StatRule {
  final RuleStat stat;
  final RuleMode mode;
  final RuleTarget to;

  /// La durée du statut produit, en tours.
  final int duration;

  const StatRule({
    required this.stat,
    required this.mode,
    required this.to,
    this.duration = 1,
  });

  static const Map<String, RuleStat> _stats = {
    'armor': RuleStat.armor,
    'mana': RuleStat.mana,
  };

  static const Map<String, RuleMode> _modes = {'convert': RuleMode.convert};

  /// `status:might` ne peut pas être un nom d'énumération : la correspondance
  /// est déclarée ici, avec le vocabulaire que le fichier de classe écrit.
  static const Map<String, RuleTarget> _targets = {
    'status:might': RuleTarget.statusMight,
  };

  /// Le vocabulaire que le fichier de classe écrit, exposé pour l'éditeur de
  /// contenu — précédent : `PassiveMastery.fields` (spec P-49, §3.3).
  ///
  /// Ces listes ne sont **pas** `_names(RuleStat.values)` et compagnie :
  /// `RuleTarget.statusMight` s'écrit `"status:might"` dans le fichier, et le
  /// nom Dart n'y a jamais cours. Le seul endroit qui connaisse la
  /// correspondance est ce parseur ; la recopier dans un descripteur ferait
  /// diverger les deux au premier ajout (spec P-41, §9.2).
  static List<String> get statNames => _stats.keys.toList(growable: false);
  static List<String> get modeNames => _modes.keys.toList(growable: false);
  static List<String> get targetNames => _targets.keys.toList(growable: false);

  static T _read<T>(Map<String, dynamic> json, String key, Map<String, T> by) {
    final value = json[key];
    final parsed = value is String ? by[value] : null;
    if (parsed == null) {
      throw FormatException(
        'statRules.$key : valeur "$value" inconnue — attendu : '
        '${by.keys.join(', ')}',
      );
    }
    return parsed;
  }

  factory StatRule.fromJson(Map<String, dynamic> json) => StatRule(
        stat: _read(json, 'stat', _stats),
        mode: _read(json, 'mode', _modes),
        to: _read(json, 'to', _targets),
        duration: json['duration'] as int? ?? 1,
      );

  // Egalite par valeur : `RunState.fromJsonWithReport` reconstruit ces regles
  // depuis le registre plutot que de les deserialiser (decision 1 du plan),
  // et une comparaison par identite laisserait passer une reconstruction
  // structurellement fausse sans qu'aucun test ne le voie.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StatRule &&
          other.stat == stat &&
          other.mode == mode &&
          other.to == to &&
          other.duration == duration);

  @override
  int get hashCode => Object.hash(stat, mode, to, duration);

  /// Lit la clé `statRules` d'une classe. Absente : aucune règle — c'est le
  /// cas du Paladin et du Mage.
  static List<StatRule> parseAll(Object? json) {
    if (json == null) return const [];
    if (json is! List) {
      throw FormatException('statRules doit être une liste — reçu : $json');
    }
    return json
        .map((e) => StatRule.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
