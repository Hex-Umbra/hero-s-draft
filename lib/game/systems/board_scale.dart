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
/// serrées : six places de [enemySlotWidth] et cinq écarts minimaux, 737.
const double referenceRowFrameWidth =
    6 * enemySlotWidth + 5 * GameConstants.enemyRowMinGap;

/// La taille d'un pixel de cadre, en pixels physiques (B90, B91). Le plafond
/// `limit` est le plus petit de trois rapports : la rangée de
/// [referenceRowWidth] dans sa part de la largeur, la barre sous le haut de
/// l'écran, le cadre au-dessus de [rowFloorY]. La cible suit le héros : 2,2
/// pixels d'écran par pixel de cadre pour 1080 pixels physiques de hauteur,
/// plafonnée par `limit`. Si elle est à 10 % près d'un entier `n` d'au moins 2
/// qui tient sous `limit`, seuil compris, elle s'y arrondit et tout reste net ;
/// sinon elle reste continue et lissée (B85).
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
  final target = min(
    GameConstants.enemyFrameReferenceScale *
        screen.height *
        devicePixelRatio /
        GameConstants.enemyFrameReferenceHeight,
    limit,
  );
  final n = target.roundToDouble();
  if (n >= 2 &&
      n <= limit &&
      (target - n).abs() <=
          GameConstants.enemyFrameSnapTolerance * n +
              GameConstants.enemyFrameSnapEpsilon) {
    return BoardScale(frame: n / devicePixelRatio, crisp: true);
  }
  return BoardScale(frame: target / devicePixelRatio, crisp: false);
}
