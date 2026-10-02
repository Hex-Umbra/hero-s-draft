import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/damage_pipeline.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';

/// Le critique que la carte jouée ajoute à celui de l'attaquant (spec P-43
/// E2, §4.2, A10) : `precise`.
void main() {
  // Ni critique, ni statut : seul le bonus de la carte peut critiquer.
  EntityStats stats() =>
      EntityStats(maxPv: 100, currentPv: 100, armure: 0, might: 0);

  test('critChanceBonus s ajoute au jet : a 100 points, le coup est critique',
      () {
    for (var i = 0; i < 20; i++) {
      final (damage, isCrit) = DamagePipeline.calculate(
        initialDamage: 10,
        attackerStats: stats(),
        defenderStats: stats(),
        critChanceBonus: 100,
      );
      expect((damage, isCrit), (15, true));
    }
  });

  test('0 par defaut : le jet d aujourd hui, sans critique a 0 %', () {
    for (var i = 0; i < 20; i++) {
      expect(
        DamagePipeline.calculate(
          initialDamage: 10,
          attackerStats: stats(),
          defenderStats: stats(),
        ),
        (10, false),
      );
    }
  });
}
