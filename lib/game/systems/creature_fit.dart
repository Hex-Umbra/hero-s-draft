import 'dart:ui';

/// Le rectangle de l'ancienne peinture qui contient la créature (B75, spec
/// P-05, vague 2, §5.4), en pixels de l'image.
const Rect oldSpriteRect = Rect.fromLTRB(308, 329, 1388, 1949);

/// La part de l'image d'une créature à dessiner, et si elle se lisse.
class CreatureFit {
  final Rect source;
  final bool smooth;

  const CreatureFit({required this.source, required this.smooth});
}

/// Un sprite neuf de 128 × 192 se dessine entier et net ; une ancienne
/// peinture, qui contient [oldSpriteRect], se recadre dessus et se lisse ;
/// toute autre image se dessine entière.
CreatureFit creatureFitOf(int imageWidth, int imageHeight) {
  final whole = Rect.fromLTWH(
    0,
    0,
    imageWidth.toDouble(),
    imageHeight.toDouble(),
  );
  if (imageWidth == 128 && imageHeight == 192) {
    return CreatureFit(source: whole, smooth: false);
  }
  if (imageWidth >= oldSpriteRect.right &&
      imageHeight >= oldSpriteRect.bottom) {
    return const CreatureFit(source: oldSpriteRect, smooth: true);
  }
  return CreatureFit(source: whole, smooth: false);
}
