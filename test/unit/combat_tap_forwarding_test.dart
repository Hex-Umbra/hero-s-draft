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
}
