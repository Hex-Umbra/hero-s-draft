import 'package:flame/components.dart';
import '../heros_draft_game.dart';
import '../game_constants.dart';
import '../../models/fire_wave_report.dart';
import '../components/entities/enemy_card.dart';
import '../components/entities/status_indicator.dart';
import '../components/visual_effects/fire_wave_effects.dart';
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

  /// Une vague de la chaine du Feu (spec P-53, §5.2, F-a) : un eclair sur
  /// chaque porteur qui explose, puis une boule de feu vers chacun de ses
  /// voisins, dont l'arrivee montre les degats retenus du voisin et
  /// l'embrase ; un porteur sous le seuil rougeoie seul. Le Feu recu
  /// s'affiche une fois par voisin, a la premiere arrivee de la vague.
  void playFireWave(FireWaveReport report) {
    final received = <String, int>{};
    for (final resolution in report.resolved) {
      for (final splash in resolution.splashes) {
        received[splash.targetId] =
            (received[splash.targetId] ?? 0) + splash.charge;
      }
    }
    final reached = <String>{};

    for (final resolution in report.resolved) {
      final bearer = _cardOf(resolution.bearerId);
      if (bearer == null) continue;
      if (resolution.tranches == 0) {
        bearer.emberFlash();
        continue;
      }
      game.add(
        FireBurst(
          position: bearer.position.clone(),
          radius: 1.5 * bearer.size.x * bearer.scale.x,
          onComplete: () {
            for (final splash in resolution.splashes) {
              final neighbour = _cardOf(splash.targetId);
              if (neighbour == null) continue;
              game.add(
                Fireball(
                  from: bearer.position,
                  to: neighbour.position.clone(),
                  onArrive: () {
                    if (!neighbour.isMounted) return;
                    neighbour.resolvePendingVisualStats();
                    neighbour.emberFlash();
                    if (!reached.add(neighbour.id)) return;
                    final charge = received[neighbour.id] ?? 0;
                    if (charge <= 0) return;
                    neighbour.spawnFloatingText(
                      '+$charge ${statusEmoji(resolution.chargeId)}',
                      FireBurst.edge,
                      neighbour.position +
                          Vector2(0, -neighbour.size.y * neighbour.scale.y / 2),
                    );
                  },
                ),
              );
            }
          },
        ),
      );
    }
  }

  /// La carte montee de l'ennemi [id], nulle si elle n'est plus en jeu.
  EnemyCard? _cardOf(String id) {
    for (final card in game.enemyCards) {
      if (card.id == id && card.isMounted) return card;
    }
    return null;
  }
}
