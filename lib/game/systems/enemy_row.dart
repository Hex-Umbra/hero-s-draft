import 'dart:math';

import '../../models/data/tier_frame_data.dart';
import '../game_constants.dart';

/// Une place de la rangée des ennemis : sa largeur et l'écart minimal qu'elle
/// demande à sa voisine, en pixels de cadre (spec P-05, vague 2, §5.6).
class RowSlot {
  final double width;
  final double gap;

  const RowSlot({required this.width, required this.gap});
}

/// La place de plus petit cadre : le gabarit et la part d'**une** languette,
/// 88 + 29 = 117 (B91). Une carte en porte une de chaque côté : quand deux
/// voisines en portent chacune une du côté qui les sépare, ces deux languettes
/// se superposent, et la carte dessinée par-dessus reçoit le pointeur
/// (`inDrawOrder` dans `entity_hover.dart`).
const double enemySlotWidth =
    GameConstants.enemyTemplateWidth + GameConstants.enemySlotTabWidth;

/// La place d'un ennemi de cadre [frame] : la plus large de son cadre et de
/// [enemySlotWidth] — 117 du tier 1 au tier 4, 120 au tier 5.
RowSlot slotOf(TierFrame frame, {double gap = GameConstants.enemyRowMinGap}) =>
    RowSlot(width: max(frame.width.toDouble(), enemySlotWidth), gap: gap);

/// Les abscisses des centres des [slots], de gauche à droite, sur [screenWidth]
/// pixels logiques. [unit] est la taille logique d'un pixel de cadre. Chaque
/// centre tombe sur un pixel physique, et deux voisines ne sont jamais plus
/// proches que leur distance minimale.
List<double> placeRow({
  required List<RowSlot> slots,
  required double unit,
  required double screenWidth,
  double devicePixelRatio = 1,
}) {
  if (slots.isEmpty) return const [];
  final k = unit * devicePixelRatio;
  final minimal = [
    for (var i = 1; i < slots.length; i++)
      (slots[i - 1].width + slots[i].width) / 2 +
          max(slots[i - 1].gap, slots[i].gap),
  ];
  final spread = minimal.isEmpty
      ? 0.0
      : (0.85 * screenWidth / (slots.length + 1) / unit -
              minimal.reduce((a, b) => a + b) / minimal.length)
          .clamp(
            0.0,
            GameConstants.enemyRowMaxGap - GameConstants.enemyRowMinGap,
          );
  final steps = [
    for (final m in minimal)
      max(((m + spread) * k).roundToDouble(), (m * k).ceilToDouble()),
  ];
  final extent = steps.fold(0.0, (a, b) => a + b) +
      (slots.first.width + slots.last.width) / 2 * k;
  var x = ((screenWidth * devicePixelRatio - extent) / 2 +
          slots.first.width / 2 * k)
      .roundToDouble();
  final centers = [x / devicePixelRatio];
  for (final step in steps) {
    x += step;
    centers.add(x / devicePixelRatio);
  }
  return centers;
}

/// L'ordonnée du centre de la rangée : une part de [screenHeight], calée sur
/// le pixel physique.
double rowCenterYFor(double screenHeight, {double devicePixelRatio = 1}) =>
    (GameConstants.enemyRowCenterY * screenHeight * devicePixelRatio)
        .roundToDouble() /
    devicePixelRatio;

/// Le décalage horizontal, logique, qui garde la carte ouverte dans l'écran
/// (B89), arrondi vers l'intérieur. [left] et [right] bornent la carte ouverte
/// à son arrivée, AVANT décalage : sa zone au repos — canevas, barre,
/// languettes au repos —, à l'échelle de la fiche, posée sur `restPosition`
/// plus la descente. Une carte plus large que l'écran se centre.
double inspectionShift({
  required double left,
  required double right,
  required double screenWidth,
  double devicePixelRatio = 1,
}) {
  if (right - left > screenWidth) return (screenWidth - right - left) / 2;
  // La grandeur s'arrondit au pixel physique supérieur : sous B85, le bord de
  // la carte ne tombe pas sur un pixel physique, et la carte ne doit jamais
  // dépasser l'écran. Le millionième absorbe l'erreur d'arrondi d'un produit.
  double inward(double overflow) =>
      ((overflow * devicePixelRatio) - 1e-6).ceilToDouble() / devicePixelRatio;
  if (left < 0) return inward(-left);
  if (right > screenWidth) return -inward(right - screenWidth);
  return 0;
}
