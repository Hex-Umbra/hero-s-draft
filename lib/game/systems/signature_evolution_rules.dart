import 'dart:math' show Random;

import '../../models/data/forge_upgrade_data.dart';
import '../../models/data/signature_evolution_data.dart';
import '../../models/signature_instance.dart';

/// Les règles de tirage et de choix des évolutions de signature (spec P-42 T1 et P-44
/// lot 1, §4.10 ; A26, Q6, Q7). Pures : ni Riverpod ni état, seulement une
/// signature et un tirage.
abstract final class SignatureEvolutionRules {
  /// Le nombre d'évolutions proposées à chaque choix.
  static const int offerSize = 3;

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
  /// mineures quand il en reste moins de [offerSize] (A26, Q6).
  static List<SignatureEvolutionData> admissible(SignatureInstance s) {
    final minors = _ofTier(s, EvolutionTier.minor);
    if (s.nextTier == EvolutionTier.minor) return minors;
    final majors = eligibleMajors(s);
    return majors.length < offerSize ? [...majors, ...minors] : majors;
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

  /// Les évolutions proposées : sans poids, sans remise. Au palier mineur,
  /// [offerSize] mineures ; au palier majeur, les majeures éligibles puis, pour
  /// compléter, des mineures. Moins si le pool n'en a pas assez.
  static List<SignatureEvolutionData> offer(SignatureInstance s, Random rng) {
    List<SignatureEvolutionData> draw(List<SignatureEvolutionData> pool, int n) =>
        ([...pool]..shuffle(rng)).take(n).toList();

    if (s.nextTier == EvolutionTier.minor) {
      return draw(_ofTier(s, EvolutionTier.minor), offerSize);
    }
    final majors = draw(eligibleMajors(s), offerSize);
    return [
      ...majors,
      ...draw(_ofTier(s, EvolutionTier.minor), offerSize - majors.length),
    ];
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
