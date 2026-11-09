import '../../models/data/forge_upgrade_data.dart';
import '../../models/data/signature_evolution_data.dart';
import '../../models/signature_instance.dart';

/// Le pool d'une signature rangé pour son écran d'évolution (D78) : chaque
/// évolution y est une fois, et une seule.
typedef SignatureEvolutionBoard = ({
  /// Ce que le choix en cours peut prendre.
  List<SignatureEvolutionData> choices,

  /// L'autre rang, qui s'ouvre au palier suivant, au niveau du héros
  /// [upcomingHeroLevel]. Une mineure déjà prise y reste : elle remontera.
  List<SignatureEvolutionData> upcoming,
  int upcomingHeroLevel,

  /// Les majeures prises : elles ne se reprennent pas.
  List<SignatureEvolutionData> takenMajors,

  /// Les majeures exclues pour la run, chacune avec la majeure prise qui
  /// l'exclut (Q7).
  List<(SignatureEvolutionData, SignatureEvolutionData)> excluded,
});

/// Les règles de choix des évolutions de signature (spec P-42 T1 et P-44 lot 1,
/// §4.10 ; A26, Q6, Q7, D78). Pures : ni Riverpod ni état, seulement une
/// signature.
abstract final class SignatureEvolutionRules {
  /// Sous ce nombre de majeures éligibles, le palier majeur admet aussi les
  /// mineures (Q6).
  static const int _enoughMajors = 3;

  static List<SignatureEvolutionData> _ofTier(
          SignatureInstance s, EvolutionTier tier) =>
      [
        for (final e in s.data.evolutions)
          if (e.tier == tier) e,
      ];

  /// Les majeures du pool ni prises, ni exclues par une majeure prise, ni
  /// l'excluant (Q7).
  static List<SignatureEvolutionData> eligibleMajors(SignatureInstance s) {
    final taken = [for (final (evolution, _) in s.taken) evolution];
    return [
      for (final major in _ofTier(s, EvolutionTier.major))
        if (!taken.any((t) => t.id == major.id || t.excludesOrIsExcludedBy(major)))
          major,
    ];
  }

  /// Ce que le prochain choix de [s] peut prendre : au palier mineur, les
  /// mineures ; au palier majeur, les majeures éligibles, plus toutes les
  /// mineures quand il en reste moins de [_enoughMajors] (A26, Q6).
  static List<SignatureEvolutionData> admissible(SignatureInstance s) {
    final minors = _ofTier(s, EvolutionTier.minor);
    if (s.nextTier == EvolutionTier.minor) return minors;
    final majors = eligibleMajors(s);
    return majors.length < _enoughMajors ? [...majors, ...minors] : majors;
  }

  /// [s] une fois l'évolution [evolutionId] prise (voir [withChoice]), ou
  /// `null` si elle n'est pas [admissible].
  static SignatureInstance? take(SignatureInstance s, String evolutionId) {
    final chosen = admissible(s).where((e) => e.id == evolutionId).firstOrNull;
    if (chosen == null) return null;
    return SignatureInstance(
      s.data,
      evolutions: withChoice(s.evolutions, chosen),
    );
  }

  /// Le pool de [s] rangé pour son écran d'évolution, dans l'ordre du pool.
  static SignatureEvolutionBoard board(SignatureInstance s) {
    final choices = admissible(s);
    final takenMajors = [
      for (final (evolution, _) in s.taken)
        if (evolution.tier == EvolutionTier.major) evolution,
    ];
    final excluded = [
      for (final major in _ofTier(s, EvolutionTier.major))
        if (takenMajors.where(major.excludesOrIsExcludedBy).firstOrNull
            case final by?)
          (major, by),
    ];
    final placed = {
      for (final e in [...choices, ...takenMajors]) e.id,
      for (final (e, _) in excluded) e.id,
    };
    return (
      choices: choices,
      upcoming: [
        for (final e in s.data.evolutions)
          if (!placed.contains(e.id)) e,
      ],
      upcomingHeroLevel: s.nextEvolutionHeroLevel + 5,
      takenMajors: takenMajors,
      excluded: excluded,
    );
  }

  /// Les évolutions après le choix de [chosen] : une mineure déjà prise monte
  /// d'un niveau à sa place, toute autre entre à `'<id>:1'` à la fin.
  static List<String> withChoice(
      List<String> evolutions, SignatureEvolutionData chosen) {
    final levels = ForgeUpgradeData.levelsOf(evolutions);
    if (levels.containsKey(chosen.id)) {
      return [
        for (final entry in levels.entries)
          '${entry.key}:${entry.key == chosen.id ? entry.value + 1 : entry.value}',
      ];
    }
    return [...evolutions, '${chosen.id}:1'];
  }
}
