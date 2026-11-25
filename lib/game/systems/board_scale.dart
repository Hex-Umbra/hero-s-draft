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

/// La taille d'un pixel de cadre, en pixels physiques (B90, B91, B93). Le
/// plafond `limit` est le plus petit de trois rapports : la rangée de
/// [referenceRowWidth] dans sa part de la largeur ; le cadre au-dessus de
/// [rowFloorY], la rangée à [rowCenterY] ; la carte entière, de la barre au
/// bas du plus grand cadre, entre `enemyRowTopClearance` et [rowFloorY] — la
/// place qu'il lui faut quand [enemyRowCenterYFor] la descend. La cible suit le héros : 2,2
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
    (rowFloorY * devicePixelRatio - center) / frameBelowWindowCenter,
    (rowFloorY - GameConstants.enemyRowTopClearance) *
        devicePixelRatio /
        (barTopAboveWindowCenter + frameBelowWindowCenter),
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

/// L'ordonnée logique du centre de la rangée à l'échelle [scale] (B93) : sa
/// part de l'écran ([rowCenterYFor]), descendue s'il le faut pour que le haut
/// des barres de PV reste sous `enemyRowTopClearance` ; calée sur le pixel
/// physique, vers le bas quand elle descend.
double enemyRowCenterYFor(
  double screenHeight, {
  required BoardScale scale,
  double devicePixelRatio = 1,
}) {
  final share = rowCenterYFor(screenHeight, devicePixelRatio: devicePixelRatio);
  final belowHud = GameConstants.enemyRowTopClearance +
      barTopAboveWindowCenter * scale.frame;
  if (share >= belowHud) return share;
  // Le millionième absorbe l'erreur d'arrondi d'un produit.
  return ((belowHud * devicePixelRatio) - 1e-6).ceilToDouble() /
      devicePixelRatio;
}
