import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/components/entities/enemy_card.dart';
import 'package:roguelike_card_game/game/components/entities/enemy_health_bar.dart';
import 'package:roguelike_card_game/game/components/entities/status_tabs.dart';
import 'package:roguelike_card_game/game/systems/status_readout.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';

import 'tier_frame_fixture.dart';

/// La zone de la carte est son test d'appui (spec P-05 vague 2, A17) : ni la
/// barre ni les languettes ne prennent plus d'appui.
void main() {
  const gabarit = Rect.fromLTWH(16, 16, 88, 120); // le tier 5

  EnemyCard card(int tier) => EnemyCard(
        instance: EnemyInstance(
          id: 'e',
          data: const EnemyData(
            id: 'slime',
            maxHp: 18,
            baseDamage: 4,
            spritePath: 'slime.png',
          ),
          stats: EntityStats(maxPv: 18, currentPv: 18, armure: 0, might: 4),
        ),
        frame: testFrameOf(tier),
        windowBackground: null,
        onTapEnemy: (_, _) {},
      );

  test('ni la barre ni les languettes ne prennent d appui', () {
    expect(EnemyHealthBar(anchorRect: gabarit), isNot(isA<TapCallbacks>()));
    expect(
      StatusTabs(side: StatusSide.right, anchorRect: gabarit),
      isNot(isA<TapCallbacks>()),
    );
  });

  test('la zone de la carte recoit l appui jusqu au haut de sa barre, coins '
      'compris', () {
    final tier1 = card(1);
    expect(tier1.containsLocalPoint(Vector2(50, -2)), isTrue);
    expect(tier1.containsLocalPoint(Vector2(50, -18)), isFalse);

    // Au tier 2, la barre couvre x 4 à 92 ; les coins de part et d'autre,
    // au-dessus du canevas, sont à la carte.
    final tier2 = card(2);
    expect(tier2.containsLocalPoint(Vector2(2, -10)), isTrue);
    expect(tier2.containsLocalPoint(Vector2(94, -10)), isTrue);
    expect(tier2.containsLocalPoint(Vector2(2, -14)), isFalse);
    // Une épine du bord, un jour du cadre sous la fenêtre.
    expect(tier2.containsLocalPoint(Vector2(1, 60)), isTrue);
    expect(tier2.containsLocalPoint(Vector2(48, 125)), isTrue);
  });

  test('une languette deroulee vers l interieur garde son rectangle de repos '
      'dans la zone', () {
    final tabs = StatusTabs(side: StatusSide.right, anchorRect: gabarit);
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

    // Dans la carte : 120 est dans le rectangle de repos (103 à 133), hors du
    // rectangle dessiné, qui finit au bord droit du gabarit (104).
    const inRest = Offset(120, 30);
    expect(tabs.localRect!.contains(inRest), isFalse);
    expect(tabs.restLocalRect!.contains(inRest), isTrue);
    expect(tabs.zoneLocalRects.any((r) => r.contains(inRest)), isTrue);
    expect(
      tabs.zoneLocalRects.any((r) => r.contains(const Offset(150, 30))),
      isFalse,
    );
  });
}
