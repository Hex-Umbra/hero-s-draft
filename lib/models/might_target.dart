/// Ce que la Puissance d'une classe renforce (spec P-41, §7.1).
///
/// La classe le déclare dans son `class.json` ; les stats du héros en portent
/// une copie, que lit `PowerRules`. L'ordre des valeurs est l'ordre
/// d'affichage.
enum MightTarget {
  /// Les dégâts d'un effet `damage` porté par une carte Attaque.
  attack,

  /// Les dégâts d'un effet `damage` porté par une carte Compétence.
  skill,

  /// L'intensité d'un statut posé sur un ennemi, par une carte ou par l'une de
  /// ses runes — jamais sa durée.
  alteration;

  /// Lit une liste JSON de cibles. Lève [FormatException] sur une valeur qui
  /// n'est pas une liste, sur une liste vide et sur une cible inconnue : une
  /// classe dont la Puissance ne renforcerait rien est une faute de donnée.
  static Set<MightTarget> parseAll(Object? json) {
    if (json is! List || json.isEmpty) {
      throw FormatException(
        'mightTargets doit être une liste non vide — reçu : $json',
      );
    }
    return {
      for (final name in json)
        MightTarget.values.firstWhere(
          (target) => target.name == name,
          orElse: () => throw FormatException(
            'mightTargets : cible inconnue "$name" — attendu : '
            '${MightTarget.values.map((target) => target.name).join(', ')}',
          ),
        ),
    };
  }
}
