import 'package:flame/components.dart';
import '../heros_draft_game.dart';
import '../game_constants.dart';
import '../components/visual_effects/targeting_line.dart';

class CombatVisualSystem extends Component with HasGameReference<HerosDraftGame> {
  late final TargetingLine targetingLine;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    targetingLine = TargetingLine();
    add(targetingLine..priority = GameConstants.priorityTargetingLine);
  }

  void updatePointer(Vector2 pointerPos) {
    if (game.focusedCard != null && !game.focusedCard!.isDragging) {
      targetingLine.updatePoints(
        game.focusedCard!.position + Vector2(0, -40),
        pointerPos,
      );
    }
  }
}
