import 'dart:math';
import 'dart:ui';

import '../game_constants.dart';
import 'enemy_row.dart';

/// La taille d'un pixel de cadre à l'écran, et si elle tombe juste (spec P-05,
/// vague 2, §5.1). [frame] est en pixels logiques ; un pixel de créature vaut
/// la moitié d'un pixel de cadre.
class BoardScale {
  final double frame;
  final bool crisp;

  const BoardScale({required this.frame, required this.crisp});

  double get creature => frame / 2;
}

/// Du centre de la fenêtre au haut de la barre de PV du gabarit : la moitié
/// de la fenêtre, la marge du gabarit et la barre au-dessus du gabarit.
const double barTopAboveWindowCenter = GameConstants.enemyWindowHeight / 2 +
    GameConstants.enemyTemplateMargin -
    GameConstants.enemyHealthBarTop;

/// Du centre de la fenêtre au bas du plus grand cadre, celui du tier 5 : la
/// moitié de la fenêtre et sa marge de 28 (gardé par `tier_frames_test`).
const double frameBelowWindowCenter = GameConstants.enemyWindowHeight / 2 + 28;

/// La largeur, en pixels de cadre, de la rangée de six places les plus
/// serrées.
const double referenceRowFrameWidth =
    6 * enemySlotWidth + 5 * GameConstants.enemyRowMinGap;

/// Le palier du plateau : le plus grand pas pair, en pixels physiques par
/// pixel de cadre, que l'écran permet à la rangée de [referenceRowWidth], à la
/// barre au-dessus de [rowCenterY] et au cadre au-dessus de [rowFloorY]. Sous
/// 2, l'échelle est lissée.
BoardScale boardScaleFor({
  required Size screen,
  required double devicePixelRatio,
  required double rowCenterY,
  required double rowFloorY,
  double referenceRowWidth = referenceRowFrameWidth,
}) {
  final center = rowCenterY * devicePixelRatio;
  final limit = [
    GameConstants.enemyRowUsableWidth *
        screen.width *
        devicePixelRatio /
        referenceRowWidth,
    center / barTopAboveWindowCenter,
    (rowFloorY * devicePixelRatio - center) / frameBelowWindowCenter,
  ].reduce(min);
  final even = 2 * (limit / 2).floorToDouble();
  if (even >= 2) return BoardScale(frame: even / devicePixelRatio, crisp: true);
  return BoardScale(frame: limit / devicePixelRatio, crisp: false);
}
