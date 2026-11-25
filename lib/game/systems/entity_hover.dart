import 'dart:ui';

import '../../models/data/tier_frame_data.dart';
import '../game_constants.dart';
import 'status_readout.dart';

/// La fenêtre du cadre : 64 × 96 à son offset.
Rect enemyWindowRect(TierFrame frame) => Rect.fromLTWH(
      frame.windowX.toDouble(),
      frame.windowY.toDouble(),
      GameConstants.enemyWindowWidth,
      GameConstants.enemyWindowHeight,
    );

/// Le gabarit : la fenêtre agrandie de sa marge, le même sur les cinq cadres.
Rect enemyTemplateRect(TierFrame frame) =>
    enemyWindowRect(frame).inflate(GameConstants.enemyTemplateMargin);

/// La zone d'un ennemi sous le pointeur : du haut de sa barre de PV, au-dessus
/// du gabarit, au bas du canevas, sur toute sa largeur.
Rect enemyZoneRect(TierFrame frame) => Rect.fromLTRB(
      0,
      enemyTemplateRect(frame).top + GameConstants.enemyHealthBarTop,
      frame.width.toDouble(),
      frame.height.toDouble(),
    );

/// La zone d'un ennemi sous le pointeur : le rectangle continu de sa barre de
/// PV au bas de sa carte (spec P-05, §4.5).
Rect enemyBodyRect(double cardWidth, double cardHeight) =>
    Rect.fromLTRB(0, GameConstants.enemyHealthBarTop, cardWidth, cardHeight);

/// Vrai quand la languette déroulée vers l'extérieur sortirait de l'écran :
/// elle se déroule alors vers l'intérieur, par-dessus sa propre carte (B39).
/// [attachEdge] est le bord de la carte du côté de la languette et
/// [unfoldedWidth] sa largeur déroulée, tous deux sur le canevas.
bool unfoldsInward({
  required StatusSide side,
  required double attachEdge,
  required double unfoldedWidth,
  required double screenWidth,
}) =>
    switch (side) {
      StatusSide.left => attachEdge - unfoldedWidth < 0,
      StatusSide.right => attachEdge + unfoldedWidth > screenWidth,
    };

/// La carte que le pointeur survole parmi [zones], une entrée par carte
/// vivante, en rectangles (sa carte et ses languettes). La courante l'emporte
/// tant que le pointeur reste dans sa zone ; sinon la première zone qui le
/// contient ; sinon `null`.
int? pickHoveredEntity({
  required List<List<Rect>> zones,
  required int? current,
  required Offset pointer,
}) {
  bool holds(int index) => zones[index].any((zone) => zone.contains(pointer));

  if (current != null && current < zones.length && holds(current)) {
    return current;
  }
  for (var index = 0; index < zones.length; index++) {
    if (holds(index)) return index;
  }
  return null;
}
