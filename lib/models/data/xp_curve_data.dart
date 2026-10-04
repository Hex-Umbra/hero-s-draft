import 'dart:math' show max, min;

/// La courbe d'XP de la run (spec P-43 E3, §3.2 ; D24, D58, D67) : le prix
/// d'un niveau, par acte, lu dans `assets/data/xp_curve.json`.
///
/// Un document de configuration, pas une entité : ni id, ni dossier, hors de
/// l'éditeur de contenu, comme `audio.json`. Le palier d'un niveau en est
/// **dérivé** à chaque lecture, jamais stocké (A8).
class XpCurveData {
  /// Le prix d'un niveau à l'acte 1, 2, … ; la dernière valeur vaut pour
  /// tout acte au-delà de la table (D67).
  final List<int> xpPerLevelByAct;

  const XpCurveData(this.xpPerLevelByAct);

  /// Le palier d'XP à l'acte [act] : l'acte borné à 1 en dessous, la
  /// dernière valeur répétée au-delà de la table.
  int thresholdFor(int act) =>
      xpPerLevelByAct[min(max(act, 1), xpPerLevelByAct.length) - 1];

  /// Refuse une table absente ou vide, et tout palier qui n'est pas un
  /// entier d'au moins 1 : un palier nul ferait boucler `gainXp` sans fin.
  factory XpCurveData.fromJson(Map<String, dynamic> json) {
    final raw = json['xpPerLevelByAct'];
    if (raw is! List || raw.isEmpty) {
      throw const FormatException(
        'xp_curve : "xpPerLevelByAct" doit etre une liste non vide d entiers',
      );
    }
    final values = <int>[];
    for (final value in raw) {
      if (value is! int || value < 1) {
        throw FormatException(
          'xp_curve : "xpPerLevelByAct" porte "$value" ; un palier est un '
          'entier d au moins 1',
        );
      }
      values.add(value);
    }
    return XpCurveData(List.unmodifiable(values));
  }
}
