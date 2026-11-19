import 'dart:math';

// La géométrie de la main en éventail, en règles pures : des nombres en
// entrée, un résultat en sortie, aucun composant Flame. `LayoutSystem` y lit
// l'écart entre deux cartes, `HerosDraftGame` la carte survolée.

/// L'écart angulaire d'une main de cinq cartes ou moins : le plus large.
const double handMaxAngleStep = 0.08;

/// L'écart angulaire le plus serré de la règle d'origine, celui d'une main
/// de dix cartes.
const double handMinAngleStep = 0.04;

/// L'écart angulaire entre deux cartes voisines d'une main de [count] cartes,
/// posées sur un cercle de rayon [radius].
///
/// L'éventail s'étale sur [availableWidth], l'écran moins les réserves des
/// panneaux latéraux : les cartes extrêmes, larges de [cardWidth] à l'écran,
/// y tiennent bord à bord. L'écart reste borné : jamais plus serré que la
/// règle d'origine (`0,4 / count`), jamais plus large qu'une main de cinq
/// cartes.
double handAngleStep({
  required int count,
  required double availableWidth,
  required double cardWidth,
  required double radius,
}) {
  if (count < 2) return handMaxAngleStep;
  final legacy = (0.4 / count).clamp(handMinAngleStep, handMaxAngleStep);
  // La corde entre les centres extrêmes vaut 2 R sin(angle total / 2) : on
  // en tire l'angle qui place ces centres à cardWidth / 2 des bords.
  final span = (availableWidth - cardWidth).clamp(0.0, 2 * radius);
  final widthStep = 2 * asin(span / (2 * radius)) / (count - 1);
  return widthStep.clamp(legacy, handMaxAngleStep);
}

/// Une carte de la main pour l'arbitre du survol : son centre, son angle (en
/// radians, sens horaire à l'écran, l'axe y vers le bas), sa taille relative
/// à la taille de base d'une carte en main, et si elle peut être survolée.
class HandCardPose {
  final double x;
  final double y;
  final double angle;
  final double scale;
  final bool hoverable;

  const HandCardPose({
    required this.x,
    required this.y,
    required this.angle,
    this.scale = 1.0,
    this.hoverable = true,
  });
}

/// L'indice dans [cards] de la carte survolée par le pointeur
/// ([pointerX], [pointerY]), ou null.
///
/// [cards] suit l'ordre de dessin : une carte recouvre toutes celles qui la
/// précèdent. La carte retenue est la plus haute dont le rectangle — [width]
/// × [height] fois sa taille, tourné de son angle autour de son centre —
/// contient le pointeur. Les cartes sont lues au repos, jamais agrandies par
/// le survol : la bande visible de chaque carte lui appartient, même quand sa
/// voisine survolée, grossie, la recouvre.
///
/// Hystérésis : quand aucune carte ne contient le pointeur, la carte
/// [current] reste survolée tant qu'il reste dans son rectangle agrandi de
/// [hoverScale] — passer sur le bord de la carte grossie ne la fait pas
/// retomber. Elle ne s'étend pas sur les voisines : dans une main serrée, la
/// carte grossie recouvre toute la bande visible de la suivante, qu'elle
/// rendrait inatteignable.
int? pickHoveredCard({
  required List<HandCardPose> cards,
  required double pointerX,
  required double pointerY,
  required double width,
  required double height,
  required double hoverScale,
  int? current,
}) {
  for (var i = cards.length - 1; i >= 0; i--) {
    final card = cards[i];
    if (card.hoverable &&
        _contains(card, pointerX, pointerY, width, height, card.scale)) {
      return i;
    }
  }
  if (current == null || current < 0 || current >= cards.length) return null;
  final card = cards[current];
  final enlarged = max(card.scale, hoverScale);
  if (card.hoverable &&
      _contains(card, pointerX, pointerY, width, height, enlarged)) {
    return current;
  }
  return null;
}

/// Vrai si le point est dans le rectangle de [card], agrandi de [scale] :
/// le point est ramené dans le repère de la carte par la rotation inverse.
bool _contains(
  HandCardPose card,
  double px,
  double py,
  double width,
  double height,
  double scale,
) {
  final dx = px - card.x;
  final dy = py - card.y;
  final c = cos(card.angle);
  final s = sin(card.angle);
  final localX = dx * c + dy * s;
  final localY = -dx * s + dy * c;
  return localX.abs() <= width * scale / 2 &&
      localY.abs() <= height * scale / 2;
}
