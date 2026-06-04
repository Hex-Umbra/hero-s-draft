import 'package:flame/components.dart';
import 'package:roguelike_card_game/models/map_node.dart';

class GameConstants {
  // --- Z-INDEX PRIORITIES ---
  static const int priorityBackground = -100;
  static const int priorityCardBase = 10;
  static const int priorityCardHovered = 100;
  static const int priorityCardFocused = 150;
  static const int priorityCardTrail = 200;
  static const int priorityTargetingLine = 300;
  static const int priorityCardDraggingMax = 500;

  // --- CARD DIMENSIONS ---
  static const double cardWidth = 140.0;
  static const double cardHeight = 196.0;
  static final Vector2 cardSize = Vector2(cardWidth, cardHeight);

  // --- STAT BADGE DIMENSIONS ---
  static final Vector2 badgeHpSize = Vector2(130.0, 16.0);
  static final Vector2 badgeStandardSize = Vector2(48.0, 22.0);
  static final Vector2 badgeCircleSize = Vector2.all(36.0);

  // --- MAP GENERATION QUOTAS ---
  static const Map<MapNodeType, ({int min, int max})> nodeQuotas = {
    MapNodeType.combat: (min: 12, max: 22),
    MapNodeType.elite: (min: 3, max: 6),
    MapNodeType.rest: (min: 3, max: 6),
    MapNodeType.shop: (min: 2, max: 5),
    MapNodeType.event: (min: 4, max: 9),
  };
}

