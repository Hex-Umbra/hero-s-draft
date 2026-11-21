import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/components/entities/enemy_health_bar.dart';
import 'package:roguelike_card_game/game/components/entities/status_tabs.dart';
import 'package:roguelike_card_game/game/systems/status_readout.dart';

void main() {
  test('la barre renvoie son appui a sa carte, pointeur compris', () {
    final events = <TapDownEvent>[];
    final bar = EnemyHealthBar(width: 100, onTap: events.add);

    bar.onTapDown(TapDownEvent(7, FlameGame(), TapDownDetails()));

    expect(events.single.pointerId, 7);
  });

  test('la zone d appui de la barre descend jusqu au haut de la carte', () {
    final bar = EnemyHealthBar(width: 100, onTap: (_) {});

    expect(bar.position, Vector2(0, -17));
    expect(bar.size, Vector2(100, 17));
    expect(bar.containsLocalPoint(Vector2(50, 15)), isTrue);
  });

  test('les languettes renvoient leur appui a leur carte', () {
    final events = <TapDownEvent>[];
    final tabs = StatusTabs(
      side: StatusSide.right,
      cardWidth: 100,
      onTap: events.add,
    );

    tabs.onTapDown(TapDownEvent(3, FlameGame(), TapDownDetails()));

    expect(events.single.pointerId, 3);
  });

  test('une languette deroulee vers l interieur garde son rectangle de repos '
      'pour l appui', () {
    final tabs = StatusTabs(
      side: StatusSide.right,
      cardWidth: 100,
      onTap: (_) {},
    );
    tabs.setEntries(const [
      StatusReadout(
        key: 'poison:',
        emoji: '🧪',
        restValue: '3',
        tone: ReadoutTone.debuff,
        title: 'Poison 3',
      ),
    ]);
    tabs.setUnfolded(true, inward: true);

    // Dans la carte : 120 est dans le rectangle de repos (99 à 129), hors du
    // rectangle dessiné, qui finit au bord droit de la carte (100).
    const inRest = Offset(120, 20);
    expect(tabs.localRect!.contains(inRest), isFalse);
    expect(tabs.restLocalRect!.contains(inRest), isTrue);

    Vector2 local(Offset card) =>
        Vector2(card.dx, card.dy) - tabs.position;
    expect(tabs.containsLocalPoint(local(inRest)), isTrue);
    expect(tabs.containsLocalPoint(local(const Offset(150, 20))), isFalse);
  });
}
