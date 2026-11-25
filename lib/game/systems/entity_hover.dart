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

/// Les [items] dans l'ordre où Flame les dessine, du dessous au dessus : par
/// [priorityOf] croissante et, à priorité égale, dans l'ordre de [items] —
/// celui des enfants de leur parent. Le tri est stable, comme le
/// rééquilibrage par lequel Flame applique un changement de priorité : il
/// reprend les enfants dans leur ordre et les replace par priorité. Une
/// priorité changée et pas encore appliquée compte donc déjà.
List<T> inDrawOrder<T>(Iterable<T> items, int Function(T item) priorityOf) {
  final list = items.toList();
  final order = [for (var index = 0; index < list.length; index++) index]
    ..sort((a, b) {
      final byPriority = priorityOf(list[a]).compareTo(priorityOf(list[b]));
      return byPriority != 0 ? byPriority : a.compareTo(b);
    });
  return [for (final index in order) list[index]];
}

/// Le dernier de [drawn], rangé par [inDrawOrder], qui satisfait [test] :
/// quand deux zones se chevauchent — deux languettes voisines au repos (B91),
/// une languette déroulée sur une voisine —, celui que le joueur voit
/// par-dessus. Le même choix que l'appui, que Flame donne au dernier dessiné.
T? topmostWhere<T>(List<T> drawn, bool Function(T item) test) {
  for (final item in drawn.reversed) {
    if (test(item)) return item;
  }
  return null;
}

/// La carte que le pointeur survole parmi [zones], une entrée par carte
/// vivante dans l'ordre de dessin ([inDrawOrder]), en rectangles (sa carte et
/// ses languettes). La courante l'emporte tant que le pointeur reste dans sa
/// zone — survolée, elle est dessinée par-dessus ses voisines ; sinon la
/// dernière dessinée des zones qui le contiennent ; sinon `null`.
int? pickHoveredEntity({
  required List<List<Rect>> zones,
  required int? current,
  required Offset pointer,
}) {
  bool holds(int index) => zones[index].any((zone) => zone.contains(pointer));

  if (current != null && current < zones.length && holds(current)) {
    return current;
  }
  return topmostWhere(
    [for (var index = 0; index < zones.length; index++) index],
    holds,
  );
}
