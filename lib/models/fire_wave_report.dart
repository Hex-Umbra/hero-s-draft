import 'package:meta/meta.dart';

/// Le Feu qu'une explosion fait recevoir à un voisin, réellement reçu — 0 pour
/// un voisin que la vague a tué (spec P-53, §4.7).
@immutable
class FireSplash {
  final String targetId;
  final int charge;

  const FireSplash({
    required this.targetId,
    required this.charge,
  });
}

/// La résolution d'un porteur pendant une vague : ses tranches complètes, et
/// ce que ses explosions posent à chaque voisin.
@immutable
class FireResolution {
  final String bearerId;
  final String chargeId;
  final int tranches;
  final List<FireSplash> splashes;

  FireResolution({
    required this.bearerId,
    required this.chargeId,
    required this.tranches,
    required List<FireSplash> splashes,
  }) : splashes = List.unmodifiable(splashes);
}

/// Le compte rendu d'une vague de la chaîne du Feu (spec P-53, A12) : Flame le
/// lit pour animer la vague ; [nextBearerIds] porte la chaîne jusqu'à l'appel
/// suivant. Jamais sauvegardé (spec §8).
@immutable
class FireWaveReport {
  final int wave;
  final List<FireResolution> resolved;
  final Set<String> nextBearerIds;

  FireWaveReport({
    required this.wave,
    required List<FireResolution> resolved,
    required Set<String> nextBearerIds,
  })  : resolved = List.unmodifiable(resolved),
        nextBearerIds = Set.unmodifiable(nextBearerIds);
}
