import 'package:meta/meta.dart';

/// Le cadre d'un tier d'ennemi, tel que `assets/data/tier_frames.json` le
/// déclare (spec P-05, vague 2, §4.1) : la taille de son canevas et
/// l'offset du coin haut-gauche de la fenêtre de 64 × 96 qu'il entoure.
///
/// `fromJson` ne valide que la forme de l'entrée. Ce que la fenêtre doit à
/// la taille du canevas (qu'elle y tienne, qu'elle y soit centrée) se
/// contrôle au chargement, par `tierFrameFaults`, qui lit les mesures de la
/// fenêtre dans `GameConstants`.
@immutable
class TierFrame {
  final int tier;
  final int width;
  final int height;
  final int windowX;
  final int windowY;

  const TierFrame({
    required this.tier,
    required this.width,
    required this.height,
    required this.windowX,
    required this.windowY,
  });

  /// L'image du cadre, sous les données.
  String get imagePath => 'assets/data/frames/tier_$tier.png';

  factory TierFrame.fromJson(Map<String, dynamic> json) {
    final tier = json['tier'];
    if (tier is! int || tier < 1) {
      throw FormatException(
        'tier : doit être un entier ≥ 1 — reçu : $tier',
      );
    }
    final size = _pair(json['size'], tier, 'size');
    if (size.$1.isOdd || size.$2.isOdd) {
      throw FormatException(
        'tier $tier : "size" doit être deux entiers pairs — '
        'reçu : [${size.$1}, ${size.$2}]',
      );
    }
    final window = _pair(json['window'], tier, 'window');
    return TierFrame(
      tier: tier,
      width: size.$1,
      height: size.$2,
      windowX: window.$1,
      windowY: window.$2,
    );
  }

  static (int, int) _pair(Object? raw, int tier, String key) {
    if (raw is List && raw.length == 2 && raw[0] is int && raw[1] is int) {
      return (raw[0] as int, raw[1] as int);
    }
    throw FormatException(
      'tier $tier : "$key" doit être deux entiers — reçu : $raw',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TierFrame &&
      other.tier == tier &&
      other.width == width &&
      other.height == height &&
      other.windowX == windowX &&
      other.windowY == windowY;

  @override
  int get hashCode => Object.hash(tier, width, height, windowX, windowY);

  @override
  String toString() =>
      'TierFrame(tier $tier, ${width}x$height, fenêtre $windowX,$windowY)';
}

/// Les cadres du jeu, un par tier. Vide par défaut, comme `ChargeCatalog` :
/// un registre construit à la main n'en porte aucun, et `loadGameDataRegistry`
/// refuse un ennemi dont le tier n'a pas le sien.
class TierFrameTable {
  final List<TierFrame> frames;

  const TierFrameTable(this.frames);

  const TierFrameTable.empty() : frames = const [];

  /// Le cadre du [tier], ou `null` quand la table n'en a pas.
  TierFrame? of(int tier) {
    for (final frame in frames) {
      if (frame.tier == tier) return frame;
    }
    return null;
  }

  factory TierFrameTable.fromJson(Map<String, dynamic> json) {
    final raw = json['frames'];
    if (raw is! List) {
      throw FormatException('"frames" doit être une liste — reçu : $raw');
    }
    final frames = <TierFrame>[];
    final seen = <int>{};
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) {
        throw FormatException(
          'une entrée de "frames" doit être un objet — reçu : $entry',
        );
      }
      final frame = TierFrame.fromJson(entry);
      if (!seen.add(frame.tier)) {
        throw FormatException('tier ${frame.tier} : déclaré deux fois');
      }
      frames.add(frame);
    }
    return TierFrameTable(List.unmodifiable(frames));
  }
}
