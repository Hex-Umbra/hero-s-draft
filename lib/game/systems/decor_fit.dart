import 'dart:math';
import 'dart:ui';

/// La taille d'un décor de combat, en pixels de décor.
const double decorWidth = 640;
const double decorHeight = 360;

/// Où et à quelle échelle le décor se pose : [scale] pixels logiques par pixel
/// de décor, [left] et [top] le coin haut-gauche (négatifs quand le décor est
/// rogné).
class DecorFit {
  final double scale;
  final double left;
  final double top;

  const DecorFit({required this.scale, required this.left, required this.top});
}

/// Le décor couvre l'écran, centré, au rapport le plus petit qui le couvre ;
/// son coin tombe sur le pixel physique (spec P-05, vague 2, §5.2).
DecorFit decorFitFor({required Size screen, required double devicePixelRatio}) {
  final width = screen.width * devicePixelRatio;
  final height = screen.height * devicePixelRatio;
  final factor = max(width / decorWidth, height / decorHeight);
  return DecorFit(
    scale: factor / devicePixelRatio,
    left:
        ((width - decorWidth * factor) / 2).roundToDouble() / devicePixelRatio,
    top: ((height - decorHeight * factor) / 2).roundToDouble() /
        devicePixelRatio,
  );
}
